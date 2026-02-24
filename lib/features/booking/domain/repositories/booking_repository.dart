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

  /// Create a pending university request booking
  Future<Either<Failure, BookingEntity>> createUniversityRequest({
    required DateTime bookingDate,
    required String universityId,
    required bool isCustomUniversity,
    String? customUniversityName,
    String? pickupStationId,
    String? departureTime,
    String? returnTime,
    required double totalPrice,
    BookingSelectionType selectionType = BookingSelectionType.seat,
    int passengerCount = 1,
    bool splitPreference = true,
    bool isLadies = false,
  });

  /// Create a new booking
  Future<Either<Failure, BookingEntity>> createBooking({
    String? scheduleId,
    required DateTime bookingDate,
    required String tripType,
    String? pickupStationId,
    String? dropoffStationId,
    String? departureTime,
    String? returnTime,
    String? paymentProofImage,
    String? transferNumber,
    required double totalPrice,
    BookingSelectionType selectionType = BookingSelectionType.seat,
    int passengerCount = 1,
    bool splitPreference = true,
    bool isLadies = false,
  });

  /// Get all bookings for the current user
  Future<Either<Failure, List<BookingEntity>>> getUserBookings();

  /// Get a specific booking by ID
  Future<Either<Failure, BookingEntity>> getBookingById(String id);

  Future<Either<Failure, BookingEntity>> updateBooking({
    required String bookingId,
    required DateTime bookingDate,
    required String tripType,
    String? pickupStationId,
    String? dropoffStationId,
    String? departureTime,
    String? returnTime,
    required double totalPrice,
    BookingSelectionType selectionType = BookingSelectionType.seat,
    int passengerCount = 1,
    bool splitPreference = true,
    bool isLadies = false,
  });

  /// Transfer a booking to another user
  Future<Either<Failure, BookingEntity>> transferBooking({
    required String bookingId,
    String? targetUserId,
    String? targetPhoneNumber,
  });

  /// Generate an invitation link for a booking
  Future<Either<Failure, String>> generateInviteLink({
    required String bookingId,
  });

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
