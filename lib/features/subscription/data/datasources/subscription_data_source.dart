import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/subscription_entity.dart';

/// Subscription data source interface
abstract class SubscriptionDataSource {
  Future<String> createSubscription({
    required String userId,
    required SubscriptionPlanType planType,
    required String? paymentProofUrl,
    required String? transferNumber,
    bool isInstallment = false,
    String? tripType,
    String? pickupStationId,
    String? dropoffStationId,
  });

  Future<Map<String, dynamic>?> getUserSubscription(String userId);

  Future<List<Map<String, dynamic>>> getUserSubscriptions(String userId);

  Future<void> cancelSubscription(String subscriptionId);
}

/// Subscription data source implementation
class SubscriptionDataSourceImpl implements SubscriptionDataSource {
  final SupabaseClient _supabase;

  SubscriptionDataSourceImpl(this._supabase);

  @override
  Future<String> createSubscription({
    required String userId,
    required SubscriptionPlanType planType,
    required String? paymentProofUrl,
    required String? transferNumber,
    bool isInstallment = false,
    String? tripType,
    String? pickupStationId,
    String? dropoffStationId,
  }) async {
    try {
      final now = DateTime.now();
      final endDate = now.add(Duration(days: planType.durationDays));

      AppLogger.info('Creating subscription for user $userId');
      AppLogger.info(
        'Plan: ${planType.name}, Duration: ${planType.durationDays} days',
      );
      AppLogger.info('Start: $now, End: $endDate');

      // Calculate price and interest
      double finalPrice = planType.price;
      double interestRate = 0.0;

      if (isInstallment && planType == SubscriptionPlanType.semester) {
        interestRate = 0.05; // 5% service fee
        finalPrice = finalPrice * (1 + interestRate);
      }

      // Insert into subscriptions table (transaction record)
      final subscription = await _supabase
          .from('subscriptions')
          .insert({
            'user_id': userId,
            'plan_type': planType.name,
            'total_price': finalPrice,
            'payment_proof_url': paymentProofUrl,
            'transfer_number': transferNumber,
            'status': SubscriptionStatus.pending.name,
            'start_date': now.toIso8601String(),
            'end_date': endDate.toIso8601String(),
            'is_installment': isInstallment,
            'allow_location_change': planType == SubscriptionPlanType.semester,
            'interest_rate': interestRate,
            'trip_type': tripType,
            'pickup_station_id': pickupStationId,
            'dropoff_station_id': dropoffStationId,
          })
          .select()
          .single();

      final subscriptionId = subscription['id'];

      AppLogger.info('✅ Subscription created successfully');
      return subscriptionId;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to create subscription', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>?> getUserSubscription(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select(
            'subscription_type, subscription_start_date, subscription_end_date, subscription_status',
          )
          .eq('id', userId)
          .maybeSingle();

      return response;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get user subscription', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getUserSubscriptions(String userId) async {
    try {
      final response = await _supabase
          .from('subscriptions')
          .select()
          .eq('id', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get user subscriptions', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> cancelSubscription(String subscriptionId) async {
    try {
      AppLogger.info(
        '🔴 Starting cancellation for subscription: $subscriptionId',
      );

      // First, get the subscription to find the user_id
      final subscription = await _supabase
          .from('subscriptions')
          .select('user_id, status')
          .eq('id', subscriptionId)
          .single();

      AppLogger.info('📋 Current subscription data: $subscription');

      // Update subscription status to expired and add cancellation metadata
      AppLogger.info('⏳ Updating subscription status to expired...');
      await _supabase
          .from('subscriptions')
          .update({
            'status': SubscriptionStatus.expired.name,
            'updated_at': DateTime.now().toIso8601String(),
            'cancelled_at': DateTime.now().toIso8601String(),
            'cancellation_reason': 'User requested cancellation',
          })
          .eq('id', subscriptionId);
      AppLogger.info('✅ Subscription status updated');

      // The 'trigger_sync_subscription_status' in the database will automatically
      // update the user's status in the 'users' table.

      // Verify the update
      final verifySubscription = await _supabase
          .from('subscriptions')
          .select('status')
          .eq('id', subscriptionId)
          .single();
      AppLogger.info(
        '🔍 Verified subscription status: ${verifySubscription['status']}',
      );

      AppLogger.info('✅ Subscription canceled successfully');
    } catch (e, stackTrace) {
      AppLogger.error('❌ Failed to cancel subscription', e, stackTrace);
      rethrow;
    }
  }
}
