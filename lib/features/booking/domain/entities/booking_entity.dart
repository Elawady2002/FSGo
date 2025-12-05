import 'package:equatable/equatable.dart';

/// Booking status enumeration
enum BookingStatus {
  pending,
  confirmed,
  cancelled,
  completed;

  String toJson() => name;

  static BookingStatus fromJson(String value) {
    return BookingStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => BookingStatus.pending,
    );
  }
}

/// Payment status enumeration
enum PaymentStatus {
  unpaid,
  paid,
  refunded;

  String toJson() => name;

  static PaymentStatus fromJson(String value) {
    return PaymentStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => PaymentStatus.unpaid,
    );
  }
}

/// Booking entity - represents a booking in the domain layer
class BookingEntity extends Equatable {
  final String id;
  final String userId;
  final String scheduleId;
  final String?
  subscriptionId; // Link to subscription if booking is from subscription
  final DateTime bookingDate;
  final String tripType; // 'departure_only', 'return_only', 'round_trip'
  final String? pickupStationId;
  final String? dropoffStationId;
  final String? departureTime; // e.g., 'AM 7:00'
  final String? returnTime; // e.g., 'PM 3:00'
  final String? paymentProofImage;
  final String? transferNumber;
  final BookingStatus status;
  final PaymentStatus paymentStatus;
  final double totalPrice;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BookingEntity({
    required this.id,
    required this.userId,
    required this.scheduleId,
    this.subscriptionId,
    required this.bookingDate,
    required this.tripType,
    this.pickupStationId,
    this.dropoffStationId,
    this.departureTime,
    this.returnTime,
    this.paymentProofImage,
    this.transferNumber,
    required this.status,
    required this.paymentStatus,
    required this.totalPrice,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    userId,
    scheduleId,
    subscriptionId,
    bookingDate,
    tripType,
    pickupStationId,
    dropoffStationId,
    departureTime,
    returnTime,
    paymentProofImage,
    transferNumber,
    status,
    paymentStatus,
    totalPrice,
    createdAt,
    updatedAt,
  ];

  bool get isPaid => paymentStatus == PaymentStatus.paid;
  bool get isConfirmed => status == BookingStatus.confirmed;
  bool get isCancelled => status == BookingStatus.cancelled;
  bool get isCompleted => status == BookingStatus.completed;
  bool get isFromSubscription => subscriptionId != null;
}
