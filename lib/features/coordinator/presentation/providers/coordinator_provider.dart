import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasources/coordinator_data_source.dart';
import '../../domain/entities/coordinator_schedule_entity.dart';
import '../../domain/entities/office_plan_entity.dart';
import '../../../../core/domain/entities/user_entity.dart';

export '../../data/datasources/coordinator_data_source.dart' show DriverInvite;

// ── DI ───────────────────────────────────────────────────────

final coordinatorDataSourceProvider = Provider<CoordinatorDataSource>((ref) {
  return CoordinatorDataSource(Supabase.instance.client);
});

// ── Schedule State ────────────────────────────────────────────

class CoordinatorScheduleState {
  final List<CoordinatorScheduleEntity> schedules;
  final bool isLoading;
  final String? error;

  const CoordinatorScheduleState({
    this.schedules = const [],
    this.isLoading = false,
    this.error,
  });

  CoordinatorScheduleState copyWith({
    List<CoordinatorScheduleEntity>? schedules,
    bool? isLoading,
    String? error,
  }) {
    return CoordinatorScheduleState(
      schedules: schedules ?? this.schedules,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class CoordinatorScheduleNotifier
    extends StateNotifier<CoordinatorScheduleState> {
  final CoordinatorDataSource _dataSource;
  final String _coordinatorId;

  CoordinatorScheduleNotifier(this._dataSource, this._coordinatorId)
      : super(const CoordinatorScheduleState(isLoading: true)) {
    Future.microtask(load);
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final schedules = await _dataSource.getMySchedules(_coordinatorId);
      state = state.copyWith(schedules: schedules, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<String?> createSchedule({
    required String origin,
    required String destination,
    required String departureTime,
    required List<String> availableDays,
    required double baseFare,
    required ScheduleType scheduleType,
    String? subscriptionType,
    int? durationDays,
  }) async {
    try {
      final created = await _dataSource.createSchedule(
        coordinatorId: _coordinatorId,
        origin: origin,
        destination: destination,
        departureTime: departureTime,
        availableDays: availableDays,
        baseFare: baseFare,
        scheduleType: scheduleType,
        subscriptionType: subscriptionType,
        durationDays: durationDays,
      );
      state = state.copyWith(
        schedules: [created, ...state.schedules],
      );
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// Invite a new driver to join the office via email
  Future<String?> inviteDriver({
    required String coordinatorId,
    String? driverName,
    required String driverEmail,
  }) async {
    try {
      await _dataSource.inviteDriver(
        coordinatorId: coordinatorId,
        driverName: driverName,
        driverEmail: driverEmail,
      );
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> assignDriver(
      String scheduleId, String driverId, String driverName) async {
    try {
      await _dataSource.assignDriver(
        scheduleId: scheduleId,
        driverId: driverId,
      );
      final updated = state.schedules.map((s) {
        if (s.id == scheduleId) {
          return s.copyWith(driverId: driverId, driverName: driverName);
        }
        return s;
      }).toList();
      state = state.copyWith(schedules: updated);
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}

final coordinatorScheduleProvider = StateNotifierProvider.family<
    CoordinatorScheduleNotifier,
    CoordinatorScheduleState,
    String>((ref, coordinatorId) {
  final ds = ref.watch(coordinatorDataSourceProvider);
  return CoordinatorScheduleNotifier(ds, coordinatorId);
});

// ── Drivers List ──────────────────────────────────────────────

final coordinatorDriversProvider =
    FutureProvider.family<List<UserEntity>, String>((ref, coordinatorId) async {
  final ds = ref.watch(coordinatorDataSourceProvider);
  return ds.getMyDrivers(coordinatorId);
});

// ── Pending Invites ───────────────────────────────────────────

final pendingInvitesProvider =
    FutureProvider.family<List<DriverInvite>, String>((ref, coordinatorId) async {
  final ds = ref.watch(coordinatorDataSourceProvider);
  return ds.getPendingInvites(coordinatorId);
});

// ── Office Plans ──────────────────────────────────────────────

class OfficePlanState {
  final List<OfficePlanEntity> plans;
  final bool isLoading;
  final String? error;

  const OfficePlanState({
    this.plans = const [],
    this.isLoading = false,
    this.error,
  });

  OfficePlanState copyWith({
    List<OfficePlanEntity>? plans,
    bool? isLoading,
    String? error,
  }) {
    return OfficePlanState(
      plans: plans ?? this.plans,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class OfficePlanNotifier extends StateNotifier<OfficePlanState> {
  final CoordinatorDataSource _dataSource;
  final String _coordinatorId;

  OfficePlanNotifier(this._dataSource, this._coordinatorId)
      : super(const OfficePlanState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final plans = await _dataSource.getOfficePlans(_coordinatorId);
      state = state.copyWith(plans: plans, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<String?> createPlan({
    required String planName,
    required OfficePlanType planType,
    required double price,
    required int durationDays,
    int? maxStudents,
  }) async {
    try {
      final plan = await _dataSource.createOfficePlan(
        coordinatorId: _coordinatorId,
        planName: planName,
        planType: planType,
        price: price,
        durationDays: durationDays,
        maxStudents: maxStudents,
      );
      state = state.copyWith(plans: [plan, ...state.plans]);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> togglePlan(String planId, bool isActive) async {
    await _dataSource.togglePlanActive(planId, isActive);
    final updated = state.plans.map((p) {
      if (p.id == planId) {
        return OfficePlanEntity(
          id: p.id,
          coordinatorId: p.coordinatorId,
          planName: p.planName,
          planType: p.planType,
          price: p.price,
          durationDays: p.durationDays,
          maxStudents: p.maxStudents,
          isActive: isActive,
          createdAt: p.createdAt,
        );
      }
      return p;
    }).toList();
    state = state.copyWith(plans: updated);
  }
}

final officePlanProvider = StateNotifierProvider.family<OfficePlanNotifier,
    OfficePlanState, String>((ref, coordinatorId) {
  final ds = ref.watch(coordinatorDataSourceProvider);
  return OfficePlanNotifier(ds, coordinatorId);
});
