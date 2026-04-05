import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:fielsekkia_driver/l10n/app_localizations.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:fielsekkia_driver/core/utils/digit_converter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../booking/presentation/providers/booking_provider.dart';
import '../../../subscription/domain/entities/subscription_schedule_entity.dart';
import '../../../subscription/domain/entities/subscription_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../booking/domain/entities/booking_entity.dart';
import '../../../../core/domain/entities/user_entity.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/widgets/unified_calendar.dart';

enum FullScreenView { bookingList, timeEditor }

class FullScreenBookingView extends ConsumerStatefulWidget {
  final DateTime initialDate;
  final Map<String, SubscriptionScheduleEntity> schedules;
  final SubscriptionEntity subscription;
  final Function(DateTime) onDateSelected;
  final Function(SubscriptionScheduleEntity) onBookingTap;

  const FullScreenBookingView({
    super.key,
    required this.initialDate,
    required this.schedules,
    required this.subscription,
    required this.onDateSelected,
    required this.onBookingTap,
  });

  @override
  ConsumerState<FullScreenBookingView> createState() =>
      _FullScreenBookingViewState();
}

class _FullScreenBookingViewState extends ConsumerState<FullScreenBookingView>
    with SingleTickerProviderStateMixin {
  FullScreenView _currentView = FullScreenView.bookingList;
  SubscriptionScheduleEntity? _selectedBooking;
  String _editingTripType = 'round_trip';
  String? _editingDepartureTime;
  String? _editingReturnTime;
  BookingSelectionType _selectionType = BookingSelectionType.seat;
  int _passengerCount = 1;
  bool _splitPreference = true;
  late DateTime _selectedDate;
  late DateTime _currentMonth;
  late ScrollController _dateScrollController;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _isLoading = false;

  UserEntity? get user => ref.watch(authProvider).value;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _currentMonth = DateTime(widget.initialDate.year, widget.initialDate.month);

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

  // Helper to normalize time strings (e.g. "07:30:00" -> "7:30 AM")
  String? _normalizeTime(String? dbTime) {
    if (dbTime == null) return null;
    try {
      // Try parsing as HH:mm:ss or HH:mm
      final parts = dbTime.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final dt = DateTime(2022, 1, 1, hour, minute);
      // Format to "h:mm a" to match chips (e.g. "7:30 AM")
      return DateFormat('h:mm a', 'en').format(dt).w;
    } catch (e) {
      return dbTime; // Fallback
    }
  }

  // Helper to convert UI time to DB format (e.g. "7:30 AM" -> "07:30:00")
  String? _toDbTime(String? uiTime) {
    if (uiTime == null) return null;
    try {
      final dt = DateFormat('h:mm a', 'en').parse(uiTime);
      return DateFormat('HH:mm:ss').format(dt).w;
    } catch (e) {
      return uiTime;
    }
  }

  Future<void> _saveBooking() async {
    final l10n = AppLocalizations.of(context)!;
    final currentUser = user; // Local variable for type promotion
    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.userNotLoggedIn)),
        );
      }
      return;
    }

    // Validate time selection based on trip type
    bool isValid = true;
    String validationError = '';

    if (_editingTripType == 'departure_only' && _editingDepartureTime == null) {
      isValid = false;
      validationError = l10n.selectDepartureTimeError;
    } else if (_editingTripType == 'return_only' &&
        _editingReturnTime == null) {
      isValid = false;
      validationError = l10n.selectReturnTimeError;
    }

    if (!isValid) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(validationError)));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      final bookingDate = _selectedDate.toIso8601String().split('T')[0];

      // Calculate price based on trip type
      double price;
      switch (_editingTripType) {
        case 'departure_only':
        case 'return_only':
          price = 50.0;
          break;
        case 'round_trip':
        default:
          price = 80.0;
          break;
      }

      AppLogger.info('Saving booking for user: ${currentUser.id}');

      if (_selectedBooking == null) {

        await supabase.from('bookings').insert({
          'user_id': currentUser.id,
          'subscription_id': widget.subscription.id,
          // schedule_id is optional - not needed for subscription bookings
          'booking_date': bookingDate,
          'trip_type': _editingTripType,
          'pickup_station_id': widget.subscription.pickupStationId,
          'dropoff_station_id': widget.subscription.dropoffStationId,
          'departure_time': _toDbTime(_editingDepartureTime),
          'return_time': _toDbTime(_editingReturnTime),
          'status': 'confirmed',
          'payment_status': 'paid',
          'total_price': price,
          'selection_type': _selectionType.toJson(),
          'passenger_count': _passengerCount,
          'split_preference': _splitPreference,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });

      } else {

        final response = await supabase
            .from('bookings')
            .update({
              'trip_type': _editingTripType,
              'pickup_station_id': widget.subscription.pickupStationId,
              'dropoff_station_id': widget.subscription.dropoffStationId,
              'departure_time': _toDbTime(_editingDepartureTime),
              'return_time': _toDbTime(_editingReturnTime),
              'total_price': price,
              'selection_type': _selectionType.toJson(),
              'passenger_count': _passengerCount,
              'split_preference': _splitPreference,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', _selectedBooking!.id)
            .select(); // Add .select() to get the updated row

        if (response.isEmpty) {
          AppLogger.warning('No rows were updated for booking ${_selectedBooking!.id}. Check RLS policies.');
        }
      }

      if (mounted) {
        // Refresh providers
        ref.invalidate(userBookingsProvider);
        ref.invalidate(upcomingBookingProvider);
        Navigator.of(context).pop();
      }
    } catch (e) {
      AppLogger.error('Error saving booking', e);
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorOccurred(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildCalendarGrid() {
    List<CalendarEvent> events = [];
    
    // Add events for schedules
    widget.schedules.forEach((dateString, schedule) {
      try {
        events.add(CalendarEvent(
          date: DateTime.parse(dateString),
          color: AppTheme.primaryColor,
          isHighlight: true,
          payload: schedule,
        ));
      } catch (e) {
        AppLogger.warning('Invalid date string in schedules: $dateString');
      }
    });

    // Add outline for start and end date
    events.add(CalendarEvent(
      date: widget.subscription.startDate,
      color: AppTheme.primaryColor,
      isOutline: true,
      isHighlight: false,
    ));

    events.add(CalendarEvent(
      date: widget.subscription.endDate,
      color: AppTheme.primaryColor,
      isOutline: true,
      isHighlight: false,
    ));

    return UnifiedCalendarWidget(
      mode: UnifiedCalendarMode.eventView,
      initialDate: _selectedDate,
      events: events,
      accentColor: AppTheme.primaryColor,
      transparentBackground: true,
      showHeaderCenterAligned: true,
      onDateSelected: (date) {
        setState(() {
          _selectedDate = date;
        });
        widget.onDateSelected(date);
      },
      selectableDayPredicate: (date) {
        final isWeekend = date.weekday == DateTime.friday;
        final isWithinSubscription =
            !date.isBefore(widget.subscription.startDate) &&
            !date.isAfter(widget.subscription.endDate);
        
        return date.isAfter(DateTime.now().subtract(const Duration(days: 1))) &&
               !isWeekend &&
               isWithinSubscription;
      },
    );
  }

  List<SubscriptionScheduleEntity> _getBookingsForDate(DateTime date) {
    final dateKey = date.toIso8601String().split('T')[0];
    final schedule = widget.schedules[dateKey];
    return schedule != null ? [schedule] : [];
  }

  void _onAddNewBooking() {
    // Create a new empty booking for the selected date
    setState(() {
      _selectedBooking = null; // null means creating new
      _editingTripType = 'departure_only';
      _editingDepartureTime = null;
      _editingReturnTime = null;
      _selectionType = BookingSelectionType.seat;
      _passengerCount = 1;
      _splitPreference = true;
      _currentView = FullScreenView.timeEditor;
    });
  }

  Future<void> _close() async {
    await _animationController.reverse();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        if (_currentView == FullScreenView.timeEditor) {
          setState(() {
            _currentView = FullScreenView.bookingList;
          });
        } else {
          await _close();
        }
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: Colors.black,
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: SafeArea(
                child: _currentView == FullScreenView.bookingList
                    ? _buildBookingListView()
                    : _buildTimeEditorView(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBookingListView() {
    final bookings = _getBookingsForDate(_selectedDate);

    return Column(
      children: [
        // Header with close and add buttons
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    CupertinoIcons.xmark,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              Text(
                AppLocalizations.of(context)!.bookings,
                style: AppTheme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: _onAddNewBooking,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.transparent, // Removed background
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    CupertinoIcons.add,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Full month calendar
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.55,
          child: _buildCalendarGrid(),
        ),

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
                        AppLocalizations.of(context)!.noBookingOnThisDay,
                        style: AppTheme.textTheme.titleMedium?.copyWith(
                          color: Colors.white70,
                        ),
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
                      index: index,
                      onTap: () {
                        // Initialize editing state with current booking values
                        setState(() {
                          _selectedBooking = bookings[index];
                          _editingTripType = bookings[index].tripType;
                          _editingDepartureTime = _normalizeTime(
                            bookings[index].departureTime,
                          );
                          _editingReturnTime = _normalizeTime(
                            bookings[index].returnTime,
                          );
                          _selectionType = BookingSelectionType.fromJson(bookings[index].selectionType);
                          _passengerCount = bookings[index].passengerCount;
                          _splitPreference = bookings[index].splitPreference;
                          _currentView = FullScreenView.timeEditor;
                        });
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTimeEditorView() {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    _currentView = FullScreenView.bookingList;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    CupertinoIcons.chevron_right,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                _selectedBooking == null
                    ? AppLocalizations.of(context)!.addBooking
                    : AppLocalizations.of(context)!.editBooking,
                style: AppTheme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        // Date display
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Text(
            DateFormat('EEEE d MMMM', 'ar_EG')
                .format(_selectedDate).w,
            style: AppTheme.textTheme.titleLarge?.copyWith(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),


        // Time selection
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Departure times
                if (_editingTripType == 'departure_only' ||
                    _editingTripType == 'round_trip') ...[
                  Text(
                    AppLocalizations.of(context)!.departureTime,
                    style: AppTheme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 19,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      '6:00 AM',
                      '6:30 AM',
                      '7:00 AM',
                      '7:30 AM',
                      '8:00 AM',
                    ].map((time) => _buildTimeChip(time, true)).toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                // Return times
                if (_editingTripType == 'return_only' ||
                    _editingTripType == 'round_trip') ...[
                  Text(
                    AppLocalizations.of(context)!.returnTime,
                    style: AppTheme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 19,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      '2:00 PM',
                      '2:30 PM',
                      '3:00 PM',
                      '3:30 PM',
                      '4:00 PM',
                    ].map((time) => _buildTimeChip(time, false)).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Confirm button
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
          child: CustomButton(
            text: AppLocalizations.of(context)!.confirmSchedule,
            onPressed: _isLoading ? null : _saveBooking,
            isLoading: _isLoading,
            backgroundColor: AppTheme.primaryColor,
            textColor: Colors.black,
          ),
        ),
      ],
    );
  }


  Widget _buildTimeChip(String time, bool isDeparture) {
    final currentTime = isDeparture ? _editingDepartureTime : _editingReturnTime;
    final isSelected = currentTime == time;

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isDeparture) {
            _editingDepartureTime = time;
          } else {
            _editingReturnTime = time;
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: isSelected
              ? null
              : Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 1,
                ),
        ),
        child: Text(
          time,
          style: AppTheme.textTheme.bodyMedium?.copyWith(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 15,
          ),
        ),
      ),
    );
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
                      booking.dropoffStationId != null
                          ? AppLocalizations.of(context)!.stationToStation
                          : (booking.tripType == 'round_trip'
                              ? AppLocalizations.of(context)!.roundTrip
                              : booking.tripType == 'departure_only'
                                  ? AppLocalizations.of(context)!.departureOnly
                                  : AppLocalizations.of(context)!.returnOnly),
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
                              AppLocalizations.of(context)!.departureTime,
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
                              AppLocalizations.of(context)!.returnTime,
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
                      AppLocalizations.of(context)!.clickToEditTimes,
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
