import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/fleet_provider.dart';
import '../../data/repositories/reservation_repository.dart';

const _kBg = Colors.white;
const _kCard = Color(0xFFF5F5F5);
const _kLime = Color(0xFF1A1A1A);
const _kText = Color(0xFF1A1A1A);
const _kSubText = Color(0xFF666666);

/// Fleet planning dashboard for station managers.
///
/// Shows total reserved seats per destination for a selected date.
class FleetDashboardScreen extends ConsumerStatefulWidget {
  const FleetDashboardScreen({super.key});

  @override
  ConsumerState<FleetDashboardScreen> createState() =>
      _FleetDashboardScreenState();
}

class _FleetDashboardScreenState
    extends ConsumerState<FleetDashboardScreen> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));

  @override
  Widget build(BuildContext context) {
    final reservationsAsync =
        ref.watch(fleetReservationsProvider(_selectedDate));

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        title: Text(
          'تخطيط الأسطول',
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
          _DateHeader(date: _selectedDate),
          Expanded(
            child: reservationsAsync.when(
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
              data: (summaries) => summaries.isEmpty
                  ? _EmptyFleet(date: _selectedDate)
                  : _SummaryList(
                      summaries: summaries,
                      onRefresh: () => ref.invalidate(
                          fleetReservationsProvider(_selectedDate)),
                    ),
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
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: _kLime),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }
}

// ── Date Header ────────────────────────────────────────────────

class _DateHeader extends StatelessWidget {
  final DateTime date;
  const _DateHeader({required this.date});

  @override
  Widget build(BuildContext context) {
    final isTomorrow = _isTomorrow(date);
    final label = isTomorrow
        ? 'غداً'
        : DateFormat('EEEE، d MMMM', 'ar_EG').format(date);

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
            label,
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

  bool _isTomorrow(DateTime d) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return d.year == tomorrow.year &&
        d.month == tomorrow.month &&
        d.day == tomorrow.day;
  }
}

// ── Summary List ───────────────────────────────────────────────

class _SummaryList extends StatelessWidget {
  final List<ReservationSummary> summaries;
  final VoidCallback onRefresh;
  const _SummaryList(
      {required this.summaries, required this.onRefresh});

  int get _totalSeats =>
      summaries.fold(0, (sum, s) => sum + s.totalSeats);

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: _kLime,
      backgroundColor: _kCard,
      onRefresh: () async => onRefresh(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Total summary chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _kLime.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kLime.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(CupertinoIcons.sum, color: _kText, size: 18),
                const SizedBox(width: 10),
                Text(
                  'إجمالي المقاعد المحجوزة: $_totalSeats',
                  style: GoogleFonts.cairo(
                    color: _kText,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...summaries.map((s) => _DestinationCard(summary: s)),
        ],
      ),
    );
  }
}

// ── Destination Card ───────────────────────────────────────────

class _DestinationCard extends StatelessWidget {
  final ReservationSummary summary;
  const _DestinationCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _kLime.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(CupertinoIcons.location_fill,
                color: _kLime, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              summary.destination,
              style: GoogleFonts.cairo(
                color: _kText,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${summary.totalSeats}',
                style: GoogleFonts.cairo(
                  color: _kLime,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              Text(
                'مقعد محجوز',
                style: GoogleFonts.cairo(color: _kSubText, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Empty State ────────────────────────────────────────────────

class _EmptyFleet extends StatelessWidget {
  final DateTime date;
  const _EmptyFleet({required this.date});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(CupertinoIcons.car_detailed, size: 64, color: _kLime),
          const SizedBox(height: 16),
          Text(
            'لا توجد حجوزات',
            style: GoogleFonts.cairo(
              color: _kText,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'لم يتم تسجيل أي حجوزات لهذا اليوم',
            style: GoogleFonts.cairo(color: _kSubText, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
