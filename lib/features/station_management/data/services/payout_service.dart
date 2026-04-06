import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/payout_settle_entity.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/logger_service.dart';

/// Handles payout settlement operations.
class PayoutService {
  final SupabaseClient _client;
  final StorageService _storage;

  PayoutService(this._client, this._storage);

  /// Fetch pending payout requests.
  Future<List<PayoutSettleEntity>> getPendingPayouts() async {
    final rows = await _client
        .from('payout_requests')
        .select('*, driver:driver_id(full_name)')
        .eq('status', 'pending')
        .order('created_at', ascending: false);

    return (rows as List)
        .map((e) => PayoutSettleEntity.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Upload proof image and mark payout as settled.
  Future<PayoutSettleEntity> settleWithProof({
    required String payoutId,
    required String managerId,
    required File proofImage,
  }) async {
    LoggerService.info('💰 Settling payout $payoutId');

    // Upload to storage bucket (reuse existing StorageService)
    final proofUrl = await _storage.uploadPaymentProof(proofImage, managerId);

    // Update payout record
    final updated = await _client
        .from('payout_requests')
        .update({
          'status': 'settled',
          'proof_url': proofUrl,
          'settled_at': DateTime.now().toIso8601String(),
          'settled_by': managerId,
        })
        .eq('id', payoutId)
        .select('*, driver:driver_id(full_name)')
        .single();

    LoggerService.info('✅ Payout $payoutId settled');
    return PayoutSettleEntity.fromJson(updated as Map<String, dynamic>);
  }
}
