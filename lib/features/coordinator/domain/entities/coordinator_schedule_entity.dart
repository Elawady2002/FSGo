import 'package:equatable/equatable.dart';

/// Approval status for a coordinator-created schedule
enum ScheduleApprovalStatus {
  pendingApproval,
  approved,
  rejected;

  String toJson() {
    switch (this) {
      case ScheduleApprovalStatus.pendingApproval:
        return 'pending_approval';
      case ScheduleApprovalStatus.approved:
        return 'approved';
      case ScheduleApprovalStatus.rejected:
        return 'rejected';
    }
  }

  static ScheduleApprovalStatus fromApprovedFlag(bool isApproved) =>
      isApproved ? ScheduleApprovalStatus.approved : ScheduleApprovalStatus.pendingApproval;

  String get label {
    switch (this) {
      case ScheduleApprovalStatus.pendingApproval:
        return 'في انتظار الموافقة';
      case ScheduleApprovalStatus.approved:
        return 'تمت الموافقة';
      case ScheduleApprovalStatus.rejected:
        return 'مرفوض';
    }
  }
}

/// A schedule created and managed by a coordinator (station/office owner)
class CoordinatorScheduleEntity extends Equatable {
  final String id;
  final String coordinatorId;
  final String origin;
  final String destination;
  final String departureTime; // "HH:mm"
  final List<String> availableDays;
  final int capacity;
  final double baseFare;
  final double adminMargin;
  final bool isApproved;
  final bool isActive;
  final String? driverId;
  final String? driverName;
  final DateTime createdAt;

  const CoordinatorScheduleEntity({
    required this.id,
    required this.coordinatorId,
    required this.origin,
    required this.destination,
    required this.departureTime,
    required this.availableDays,
    required this.capacity,
    required this.baseFare,
    required this.adminMargin,
    required this.isApproved,
    required this.isActive,
    this.driverId,
    this.driverName,
    required this.createdAt,
  });

  ScheduleApprovalStatus get approvalStatus =>
      ScheduleApprovalStatus.fromApprovedFlag(isApproved);

  bool get canAssignDriver => isApproved && driverId == null;
  bool get hasDriver => driverId != null;

  double get totalFare => baseFare + adminMargin;

  String get routeLabel => '$origin → $destination';

  String get daysLabel {
    const dayNames = {
      'sunday': 'الأحد',
      'monday': 'الاثنين',
      'tuesday': 'الثلاثاء',
      'wednesday': 'الأربعاء',
      'thursday': 'الخميس',
      'friday': 'الجمعة',
      'saturday': 'السبت',
    };
    return availableDays.map((d) => dayNames[d] ?? d).join('، ');
  }

  @override
  List<Object?> get props => [
    id,
    coordinatorId,
    origin,
    destination,
    departureTime,
    availableDays,
    capacity,
    baseFare,
    adminMargin,
    isApproved,
    isActive,
    driverId,
    driverName,
    createdAt,
  ];
}
