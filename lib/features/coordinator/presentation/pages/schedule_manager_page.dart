import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/domain/entities/user_entity.dart';
import '../../domain/entities/coordinator_schedule_entity.dart';
import '../providers/coordinator_provider.dart';
import 'add_schedule_page.dart';
import 'driver_assigner_page.dart';
import 'trip_assignment_page.dart';

// ── Design tokens ──────────────────────────────────────────────
const _kBg = Colors.white;
const _kCard = Color(0xFFF5F5F5);
const _kText = Color(0xFF1A1A1A);
const _kSubText = Color(0xFF666666);
const _kUniversity = Color(0xFF5B6BF8);
const _kStation = Color(0xFF2DB37A);

class ScheduleManagerPage extends ConsumerStatefulWidget {
  final UserEntity coordinator;
  const ScheduleManagerPage({super.key, required this.coordinator});

  @override
  ConsumerState<ScheduleManagerPage> createState() =>
      _ScheduleManagerPageState();
}

class _ScheduleManagerPageState extends ConsumerState<ScheduleManagerPage> {
  // null = الكل، university / station = فلتر محدد
  ScheduleType? _filterType;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(coordinatorScheduleProvider(widget.coordinator.id).notifier)
          .load();
    });
  }

  List<CoordinatorScheduleEntity> _filtered(
      List<CoordinatorScheduleEntity> all) {
    if (_filterType == null) return all;
    return all.where((s) => s.scheduleType == _filterType).toList();
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
            icon: const Icon(CupertinoIcons.add, color: _kText),
            onPressed: () => _openAddSchedule(context),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _FilterTabBar(
            current: _filterType,
            counts: _buildCounts(scheduleState.schedules),
            onChanged: (t) => setState(() => _filterType = t),
          ),
        ),
      ),
      body: Builder(builder: (_) {
        if (scheduleState.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: _kText),
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

        final filtered = _filtered(scheduleState.schedules);

        if (filtered.isEmpty) {
          return _EmptyView(onAdd: () => _openAddSchedule(context));
        }
        return RefreshIndicator(
          color: _kText,
          backgroundColor: _kCard,
          onRefresh: () => ref
              .read(
                  coordinatorScheduleProvider(widget.coordinator.id).notifier)
              .load(),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            itemCount: filtered.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final schedule = filtered[i];
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
        backgroundColor: _kText,
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

  Map<ScheduleType?, int> _buildCounts(
      List<CoordinatorScheduleEntity> schedules) {
    return {
      null: schedules.length,
      ScheduleType.university:
          schedules.where((s) => s.isUniversity).length,
      ScheduleType.station:
          schedules.where((s) => s.isStation).length,
    };
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
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        reverseTransitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: TripAssignmentPage(
              schedule: schedule,
              coordinator: widget.coordinator,
              date: DateTime.now(),
            ),
          );
        },
      ),
    );
  }
}

// ── Filter Tab Bar ─────────────────────────────────────────────

class _FilterTabBar extends StatelessWidget {
  final ScheduleType? current;
  final Map<ScheduleType?, int> counts;
  final ValueChanged<ScheduleType?> onChanged;

  const _FilterTabBar({
    required this.current,
    required this.counts,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kBg,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          _FilterChip(
            label: 'الكل',
            count: counts[null] ?? 0,
            isSelected: current == null,
            color: _kText,
            onTap: () => onChanged(null),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'جامعة',
            count: counts[ScheduleType.university] ?? 0,
            isSelected: current == ScheduleType.university,
            color: _kUniversity,
            onTap: () => onChanged(ScheduleType.university),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'موقف',
            count: counts[ScheduleType.station] ?? 0,
            isSelected: current == ScheduleType.station,
            color: _kStation,
            onTap: () => onChanged(ScheduleType.station),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : _kCard,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.cairo(
                color: isSelected ? Colors.white : _kSubText,
                fontSize: 13,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.25)
                    : color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.cairo(
                  color: isSelected ? Colors.white : color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
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

  Color get _typeColor =>
      schedule.isUniversity ? _kUniversity : _kStation;

  @override
  Widget build(BuildContext context) {
    final status = schedule.approvalStatus;
    final statusColor = status == ScheduleApprovalStatus.approved
        ? const Color(0xFF4CAF50)
        : _kSubText;

    return Hero(
      tag: 'schedule-card-${schedule.id}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onAssignDriver,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: _kCard,
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Route + badges row
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        schedule.routeLabel,
                        style: GoogleFonts.cairo(
                          color: _kText,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _TypeBadge(
                      label: schedule.scheduleType.label,
                      color: _typeColor,
                      icon: schedule.isUniversity
                          ? CupertinoIcons.building_2_fill
                          : CupertinoIcons.bus,
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // University-specific: subscription info
                if (schedule.isUniversity && schedule.subscriptionType != null) ...[
                  Row(
                    children: [
                      Icon(CupertinoIcons.tag, size: 13, color: _typeColor),
                      const SizedBox(width: 4),
                      Text(
                        schedule.subscriptionLabel,
                        style: GoogleFonts.cairo(
                            color: _typeColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                      if (schedule.durationDays != null) ...[
                        Text(
                          ' • ${schedule.durationDays} يوم',
                          style: GoogleFonts.cairo(
                              color: _kSubText, fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                ],

                // Time + days
                Row(
                  children: [
                    const Icon(CupertinoIcons.clock,
                        size: 13, color: _kSubText),
                    const SizedBox(width: 4),
                    Text(
                      schedule.departureTime,
                      style:
                          GoogleFonts.cairo(color: _kSubText, fontSize: 12),
                    ),
                    const SizedBox(width: 12),
                    const Icon(CupertinoIcons.calendar,
                        size: 13, color: _kSubText),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        schedule.daysLabel,
                        style: GoogleFonts.cairo(
                            color: _kSubText, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Fare + capacity + status
                Row(
                  children: [
                    const Icon(CupertinoIcons.money_dollar_circle,
                        size: 13, color: _kSubText),
                    const SizedBox(width: 4),
                    Text(
                      '${schedule.baseFare.toStringAsFixed(0)} جنيه',
                      style:
                          GoogleFonts.cairo(color: _kSubText, fontSize: 12),
                    ),
                    const SizedBox(width: 12),
                    const Icon(CupertinoIcons.person_2,
                        size: 13, color: _kSubText),
                    const SizedBox(width: 4),
                    Text(
                      '${schedule.capacity} مقعد',
                      style:
                          GoogleFonts.cairo(color: _kSubText, fontSize: 12),
                    ),
                    const Spacer(),
                    _StatusBadge(
                        label: status.label, color: statusColor),
                  ],
                ),

                // Driver chip or assign button
                const SizedBox(height: 12),
                if (schedule.hasDriver)
                  _DriverChip(
                      driverName: schedule.driverName!,
                      color: _typeColor)
                else if (schedule.canAssignDriver)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _typeColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        elevation: 0,
                      ),
                      onPressed: onAssignDriver,
                      icon: const Icon(CupertinoIcons.person_add_solid,
                          size: 15),
                      label: Text(
                        'تعيين سائق',
                        style: GoogleFonts.cairo(
                            fontWeight: FontWeight.w700, fontSize: 14),
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
          ),
        ),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  const _TypeBadge(
      {required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.cairo(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.cairo(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DriverChip extends StatelessWidget {
  final String driverName;
  final Color color;
  const _DriverChip({required this.driverName, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(CupertinoIcons.person_crop_circle_fill,
              size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            driverName,
            style: GoogleFonts.cairo(
                color: color,
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
              size: 72, color: _kText),
          const SizedBox(height: 16),
          Text(
            'لا توجد مواعيد بعد',
            style: GoogleFonts.cairo(
                color: _kText,
                fontSize: 18,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'أنشئ أول موعد لمسارك',
            style: GoogleFonts.cairo(color: _kSubText, fontSize: 14),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kText,
              foregroundColor: _kBg,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 12),
              elevation: 0,
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
                color: _kText,
                fontSize: 16,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error,
              style:
                  GoogleFonts.cairo(color: _kSubText, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: onRetry,
            child: Text('إعادة المحاولة',
                style: GoogleFonts.cairo(color: _kText)),
          ),
        ],
      ),
    );
  }
}
