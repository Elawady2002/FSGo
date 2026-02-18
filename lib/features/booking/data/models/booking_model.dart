import '../../domain/entities/booking_entity.dart';

/// Booking model - maps between Supabase JSON and BookingEntity
class BookingModel extends BookingEntity {
  const BookingModel({
    required super.id,
    required super.userId,
    super.scheduleId, // Made optional to match entity
    super.subscriptionId,
    required super.bookingDate,
    required super.tripType,
    super.pickupStationId,
    super.dropoffStationId,
    super.departureTime,
    super.returnTime,
    super.paymentProofImage,
    super.transferNumber,
    super.selectionType = BookingSelectionType.seat,
    super.passengerCount = 1,
    super.splitPreference = true,
    required super.status,
    required super.paymentStatus,
    required super.totalPrice,
    super.isLadies = false,
    required super.createdAt,
    required super.updatedAt,
  });

  /// Create BookingModel from Supabase JSON
  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      scheduleId: json['schedule_id'] as String?, // Handle null
      subscriptionId: json['subscription_id'] as String?,
      bookingDate: DateTime.parse(json['booking_date'] as String),
      tripType:
          (json['trip_type'] as String?) ??
          'round_trip', // Handle null with default
      pickupStationId: json['pickup_station_id'] as String?,
      dropoffStationId: json['dropoff_station_id'] as String?,
      departureTime: json['departure_time'] as String?,
      returnTime: json['return_time'] as String?,
      paymentProofImage: json['payment_proof_image'] as String?,
      transferNumber: json['transfer_number'] as String?,
      status: BookingStatus.fromJson(
        (json['status'] as String?) ?? 'pending',
      ), // Handle null
      paymentStatus: PaymentStatus.fromJson(
        (json['payment_status'] as String?) ?? 'unpaid',
      ), // Handle null
      selectionType: BookingSelectionType.fromJson(
        (json['selection_type'] as String?) ?? 'seat',
      ),
      passengerCount: (json['passenger_count'] as int?) ?? 1,
      splitPreference: (json['split_preference'] as bool?) ?? true,
      totalPrice:
          (json['total_price'] as num?)?.toDouble() ?? 0.0, // Handle null
      isLadies: (json['is_ladies'] as bool?) ?? false,
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
      'subscription_id': subscriptionId,
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
      'selection_type': selectionType.toJson(),
      'passenger_count': passengerCount,
      'split_preference': splitPreference,
      'total_price': totalPrice,
      'is_ladies': isLadies,
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
      subscriptionId: entity.subscriptionId,
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
      selectionType: entity.selectionType,
      passengerCount: entity.passengerCount,
      splitPreference: entity.splitPreference,
      totalPrice: entity.totalPrice,
      isLadies: entity.isLadies,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
