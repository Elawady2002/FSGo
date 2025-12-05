import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../booking/data/datasources/booking_data_source.dart';
import '../../../booking/domain/entities/booking_entity.dart';
import '../../../subscription/domain/entities/subscription_entity.dart';
import '../../../subscription/domain/entities/subscription_schedule_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

enum SubscriptionCardView { details, calendar, bookingList, timeSelection }

class ActiveSubscriptionCard extends ConsumerStatefulWidget {
  final SubscriptionEntity subscription;
  final List<BookingEntity> regularBookings;

  const ActiveSubscriptionCard({
    super.key,
    required this.subscription,
    this.regularBookings = const [],
  });

  @override
  ConsumerState<ActiveSubscriptionCard> createState() =>
      _ActiveSubscriptionCardState();
}

class _ActiveSubscriptionCardState
    extends ConsumerState<ActiveSubscriptionCard> {
  SubscriptionCardView _currentView = SubscriptionCardView.details;
  SubscriptionCardView _previousView = SubscriptionCardView.details;
  DateTime? _selectedDate;
  String? _selectedDepartureTime;
  String? _selectedReturnTime;
  String _selectedTripType = 'round_trip';
  String _universityName = 'الجامعة';
  Map<String, SubscriptionScheduleEntity> _schedules = {};
  bool _isLoadingSchedules = true;
  late DateTime _currentMonth;

  final List<String> _departureTimes = [
    'AM 6:00',
    'AM 6:30',
    'AM 7:00',
    'AM 7:30',
    'AM 8:00',
  ];

  final List<String> _returnTimes = [
    'PM 2:00',
    'PM 2:30',
    'PM 3:00',
    'PM 3:30',
    'PM 4:00',
  ];

  @override
  void initState() {
    super.initState();
    _currentMonth = widget.subscription.startDate;
    _fetchUniversityName();
    _fetchSchedules();
  }

  @override
  void didUpdateWidget(ActiveSubscriptionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refresh calendar when regularBookings list changes
    if (oldWidget.regularBookings.length != widget.regularBookings.length) {
      _fetchSchedules();
    }
  }

  Future<void> _fetchUniversityName() async {
    final user = ref.read(authProvider);
    if (user?.universityId != null) {
      try {
        final response = await Supabase.instance.client
            .from('universities')
            .select('name')
            .eq('id', user!.universityId!)
            .single();
        if (mounted) {
          setState(() {
            _universityName = response['name'] as String;
          });
        }
      } catch (e) {
        // Fallback or log error
      }
    }
  }

  Future<void> _fetchSchedules() async {
    if (widget.subscription.id == null) return;

    setState(() => _isLoadingSchedules = true);

    try {
      final Map<String, SubscriptionScheduleEntity> schedulesMap = {};

      // 1. Fetch subscription bookings from bookings table
      final response = await Supabase.instance.client
          .from('bookings')
          .select()
          .eq('subscription_id', widget.subscription.id!)
          .order('booking_date');

      for (var booking in response) {
        final bookingDate = DateTime.parse(booking['booking_date'] as String);
        final dateKey = bookingDate.toIso8601String().split('T')[0];

        schedulesMap[dateKey] = SubscriptionScheduleEntity(
          id: booking['id'] as String,
          subscriptionId: booking['subscription_id'] as String,
          tripDate: bookingDate,
          tripType: booking['trip_type'] as String,
          departureTime: booking['departure_time'] as String?,
          returnTime: booking['return_time'] as String?,
          createdAt: DateTime.parse(booking['created_at'] as String),
          updatedAt: booking['updated_at'] != null
              ? DateTime.parse(booking['updated_at'] as String)
              : DateTime.parse(booking['created_at'] as String),
        );
      }

      // 2. Add regular bookings from widget.regularBookings
      for (var booking in widget.regularBookings) {
        final dateKey = booking.bookingDate.toIso8601String().split('T')[0];

        // Convert BookingEntity to SubscriptionScheduleEntity
        schedulesMap[dateKey] = SubscriptionScheduleEntity(
          id: booking.id,
          subscriptionId: '', // Empty for regular bookings
          tripDate: booking.bookingDate,
          tripType: booking.tripType,
          departureTime: booking.departureTime,
          returnTime: booking.returnTime,
          createdAt: booking.createdAt,
          updatedAt: booking.updatedAt,
        );
      }

      if (mounted) {
        setState(() {
          _schedules = schedulesMap;
          _isLoadingSchedules = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingSchedules = false);
      }
    }
  }

  void _playSound() {
    HapticFeedback.selectionClick();
    SystemSound.play(SystemSoundType.click);
  }

  void _onCalendarIconTap() {
    _playSound();
    setState(() {
      _previousView = _currentView;
      _currentView = SubscriptionCardView.calendar;
    });
  }

  void _onDateSelected(DateTime date) {
    _playSound();
    final dateKey = date.toIso8601String().split('T')[0];
    final existingSchedule = _schedules[dateKey];

    setState(() {
      _selectedDate = date;
      _previousView = _currentView;
      _currentView =
          SubscriptionCardView.details; // Back to details to show updated data

      // Load existing schedule if available
      if (existingSchedule != null) {
        _selectedTripType = existingSchedule.tripType;
        _selectedDepartureTime = existingSchedule.departureTime;
        _selectedReturnTime = existingSchedule.returnTime;
      } else {
        // Reset to defaults
        _selectedTripType = 'round_trip';
        _selectedDepartureTime = null;
        _selectedReturnTime = null;
      }
    });
  }

  void _onBackToCalendar() {
    _playSound();
    setState(() {
      _previousView = _currentView;
      _currentView = SubscriptionCardView.calendar;
      _selectedDate = null;
      _selectedDepartureTime = null;
      _selectedReturnTime = null;
    });
  }

  void _onBackToDetails() {
    _playSound();
    setState(() {
      _previousView = _currentView;
      _currentView = SubscriptionCardView.details;
      _selectedDate = null;
      _selectedDepartureTime = null;
      _selectedReturnTime = null;
    });
  }

  Future<void> _onConfirmSchedule() async {
    _playSound();
    if (_selectedDate == null) return;

    try {
      final user = ref.read(authProvider);
      if (user == null) throw Exception('User not authenticated');

      // Create booking directly in bookings table
      final bookingDataSource = BookingDataSourceImpl();

      await bookingDataSource.createSubscriptionBooking(
        userId: user.id,
        subscriptionId: widget.subscription.id!,
        scheduleId: user.universityId ?? '00000000-0000-0000-0000-000000000000',
        bookingDate: _selectedDate!,
        tripType: _selectedTripType,
        pickupStationId: null, // TODO: Get from user profile
        dropoffStationId: null, // TODO: Get from user profile
        departureTime: _selectedDepartureTime,
        returnTime: _selectedReturnTime,
        totalPrice: 0.0, // Already paid via subscription
      );

      if (mounted) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم حفظ الحجز بنجاح')));

        // Refresh schedules to show the new booking
        await _fetchSchedules();
        _onBackToCalendar();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ: $e')));
      }
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  bool _canConfirm() {
    if (_selectedDate == null) return false;
    if (_selectedTripType == 'departure_only' &&
        _selectedDepartureTime == null) {
      return false;
    }
    if (_selectedTripType == 'return_only' && _selectedReturnTime == null) {
      return false;
    }
    if (_selectedTripType == 'round_trip' &&
        (_selectedDepartureTime == null || _selectedReturnTime == null)) {
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic,
          alignment: Alignment.topCenter,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            layoutBuilder: (currentChild, previousChildren) {
              return Stack(
                alignment: Alignment.topCenter,
                children: <Widget>[
                  ...previousChildren,
                  if (currentChild != null) currentChild,
                ],
              );
            },
            transitionBuilder: (child, animation) {
              final isForward = _currentView.index > _previousView.index;
              final offset = isForward
                  ? const Offset(1.0, 0.0)
                  : const Offset(-1.0, 0.0);

              return SlideTransition(
                position: Tween<Offset>(
                  begin: offset,
                  end: Offset.zero,
                ).animate(animation),
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            child: _buildCurrentViewContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentViewContent() {
    switch (_currentView) {
      case SubscriptionCardView.details:
        return _buildDetailsContent();
      case SubscriptionCardView.calendar:
        return _buildCalendarContent();
      case SubscriptionCardView.bookingList:
        return _buildBookingListContent();
      case SubscriptionCardView.timeSelection:
        return _buildTimeSelectionContent();
    }
  }

  Widget _buildDetailsContent() {
    return GestureDetector(
      onTap: () {
        if (_selectedDate != null) {
          _playSound();
          setState(() {
            _previousView = _currentView;
            _currentView = SubscriptionCardView.bookingList;
          });
        }
      },
      child: Padding(
        key: const ValueKey('details'),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'قريباً',
                    style: AppTheme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _onCalendarIconTap,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      CupertinoIcons.calendar,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ).animate().fadeIn().slideX(begin: -0.2, end: 0),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'تاريخ البداية',
                        style: AppTheme.textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat(
                          'd MMMM',
                          'ar',
                        ).format(widget.subscription.startDate),
                        style: AppTheme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'تاريخ الانتهاء',
                        style: AppTheme.textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat(
                          'd MMMM',
                          'ar',
                        ).format(widget.subscription.endDate),
                        style: AppTheme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.2, end: 0),
            const SizedBox(height: 24),
            const Divider(color: Colors.white24),
            const SizedBox(height: 16),
            // Route Info at the bottom
            Row(
              children: [
                const Icon(
                  CupertinoIcons.location_solid,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'من منطقتك إلى $_universityName',
                    style: AppTheme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarContent() {
    return Container(
      key: const ValueKey('calendar'),
      // Fixed height for calendar view to ensure consistency or let it size itself?
      // Letting it size itself might be better for AnimatedSize.
      // But we need a constraint for the grid.
      height: 450,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _onBackToDetails,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      CupertinoIcons.chevron_back,
                      size: 20,
                      color: Colors.white,
                    ),
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
          const Divider(height: 1, color: Colors.white10),
          Expanded(
            child: _isLoadingSchedules
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.primaryColor,
                      ),
                    ),
                  )
                : _buildCalendarGrid(),
          ),
        ],
      ),
    );
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
    // Adjust for week starting on Sunday (Sunday=7 in DateTime)
    // We want Sunday to be index 0
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
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.75, // Taller to accommodate the dot below
          ),
          itemCount: offset + daysInMonth,
          itemBuilder: (context, index) {
            if (index < offset) return const SizedBox();

            final day = index - offset + 1;
            final date = DateTime(_currentMonth.year, _currentMonth.month, day);
            final dateKey = date.toIso8601String().split('T')[0];

            final isToday = _isSameDay(date, DateTime.now());
            // Only disable Fridays (weekend in Egypt)
            final isWeekend = date.weekday == DateTime.friday;

            // Check if date is within subscription range
            final isWithinSubscription =
                !date.isBefore(widget.subscription.startDate) &&
                !date.isAfter(widget.subscription.endDate);

            final isAvailable =
                date.isAfter(
                  DateTime.now().subtract(const Duration(days: 1)),
                ) &&
                !isWeekend &&
                isWithinSubscription;

            final hasSchedule = _schedules.containsKey(dateKey);
            final isSelected =
                _selectedDate != null && _isSameDay(date, _selectedDate!);

            final isStartDate = _isSameDay(date, widget.subscription.startDate);
            final isEndDate = _isSameDay(date, widget.subscription.endDate);

            // Determine styles based on state
            // Priority: Selected > Schedule > Start/End > Default

            Color? backgroundColor;
            BoxBorder? border;
            Color textColor = Colors.white;
            FontWeight fontWeight = FontWeight.normal;

            if (isSelected) {
              backgroundColor = AppTheme.primaryColor;
              textColor = Colors.black;
              fontWeight = FontWeight.bold;
            } else if (hasSchedule) {
              // All bookings are yellow
              backgroundColor = AppTheme.primaryColor;
              textColor = Colors.black;
              fontWeight = FontWeight.bold;
            } else if (isStartDate || isEndDate) {
              backgroundColor = Colors.transparent;
              border = Border.all(color: AppTheme.primaryColor, width: 2);
              textColor = AppTheme.primaryColor;
              fontWeight = FontWeight.bold;
            } else {
              backgroundColor = Colors.transparent;
              textColor = isAvailable ? Colors.white : Colors.white24;
            }

            return GestureDetector(
              onTap: isAvailable ? () => _onDateSelected(date) : null,
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(12),
                        border: border,
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
                  // Today Indicator (Red Dot) - Outside the container
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isToday ? Colors.red : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBookingListContent() {
    if (_selectedDate == null) {
      return const Center(child: Text('لا يوجد تاريخ محدد'));
    }

    final dateKey = _selectedDate!.toIso8601String().split('T')[0];
    final bookingsOnDate = _schedules[dateKey];

    return Padding(
      key: const ValueKey('bookingList'),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with back button
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  _playSound();
                  setState(() {
                    _previousView = _currentView;
                    _currentView = SubscriptionCardView.calendar;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    CupertinoIcons.chevron_back,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'اختار المواعيد',
                      style: AppTheme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      DateFormat('EEEE d MMMM', 'ar').format(_selectedDate!),
                      style: AppTheme.textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(height: 1, color: Colors.white10),
          const SizedBox(height: 24),

          // Booking or empty message
          if (bookingsOnDate == null)
            Expanded(
              child: Center(
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
                      style: AppTheme.textTheme.titleMedium?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: GestureDetector(
                onTap: () {
                  _playSound();
                  setState(() {
                    _selectedTripType = bookingsOnDate.tripType;
                    _selectedDepartureTime = bookingsOnDate.departureTime;
                    _selectedReturnTime = bookingsOnDate.returnTime;
                    _previousView = _currentView;
                    _currentView = SubscriptionCardView.timeSelection;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            bookingsOnDate.tripType == 'round_trip'
                                ? CupertinoIcons.arrow_right_arrow_left
                                : bookingsOnDate.tripType == 'departure_only'
                                ? CupertinoIcons.arrow_right
                                : CupertinoIcons.arrow_left,
                            color: AppTheme.primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            bookingsOnDate.tripType == 'round_trip'
                                ? 'ذهاب وعودة'
                                : bookingsOnDate.tripType == 'departure_only'
                                ? 'ذهاب فقط'
                                : 'عودة فقط',
                            style: AppTheme.textTheme.titleMedium?.copyWith(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (bookingsOnDate.departureTime != null) ...[
                        Row(
                          children: [
                            const Icon(
                              CupertinoIcons.time,
                              size: 16,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'ميعاد الذهاب: ${bookingsOnDate.departureTime}',
                              style: AppTheme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (bookingsOnDate.returnTime != null) ...[
                        Row(
                          children: [
                            const Icon(
                              CupertinoIcons.time,
                              size: 16,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'ميعاد العودة: ${bookingsOnDate.returnTime}',
                              style: AppTheme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
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
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimeSelectionContent() {
    return Container(
      key: const ValueKey('timeSelection'),
      height: 500, // Slightly taller for time selection
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _onBackToCalendar,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      CupertinoIcons.chevron_back,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'اختار المواعيد',
                        style: AppTheme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (_selectedDate != null)
                        Text(
                          DateFormat(
                            'EEEE، d MMMM',
                            'ar',
                          ).format(_selectedDate!),
                          style: AppTheme.textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white10),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'نوع الرحلة',
                    style: AppTheme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildTripTypeSelector()
                      .animate()
                      .fadeIn(delay: 100.ms)
                      .slideX(begin: 0.1, end: 0),
                  const SizedBox(height: 24),
                  if (_selectedTripType != 'return_only') ...[
                    Text(
                      'ميعاد الذهاب',
                      style: AppTheme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ).animate().fadeIn(delay: 200.ms),
                    const SizedBox(height: 12),
                    _buildTimeSelector(
                          times: _departureTimes,
                          selectedTime: _selectedDepartureTime,
                          onSelect: (time) {
                            _playSound();
                            setState(() {
                              if (_selectedDepartureTime == time) {
                                _selectedDepartureTime = null;
                              } else {
                                _selectedDepartureTime = time;
                              }
                            });
                          },
                        )
                        .animate()
                        .fadeIn(delay: 250.ms)
                        .slideX(begin: 0.1, end: 0),
                    const SizedBox(height: 24),
                  ],
                  if (_selectedTripType != 'departure_only') ...[
                    Text(
                      'ميعاد العودة',
                      style: AppTheme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ).animate().fadeIn(delay: 300.ms),
                    const SizedBox(height: 12),
                    _buildTimeSelector(
                          times: _returnTimes,
                          selectedTime: _selectedReturnTime,
                          onSelect: (time) {
                            _playSound();
                            setState(() {
                              if (_selectedReturnTime == time) {
                                _selectedReturnTime = null;
                              } else {
                                _selectedReturnTime = time;
                              }
                            });
                          },
                        )
                        .animate()
                        .fadeIn(delay: 350.ms)
                        .slideX(begin: 0.1, end: 0),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _canConfirm() ? _onConfirmSchedule : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  disabledBackgroundColor: Colors.white10,
                ),
                child: const Text(
                  'تأكيد الجدول',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
        ],
      ),
    );
  }

  Widget _buildTripTypeSelector() {
    final types = [
      {'value': 'departure_only', 'label': 'ذهاب فقط'},
      {'value': 'return_only', 'label': 'عودة فقط'},
      {'value': 'round_trip', 'label': 'ذهاب وعودة'},
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: types.map((type) {
          final isSelected = _selectedTripType == type['value'];
          return Expanded(
            child: GestureDetector(
              onTap: () {
                _playSound();
                setState(() => _selectedTripType = type['value'] as String);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Text(
                  type['label'] as String,
                  textAlign: TextAlign.center,
                  style: AppTheme.textTheme.bodyMedium?.copyWith(
                    color: isSelected ? Colors.black : Colors.white60,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTimeSelector({
    required List<String> times,
    required String? selectedTime,
    required Function(String) onSelect,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: times.map((time) {
        final isSelected = selectedTime == time;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onSelect(time),
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryColor : Colors.white10,
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? Border.all(color: AppTheme.primaryColor, width: 2)
                    : Border.all(color: Colors.transparent, width: 2),
              ),
              child: Text(
                time,
                style: AppTheme.textTheme.bodyMedium?.copyWith(
                  color: isSelected ? Colors.black : Colors.white70,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
