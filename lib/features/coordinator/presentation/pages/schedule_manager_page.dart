import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/domain/entities/user_entity.dart';
import '../../domain/entities/coordinator_schedule_entity.dart';
import '../providers/coordinator_provider.dart';
import 'add_schedule_page.dart';
import 'driver_assigner_page.dart';

// ── Design tokens ──────────────────────────────────────────────
const _kBg = Color(0xFF1A1A1A);
const _kCard = Color(0xFF242424);
const _kLime = Color(0xFFC9D420);
const _kText = Colors.white;
const _kSubText = Color(0xFF9E9E9E);

class ScheduleManagerPage extends ConsumerStatefulWidget {
  final UserEntity coordinator;
  const ScheduleManagerPage({super.key, required this.coordinator});

  @override
  ConsumerState<ScheduleManagerPage> createState() =>
      _ScheduleManagerPageState();
}

class _ScheduleManagerPageState extends ConsumerState<ScheduleManagerPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(coordinatorScheduleProvider(widget.coordinator.id).notifier)
          .load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheduleState =
        ref.watch(coordinatorScheduleProvider(widget.coordinator.id));

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        title: Text(
          'إدارة المواعيد',
          style: GoogleFonts.cairo(
            color: _kText,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: _kText),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.add, color: _kLime),
            onPressed: () => _openAddSchedule(context),
          ),
        ],
      ),
      body: Builder(builder: (_) {
        if (scheduleState.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: _kLime),
          );
        }
        if (scheduleState.error != null) {
          return _ErrorView(
            error: scheduleState.error!,
            onRetry: () => ref
                .read(coordinatorScheduleProvider(widget.coordinator.id)
                    .notifier)
                .load(),
          );
        }
        if (scheduleState.schedules.isEmpty) {
          return _EmptyView(onAdd: () => _openAddSchedule(context));
        }
        return RefreshIndicator(
          color: _kLime,
          backgroundColor: _kCard,
          onRefresh: () => ref
              .read(
                  coordinatorScheduleProvider(widget.coordinator.id).notifier)
              .load(),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: scheduleState.schedules.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final schedule = scheduleState.schedules[i];
              return _ScheduleCard(
                schedule: schedule,
                coordinator: widget.coordinator,
                onAssignDriver: () =>
                    _openAssignDriver(context, schedule),
              );
            },
          ),
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _kLime,
        foregroundColor: _kBg,
        onPressed: () => _openAddSchedule(context),
        icon: const Icon(CupertinoIcons.add),
        label: Text(
          'موعد جديد',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  void _openAddSchedule(BuildContext context) {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (_) =>
            AddSchedulePage(coordinator: widget.coordinator),
      ),
    ).then((_) {
      ref
          .read(coordinatorScheduleProvider(widget.coordinator.id).notifier)
          .load();
    });
  }

  void _openAssignDriver(
      BuildContext context, CoordinatorScheduleEntity schedule) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DriverAssignerSheet(
        schedule: schedule,
        coordinator: widget.coordinator,
      ),
    );
  }
}

// ── Schedule Card ──────────────────────────────────────────────

class _ScheduleCard extends StatelessWidget {
  final CoordinatorScheduleEntity schedule;
  final UserEntity coordinator;
  final VoidCallback onAssignDriver;

  const _ScheduleCard({
    required this.schedule,
    required this.coordinator,
    required this.onAssignDriver,
  });

  @override
  Widget build(BuildContext context) {
    final status = schedule.approvalStatus;
    final statusColor = status == ScheduleApprovalStatus.approved
        ? Colors.greenAccent
        : _kLime;

    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Route + badge row
          Row(
            children: [
              Expanded(
                child: Text(
                  schedule.routeLabel,
                  style: GoogleFonts.cairo(
                    color: _kText,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _StatusBadge(label: status.label, color: statusColor),
            ],
          ),
          const SizedBox(height: 8),
          // Time + days
          Row(
            children: [
              const Icon(CupertinoIcons.clock, size: 14, color: _kSubText),
              const SizedBox(width: 4),
              Text(
                schedule.departureTime,
                style: GoogleFonts.cairo(color: _kSubText, fontSize: 13),
              ),
              const SizedBox(width: 16),
              const Icon(CupertinoIcons.calendar, size: 14, color: _kSubText),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  schedule.daysLabel,
                  style: GoogleFonts.cairo(color: _kSubText, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Fare + capacity
          Row(
            children: [
              const Icon(CupertinoIcons.money_dollar_circle,
                  size: 14, color: _kSubText),
              const SizedBox(width: 4),
              Text(
                '${schedule.baseFare.toStringAsFixed(0)} جنيه',
                style: GoogleFonts.cairo(color: _kSubText, fontSize: 13),
              ),
              const SizedBox(width: 16),
              const Icon(CupertinoIcons.person_2, size: 14, color: _kSubText),
              const SizedBox(width: 4),
              Text(
                '${schedule.capacity} مقعد',
                style: GoogleFonts.cairo(color: _kSubText, fontSize: 13),
              ),
            ],
          ),
          // Driver chip or assign button
          const SizedBox(height: 12),
          if (schedule.hasDriver)
            _DriverChip(driverName: schedule.driverName!)
          else if (schedule.canAssignDriver)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kLime,
                  foregroundColor: _kBg,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onPressed: onAssignDriver,
                icon: const Icon(CupertinoIcons.person_add_solid, size: 16),
                label: Text(
                  'تعيين سائق',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
                ),
              ),
            )
          else
            Text(
              'في انتظار موافقة الإدارة لتعيين سائق',
              style: GoogleFonts.cairo(color: _kSubText, fontSize: 12),
            ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: GoogleFonts.cairo(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DriverChip extends StatelessWidget {
  final String driverName;
  const _DriverChip({required this.driverName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.greenAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(CupertinoIcons.person_crop_circle_fill,
              size: 14, color: Colors.greenAccent),
          const SizedBox(width: 6),
          Text(
            driverName,
            style: GoogleFonts.cairo(
                color: Colors.greenAccent,
                fontSize: 13,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ── Empty/Error States ─────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyView({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(CupertinoIcons.calendar_badge_plus,
              size: 72, color: _kLime),
          const SizedBox(height: 16),
          Text(
            'لا توجد مواعيد بعد',
            style: GoogleFonts.cairo(
                color: _kText, fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'أنشئ أول موعد لمسارك',
            style: GoogleFonts.cairo(color: _kSubText, fontSize: 14),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kLime,
              foregroundColor: _kBg,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: onAdd,
            icon: const Icon(CupertinoIcons.add),
            label: Text('إضافة موعد',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(CupertinoIcons.exclamationmark_circle,
              size: 48, color: Colors.redAccent),
          const SizedBox(height: 12),
          Text(
            'حدث خطأ',
            style: GoogleFonts.cairo(
                color: _kText, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error,
              style: GoogleFonts.cairo(color: _kSubText, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: onRetry,
            child: Text('إعادة المحاولة',
                style: GoogleFonts.cairo(color: _kLime)),
          ),
        ],
      ),
    );
  }
}
