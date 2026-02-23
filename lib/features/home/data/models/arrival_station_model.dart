import '../../../booking/domain/entities/arrival_station_entity.dart';

class ArrivalStationModel extends ArrivalStationEntity {
  const ArrivalStationModel({
    required super.id,
    required super.boardingStationId,
    required super.nameAr,
    required super.nameEn,
    required super.price,
    required super.schedules,
  });

  factory ArrivalStationModel.fromJson(Map<String, dynamic> json) {
    // Parse schedules - can be a JSON string or a List
    List<String> parsedSchedules = [];
    final rawSchedules = json['schedules'];
    if (rawSchedules is List) {
      parsedSchedules = rawSchedules.map((e) => e.toString()).toList();
    } else if (rawSchedules is String && rawSchedules.isNotEmpty) {
      // Try parsing as JSON array string
      try {
        final decoded = rawSchedules;
        parsedSchedules = [decoded];
      } catch (_) {
        parsedSchedules = [];
      }
    }

    return ArrivalStationModel(
      id: json['id'] as String,
      boardingStationId: json['boarding_station_id'] as String,
      nameAr: json['name_ar'] as String,
      nameEn: json['name_en'] as String,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      schedules: parsedSchedules,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'boarding_station_id': boardingStationId,
      'name_ar': nameAr,
      'name_en': nameEn,
      'price': price,
      'schedules': schedules,
    };
  }
}
