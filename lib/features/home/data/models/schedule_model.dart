import '../../../booking/domain/entities/schedule_entity.dart';

class ScheduleModel extends ScheduleEntity {
  const ScheduleModel({
    required super.id,
    required super.routeId,
    required super.direction,
    required super.departureTime,
    required super.daysOfWeek,
    required super.capacity,
    required super.pricePerTrip,
    required super.isActive,
  });

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    return ScheduleModel(
      id: json['id'] as String,
      routeId: json['route_id'] as String,
      direction: RouteDirection.fromJson(json['direction'] as String),
      departureTime: json['departure_time'] as String,
      daysOfWeek: List<int>.from(
        (json['days_of_week'] as List?) ?? (json['available_days'] as List?) ?? [],
      ),
      capacity: json['capacity'] as int,
      pricePerTrip: (json['price_per_trip'] as num).toDouble(),
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'route_id': routeId,
      'direction': direction.toJson(),
      'departure_time': departureTime,
      'days_of_week': daysOfWeek,
      'capacity': capacity,
      'price_per_trip': pricePerTrip,
      'is_active': isActive,
    };
  }
}
