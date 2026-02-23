import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/logger.dart';

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
    required String type,
    required String proofUrl,
    required String senderPhone,
  });
}

class WalletRepositoryImpl implements WalletRepository {
  final SupabaseClient _supabase;

  WalletRepositoryImpl(this._supabase);

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
      AppLogger.info('💸 Deducting $amount from wallet for: $reason');

      // Get current balance
      final balanceResult = await getBalance(userId);
      final currentBalance = balanceResult.fold(
        (failure) => throw Exception(failure.message),
        (balance) => balance,
      );

      if (currentBalance < amount) {
        AppLogger.warning('⚠️ Insufficient balance: $currentBalance < $amount');
        return Left(ServerFailure(message: 'رصيد غير كافي'));
      }

      final newBalance = currentBalance - amount;

      // Update balance
      await _supabase
          .from('users')
          .update({'wallet_balance': newBalance})
          .eq('id', userId);

      // Record transaction
      await _supabase.from('wallet_transactions').insert({
        'user_id': userId,
        'amount': amount,
        'type': 'debit',
        'reason': reason,
        'balance_after': newBalance,
      });

      AppLogger.info('✅ Amount deducted. New balance: $newBalance');
      return Right(newBalance);
    } catch (e) {
      AppLogger.error('❌ Error deducting amount: $e');
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
      AppLogger.info('💰 Adding $amount to wallet for: $reason');

      // Get current balance
      final balanceResult = await getBalance(userId);
      final currentBalance = balanceResult.fold(
        (failure) => throw Exception(failure.message),
        (balance) => balance,
      );

      final newBalance = currentBalance + amount;

      // Update balance
      await _supabase
          .from('users')
          .update({'wallet_balance': newBalance})
          .eq('id', userId);

      // Record transaction
      await _supabase.from('wallet_transactions').insert({
        'user_id': userId,
        'amount': amount,
        'type': 'credit',
        'reason': reason,
        'balance_after': newBalance,
      });

      AppLogger.info('✅ Amount added. New balance: $newBalance');
      return Right(newBalance);
    } catch (e) {
      return Left(ServerFailure(message: 'فشل في إضافة المبلغ'));
    }
  }

  @override
  Future<Either<Failure, void>> createWalletRequest({
    required String userId,
    required double amount,
    required String method,
    required String type,
    required String proofUrl,
    required String senderPhone,
  }) async {
    try {
      AppLogger.info('📝 Creating wallet $type request for user $userId');

      // 1. Insert the recharge request for admin review
      await _supabase.from('wallet_recharge_requests').insert({
        'user_id': userId,
        'amount': amount,
        'method': method,
        'type': type,
        'proof_url': proofUrl,
        'sender_phone': senderPhone,
        'status': 'pending',
      });

      // 2. Insert a pending transaction so it shows in user's history
      final reason = type == 'withdraw'
          ? 'سحب رصيد - $method ($senderPhone)'
          : 'شحن رصيد - $method ($senderPhone)';

      await _supabase.from('wallet_transactions').insert({
        'user_id': userId,
        'amount': amount,
        'type': type == 'withdraw' ? 'debit' : 'credit',
        'reason': reason,
        'status': 'pending',
      });

      return const Right(null);
    } catch (e) {
      AppLogger.error('❌ Error creating wallet request: $e');
      return Left(ServerFailure(message: 'فشل في إرسال الطلب'));
    }
  }
}

// Provider
final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  final supabase = Supabase.instance.client;
  return WalletRepositoryImpl(supabase);
});
