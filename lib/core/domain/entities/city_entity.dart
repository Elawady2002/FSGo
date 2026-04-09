import 'package:equatable/equatable.dart';

/// City entity - represents a city in the domain layer
class CityEntity extends Equatable {
  final String id;
  final String nameAr;
  final String nameEn;
  final String? governorate;
  final bool isActive;

  const CityEntity({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    this.governorate,
    required this.isActive,
  });

  @override
  List<Object?> get props => [
        id,
        nameAr,
        nameEn,
        governorate,
        isActive,
      ];

  String getLocalizedName(String languageCode) {
    return languageCode == 'ar' ? nameAr : nameEn;
  }
}
