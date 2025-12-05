import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../subscription/domain/entities/subscription_schedule_entity.dart';

class FullScreenBookingView extends StatefulWidget {
  final DateTime initialDate;
  final Map<String, SubscriptionScheduleEntity> schedules;
  final Function(DateTime) onDateSelected;
  final Function(SubscriptionScheduleEntity) onBookingTap;

  const FullScreenBookingView({
    super.key,
    required this.initialDate,
    required this.schedules,
    required this.onDateSelected,
    required this.onBookingTap,
  });

  @override
  State<FullScreenBookingView> createState() => _FullScreenBookingViewState();
}

class _FullScreenBookingViewState extends State<FullScreenBookingView>
    with SingleTickerProviderStateMixin {
  late DateTime _selectedDate;
  late DateTime _currentMonth;
  late ScrollController _dateScrollController;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _currentMonth = DateTime(widget.initialDate.year, widget.initialDate.month);
    _dateScrollController = ScrollController();

    // Setup animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _dateScrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildCalendarGrid() {
    final daysInMonth = DateUtils.getDaysInMonth(
      _currentMonth.year,
      _currentMonth.month,
    );
    final firstDayOfMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month,
      1,
    );
    final offset = firstDayOfMonth.weekday % 7;

    return Column(
      children: [
        // Month Navigation
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(
                  CupertinoIcons.chevron_right,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    _currentMonth = DateTime(
                      _currentMonth.year,
                      _currentMonth.month - 1,
                    );
                  });
                },
              ),
              Text(
                DateFormat('MMMM yyyy', 'ar').format(_currentMonth),
                style: AppTheme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(
                  CupertinoIcons.chevron_left,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    _currentMonth = DateTime(
                      _currentMonth.year,
                      _currentMonth.month + 1,
                    );
                  });
                },
              ),
            ],
          ),
        ),

        // Weekday Headers
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ['ح', 'ن', 'ث', 'ر', 'خ', 'ج', 'س']
              .map(
                (day) => Expanded(
                  child: Center(
                    child: Text(
                      day,
                      style: AppTheme.textTheme.bodySmall?.copyWith(
                        color: Colors.white60,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ).animate().fadeIn(),
        const SizedBox(height: 16),

        // Calendar Grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.75,
            ),
            itemCount: offset + daysInMonth,
            itemBuilder: (context, index) {
              if (index < offset) return const SizedBox();

              final day = index - offset + 1;
              final date = DateTime(
                _currentMonth.year,
                _currentMonth.month,
                day,
              );
              final dateKey = date.toIso8601String().split('T')[0];

              final isToday = _isSameDay(date, DateTime.now());
              final hasBooking = widget.schedules.containsKey(dateKey);
              final isSelected = _isSameDay(date, _selectedDate);

              Color? backgroundColor;
              Color textColor = Colors.white;
              FontWeight fontWeight = FontWeight.normal;

              if (isSelected) {
                backgroundColor = AppTheme.primaryColor;
                textColor = Colors.black;
                fontWeight = FontWeight.bold;
              } else if (hasBooking) {
                backgroundColor = AppTheme.primaryColor.withValues(alpha: 0.3);
                textColor = AppTheme.primaryColor;
                fontWeight = FontWeight.bold;
              } else {
                backgroundColor = Colors.transparent;
                textColor = Colors.white;
              }

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDate = date;
                  });
                  widget.onDateSelected(date);
                },
                child: Column(
                  children: [
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$day',
                          style: AppTheme.textTheme.bodyMedium?.copyWith(
                            fontWeight: fontWeight,
                            color: textColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Today Indicator (Red Dot)
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isToday
                            ? const Color(0xFFFF3B30)
                            : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  List<DateTime> _getDateRange() {
    final dates = <DateTime>[];

    // Get all dates with bookings
    final bookingDates =
        widget.schedules.keys.map((key) => DateTime.parse(key)).toList()
          ..sort();

    if (bookingDates.isEmpty) return dates;

    final start = bookingDates.first;
    final end = bookingDates.last;

    for (var i = 0; i <= end.difference(start).inDays; i++) {
      dates.add(start.add(Duration(days: i)));
    }

    return dates;
  }

  List<SubscriptionScheduleEntity> _getBookingsForDate(DateTime date) {
    final dateKey = date.toIso8601String().split('T')[0];
    final schedule = widget.schedules[dateKey];
    return schedule != null ? [schedule] : [];
  }

  void _onDateTap(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
    widget.onDateSelected(date);
  }

  Future<void> _close() async {
    await _animationController.reverse();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dates = _getDateRange();
    final bookings = _getBookingsForDate(_selectedDate);

    return WillPopScope(
      onWillPop: () async {
        await _close();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: SafeArea(
              child: Column(
                children: [
                  // Header with close button
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: _close,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              CupertinoIcons.chevron_down,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'الحجوزات',
                          style: AppTheme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Full month calendar
                  SizedBox(height: 380, child: _buildCalendarGrid()),

                  const SizedBox(height: 16),

                  // Booking list or empty state
                  Expanded(
                    child: bookings.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  CupertinoIcons.calendar_badge_minus,
                                  size: 64,
                                  color: Colors.white.withValues(alpha: 0.3),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'لا يوجد حجز في هذا اليوم',
                                  style: AppTheme.textTheme.titleMedium
                                      ?.copyWith(color: Colors.white70),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: bookings.length,
                            itemBuilder: (context, index) {
                              return _BookingCardItem(
                                booking: bookings[index],
                                index:
                                    index, // Pass index for stagger animation
                                onTap: () =>
                                    widget.onBookingTap(bookings[index]),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  final DateTime date;
  final bool isSelected;
  final bool hasBooking;
  final VoidCallback onTap;

  const _DateChip({
    required this.date,
    required this.isSelected,
    required this.hasBooking,
    required this.onTap,
  });

  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
          onTap: onTap,
          child: Container(
            width: 70,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primaryColor
                  : hasBooking
                  ? AppTheme.primaryColor.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: hasBooking && !isSelected
                  ? Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.5),
                      width: 1,
                    )
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat('EEE', 'ar').format(date),
                  style: AppTheme.textTheme.bodySmall?.copyWith(
                    color: isSelected ? Colors.black : Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date.day.toString(),
                  style: AppTheme.textTheme.titleLarge?.copyWith(
                    color: isSelected ? Colors.black : Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                // Today indicator (red dot) or booking indicator (yellow dot)
                if (isToday)
                  Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF3B30), // Red for today
                          shape: BoxShape.circle,
                        ),
                      )
                      .animate(onPlay: (controller) => controller.repeat())
                      .scale(
                        begin: const Offset(1.0, 1.0),
                        end: const Offset(1.2, 1.2),
                        duration: 1000.ms,
                        curve: Curves.easeInOut,
                      )
                      .then()
                      .scale(
                        begin: const Offset(1.2, 1.2),
                        end: const Offset(1.0, 1.0),
                        duration: 1000.ms,
                        curve: Curves.easeInOut,
                      )
                else if (hasBooking)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.black : AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(delay: (50 * (date.day % 10)).ms)
        .slideX(begin: 0.2, end: 0);
  }
}

class _BookingCardItem extends StatelessWidget {
  final SubscriptionScheduleEntity booking;
  final int index;
  final VoidCallback onTap;

  const _BookingCardItem({
    required this.booking,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [const Color(0xFF1A1A1A), const Color(0xFF0D0D0D)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      booking.tripType == 'round_trip'
                          ? CupertinoIcons.arrow_right_arrow_left
                          : booking.tripType == 'departure_only'
                          ? CupertinoIcons.arrow_right
                          : CupertinoIcons.arrow_left,
                      color: AppTheme.primaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      booking.tripType == 'round_trip'
                          ? 'ذهاب وعودة'
                          : booking.tripType == 'departure_only'
                          ? 'ذهاب فقط'
                          : 'عودة فقط',
                      style: AppTheme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (booking.departureTime != null) ...[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ميعاد الذهاب',
                              style: AppTheme.textTheme.bodySmall?.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              booking.departureTime!,
                              style: AppTheme.textTheme.headlineSmall?.copyWith(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (booking.returnTime != null) ...[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ميعاد العودة',
                              style: AppTheme.textTheme.bodySmall?.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              booking.returnTime!,
                              style: AppTheme.textTheme.headlineSmall?.copyWith(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'اضغط لتعديل المواعيد',
                      style: AppTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      CupertinoIcons.arrow_right,
                      size: 16,
                      color: AppTheme.primaryColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(delay: (100 * index).ms)
        .slideY(begin: 0.3, end: 0, delay: (100 * index).ms);
  }
}
