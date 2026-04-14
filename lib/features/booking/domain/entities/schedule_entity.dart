import 'package:equatable/equatable.dart';

/// Route direction enumeration
enum RouteDirection {
  toUniversity('to_university'),
  fromUniversity('from_university');

  final String value;
  const RouteDirection(this.value);

  String toJson() => value;

  static RouteDirection fromJson(String value) {
    return RouteDirection.values.firstWhere(
      (direction) => direction.value == value,
      orElse: () => RouteDirection.toUniversity,
    );
  }
}

/// Schedule entity - represents a schedule for a route
class ScheduleEntity extends Equatable {
  final String id;
  final String routeId;
  final RouteDirection direction;
  final String departureTime; // Format: "HH:mm"
  final List<int> daysOfWeek; // [1, 2, 3...] where 1 = Monday
  final int capacity;
  final double pricePerTrip;
  final bool isActive;

  const ScheduleEntity({
    required this.id,
    required this.routeId,
    required this.direction,
    required this.departureTime,
    required this.daysOfWeek,
    required this.capacity,
    required this.pricePerTrip,
    required this.isActive,
  });

  @override
  List<Object?> get props => [
    id,
    routeId,
    direction,
    departureTime,
    daysOfWeek,
    capacity,
    pricePerTrip,
    isActive,
  ];

  /// Check if schedule is available on a specific day
  bool isAvailableOn(DateTime date) {
    return daysOfWeek.contains(date.weekday);
  }
}
