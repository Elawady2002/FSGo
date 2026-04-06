import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/services/payout_service.dart';
import '../../domain/entities/payout_settle_entity.dart';
import '../../../../core/services/storage_service.dart';

// ── DI ────────────────────────────────────────────────────────

final payoutServiceProvider = Provider<PayoutService>((ref) {
  final client = Supabase.instance.client;
  return PayoutService(client, StorageService(client));
});

// ── Payout List ────────────────────────────────────────────────

final pendingPayoutsProvider =
    FutureProvider<List<PayoutSettleEntity>>((ref) {
  return ref.watch(payoutServiceProvider).getPendingPayouts();
});

// ── Settlement Notifier ────────────────────────────────────────

class SettlementState {
  final bool isLoading;
  final String? error;
  final bool settled;

  const SettlementState({
    this.isLoading = false,
    this.error,
    this.settled = false,
  });

  SettlementState copyWith(
          {bool? isLoading, String? error, bool? settled}) =>
      SettlementState(
        isLoading: isLoading ?? this.isLoading,
        error: error,
        settled: settled ?? this.settled,
      );
}

class SettlementNotifier extends StateNotifier<SettlementState> {
  final PayoutService _service;
  final Ref _ref;

  SettlementNotifier(this._service, this._ref)
      : super(const SettlementState());

  Future<void> settle({
    required String payoutId,
    required String managerId,
    required File proofImage,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.settleWithProof(
        payoutId: payoutId,
        managerId: managerId,
        proofImage: proofImage,
      );
      // Refresh the payout list
      _ref.invalidate(pendingPayoutsProvider);
      state = state.copyWith(isLoading: false, settled: true);
    } catch (e) {
      state = state.copyWith(
          isLoading: false, error: 'فشل التسوية: ${e.toString()}');
    }
  }
}

final settlementProvider =
    StateNotifierProvider<SettlementNotifier, SettlementState>((ref) {
  return SettlementNotifier(ref.watch(payoutServiceProvider), ref);
});
