import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_theme.dart';

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
    _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
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
    final monthStart = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final monthEnd = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final daysInMonth = monthEnd.day;

    // Get the weekday of the first day (1 = Monday, 7 = Sunday)
    final firstWeekday = monthStart.weekday;

    // Calculate offset for first week (Sunday = 0, Monday = 1, etc.)
    final offset = firstWeekday == 7 ? 0 : firstWeekday;

    final totalCells = offset + daysInMonth;
    final weeks = (totalCells / 7).ceil();

    final canGoPrevious = _currentMonth.isAfter(widget.startDate);
    final canGoNext = DateTime(
      _currentMonth.year,
      _currentMonth.month + 1,
      1,
    ).isBefore(widget.endDate);

    return Column(
      children: [
        // Month navigation
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: canGoPrevious
                    ? () {
                        setState(() {
                          _currentMonth = DateTime(
                            _currentMonth.year,
                            _currentMonth.month - 1,
                            1,
                          );
                        });
                      }
                    : null,
                icon: Icon(
                  CupertinoIcons.chevron_right,
                  color: canGoPrevious ? Colors.white : Colors.grey,
                ),
              ),
              Text(
                DateFormat('MMMM yyyy', 'ar').format(_currentMonth),
                style: AppTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              IconButton(
                onPressed: canGoNext
                    ? () {
                        setState(() {
                          _currentMonth = DateTime(
                            _currentMonth.year,
                            _currentMonth.month + 1,
                            1,
                          );
                        });
                      }
                    : null,
                icon: Icon(
                  CupertinoIcons.chevron_forward,
                  color: canGoNext ? Colors.white : Colors.grey,
                ),
              ),
            ],
          ),
        ),

        // Calendar grid
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                // Weekday headers
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: ['ح', 'ن', 'ث', 'ر', 'خ', 'ج', 'س']
                      .map(
                        (day) => Expanded(
                          child: Center(
                            child: Text(
                              day,
                              style: AppTheme.textTheme.bodySmall?.copyWith(
                                color: Colors.white70,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 16),
                // Calendar days
                ...List.generate(weeks, (weekIndex) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(7, (dayIndex) {
                        final cellIndex = weekIndex * 7 + dayIndex;

                        // Empty cell before month starts
                        if (cellIndex < offset) {
                          return const Expanded(child: SizedBox());
                        }

                        final dayNumber = cellIndex - offset + 1;

                        // Empty cell after month ends
                        if (dayNumber > daysInMonth) {
                          return const Expanded(child: SizedBox());
                        }

                        final date = DateTime(
                          _currentMonth.year,
                          _currentMonth.month,
                          dayNumber,
                        );

                        final isToday = _isSameDay(date, DateTime.now());
                        final isFriday = date.weekday == 5; // Friday
                        final isPast = date.isBefore(
                          DateTime.now().subtract(const Duration(days: 1)),
                        );
                        final isOutOfRange =
                            date.isAfter(widget.endDate) ||
                            date.isBefore(widget.startDate);
                        final isAvailable =
                            !isFriday && !isPast && !isOutOfRange;

                        return Expanded(
                          child: GestureDetector(
                            onTap: isAvailable
                                ? () => widget.onDateSelected(date)
                                : null,
                            child: Container(
                              margin: const EdgeInsets.all(4),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isToday
                                    ? AppTheme.primaryColor.withValues(alpha: 0.2)
                                    : (isAvailable
                                          ? Colors.white.withValues(alpha: 0.05)
                                          : Colors.transparent),
                                borderRadius: BorderRadius.circular(12),
                                border: isToday
                                    ? Border.all(
                                        color: AppTheme.primaryColor,
                                        width: 2,
                                      )
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  '$dayNumber',
                                  style: AppTheme.textTheme.bodyMedium
                                      ?.copyWith(
                                        fontWeight: isToday
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: isAvailable
                                            ? (isToday
                                                  ? AppTheme.primaryColor
                                                  : Colors.white)
                                            : Colors.white30,
                                      ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
