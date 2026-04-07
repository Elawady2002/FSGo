import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasources/coordinator_data_source.dart';
import '../../domain/entities/coordinator_schedule_entity.dart';
import '../../domain/entities/office_plan_entity.dart';
import '../../../../core/domain/entities/user_entity.dart';

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
      : super(CoordinatorScheduleState(
          schedules: [
            CoordinatorScheduleEntity(
              id: 'mock-1',
              coordinatorId: _coordinatorId,
              origin: 'المنصورة',
              destination: 'القاهرة',
              departureTime: '08:00',
              availableDays: const ['sunday', 'tuesday', 'thursday'],
              capacity: 14,
              baseFare: 45.0,
              adminMargin: 5.0,
              isApproved: true,
              isActive: true,
              createdAt: DateTime.now(),
              driverName: 'أحمد محمود (تجريبي)',
              driverId: 'mock-driver',
            ),
          ],
        ));

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
    required int capacity,
    required double baseFare,
  }) async {
    try {
      // 🧪 MOCK MODE: Skip database call for now as requested
      final created = CoordinatorScheduleEntity(
        id: 'mock-${DateTime.now().millisecondsSinceEpoch}',
        coordinatorId: _coordinatorId,
        origin: origin,
        destination: destination,
        departureTime: departureTime,
        availableDays: availableDays,
        capacity: capacity,
        baseFare: baseFare,
        adminMargin: 5.0, // Mock admin margin
        isApproved: false, // Initially pending
        isActive: true,
        createdAt: DateTime.now(),
      );

      state = state.copyWith(
        schedules: [created, ...state.schedules],
      );
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// Invite a new driver to join the office
  Future<String?> inviteDriver({
    required String coordinatorId,
    required String driverName,
    required String driverPhone,
  }) async {
    try {
      await _dataSource.inviteDriver(
        coordinatorId: coordinatorId,
        driverName: driverName,
        driverPhone: driverPhone,
      );
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> assignDriver(String scheduleId, String driverId,
      String driverName) async {
    try {
      await _dataSource.assignDriver(
        scheduleId: scheduleId,
        driverId: driverId,
      );
      // Update local state
      final updated = state.schedules.map((s) {
        if (s.id == scheduleId) {
          return CoordinatorScheduleEntity(
            id: s.id,
            coordinatorId: s.coordinatorId,
            origin: s.origin,
            destination: s.destination,
            departureTime: s.departureTime,
            availableDays: s.availableDays,
            capacity: s.capacity,
            baseFare: s.baseFare,
            adminMargin: s.adminMargin,
            isApproved: s.isApproved,
            isActive: s.isActive,
            driverId: driverId,
            driverName: driverName,
            createdAt: s.createdAt,
          );
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
