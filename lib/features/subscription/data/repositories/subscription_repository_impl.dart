import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../../booking/data/datasources/booking_data_source.dart';
import '../../domain/entities/subscription_entity.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../datasources/subscription_data_source.dart';

/// Subscription repository implementation
class SubscriptionRepositoryImpl implements SubscriptionRepository {
  final SubscriptionDataSource _dataSource;
  final BookingDataSource _bookingDataSource;

  SubscriptionRepositoryImpl(this._dataSource, this._bookingDataSource);

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
      AppLogger.info('🔵 Starting subscription creation...');
      AppLogger.info('   Plan type: ${planType.name}');
      AppLogger.info('   Has schedule params: ${scheduleParams != null}');

      // 1. Create the subscription record
      final subscriptionId = await _dataSource.createSubscription(
        userId: userId,
        planType: planType,
        paymentProofUrl: paymentProofUrl,
        transferNumber: transferNumber,
        isInstallment: isInstallment,
        tripType: scheduleParams?.tripType,
        pickupStationId: scheduleParams?.pickupStationId,
        dropoffStationId: scheduleParams?.dropoffStationId,
      );

      AppLogger.info('✅ Subscription created with ID: $subscriptionId');

      // 2. If monthly plan and schedule params provided, generate 26 bookings in bookings table
      if (planType == SubscriptionPlanType.monthly && scheduleParams != null) {
        AppLogger.info('🔵 Creating 26 bookings for monthly subscription...');

        DateTime currentDate = scheduleParams.startDate;
        int bookingsCreated = 0;

        // Get subscription end date (same day next month)
        final endDate = DateTime(
          scheduleParams.startDate.year,
          scheduleParams.startDate.month + 1,
          scheduleParams.startDate.day,
        );

        AppLogger.info('   Start date: $currentDate');
        AppLogger.info('   End date: $endDate');

        // Use universityId as scheduleId temporarily
        // This allows the system to work while proper route selection is being implemented
        final scheduleId =
            scheduleParams.scheduleId ?? '00000000-0000-0000-0000-000000000000';
        AppLogger.info('   Schedule ID: $scheduleId');

        while (bookingsCreated < 26 && currentDate.isBefore(endDate)) {
          // Skip Fridays (Friday is weekday 5 in Dart)
          if (currentDate.weekday != DateTime.friday) {
            AppLogger.info('   Creating booking for date: $currentDate');

            // Create booking in bookings table
            await _bookingDataSource.createSubscriptionBooking(
              userId: userId,
              subscriptionId: subscriptionId,
              scheduleId: scheduleId,
              bookingDate: currentDate,
              tripType: scheduleParams.tripType,
              pickupStationId: scheduleParams.pickupStationId,
              dropoffStationId: scheduleParams.dropoffStationId,
              departureTime: scheduleParams.departureTime,
              returnTime: scheduleParams.returnTime,
              totalPrice: 0.0, // Price is already paid in subscription
            );
            bookingsCreated++;
          }
          currentDate = currentDate.add(const Duration(days: 1));
        }

        AppLogger.info('✅ Created $bookingsCreated bookings successfully!');
      } else {
        AppLogger.warning('⚠️ Skipping booking creation:');
        AppLogger.warning(
          '   Is monthly: ${planType == SubscriptionPlanType.monthly}',
        );
        AppLogger.warning('   Has params: ${scheduleParams != null}');
      }

      return const Right(null);
    } catch (e, stackTrace) {
      AppLogger.error('❌ Error creating subscription: $e');
      AppLogger.error('   Stack trace: $stackTrace');
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
        tripType: data['trip_type'] as String? ?? 'round_trip',
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
      AppLogger.info(
        'DEBUG: Fetched ${dataList.length} subscriptions for user $userId',
      );
      for (var d in dataList) {
        AppLogger.info(
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
          tripType: data['trip_type'] as String? ?? 'round_trip',
          pickupStationId: data['pickup_station_id'] as String?,
          dropoffStationId: data['dropoff_station_id'] as String?,
        );
      }).toList();

      return Right(subscriptions);
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
