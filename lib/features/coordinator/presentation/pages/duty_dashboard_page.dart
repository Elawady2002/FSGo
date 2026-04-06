import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/entities/coordinator_schedule_entity.dart';
import '../providers/driver_duty_provider.dart';
import 'manifest_page.dart';

const _kBg = Color(0xFF1A1A1A);
const _kCard = Color(0xFF242424);
const _kLime = Color(0xFFC9D420);
const _kText = Colors.white;
const _kSubText = Color(0xFF9E9E9E);

/// Full-page Duty Dashboard shown for Driver role users.
class DutyDashboardPage extends ConsumerStatefulWidget {
  final String driverId;
  const DutyDashboardPage({super.key, required this.driverId});

  @override
  ConsumerState<DutyDashboardPage> createState() => _DutyDashboardPageState();
}

class _DutyDashboardPageState extends ConsumerState<DutyDashboardPage> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final schedulesAsync =
        ref.watch(driverAssignedSchedulesProvider(widget.driverId));

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        title: Text(
          'مهامي اليوم',
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
            icon: const Icon(CupertinoIcons.calendar, color: _kLime),
            onPressed: _pickDate,
          ),
        ],
      ),
      body: Column(
        children: [
          _DateBanner(date: _selectedDate),
          Expanded(
            child: schedulesAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: _kLime),
              ),
              error: (e, _) => Center(
                child: Text(
                  'خطأ: $e',
                  style: GoogleFonts.cairo(color: Colors.redAccent),
                  textAlign: TextAlign.center,
                ),
              ),
              data: (schedules) {
                // Filter schedules that are available on the selected day
                final dayName = _dayName(_selectedDate.weekday);
                final filtered = schedules
                    .where((s) => s.availableDays.contains(dayName))
                    .toList();

                if (filtered.isEmpty) {
                  return _EmptyDuty(
                    date: _selectedDate,
                    onChangeDate: _pickDate,
                  );
                }
                return RefreshIndicator(
                  color: _kLime,
                  backgroundColor: _kCard,
                  onRefresh: () => ref.refresh(
                    driverAssignedSchedulesProvider(widget.driverId).future,
                  ),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      return _DutyCard(
                        schedule: filtered[i],
                        date: _selectedDate,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: _kLime,
            onSurface: _kText,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  String _dayName(int weekday) {
    const days = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];
    return days[(weekday - 1) % 7];
  }
}

// ── Date Banner ────────────────────────────────────────────────

class _DateBanner extends StatelessWidget {
  final DateTime date;
  const _DateBanner({required this.date});

  @override
  Widget build(BuildContext context) {
    final isToday = _isToday(date);
    final dayNames = [
      'الاثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد',
    ];
    final dayLabel = dayNames[(date.weekday - 1) % 7];
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(CupertinoIcons.calendar_today,
              color: _kLime, size: 16),
          const SizedBox(width: 8),
          Text(
            isToday
                ? 'اليوم — $dayLabel'
                : '$dayLabel ${date.day}/${date.month}/${date.year}',
            style: GoogleFonts.cairo(
              color: _kText,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }
}

// ── Duty Card ──────────────────────────────────────────────────

class _DutyCard extends StatelessWidget {
  final CoordinatorScheduleEntity schedule;
  final DateTime date;
  const _DutyCard({required this.schedule, required this.date});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (_) => ManifestPage(
            schedule: schedule,
            date: date,
          ),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _kLime.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    schedule.departureTime.split(':')[0],
                    style: GoogleFonts.cairo(
                      color: _kLime,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                  Text(
                    ':${schedule.departureTime.split(':').length > 1 ? schedule.departureTime.split(':')[1] : '00'}',
                    style: GoogleFonts.cairo(
                        color: _kLime.withValues(alpha: 0.7), fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    schedule.routeLabel,
                    style: GoogleFonts.cairo(
                      color: _kText,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(CupertinoIcons.person_2,
                          size: 13, color: _kSubText),
                      const SizedBox(width: 4),
                      Text(
                        '${schedule.capacity} مقعد',
                        style: GoogleFonts.cairo(
                            color: _kSubText, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Icon(CupertinoIcons.chevron_right,
                    color: _kSubText, size: 16),
                const SizedBox(height: 4),
                Text(
                  'عرض الركاب',
                  style: GoogleFonts.cairo(
                      color: _kLime, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty State ────────────────────────────────────────────────

class _EmptyDuty extends StatelessWidget {
  final DateTime date;
  final VoidCallback onChangeDate;
  const _EmptyDuty({required this.date, required this.onChangeDate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(CupertinoIcons.car_detailed,
              size: 64, color: _kLime),
          const SizedBox(height: 16),
          Text(
            'لا توجد مهام هذا اليوم',
            style: GoogleFonts.cairo(
              color: _kText,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'لم يتم تعيينك في أي رحلة لهذا اليوم',
            style: GoogleFonts.cairo(color: _kSubText, fontSize: 14),
          ),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: onChangeDate,
            icon: const Icon(CupertinoIcons.calendar, color: _kLime),
            label: Text(
              'تغيير التاريخ',
              style: GoogleFonts.cairo(color: _kLime),
            ),
          ),
        ],
      ),
    );
  }
}
