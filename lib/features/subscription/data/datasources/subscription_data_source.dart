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
  });

  Future<Map<String, dynamic>?> getUserSubscription(String userId);

  Future<List<Map<String, dynamic>>> getUserSubscriptions(String userId);

  Future<List<Map<String, dynamic>>> getSubscriptionInstallments(
    String subscriptionId,
  );

  // Subscription Schedule methods
  Future<Map<String, dynamic>> createOrUpdateSchedule({
    required String subscriptionId,
    required DateTime tripDate,
    required String tripType,
    String? departureTime,
    String? returnTime,
  });

  Future<List<Map<String, dynamic>>> getSubscriptionSchedules(
    String subscriptionId,
  );

  Future<void> deleteSchedule(String scheduleId);

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
          })
          .select()
          .single();

      final subscriptionId = subscription['id'];

      // Create installments if applicable
      if (isInstallment && planType == SubscriptionPlanType.semester) {
        final installmentAmount = finalPrice / 3;

        for (int i = 0; i < 3; i++) {
          final dueDate = now.add(Duration(days: i * 30)); // Monthly

          await _supabase.from('subscription_installments').insert({
            'subscription_id': subscriptionId,
            'amount': installmentAmount,
            'due_date': dueDate.toIso8601String(),
            'status': i == 0
                ? 'pending'
                : 'pending', // First one might be paid immediately? Kept pending for manual approval
            'created_at': now.toIso8601String(),
          });
        }
      }

      // Update user's profile with current subscription details
      await _supabase
          .from('users')
          .update({
            'subscription_type': planType.name,
            'subscription_start_date': now.toIso8601String(),
            'subscription_end_date': endDate.toIso8601String(),
            'subscription_status': SubscriptionStatus.pending.name,
          })
          .eq('id', userId);

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
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get user subscriptions', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getSubscriptionInstallments(
    String subscriptionId,
  ) async {
    try {
      final response = await _supabase
          .from('subscription_installments')
          .select()
          .eq('subscription_id', subscriptionId)
          .order('due_date', ascending: true);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get subscription installments', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> createOrUpdateSchedule({
    required String subscriptionId,
    required DateTime tripDate,
    required String tripType,
    String? departureTime,
    String? returnTime,
  }) async {
    try {
      final dateString = tripDate.toIso8601String().split('T')[0];

      // Check if schedule already exists
      final existing = await _supabase
          .from('subscription_schedules')
          .select()
          .eq('subscription_id', subscriptionId)
          .eq('trip_date', dateString)
          .maybeSingle();

      if (existing != null) {
        // Update existing schedule
        final updated = await _supabase
            .from('subscription_schedules')
            .update({
              'trip_type': tripType,
              'departure_time': departureTime,
              'return_time': returnTime,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', existing['id'])
            .select()
            .single();
        return updated;
      } else {
        // Create new schedule
        final created = await _supabase
            .from('subscription_schedules')
            .insert({
              'subscription_id': subscriptionId,
              'trip_date': dateString,
              'trip_type': tripType,
              'departure_time': departureTime,
              'return_time': returnTime,
            })
            .select()
            .single();
        return created;
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to create/update schedule', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getSubscriptionSchedules(
    String subscriptionId,
  ) async {
    try {
      final response = await _supabase
          .from('subscription_schedules')
          .select()
          .eq('subscription_id', subscriptionId)
          .order('trip_date', ascending: true);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get subscription schedules', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> deleteSchedule(String scheduleId) async {
    try {
      await _supabase
          .from('subscription_schedules')
          .delete()
          .eq('id', scheduleId);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to delete schedule', e, stackTrace);
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
      final userId = subscription['user_id'] as String;

      // Update subscription status to expired
      AppLogger.info('⏳ Updating subscription status to expired...');
      await _supabase
          .from('subscriptions')
          .update({
            'status': SubscriptionStatus.expired.name,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', subscriptionId);
      AppLogger.info('✅ Subscription status updated');

      // Update user's subscription status to expired
      AppLogger.info('⏳ Updating user subscription status...');
      await _supabase
          .from('users')
          .update({
            'subscription_status': SubscriptionStatus.expired.name,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);
      AppLogger.info('✅ User subscription status updated');

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
