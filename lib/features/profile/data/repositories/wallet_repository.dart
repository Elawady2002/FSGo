import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/logger.dart';

abstract class WalletRepository {
  Future<Either<Failure, double>> getBalance(String userId);
  Future<Either<Failure, double>> deductAmount(String userId, double amount, String reason);
  Future<Either<Failure, double>> addAmount(String userId, double amount, String reason);
}

class WalletRepositoryImpl implements WalletRepository {
  final SupabaseClient _supabase;

  WalletRepositoryImpl(this._supabase);

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
      AppLogger.error('❌ Error adding amount: $e');
      return Left(ServerFailure(message: 'فشل في إضافة المبلغ'));
    }
  }
}

// Provider
final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  final supabase = Supabase.instance.client;
  return WalletRepositoryImpl(supabase);
});
