import 'package:equatable/equatable.dart';

enum OfficePlanType {
  monthly,
  semester;

  String get label {
    switch (this) {
      case OfficePlanType.monthly:
        return 'شهري';
      case OfficePlanType.semester:
        return 'فصل دراسي';
    }
  }
}

/// A subscription plan created by an office coordinator
class OfficePlanEntity extends Equatable {
  final String id;
  final String coordinatorId;
  final String planName;
  final OfficePlanType planType;
  final double price;
  final int durationDays;
  final int? maxStudents;
  final bool isActive;
  final DateTime createdAt;

  const OfficePlanEntity({
    required this.id,
    required this.coordinatorId,
    required this.planName,
    required this.planType,
    required this.price,
    required this.durationDays,
    this.maxStudents,
    required this.isActive,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    coordinatorId,
    planName,
    planType,
    price,
    durationDays,
    maxStudents,
    isActive,
    createdAt,
  ];
}
