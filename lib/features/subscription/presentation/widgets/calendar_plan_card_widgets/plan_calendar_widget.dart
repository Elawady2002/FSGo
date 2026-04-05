import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fielsekkia_driver/core/utils/digit_converter.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/unified_calendar.dart';

class PlanCalendarView extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;
  final Color accentColor;
  final ValueChanged<DateTime> onDateSelected;
  final VoidCallback onBack;

  const PlanCalendarView({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.accentColor,
    required this.onDateSelected,
    required this.onBack,
  });

  @override
  State<PlanCalendarView> createState() => _PlanCalendarViewState();
}

class _PlanCalendarViewState extends State<PlanCalendarView> {
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    _currentMonth = widget.startDate;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('calendar'),
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              GestureDetector(
                onTap: widget.onBack,
                child: const Icon(
                  CupertinoIcons.chevron_right,
                  size: 24,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'اختار يوم الرحلة',
                  style: AppTheme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),

        const Divider(height: 1, color: Colors.white24),

        // Calendar Grid
        Expanded(child: _buildCalendarGrid()),
      ],
    );
  }

  Widget _buildCalendarGrid() {
    return UnifiedCalendarWidget(
      mode: UnifiedCalendarMode.singleSelection,
      initialDate: _currentMonth,
      firstDate: widget.startDate,
      lastDate: widget.endDate,
      accentColor: widget.accentColor,
      transparentBackground: true,
      showHeaderCenterAligned: false,
      onDateSelected: widget.onDateSelected,
      selectableDayPredicate: (date) {
        final isFriday = date.weekday == DateTime.friday;
        final isPast = date.isBefore(
          DateTime.now().subtract(const Duration(days: 1)),
        );
        return !isFriday && !isPast;
      },
    );
  }
}
