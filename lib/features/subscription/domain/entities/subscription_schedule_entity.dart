import 'package:equatable/equatable.dart';

/// Entity representing a scheduled trip for a specific day in a subscription
class SubscriptionScheduleEntity extends Equatable {
  final String id;
  final String subscriptionId;
  final DateTime tripDate;
  final String tripType; // departure_only, return_only, round_trip
  final String? departureTime;
  final String? returnTime;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SubscriptionScheduleEntity({
    required this.id,
    required this.subscriptionId,
    required this.tripDate,
    required this.tripType,
    this.departureTime,
    this.returnTime,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    subscriptionId,
    tripDate,
    tripType,
    departureTime,
    returnTime,
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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
