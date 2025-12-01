import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/booking_entity.dart';
import '../../domain/entities/schedule_entity.dart';
import '../../domain/repositories/booking_repository.dart';
import '../datasources/booking_data_source.dart';

class BookingRepositoryImpl implements BookingRepository {
  final BookingDataSource _dataSource;
  final String Function() _getUserId;

  BookingRepositoryImpl(this._dataSource, this._getUserId);

  @override
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
  }) async {
    try {
      final userId = _getUserId();
      final booking = await _dataSource.createBooking(
        userId: userId,
        scheduleId: scheduleId,
        bookingDate: bookingDate,
        tripType: tripType,
        pickupStationId: pickupStationId,
        dropoffStationId: dropoffStationId,
        departureTime: departureTime,
        returnTime: returnTime,
        paymentProofImage: paymentProofImage,
        transferNumber: transferNumber,
        totalPrice: totalPrice,
      );
      return Right(booking);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<Failure, List<BookingEntity>>> getUserBookings() async {
    try {
      final userId = _getUserId();
      final bookings = await _dataSource.getUserBookings(userId);
      return Right(bookings);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<Failure, BookingEntity?>> getUpcomingBooking() async {
    try {
      final userId = _getUserId();
      final booking = await _dataSource.getUpcomingBooking(userId);
      return Right(booking);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<Failure, BookingEntity>> getBookingById(String id) async {
    try {
      final booking = await _dataSource.getBookingById(id);
      return Right(booking);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<Failure, BookingEntity>> cancelBooking(String bookingId) async {
    // TODO: Implement cancel booking
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, BookingEntity>> updatePaymentStatus({
    required String bookingId,
    required PaymentStatus paymentStatus,
  }) async {
    // TODO: Implement update payment status
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, List<ScheduleEntity>>> getSchedules({
    required String universityId,
    required DateTime date,
  }) async {
    // TODO: Implement get schedules
    throw UnimplementedError();
  }

  @override
  Stream<List<BookingEntity>> watchUserBookings() {
    // TODO: Implement real-time booking updates
    throw UnimplementedError();
  }

  Failure _handleError(Object error) {
    if (error.toString().contains('Database error')) {
      return ServerFailure(message: error.toString());
    }
    return ServerFailure(message: 'An unexpected error occurred: $error');
  }
}
