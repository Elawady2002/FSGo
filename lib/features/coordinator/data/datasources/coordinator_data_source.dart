import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/logger_service.dart';
import '../../domain/entities/coordinator_schedule_entity.dart';
import '../../domain/entities/office_plan_entity.dart';
import '../../../../core/domain/entities/user_entity.dart';

class CoordinatorDataSource {
  final SupabaseClient _client;

  CoordinatorDataSource(this._client);

  /// Fetch all schedules created by this coordinator
  Future<List<CoordinatorScheduleEntity>> getMySchedules(
    String coordinatorId,
  ) async {
    final response = await _client
        .from('schedules')
        .select('*, driver:driver_id(full_name)')
        .eq('coordinator_id', coordinatorId)
        .order('created_at', ascending: false);

    return (response as List).map(_scheduleFromJson).toList();
  }

  /// Create a new schedule (awaits admin approval)
  Future<CoordinatorScheduleEntity> createSchedule({
    required String coordinatorId,
    required String origin,
    required String destination,
    required String departureTime,
    required List<String> availableDays,
    required int capacity,
    required double baseFare,
  }) async {
    final data = {
      'coordinator_id': coordinatorId,
      'origin': origin,
      'destination': destination,
      'departure_time': departureTime,
      'available_days': availableDays,
      'capacity': capacity,
      'base_fare': baseFare,
      'admin_margin': 0,
      'is_approved': false,
      'is_active': true,
      // Legacy required columns — use placeholders until schema is confirmed
      'route_id': '00000000-0000-0000-0000-000000000000',
      'direction': 'to_university',
      'price_per_trip': baseFare,
    };

    final response =
        await _client.from('schedules').insert(data).select().single();

    return _scheduleFromJson(response);
  }

  /// Fetch drivers that belong to this coordinator's org
  /// (users where user_type = 'driver' and coordinator_id matches)
  Future<List<UserEntity>> getMyDrivers(String coordinatorId) async {
    // Drivers linked to coordinator via a 'coordinator_id' column on users,
    // or all drivers if no explicit link — show all drivers for now.
    final response = await _client
        .from('users')
        .select()
        .eq('user_type', 'driver');

    return (response as List).map((json) {
      return UserEntity(
        id: json['id'] as String,
        email: json['email'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        fullName: json['full_name'] as String? ?? '',
        userType: UserType.driver,
        isVerified: json['is_verified'] as bool? ?? false,
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.now(),
      );
    }).toList();
  }

  /// Assign a driver to an approved schedule
  Future<void> assignDriver({
    required String scheduleId,
    required String driverId,
  }) async {
    await _client
        .from('schedules')
        .update({'driver_id': driverId})
        .eq('id', scheduleId)
        .eq('is_approved', true); // safety: only assign to approved ones
  }

  // ── Office Plans ──────────────────────────────────────────

  Future<List<OfficePlanEntity>> getOfficePlans(String coordinatorId) async {
    final response = await _client
        .from('office_subscription_plans')
        .select()
        .eq('coordinator_id', coordinatorId)
        .order('created_at', ascending: false);

    return (response as List).map(_planFromJson).toList();
  }

  Future<OfficePlanEntity> createOfficePlan({
    required String coordinatorId,
    required String planName,
    required OfficePlanType planType,
    required double price,
    required int durationDays,
    int? maxStudents,
  }) async {
    final data = {
      'coordinator_id': coordinatorId,
      'plan_name': planName,
      'plan_type': planType == OfficePlanType.monthly ? 'monthly' : 'semester',
      'price': price,
      'duration_days': durationDays,
      if (maxStudents != null) 'max_students': maxStudents,
      'is_active': true,
    };

    final response = await _client
        .from('office_subscription_plans')
        .insert(data)
        .select()
        .single();

    return _planFromJson(response);
  }

  Future<void> togglePlanActive(String planId, bool isActive) async {
    await _client
        .from('office_subscription_plans')
        .update({'is_active': isActive}).eq('id', planId);
  }

  // ── Helpers ────────────────────────────────────────────────

  CoordinatorScheduleEntity _scheduleFromJson(Map<String, dynamic> json) {
    String? driverName;
    if (json['driver'] is Map) {
      driverName = (json['driver'] as Map)['full_name'] as String?;
    }
    return CoordinatorScheduleEntity(
      id: json['id'] as String,
      coordinatorId: json['coordinator_id'] as String? ?? '',
      origin: json['origin'] as String? ?? '',
      destination: json['destination'] as String? ?? '',
      departureTime: json['departure_time'] as String? ?? '',
      availableDays: List<String>.from(
        (json['available_days'] as List?) ?? [],
      ),
      capacity: (json['capacity'] as num?)?.toInt() ?? 0,
      baseFare: (json['base_fare'] as num?)?.toDouble() ?? 0,
      adminMargin: (json['admin_margin'] as num?)?.toDouble() ?? 0,
      isApproved: json['is_approved'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      driverId: json['driver_id'] as String?,
      driverName: driverName,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  OfficePlanEntity _planFromJson(Map<String, dynamic> json) {
    return OfficePlanEntity(
      id: json['id'] as String,
      coordinatorId: json['coordinator_id'] as String,
      planName: json['plan_name'] as String,
      planType: json['plan_type'] == 'monthly'
          ? OfficePlanType.monthly
          : OfficePlanType.semester,
      price: (json['price'] as num).toDouble(),
      durationDays: json['duration_days'] as int,
      maxStudents: json['max_students'] as int?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
