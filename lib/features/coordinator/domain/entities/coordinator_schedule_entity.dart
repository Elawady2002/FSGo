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

/// Type of schedule: university (with subscriptions) or station (daily recurring)
enum ScheduleType {
  university, // مواعيد جامعة — اشتراكات شهرية/ترم
  station;    // مواعيد موقف — يومية متكررة

  String get label => this == university ? 'جامعة' : 'موقف';

  String toJson() => name;

  static ScheduleType fromJson(String value) {
    return ScheduleType.values.firstWhere(
      (t) => t.name == value,
      orElse: () => ScheduleType.university,
    );
  }
}

/// A schedule created and managed by a coordinator (station/office/business owner)
class CoordinatorScheduleEntity extends Equatable {
  final String id;
  final String coordinatorId;
  final String origin;
  final String destination;
  final String departureTime; // "HH:mm"
  final List<String> availableDays;
  final double baseFare;
  final double adminMargin;
  final bool isApproved;
  final bool isActive;
  final String? driverId;
  final String? driverName;
  final DateTime createdAt;

  // Unified schedule type fields
  final ScheduleType scheduleType;
  final String? subscriptionType; // 'monthly' | 'semester' (جامعة فقط)
  final int? durationDays;        // مدة الاشتراك بالأيام (جامعة فقط)

  const CoordinatorScheduleEntity({
    required this.id,
    required this.coordinatorId,
    required this.origin,
    required this.destination,
    required this.departureTime,
    required this.availableDays,
    required this.baseFare,
    required this.adminMargin,
    required this.isApproved,
    required this.isActive,
    this.driverId,
    this.driverName,
    required this.createdAt,
    this.scheduleType = ScheduleType.university,
    this.subscriptionType,
    this.durationDays,
  });

  ScheduleApprovalStatus get approvalStatus =>
      ScheduleApprovalStatus.fromApprovedFlag(isApproved);

  bool get canAssignDriver => isApproved && driverId == null;
  bool get hasDriver => driverId != null;

  double get totalFare => baseFare + adminMargin;

  String get routeLabel => '$origin → $destination';

  bool get isUniversity => scheduleType == ScheduleType.university;
  bool get isStation => scheduleType == ScheduleType.station;

  String get subscriptionLabel =>
      subscriptionType == 'semester' ? 'فصل دراسي' : 'شهري';

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

  CoordinatorScheduleEntity copyWith({
    String? id,
    String? coordinatorId,
    String? origin,
    String? destination,
    String? departureTime,
    List<String>? availableDays,
    double? baseFare,
    double? adminMargin,
    bool? isApproved,
    bool? isActive,
    String? driverId,
    String? driverName,
    DateTime? createdAt,
    ScheduleType? scheduleType,
    String? subscriptionType,
    int? durationDays,
  }) {
    return CoordinatorScheduleEntity(
      id: id ?? this.id,
      coordinatorId: coordinatorId ?? this.coordinatorId,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      departureTime: departureTime ?? this.departureTime,
      availableDays: availableDays ?? this.availableDays,
      baseFare: baseFare ?? this.baseFare,
      adminMargin: adminMargin ?? this.adminMargin,
      isApproved: isApproved ?? this.isApproved,
      isActive: isActive ?? this.isActive,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      createdAt: createdAt ?? this.createdAt,
      scheduleType: scheduleType ?? this.scheduleType,
      subscriptionType: subscriptionType ?? this.subscriptionType,
      durationDays: durationDays ?? this.durationDays,
    );
  }

  @override
  List<Object?> get props => [
    id,
    coordinatorId,
    origin,
    destination,
    departureTime,
    availableDays,
    baseFare,
    adminMargin,
    isApproved,
    isActive,
    driverId,
    driverName,
    createdAt,
    scheduleType,
    subscriptionType,
    durationDays,
  ];
}
