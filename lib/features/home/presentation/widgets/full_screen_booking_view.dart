import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../booking/presentation/providers/booking_provider.dart';
import '../../../subscription/domain/entities/subscription_schedule_entity.dart';
import '../../../subscription/domain/entities/subscription_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

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
  late DateTime _selectedDate;
  late DateTime _currentMonth;
  late ScrollController _dateScrollController;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _isLoading = false;

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
      return DateFormat('h:mm a', 'en').format(dt);
    } catch (e) {
      return dbTime; // Fallback
    }
  }

  // Helper to convert UI time to DB format (e.g. "7:30 AM" -> "07:30:00")
  String? _toDbTime(String? uiTime) {
    if (uiTime == null) return null;
    try {
      final dt = DateFormat('h:mm a', 'en').parse(uiTime);
      return DateFormat('HH:mm:ss').format(dt);
    } catch (e) {
      return uiTime;
    }
  }

  Future<void> _saveBooking() async {
    final user = ref.read(authProvider).value;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('المستخدم غير مسجل الدخول')),
        );
      }
      return;
    }

    // Validate time selection based on trip type
    bool isValid = true;
    String validationError = '';

    if (_editingTripType == 'departure_only' && _editingDepartureTime == null) {
      isValid = false;
      validationError = 'يرجى اختيار ميعاد الذهاب';
    } else if (_editingTripType == 'return_only' &&
        _editingReturnTime == null) {
      isValid = false;
      validationError = 'يرجى اختيار ميعاد العودة';
    } else if (_editingTripType == 'round_trip' &&
        (_editingDepartureTime == null || _editingReturnTime == null)) {
      isValid = false;
      validationError = 'يرجى اختيار ميعاد الذهاب والعودة';
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

      debugPrint('📝 Saving booking...');
      debugPrint('   User ID: ${user.id}');
      debugPrint('   Booking Date: $bookingDate');
      debugPrint('   Trip Type: $_editingTripType');
      debugPrint(
        '   Departure: $_editingDepartureTime -> ${_toDbTime(_editingDepartureTime)}',
      );
      debugPrint(
        '   Return: $_editingReturnTime -> ${_toDbTime(_editingReturnTime)}',
      );
      debugPrint('   Price: $price');
      debugPrint('   Selected Booking ID: ${_selectedBooking?.id}');

      if (_selectedBooking == null) {
        // Create new booking
        debugPrint('➕ Inserting new booking...');

        await supabase.from('bookings').insert({
          'user_id': user.id,
          'subscription_id': widget.subscription.id,
          // schedule_id is optional - not needed for subscription bookings
          'booking_date': bookingDate,
          'trip_type': _editingTripType,
          'departure_time': _toDbTime(_editingDepartureTime),
          'return_time': _toDbTime(_editingReturnTime),
          'status': 'confirmed',
          'payment_status': 'paid',
          'total_price': price,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });

        debugPrint('✅ New booking created successfully!');
      } else {
        // Update existing booking
        debugPrint('🔄 Updating booking ${_selectedBooking!.id}...');

        final response = await supabase
            .from('bookings')
            .update({
              'trip_type': _editingTripType,
              'departure_time': _toDbTime(_editingDepartureTime),
              'return_time': _toDbTime(_editingReturnTime),
              'total_price': price,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', _selectedBooking!.id)
            .select(); // Add .select() to get the updated row

        debugPrint('✅ Booking update response: $response');

        if (response.isEmpty) {
          debugPrint(
            '⚠️ No rows were updated! Check RLS policies or booking ID.',
          );
        }
      }

      if (mounted) {
        // Refresh providers
        ref.invalidate(userBookingsProvider);
        ref.invalidate(upcomingBookingProvider);
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('❌ Error saving booking: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }
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
    return Column(
      children: [
        // Month Header (No arrows)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.center, // Center the month name
            children: [
              Text(
                DateFormat('MMMM yyyy', 'ar').format(_currentMonth),
                style: AppTheme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
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

        // Horizontal Calendar PageView
        Expanded(
          child: PageView.builder(
            controller: PageController(
              initialPage:
                  12 * 100, // Start in middle to allow going back/forward
            ),
            onPageChanged: (index) {
              // Calculate difference from initial page
              final difference = index - (12 * 100);
              setState(() {
                _currentMonth = DateTime(
                  widget.initialDate.year,
                  widget.initialDate.month + difference,
                );
              });
            },
            itemBuilder: (context, index) {
              final monthOffset = index - (12 * 100);
              final monthDate = DateTime(
                widget.initialDate.year,
                widget.initialDate.month + monthOffset,
              );

              final daysInMonth = DateUtils.getDaysInMonth(
                monthDate.year,
                monthDate.month,
              );
              final firstDayOfMonth = DateTime(
                monthDate.year,
                monthDate.month,
                1,
              );
              final offset = firstDayOfMonth.weekday % 7;

              return GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                physics:
                    const NeverScrollableScrollPhysics(), // Disable vertical scroll
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
                  final date = DateTime(monthDate.year, monthDate.month, day);
                  final dateKey = date.toIso8601String().split('T')[0];

                  final isToday = _isSameDay(date, DateTime.now());
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

                  final hasSchedule = widget.schedules.containsKey(dateKey);
                  final isSelected = _isSameDay(date, _selectedDate);

                  final isStartDate = _isSameDay(
                    date,
                    widget.subscription.startDate,
                  );
                  final isEndDate = _isSameDay(
                    date,
                    widget.subscription.endDate,
                  );

                  // Determine styles based on state
                  Color? backgroundColor;
                  BoxBorder? border;
                  Color textColor = Colors.white;
                  FontWeight fontWeight = FontWeight.normal;

                  if (isSelected) {
                    backgroundColor = AppTheme.primaryColor;
                    textColor = Colors.black;
                    fontWeight = FontWeight.bold;
                  } else if (hasSchedule) {
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
                    onTap: isAvailable
                        ? () {
                            setState(() {
                              _selectedDate = date;
                            });
                            widget.onDateSelected(date);
                          }
                        : null,
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
              );
            },
          ),
        ),
      ],
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
      _editingTripType = 'round_trip';
      _editingDepartureTime = null;
      _editingReturnTime = null;
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
                'الحجوزات',
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
                        'لا يوجد حجز في هذا اليوم',
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
                _selectedBooking == null ? 'إضافة حجز' : 'تعديل الحجز',
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
            DateFormat('EEEE d MMMM', 'ar').format(_selectedDate),
            style: AppTheme.textTheme.titleLarge?.copyWith(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // Trip type selector
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'نوع الرحلة',
                style: AppTheme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildTripTypeButton('ذهاب فقط', 'departure_only'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTripTypeButton('عودة فقط', 'return_only'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTripTypeButton('ذهاب وعودة', 'round_trip'),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

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
                    'ميعاد الذهاب',
                    style: AppTheme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
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
                  const SizedBox(height: 24),
                ],

                // Return times
                if (_editingTripType == 'return_only' ||
                    _editingTripType == 'round_trip') ...[
                  Text(
                    'ميعاد العودة',
                    style: AppTheme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
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
          padding: const EdgeInsets.all(24),
          child: CustomButton(
            text: 'تأكيد الجدول',
            onPressed: _isLoading ? null : _saveBooking,
            isLoading: _isLoading,
            backgroundColor: AppTheme.primaryColor,
            textColor: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildTripTypeButton(String label, String type) {
    final isSelected = _editingTripType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _editingTripType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTheme.textTheme.bodyMedium?.copyWith(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildTimeChip(String time, bool isDeparture) {
    final currentTime = isDeparture
        ? _editingDepartureTime
        : _editingReturnTime;
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          time,
          style: AppTheme.textTheme.bodyMedium?.copyWith(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
