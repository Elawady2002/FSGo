import '../../../booking/domain/entities/boarding_station_entity.dart';

class BoardingStationModel extends BoardingStationEntity {
  const BoardingStationModel({
    required super.id,
    required super.cityId,
    required super.nameAr,
    required super.nameEn,
  });

  factory BoardingStationModel.fromJson(Map<String, dynamic> json) {
    return BoardingStationModel(
      id: json['id'] as String,
      cityId: json['city_id'] as String,
      nameAr: json['name_ar'] as String,
      nameEn: json['name_en'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'city_id': cityId,
      'name_ar': nameAr,
      'name_en': nameEn,
    };
  }
}
