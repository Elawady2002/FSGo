import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/coordinator_schedule_entity.dart';
import '../../domain/entities/office_plan_entity.dart';
import '../../../../core/domain/entities/user_entity.dart';

/// Simple model for a pending driver invite record.
class DriverInvite {
  final String? driverName;
  final String driverEmail;
  final String status;

  const DriverInvite({
    this.driverName,
    required this.driverEmail,
    required this.status,
  });
}

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

    return (response as List)
        .map((e) => _scheduleFromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Create a new schedule (awaits admin approval)
  Future<CoordinatorScheduleEntity> createSchedule({
    required String coordinatorId,
    required String origin,
    required String destination,
    required String departureTime,
    required List<String> availableDays,
    required double baseFare,
    int capacity = 4,
    ScheduleType scheduleType = ScheduleType.university,
    String? subscriptionType,
    int? durationDays,
  }) async {
    final data = {
      'coordinator_id': coordinatorId,
      'origin': origin,
      'destination': destination,
      'departure_time': departureTime,
      'available_days': availableDays,
      'base_fare': baseFare,
      'admin_margin': 0,
      'price_per_trip': baseFare,
      'capacity': capacity,
      'is_approved': false,
      'is_active': true,
      'schedule_type': scheduleType.toJson(),
      if (subscriptionType != null) 'subscription_type': subscriptionType,
      if (durationDays != null) 'duration_days': durationDays,
    };

    final response =
        await _client.from('schedules').insert(data).select().single();

    return _scheduleFromJson(response);
  }

  /// Fetch pending driver invites for this coordinator
  Future<List<DriverInvite>> getPendingInvites(String coordinatorId) async {
    final response = await _client
        .from('driver_invites')
        .select()
        .eq('coordinator_id', coordinatorId)
        .eq('status', 'pending')
        .order('created_at', ascending: false);

    return (response as List).map((e) {
      return DriverInvite(
        driverName: e['driver_name'] as String?,
        driverEmail: e['driver_email'] as String? ?? '',
        status: e['status'] as String? ?? 'pending',
      );
    }).toList();
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

  /// Send a driver invite by email — inserts a pending record in driver_invites
  Future<void> inviteDriver({
    required String coordinatorId,
    String? driverName,
    required String driverEmail,
  }) async {
    await _client.from('driver_invites').insert({
      'coordinator_id': coordinatorId,
      if (driverName != null) 'driver_name': driverName,
      'driver_email': driverEmail,
      'status': 'pending',
    });
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

    return (response as List)
        .map((e) => _planFromJson(e as Map<String, dynamic>))
        .toList();
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
      'max_students': maxStudents,
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
      baseFare: (json['base_fare'] as num?)?.toDouble() ?? 0,
      adminMargin: (json['admin_margin'] as num?)?.toDouble() ?? 0,
      isApproved: json['is_approved'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      driverId: json['driver_id'] as String?,
      driverName: driverName,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      scheduleType: ScheduleType.fromJson(
        json['schedule_type'] as String? ?? 'university',
      ),
      subscriptionType: json['subscription_type'] as String?,
      durationDays: json['duration_days'] as int?,
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
