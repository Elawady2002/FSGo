import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/providers/storage_provider.dart';

abstract class WalletRepository {
  Future<Either<Failure, double>> getBalance(String userId);
  Future<Either<Failure, double>> deductAmount(
    String userId,
    double amount,
    String reason,
  );
  Future<Either<Failure, double>> addAmount(
    String userId,
    double amount,
    String reason,
  );
  Future<Either<Failure, List<Map<String, dynamic>>>> getTransactions(
    String userId,
  );
  Future<Either<Failure, void>> createWalletRequest({
    required String userId,
    required double amount,
    required String method,
    File? imageFile,
    required String phoneNumber,
  });
}

class WalletRepositoryImpl implements WalletRepository {
  final SupabaseClient _supabase;
  final StorageService? _storageService;

  WalletRepositoryImpl(this._supabase, {StorageService? storageService})
      : _storageService = storageService;

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getTransactions(
    String userId,
  ) async {
    try {
      AppLogger.info('📜 Fetching wallet transactions for user: $userId');

      final response = await _supabase
          .from('wallet_transactions')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return Right(List<Map<String, dynamic>>.from(response));
    } catch (e) {
      AppLogger.error('❌ Error fetching transactions: $e');
      return Left(ServerFailure(message: 'فشل في تحميل العمليات'));
    }
  }

  @override
  Future<Either<Failure, double>> getBalance(String userId) async {
    try {
      AppLogger.info('📊 Fetching wallet balance for user: $userId');

      final response = await _supabase
          .from('users')
          .select('wallet_balance')
          .eq('id', userId)
          .single();

      final balance = (response['wallet_balance'] as num?)?.toDouble() ?? 0.0;

      AppLogger.info('✅ Balance fetched: $balance');
      return Right(balance);
    } catch (e) {
      AppLogger.error('❌ Error fetching balance: $e');
      return Left(ServerFailure(message: 'فشل في تحميل الرصيد'));
    }
  }

  @override
  Future<Either<Failure, double>> deductAmount(
    String userId,
    double amount,
    String reason,
  ) async {
    try {
      AppLogger.info('💸 Deducting $amount from wallet via RPC for: $reason');

      final response = await _supabase.rpc(
        'handle_wallet_deduction',
        params: {
          'p_user_id': userId,
          'p_amount': amount,
          'p_reason': reason,
        },
      );

      final newBalance = (response as num).toDouble();
      AppLogger.info('✅ Amount deducted via RPC. New balance: $newBalance');
      return Right(newBalance);
    } catch (e) {
      AppLogger.error('❌ Error deducting amount via RPC: $e');
      if (e.toString().contains('رصيد غير كافي')) {
        return Left(ServerFailure(message: 'رصيد غير كافي'));
      }
      return Left(ServerFailure(message: 'فشل في خصم المبلغ'));
    }
  }

  @override
  Future<Either<Failure, double>> addAmount(
    String userId,
    double amount,
    String reason,
  ) async {
    try {
      AppLogger.info('💰 Adding $amount to wallet via RPC for: $reason');

      final response = await _supabase.rpc(
        'handle_wallet_addition',
        params: {
          'p_user_id': userId,
          'p_amount': amount,
          'p_reason': reason,
        },
      );

      final newBalance = (response as num).toDouble();
      AppLogger.info('✅ Amount added via RPC. New balance: $newBalance');
      return Right(newBalance);
    } catch (e) {
      AppLogger.error('❌ Error adding amount via RPC: $e');
      return Left(ServerFailure(message: 'فشل في إضافة المبلغ'));
    }
  }

  @override
  Future<Either<Failure, void>> createWalletRequest({
    required String userId,
    required double amount,
    required String method,
    File? imageFile,
    required String phoneNumber,
  }) async {
    try {
      AppLogger.info('📝 Creating wallet recharge request for user $userId');

      String proofImageUrl = '';
      if (imageFile != null && _storageService != null) {
        proofImageUrl = await _storageService!.uploadPaymentProof(imageFile, userId);
      }

      // 1. Insert ONLY into the new unified table 'wallet_requests'
      await _supabase.from('wallet_requests').insert({
        'user_id': userId,
        'amount': amount,
        'method': method,
        'type': 'topup', // Hardcoded as requested
        'proof_image_url': proofImageUrl,
        'phone_number': phoneNumber,
        'status': 'pending',
      });

      AppLogger.info('✅ Wallet recharge request created successfully');
      return const Right(null);
    } catch (e) {
      AppLogger.error('❌ Error creating wallet request: $e');
      return Left(ServerFailure(message: 'فشل في إرسال الطلب: $e'));
    }
  }
}

// Provider
final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  final supabase = Supabase.instance.client;
  try {
    // Attempt to watch the storage provider if it exists
    final storageService = ref.watch(storageServiceProvider);
    return WalletRepositoryImpl(supabase, storageService: storageService);
  } catch (e) {
    return WalletRepositoryImpl(supabase);
  }
});
