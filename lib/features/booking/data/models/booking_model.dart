import '../../domain/entities/booking_entity.dart';

/// Booking model - maps between Supabase JSON and BookingEntity
class BookingModel extends BookingEntity {
  const BookingModel({
    required super.id,
    required super.userId,
    required super.scheduleId,
    required super.bookingDate,
    required super.tripType,
    super.pickupStationId,
    super.dropoffStationId,
    super.departureTime,
    super.returnTime,
    super.paymentProofImage,
    super.transferNumber,
    required super.status,
    required super.paymentStatus,
    required super.totalPrice,
    required super.createdAt,
    required super.updatedAt,
  });

  /// Create BookingModel from Supabase JSON
  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      scheduleId: json['schedule_id'] as String,
      bookingDate: DateTime.parse(json['booking_date'] as String),
      tripType: json['trip_type'] as String,
      pickupStationId: json['pickup_station_id'] as String?,
      dropoffStationId: json['dropoff_station_id'] as String?,
      departureTime: json['departure_time'] as String?,
      returnTime: json['return_time'] as String?,
      paymentProofImage: json['payment_proof_image'] as String?,
      transferNumber: json['transfer_number'] as String?,
      status: BookingStatus.fromJson(json['status'] as String),
      paymentStatus: PaymentStatus.fromJson(json['payment_status'] as String),
      totalPrice: (json['total_price'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert BookingModel to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'schedule_id': scheduleId,
      'booking_date': bookingDate.toIso8601String(),
      'trip_type': tripType,
      'pickup_station_id': pickupStationId,
      'dropoff_station_id': dropoffStationId,
      'departure_time': departureTime,
      'return_time': returnTime,
      'payment_proof_image': paymentProofImage,
      'transfer_number': transferNumber,
      'status': status.toJson(),
      'payment_status': paymentStatus.toJson(),
      'total_price': totalPrice,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create BookingModel from BookingEntity
  factory BookingModel.fromEntity(BookingEntity entity) {
    return BookingModel(
      id: entity.id,
      userId: entity.userId,
      scheduleId: entity.scheduleId,
      bookingDate: entity.bookingDate,
      tripType: entity.tripType,
      pickupStationId: entity.pickupStationId,
      dropoffStationId: entity.dropoffStationId,
      departureTime: entity.departureTime,
      returnTime: entity.returnTime,
      paymentProofImage: entity.paymentProofImage,
      transferNumber: entity.transferNumber,
      status: entity.status,
      paymentStatus: entity.paymentStatus,
      totalPrice: entity.totalPrice,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
