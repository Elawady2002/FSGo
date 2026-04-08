import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../coordinator/domain/entities/coordinator_schedule_entity.dart';

class AdminDataSource {
  final SupabaseClient _client;
  AdminDataSource(this._client);

  /// All schedules pending admin approval
  Future<List<CoordinatorScheduleEntity>> getPendingSchedules() async {
    final response = await _client
        .from('schedules')
        .select('*, coordinator:coordinator_id(full_name), driver:driver_id(full_name)')
        .eq('is_approved', false)
        .not('coordinator_id', 'is', null)
        .order('created_at', ascending: false);

    return (response as List)
        .map((e) => _fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// All already-approved schedules
  Future<List<CoordinatorScheduleEntity>> getApprovedSchedules() async {
    final response = await _client
        .from('schedules')
        .select('*, coordinator:coordinator_id(full_name), driver:driver_id(full_name)')
        .eq('is_approved', true)
        .not('coordinator_id', 'is', null)
        .order('created_at', ascending: false);

    return (response as List)
        .map((e) => _fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Approve a schedule — sets is_approved = true
  Future<void> approveSchedule(String scheduleId) async {
    await _client
        .from('schedules')
        .update({'is_approved': true})
        .eq('id', scheduleId);
  }

  /// Reject: delete the schedule entirely (or set is_active = false)
  Future<void> rejectSchedule(String scheduleId) async {
    await _client
        .from('schedules')
        .update({'is_active': false})
        .eq('id', scheduleId);
  }

  CoordinatorScheduleEntity _fromJson(Map<String, dynamic> json) {
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
      availableDays: List<String>.from((json['available_days'] as List?) ?? []),
      baseFare: (json['base_fare'] as num?)?.toDouble() ?? 0,
      adminMargin: (json['admin_margin'] as num?)?.toDouble() ?? 0,
      isApproved: json['is_approved'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      driverId: json['driver_id'] as String?,
      driverName: driverName,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      // Store coordinator name in driverName field temporarily for display
      // We'll use a subclass or a separate field if needed
    );
  }
}
