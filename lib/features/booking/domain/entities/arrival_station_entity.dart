import 'package:equatable/equatable.dart';

/// Arrival station entity - represents a dropoff station in the domain layer
/// Each arrival station is linked to a specific boarding station
class ArrivalStationEntity extends Equatable {
  final String id;
  final String boardingStationId;
  final String nameAr;
  final String nameEn;
  final double price;
  final List<String> schedules;

  const ArrivalStationEntity({
    required this.id,
    required this.boardingStationId,
    required this.nameAr,
    required this.nameEn,
    required this.price,
    required this.schedules,
  });

  @override
  List<Object?> get props => [id, boardingStationId, nameAr, nameEn, price, schedules];

  String getLocalizedName(String languageCode) {
    return languageCode == 'ar' ? nameAr : nameEn;
  }
}
