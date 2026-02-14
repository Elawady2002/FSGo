import 'package:equatable/equatable.dart';

/// Entity representing a scheduled trip for a specific day in a subscription
class SubscriptionScheduleEntity extends Equatable {
  final String id;
  final String subscriptionId;
  final DateTime tripDate;
  final String tripType; // departure_only, return_only, round_trip
  final String? departureTime;
  final String? returnTime;
  final String selectionType; // seat, full_car
  final int passengerCount;
  final bool splitPreference;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Advanced booking fields
  final int? advancedBookingDays;
  final String? advancedBookingCutoffTime;

  const SubscriptionScheduleEntity({
    required this.id,
    required this.subscriptionId,
    required this.tripDate,
    required this.tripType,
    this.departureTime,
    this.returnTime,
    this.selectionType = 'seat',
    this.passengerCount = 1,
    this.splitPreference = true,
    required this.createdAt,
    required this.updatedAt,
    this.advancedBookingDays,
    this.advancedBookingCutoffTime,
  });

  @override
  List<Object?> get props => [
    id,
    subscriptionId,
    tripDate,
    tripType,
    departureTime,
    returnTime,
    selectionType,
    passengerCount,
    splitPreference,
    createdAt,
    updatedAt,
  ];

  /// Create entity from JSON
  factory SubscriptionScheduleEntity.fromJson(Map<String, dynamic> json) {
    return SubscriptionScheduleEntity(
      id: json['id'] as String,
      subscriptionId: json['subscription_id'] as String,
      tripDate: DateTime.parse(json['trip_date'] as String),
      tripType: json['trip_type'] as String,
      departureTime: json['departure_time'] as String?,
      returnTime: json['return_time'] as String?,
      selectionType: (json['selection_type'] as String?) ?? 'seat',
      passengerCount: (json['passenger_count'] as int?) ?? 1,
      splitPreference: (json['split_preference'] as bool?) ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert entity to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subscription_id': subscriptionId,
      'trip_date': tripDate.toIso8601String().split('T')[0], // Date only
      'trip_type': tripType,
      'departure_time': departureTime,
      'return_time': returnTime,
      'selection_type': selectionType,
      'passenger_count': passengerCount,
      'split_preference': splitPreference,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Copy with method
  SubscriptionScheduleEntity copyWith({
    String? id,
    String? subscriptionId,
    DateTime? tripDate,
    String? tripType,
    String? departureTime,
    String? returnTime,
    String? selectionType,
    int? passengerCount,
    bool? splitPreference,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SubscriptionScheduleEntity(
      id: id ?? this.id,
      subscriptionId: subscriptionId ?? this.subscriptionId,
      tripDate: tripDate ?? this.tripDate,
      tripType: tripType ?? this.tripType,
      departureTime: departureTime ?? this.departureTime,
      returnTime: returnTime ?? this.returnTime,
      selectionType: selectionType ?? this.selectionType,
      passengerCount: passengerCount ?? this.passengerCount,
      splitPreference: splitPreference ?? this.splitPreference,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
