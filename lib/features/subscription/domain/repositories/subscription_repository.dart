import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/subscription_entity.dart';
import '../entities/installment_entity.dart';
import '../entities/subscription_schedule_entity.dart';

/// Subscription repository interface
abstract class SubscriptionRepository {
  /// Create a new subscription for a user
  Future<Either<Failure, void>> createSubscription({
    required String userId,
    required SubscriptionPlanType planType,
    required String? paymentProofUrl,
    required String? transferNumber,
    bool isInstallment = false,
    SubscriptionScheduleParams? scheduleParams,
  });

  /// Get subscription installments
  Future<Either<Failure, List<InstallmentEntity>>> getSubscriptionInstallments(
    String subscriptionId,
  );

  /// Get user's active subscription
  Future<Either<Failure, SubscriptionEntity?>> getUserSubscription(
    String userId,
  );

  /// Get all user subscriptions (transaction history)
  Future<Either<Failure, List<SubscriptionEntity>>> getUserSubscriptions(
    String userId,
  );

  /// Create or update a subscription schedule for a specific day
  Future<Either<Failure, SubscriptionScheduleEntity>> createOrUpdateSchedule({
    required String subscriptionId,
    required DateTime tripDate,
    required String tripType,
    String? departureTime,
    String? returnTime,
  });

  /// Get all schedules for a subscription
  Future<Either<Failure, List<SubscriptionScheduleEntity>>>
  getSubscriptionSchedules(String subscriptionId);

  /// Delete a schedule
  Future<Either<Failure, void>> deleteSchedule(String scheduleId);

  /// Cancel a subscription
  Future<Either<Failure, void>> cancelSubscription(String subscriptionId);
}
