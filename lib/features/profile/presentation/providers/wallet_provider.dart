import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/logger.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/wallet_repository.dart';

// Wallet State
class WalletState {
  final double balance;
  final bool isLoading;
  final String? error;

  const WalletState({this.balance = 0.0, this.isLoading = false, this.error});

  WalletState copyWith({double? balance, bool? isLoading, String? error}) {
    return WalletState(
      balance: balance ?? this.balance,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Wallet Provider
class WalletNotifier extends StateNotifier<WalletState> {
  final WalletRepository _repository;
  final String _userId;

  WalletNotifier(this._repository, this._userId) : super(const WalletState()) {
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    if (_userId.isEmpty) return; // Guard against unauthenticated calls
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _repository.getBalance(_userId);

      result.fold(
        (failure) {
          AppLogger.error('Failed to load wallet balance: ${failure.message}');
          state = state.copyWith(isLoading: false, error: failure.message);
        },
        (balance) {
          AppLogger.info('Wallet balance loaded: $balance');
          state = state.copyWith(
            balance: balance,
            isLoading: false,
            error: null,
          );
        },
      );
    } catch (e) {
      AppLogger.error('Error loading wallet balance: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'حدث خطأ في تحميل الرصيد',
      );
    }
  }

  Future<bool> deductAmount(double amount, String reason) async {
    if (state.balance < amount) {
      AppLogger.warning('Insufficient balance: ${state.balance} < $amount');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _repository.deductAmount(_userId, amount, reason);

      return result.fold(
        (failure) {
          AppLogger.error('Failed to deduct amount: ${failure.message}');
          state = state.copyWith(isLoading: false, error: failure.message);
          return false;
        },
        (newBalance) {
          AppLogger.info(
            'Amount deducted successfully. New balance: $newBalance',
          );
          state = state.copyWith(
            balance: newBalance,
            isLoading: false,
            error: null,
          );
          return true;
        },
      );
    } catch (e) {
      AppLogger.error('Error deducting amount: $e');
      state = state.copyWith(isLoading: false, error: 'حدث خطأ في خصم المبلغ');
      return false;
    }
  }

  Future<bool> addAmount(double amount, String reason) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _repository.addAmount(_userId, amount, reason);

      return result.fold(
        (failure) {
          AppLogger.error('Failed to add amount: ${failure.message}');
          state = state.copyWith(isLoading: false, error: failure.message);
          return false;
        },
        (newBalance) {
          AppLogger.info('Amount added successfully. New balance: $newBalance');
          state = state.copyWith(
            balance: newBalance,
            isLoading: false,
            error: null,
          );
          return true;
        },
      );
    } catch (e) {
      AppLogger.error('Error adding amount: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'حدث خطأ في إضافة المبلغ',
      );
      return false;
    }
  }

  bool canAfford(double amount) {
    return state.balance >= amount;
  }

  Future<void> refresh() async {
    await _loadBalance();
  }

  Future<bool> requestTopUp({
    required double amount,
    required String method,
    required String proofUrl,
    required String senderPhone,
    bool isWithdraw = false,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final String reason = isWithdraw
          ? 'سحب رصيد - $method ($senderPhone)'
          : 'شحن رصيد - $method ($senderPhone)';

      final result = isWithdraw
          ? await _repository.deductAmount(_userId, amount, reason)
          : await _repository.addAmount(_userId, amount, reason);

      return result.fold(
        (failure) {
          AppLogger.error('Failed to process wallet request: ${failure.message}');
          state = state.copyWith(isLoading: false, error: failure.message);
          return false;
        },
        (newBalance) {
          AppLogger.info(
            'Wallet request processed successfully. New balance: $newBalance',
          );
          state = state.copyWith(
            balance: newBalance,
            isLoading: false,
            error: null,
          );
          return true;
        },
      );
    } catch (e) {
      AppLogger.error('Error processing wallet request: $e');
      state = state.copyWith(
        isLoading: false,
        error: isWithdraw ? 'حدث خطأ في طلب السحب' : 'حدث خطأ في طلب الشحن',
      );
      return false;
    }
  }
}

// Provider
final walletProvider = StateNotifierProvider<WalletNotifier, WalletState>((
  ref,
) {
  final user = ref.watch(authProvider).value;
  // Instead of throwing, return a notifier with a safe fallback
  // This prevents the app from crashing if the provider is built before auth
  if (user == null) {
    // Return a dummy notifier that does nothing or handles re-auth
    final repository = ref.watch(walletRepositoryProvider);
    return WalletNotifier(repository, ''); 
  }

  final repository = ref.watch(walletRepositoryProvider);
  return WalletNotifier(repository, user.id);
});

final walletTransactionsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final user = ref.watch(authProvider).value;
  if (user == null) return [];

  final repository = ref.watch(walletRepositoryProvider);
  final result = await repository.getTransactions(user.id);

  return result.fold((failure) => throw Exception(failure.message), (transactions) => transactions);
});
