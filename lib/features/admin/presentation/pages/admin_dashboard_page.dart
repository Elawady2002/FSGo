import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/domain/entities/user_entity.dart';
import '../../../coordinator/domain/entities/coordinator_schedule_entity.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../providers/admin_provider.dart';

const _kBg = Color(0xFF1A1A1A);
const _kCard = Color(0xFF242424);
const _kLime = Color(0xFFC9D420);
const _kText = Colors.white;
const _kSubText = Color(0xFF9E9E9E);

class AdminDashboardPage extends ConsumerStatefulWidget {
  final UserEntity admin;
  const AdminDashboardPage({super.key, required this.admin});

  @override
  ConsumerState<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends ConsumerState<AdminDashboardPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminScheduleProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminScheduleProvider);

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        title: Column(
          children: [
            Text(
              'لوحة الإدارة',
              style: GoogleFonts.cairo(
                color: _kText,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              widget.admin.fullName,
              style: GoogleFonts.cairo(color: _kLime, fontSize: 11),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.person_circle, color: _kText),
            onPressed: () => Navigator.push(
              context,
              CupertinoPageRoute(builder: (_) => const ProfilePage()),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: _kLime,
          labelColor: _kLime,
          unselectedLabelColor: _kSubText,
          labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.w700),
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(CupertinoIcons.clock, size: 14),
                  const SizedBox(width: 6),
                  Text('في الانتظار'),
                  if (state.pending.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    _CountBadge(count: state.pending.length, color: _kLime),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(CupertinoIcons.checkmark_circle, size: 14),
                  const SizedBox(width: 6),
                  Text('موافق عليها'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Builder(builder: (_) {
        if (state.isLoading) {
          return const Center(
              child: CircularProgressIndicator(color: _kLime));
        }
        if (state.error != null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(CupertinoIcons.exclamationmark_circle,
                    color: Colors.redAccent, size: 48),
                const SizedBox(height: 12),
                Text(state.error!,
                    style: GoogleFonts.cairo(color: _kSubText),
                    textAlign: TextAlign.center),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () =>
                      ref.read(adminScheduleProvider.notifier).load(),
                  child: Text('إعادة المحاولة',
                      style: GoogleFonts.cairo(color: _kLime)),
                ),
              ],
            ),
          );
        }
        return TabBarView(
          controller: _tabs,
          children: [
            _PendingTab(schedules: state.pending),
            _ApprovedTab(schedules: state.approved),
          ],
        );
      }),
    );
  }
}

// ── Pending Tab ────────────────────────────────────────────────

class _PendingTab extends ConsumerWidget {
  final List<CoordinatorScheduleEntity> schedules;
  const _PendingTab({required this.schedules});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (schedules.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(CupertinoIcons.checkmark_seal, size: 64, color: _kLime),
            const SizedBox(height: 16),
            Text(
              'لا توجد طلبات معلّقة',
              style: GoogleFonts.cairo(
                  color: _kText, fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'كل المواعيد تمت مراجعتها',
              style: GoogleFonts.cairo(color: _kSubText, fontSize: 14),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: _kLime,
      backgroundColor: _kCard,
      onRefresh: () => ref.read(adminScheduleProvider.notifier).load(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: schedules.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, i) => _PendingCard(schedule: schedules[i]),
      ),
    );
  }
}

class _PendingCard extends ConsumerWidget {
  final CoordinatorScheduleEntity schedule;
  const _PendingCard({required this.schedule});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kLime.withValues(alpha: 0.2)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Route
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
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _kLime.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'معلّق',
                  style: GoogleFonts.cairo(color: _kLime, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Details row
          _DetailRow(
              icon: CupertinoIcons.clock,
              label: schedule.departureTime),
          const SizedBox(height: 4),
          _DetailRow(
              icon: CupertinoIcons.calendar,
              label: schedule.daysLabel),
          const SizedBox(height: 4),
          _DetailRow(
            icon: CupertinoIcons.money_dollar_circle,
            label: '${schedule.baseFare.toStringAsFixed(0)} جنيه  •  ${schedule.capacity} مقعد',
          ),
          const SizedBox(height: 14),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _reject(context, ref, schedule.id),
                  child: Text('رفض',
                      style:
                          GoogleFonts.cairo(fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kBg,
                    foregroundColor: _kLime,
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    side: BorderSide(color: _kLime.withValues(alpha: 0.3), width: 1),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => _approve(context, ref, schedule.id),
                  icon: const Icon(CupertinoIcons.checkmark, size: 16),
                  label: Text('موافقة',
                      style:
                          GoogleFonts.cairo(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _approve(
      BuildContext context, WidgetRef ref, String id) async {
    final err =
        await ref.read(adminScheduleProvider.notifier).approve(id);
    if (!context.mounted) return;
    _showSnack(context, err == null ? 'تمت الموافقة ✓' : 'خطأ: $err',
        err == null ? Colors.green : Colors.redAccent);
  }

  Future<void> _reject(
      BuildContext context, WidgetRef ref, String id) async {
    final confirm = await showCupertinoDialog<bool>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: Text('تأكيد الرفض',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
        content: Text('هل تريد رفض هذا الموعد؟', style: GoogleFonts.cairo()),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('رفض'),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    final err = await ref.read(adminScheduleProvider.notifier).reject(id);
    if (!context.mounted) return;
    _showSnack(context, err == null ? 'تم الرفض' : 'خطأ: $err',
        err == null ? Colors.orange : Colors.redAccent);
  }

  void _showSnack(BuildContext context, String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.cairo()),
      backgroundColor: color,
    ));
  }
}

// ── Approved Tab ───────────────────────────────────────────────

class _ApprovedTab extends ConsumerWidget {
  final List<CoordinatorScheduleEntity> schedules;
  const _ApprovedTab({required this.schedules});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (schedules.isEmpty) {
      return Center(
        child: Text(
          'لا توجد مواعيد موافق عليها بعد',
          style: GoogleFonts.cairo(color: _kSubText, fontSize: 15),
        ),
      );
    }
    return RefreshIndicator(
      color: _kLime,
      backgroundColor: _kCard,
      onRefresh: () => ref.read(adminScheduleProvider.notifier).load(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: schedules.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final s = schedules[i];
          return Container(
            decoration: BoxDecoration(
              color: _kCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: Colors.greenAccent.withValues(alpha: 0.2)),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        s.routeLabel,
                        style: GoogleFonts.cairo(
                          color: _kText,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'موافق عليه',
                        style: GoogleFonts.cairo(
                            color: Colors.greenAccent, fontSize: 11),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                _DetailRow(
                    icon: CupertinoIcons.clock, label: s.departureTime),
                if (s.hasDriver) ...[
                  const SizedBox(height: 4),
                  _DetailRow(
                    icon: CupertinoIcons.car_detailed,
                    label: s.driverName ?? 'سائق مُعيَّن',
                    color: Colors.greenAccent,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Shared Widgets ─────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _DetailRow(
      {required this.icon, required this.label, this.color = _kSubText});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.cairo(color: color, fontSize: 13),
          ),
        ),
      ],
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;
  final Color color;
  const _CountBadge({required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: GoogleFonts.cairo(
            color: _kBg, fontSize: 11, fontWeight: FontWeight.w800),
      ),
    );
  }
}
