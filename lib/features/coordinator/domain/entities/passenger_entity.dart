import 'package:equatable/equatable.dart';

/// Payment type for a passenger on the manifest
enum PassengerPaymentType {
  cash,
  subscriber;

  String get label {
    switch (this) {
      case PassengerPaymentType.cash:
        return 'نقداً';
      case PassengerPaymentType.subscriber:
        return 'مشترك';
    }
  }
}

/// Boarding status for a passenger
enum PassengerBoardingStatus {
  booked,
  boarded;

  String get label {
    switch (this) {
      case PassengerBoardingStatus.booked:
        return 'محجوز';
      case PassengerBoardingStatus.boarded:
        return 'ركب';
    }
  }
}

/// One passenger row in the driver's manifest
class PassengerEntity extends Equatable {
  final String bookingId;
  final String userId;
  final String fullName;
  final String phone;
  final PassengerPaymentType paymentType;
  final PassengerBoardingStatus boardingStatus;
  final int passengerCount;
  final bool isLadies;

  const PassengerEntity({
    required this.bookingId,
    required this.userId,
    required this.fullName,
    required this.phone,
    required this.paymentType,
    required this.boardingStatus,
    required this.passengerCount,
    required this.isLadies,
  });

  bool get isBoarded => boardingStatus == PassengerBoardingStatus.boarded;
  bool get isSubscriber => paymentType == PassengerPaymentType.subscriber;

  @override
  List<Object?> get props => [
    bookingId,
    userId,
    fullName,
    phone,
    paymentType,
    boardingStatus,
    passengerCount,
    isLadies,
  ];
}
