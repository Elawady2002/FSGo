import 'package:equatable/equatable.dart';

/// User type enumeration
enum UserType {
  student,
  driver,
  admin,
  coordinator, // unified type: office owner / station owner / business owner
  // Legacy values — kept for code that may still reference them directly;
  // fromJson maps all three to coordinator.
  stationOwner,
  officeOwner,
  businessOwner;

  String toJson() {
    switch (this) {
      case UserType.coordinator:
        return 'coordinator';
      case UserType.stationOwner:
        return 'station_owner';
      case UserType.officeOwner:
        return 'office_owner';
      case UserType.businessOwner:
        return 'business_owner';
      default:
        return name;
    }
  }

  static UserType fromJson(String value) {
    switch (value) {
      case 'coordinator':
      case 'station_owner':
      case 'office_owner':
      case 'business_owner':
        return UserType.coordinator;
      default:
        return UserType.values.firstWhere(
          (type) => type.name == value,
          orElse: () => UserType.student,
        );
    }
  }
}

/// User entity - represents a user in the domain layer
class UserEntity extends Equatable {
  final String id;
  final String email;
  final String phone;
  final String fullName;
  final String? studentId;
  final String? universityId;
  final UserType userType;
  final String? avatarUrl;
  final bool isVerified;
  final DateTime createdAt;
  final String? subscriptionType;
  final DateTime? subscriptionStartDate;
  final DateTime? subscriptionEndDate;
  final String? subscriptionStatus;
  final String? officeName;
  final String? stationName;
  final String? businessName;

  const UserEntity({
    required this.id,
    required this.email,
    required this.phone,
    required this.fullName,
    this.studentId,
    this.universityId,
    required this.userType,
    this.avatarUrl,
    required this.isVerified,
    required this.createdAt,
    this.subscriptionType,
    this.subscriptionStartDate,
    this.subscriptionEndDate,
    this.subscriptionStatus,
    this.officeName,
    this.stationName,
    this.businessName,
  });

  @override
  List<Object?> get props => [
    id,
    email,
    phone,
    fullName,
    studentId,
    universityId,
    userType,
    avatarUrl,
    isVerified,
    createdAt,
    subscriptionType,
    subscriptionStartDate,
    subscriptionEndDate,
    subscriptionStatus,
    officeName,
    stationName,
    businessName,
  ];

  /// Role Getters
  bool get isStudent => userType == UserType.student;
  bool get isDriver => userType == UserType.driver;
  bool get isAdmin => userType == UserType.admin;
  bool get isCoordinator => userType == UserType.coordinator;
  // Legacy getters — kept for backward compatibility; all map to coordinator.
  bool get isStationOwner => userType == UserType.stationOwner;
  bool get isOfficeOwner => userType == UserType.officeOwner;
  bool get isBusinessOwner => userType == UserType.businessOwner;

  /// Display name for the business/office/station
  String get entityName =>
      businessName ?? officeName ?? stationName ?? fullName;

  /// Check if user has an active subscription
  bool get hasActiveSubscription {
    if (subscriptionStatus != 'active') return false;
    if (subscriptionEndDate == null) return false;
    return subscriptionEndDate!.isAfter(DateTime.now());
  }

  /// Check if subscription is expired
  bool get isSubscriptionExpired {
    if (subscriptionEndDate == null) return false;
    return subscriptionEndDate!.isBefore(DateTime.now());
  }

  /// Copy with method for immutability
  UserEntity copyWith({
    String? id,
    String? email,
    String? phone,
    String? fullName,
    String? studentId,
    String? universityId,
    UserType? userType,
    String? avatarUrl,
    bool? isVerified,
    DateTime? createdAt,
    String? subscriptionType,
    DateTime? subscriptionStartDate,
    DateTime? subscriptionEndDate,
    String? subscriptionStatus,
    String? officeName,
    String? stationName,
    String? businessName,
  }) {
    return UserEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      fullName: fullName ?? this.fullName,
      studentId: studentId ?? this.studentId,
      universityId: universityId ?? this.universityId,
      userType: userType ?? this.userType,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      subscriptionType: subscriptionType ?? this.subscriptionType,
      subscriptionStartDate:
          subscriptionStartDate ?? this.subscriptionStartDate,
      subscriptionEndDate: subscriptionEndDate ?? this.subscriptionEndDate,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      officeName: officeName ?? this.officeName,
      stationName: stationName ?? this.stationName,
      businessName: businessName ?? this.businessName,
    );
  }
}
