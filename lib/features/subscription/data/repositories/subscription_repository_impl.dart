import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/subscription_entity.dart';
import '../../domain/entities/installment_entity.dart';
import '../../domain/entities/subscription_schedule_entity.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../datasources/subscription_data_source.dart';

/// Subscription repository implementation
class SubscriptionRepositoryImpl implements SubscriptionRepository {
  final SubscriptionDataSource _dataSource;

  SubscriptionRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, void>> createSubscription({
    required String userId,
    required SubscriptionPlanType planType,
    required String? paymentProofUrl,
    required String? transferNumber,
    bool isInstallment = false,
    SubscriptionScheduleParams? scheduleParams,
  }) async {
    try {
      // 1. Create the subscription record
      final subscriptionId = await _dataSource.createSubscription(
        userId: userId,
        planType: planType,
        paymentProofUrl: paymentProofUrl,
        transferNumber: transferNumber,
        isInstallment: isInstallment,
      );

      // 2. If monthly plan and schedule params provided, generate 26 bookings
      if (planType == SubscriptionPlanType.monthly && scheduleParams != null) {
        DateTime currentDate = scheduleParams.startDate;
        int bookingsCreated = 0;

        while (bookingsCreated < 26) {
          // Skip Fridays (Friday is weekday 5 in Dart if Monday is 1? No, in Dart:
          // Monday=1, ..., Friday=5, Saturday=6, Sunday=7)
          // Wait, let's verify Dart weekday. DateTime.friday constant is 5.
          if (currentDate.weekday != DateTime.friday) {
            await _dataSource.createOrUpdateSchedule(
              subscriptionId: subscriptionId,
              tripDate: currentDate,
              tripType: scheduleParams.tripType,
              departureTime: scheduleParams.departureTime,
              returnTime: scheduleParams.returnTime,
            );
            bookingsCreated++;
          }
          currentDate = currentDate.add(const Duration(days: 1));
        }
      }

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, SubscriptionEntity?>> getUserSubscription(
    String userId,
  ) async {
    try {
      final data = await _dataSource.getUserSubscription(userId);
      if (data == null) return const Right(null);

      // Convert to entity
      final subscription = SubscriptionEntity(
        userId: userId,
        planType: SubscriptionPlanType.fromJson(
          data['subscription_type'] as String,
        ),
        amount: SubscriptionPlanType.fromJson(
          data['subscription_type'] as String,
        ).price,
        status: SubscriptionStatus.fromJson(
          data['subscription_status'] as String,
        ),
        startDate: DateTime.parse(data['subscription_start_date'] as String),
        endDate: DateTime.parse(data['subscription_end_date'] as String),
        createdAt: DateTime.parse(data['subscription_start_date'] as String),
      );

      return Right(subscription);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<SubscriptionEntity>>> getUserSubscriptions(
    String userId,
  ) async {
    try {
      final dataList = await _dataSource.getUserSubscriptions(userId);
      print('DEBUG: Fetched ${dataList.length} subscriptions for user $userId');
      for (var d in dataList) {
        print(
          'DEBUG: Sub: ${d['id']}, Status: ${d['status']}, End: ${d['end_date']}',
        );
      }

      final subscriptions = dataList.map((data) {
        return SubscriptionEntity(
          id: data['id'] as String?,
          userId: data['user_id'] as String,
          planType: SubscriptionPlanType.fromJson(data['plan_type'] as String),
          amount: (data['total_price'] as num).toDouble(),
          paymentProofUrl: data['payment_proof_url'] as String?,
          transferNumber: data['transfer_number'] as String?,
          status: SubscriptionStatus.fromJson(data['status'] as String),
          startDate: DateTime.parse(data['start_date'] as String),
          endDate: DateTime.parse(data['end_date'] as String),
          createdAt: DateTime.parse(data['created_at'] as String),
          allowLocationChange: data['allow_location_change'] as bool? ?? false,
          isInstallment: data['is_installment'] as bool? ?? false,
        );
      }).toList();

      return Right(subscriptions);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<InstallmentEntity>>> getSubscriptionInstallments(
    String subscriptionId,
  ) async {
    try {
      final dataList = await _dataSource.getSubscriptionInstallments(
        subscriptionId,
      );

      final installments = dataList.map((data) {
        return InstallmentEntity(
          id: data['id'] as String,
          subscriptionId: data['subscription_id'] as String,
          amount: (data['amount'] as num).toDouble(),
          dueDate: DateTime.parse(data['due_date'] as String),
          status: InstallmentStatus.fromJson(data['status'] as String),
          paymentDate: data['payment_date'] != null
              ? DateTime.parse(data['payment_date'] as String)
              : null,
          createdAt: DateTime.parse(data['created_at'] as String),
        );
      }).toList();

      return Right(installments);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, SubscriptionScheduleEntity>> createOrUpdateSchedule({
    required String subscriptionId,
    required DateTime tripDate,
    required String tripType,
    String? departureTime,
    String? returnTime,
  }) async {
    try {
      final data = await _dataSource.createOrUpdateSchedule(
        subscriptionId: subscriptionId,
        tripDate: tripDate,
        tripType: tripType,
        departureTime: departureTime,
        returnTime: returnTime,
      );

      final schedule = SubscriptionScheduleEntity.fromJson(data);
      return Right(schedule);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<SubscriptionScheduleEntity>>>
  getSubscriptionSchedules(String subscriptionId) async {
    try {
      final dataList = await _dataSource.getSubscriptionSchedules(
        subscriptionId,
      );

      final schedules = dataList.map((data) {
        return SubscriptionScheduleEntity.fromJson(data);
      }).toList();

      return Right(schedules);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteSchedule(String scheduleId) async {
    try {
      await _dataSource.deleteSchedule(scheduleId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> cancelSubscription(
    String subscriptionId,
  ) async {
    try {
      await _dataSource.cancelSubscription(subscriptionId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
