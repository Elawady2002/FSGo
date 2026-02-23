import 'package:equatable/equatable.dart';

/// Boarding station entity - represents a pickup station in the domain layer
class BoardingStationEntity extends Equatable {
  final String id;
  final String cityId;
  final String nameAr;
  final String nameEn;

  const BoardingStationEntity({
    required this.id,
    required this.cityId,
    required this.nameAr,
    required this.nameEn,
  });

  @override
  List<Object?> get props => [id, cityId, nameAr, nameEn];

  String getLocalizedName(String languageCode) {
    return languageCode == 'ar' ? nameAr : nameEn;
  }
}
