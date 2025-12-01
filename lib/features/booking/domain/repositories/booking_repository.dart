import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/booking_entity.dart';
import '../entities/schedule_entity.dart';

/// Booking repository interface
abstract class BookingRepository {
  /// Get available schedules for a specific date and university
  Future<Either<Failure, List<ScheduleEntity>>> getSchedules({
    required String universityId,
    required DateTime date,
  });

  /// Create a new booking
  Future<Either<Failure, BookingEntity>> createBooking({
    required String scheduleId,
    required DateTime bookingDate,
    required String tripType,
    String? pickupStationId,
    String? dropoffStationId,
    String? departureTime,
    String? returnTime,
    String? paymentProofImage,
    String? transferNumber,
    required double totalPrice,
  });

  /// Get all bookings for the current user
  Future<Either<Failure, List<BookingEntity>>> getUserBookings();

  /// Get a specific booking by ID
  Future<Either<Failure, BookingEntity>> getBookingById(String id);

  /// Cancel a booking
  Future<Either<Failure, BookingEntity>> cancelBooking(String bookingId);

  /// Update booking payment status
  Future<Either<Failure, BookingEntity>> updatePaymentStatus({
    required String bookingId,
    required PaymentStatus paymentStatus,
  });

  /// Get upcoming booking for the current user
  Future<Either<Failure, BookingEntity?>> getUpcomingBooking();

  /// Stream of user bookings (real-time updates)
  Stream<List<BookingEntity>> watchUserBookings();
}
