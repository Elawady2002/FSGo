import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/entities/coordinator_schedule_entity.dart';
import '../providers/driver_duty_provider.dart';
import 'manifest_page.dart';
import '../../../../core/services/notification_service.dart';
import '../../../home/presentation/widgets/global_drawer.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../home/presentation/providers/driver_status_provider.dart';
import '../../../home/domain/entities/driver_activity_status.dart';

const _kBg = Colors.white;
const _kCard = Color(0xFFF5F5F5);
const _kLime = Color(0xFFC9D420);
const _kText = Color(0xFF1A1A1A);
const _kSubText = Color(0xFF666666);

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
  void initState() {
    super.initState();
    NotificationService.instance.subscribeToAssignments(widget.driverId);
  }

  @override
  void dispose() {
    NotificationService.instance.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final schedulesAsync = ref.watch(
      driverAssignedSchedulesProvider(widget.driverId),
    );
    final user = ref.watch(authProvider).value;

    return Scaffold(
      backgroundColor: _kBg,
      drawer: GlobalDrawer(user: user, selectedIndex: 1),
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(CupertinoIcons.bars, color: _kText),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
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
              loading: () =>
                  const Center(child: CircularProgressIndicator(color: _kLime)),
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

                // Update driver status based on trips
                ref
                    .read(driverStatusProvider.notifier)
                    .updateStatusBasedOnTrips(filtered.isNotEmpty);

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
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
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
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(
            primary: _kText,
            onPrimary: _kLime,
            onSurface: _kText,
            surface: Colors.white,
          ),
          dialogTheme: const DialogThemeData(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
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
          const Icon(CupertinoIcons.calendar_today, color: _kLime, size: 16),
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
          builder: (_) => ManifestPage(schedule: schedule, date: date),
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
                      color: _kLime.withValues(alpha: 0.7),
                      fontSize: 11,
                    ),
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
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Icon(
                  CupertinoIcons.chevron_right,
                  color: _kSubText,
                  size: 16,
                ),
                const SizedBox(height: 4),
                Text(
                  'عرض الركاب',
                  style: GoogleFonts.cairo(color: _kLime, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyDuty extends ConsumerStatefulWidget {
  final DateTime date;
  final VoidCallback onChangeDate;
  const _EmptyDuty({required this.date, required this.onChangeDate});

  @override
  ConsumerState<_EmptyDuty> createState() => _EmptyDutyState();
}

class _EmptyDutyState extends ConsumerState<_EmptyDuty> {
  bool _isRefreshing = false;

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(driverStatusProvider);
    final isOffline = status == DriverActivityStatus.offline;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated Illustration Background
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _kCard, // Replacing glow with solid card color
              ),
              child: Icon(
                CupertinoIcons.car_detailed,
                size: 64,
                color: isOffline ? _kSubText.withValues(alpha: 0.3) : _kLime,
              ),
            ),
            const SizedBox(height: 32),

            // Status Indicator (Simplified - No Glow)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isOffline ? _kSubText : _kLime,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isOffline ? 'خارج الخدمة حالياً' : status.label,
                    style: GoogleFonts.cairo(
                      color: isOffline ? _kSubText : _kText,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'لا توجد رحلات مجدولة',
              style: GoogleFonts.cairo(
                color: _kText,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              isOffline
                  ? 'يرجى تفعيل حالة "متاح" لتتمكن من استلام وتأكيد المهام والرحلات من الإدارة.'
                  : 'لم يتم تعيين أي رحلات لك في هذا اليوم. يمكنك التحقق من توفر مهام جديدة بالضغط على الزر أدناه.',
              style: GoogleFonts.cairo(
                color: _kSubText,
                fontSize: 14,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Action Buttons (Redesigned: #1A1A1A Bg, #C9D420 Text, No Glow)
            if (!isOffline)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isRefreshing ? null : _handleRefresh,
                  icon: _isRefreshing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(_kLime),
                          ),
                        )
                      : const Icon(CupertinoIcons.refresh_thick, size: 20),
                  label: Text(
                    _isRefreshing ? 'جاري التحديث...' : 'تحديث المهام',
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1A1A),
                    foregroundColor: const Color(0xFFC9D420),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: widget.onChangeDate,
              icon: const Icon(CupertinoIcons.calendar, size: 18),
              label: Text(
                'عرض يوم آخر',
                style: GoogleFonts.cairo(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: _kSubText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);
    // Simulate refresh or call actual provider
    final user = ref.read(authProvider).value;
    if (user != null) {
      await ref.refresh(driverAssignedSchedulesProvider(user.id).future);
    }
    await Future.delayed(const Duration(seconds: 1)); // UX delay
    if (mounted) setState(() => _isRefreshing = false);
  }
}
