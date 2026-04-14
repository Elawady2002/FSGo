import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasources/admin_data_source.dart';
import '../../../coordinator/domain/entities/coordinator_schedule_entity.dart';

final adminDataSourceProvider = Provider<AdminDataSource>((ref) {
  return AdminDataSource(Supabase.instance.client);
});

// ── State ─────────────────────────────────────────────────────

class AdminScheduleState {
  final List<CoordinatorScheduleEntity> pending;
  final List<CoordinatorScheduleEntity> approved;
  final bool isLoading;
  final String? error;

  const AdminScheduleState({
    this.pending = const [],
    this.approved = const [],
    this.isLoading = false,
    this.error,
  });

  AdminScheduleState copyWith({
    List<CoordinatorScheduleEntity>? pending,
    List<CoordinatorScheduleEntity>? approved,
    bool? isLoading,
    String? error,
  }) {
    return AdminScheduleState(
      pending: pending ?? this.pending,
      approved: approved ?? this.approved,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AdminScheduleNotifier extends StateNotifier<AdminScheduleState> {
  final AdminDataSource _ds;
  AdminScheduleNotifier(this._ds) : super(const AdminScheduleState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final results = await Future.wait([
        _ds.getPendingSchedules(),
        _ds.getApprovedSchedules(),
      ]);
      state = state.copyWith(
        pending: results[0],
        approved: results[1],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<String?> approve(String scheduleId) async {
    try {
      await _ds.approveSchedule(scheduleId);
      final schedule = state.pending.firstWhere((s) => s.id == scheduleId);
      final approved = CoordinatorScheduleEntity(
        id: schedule.id,
        coordinatorId: schedule.coordinatorId,
        origin: schedule.origin,
        destination: schedule.destination,
        departureTime: schedule.departureTime,
        daysOfWeek: schedule.daysOfWeek,
        baseFare: schedule.baseFare,
        isApproved: true,
        isActive: schedule.isActive,
        driverId: schedule.driverId,
        driverName: schedule.driverName,
        createdAt: schedule.createdAt,
      );
      state = state.copyWith(
        pending: state.pending.where((s) => s.id != scheduleId).toList(),
        approved: [approved, ...state.approved],
      );
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> reject(String scheduleId) async {
    try {
      await _ds.rejectSchedule(scheduleId);
      state = state.copyWith(
        pending: state.pending.where((s) => s.id != scheduleId).toList(),
      );
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}

final adminScheduleProvider =
    StateNotifierProvider<AdminScheduleNotifier, AdminScheduleState>((ref) {
  return AdminScheduleNotifier(ref.watch(adminDataSourceProvider));
});
