import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/subscription_entity.dart';

enum CardViewState { details, calendar, timeSelection }

class CalendarPlanCard extends ConsumerStatefulWidget {
  final String title;
  final String price;
  final String period;
  final List<String> features;
  final bool isPopular;
  final Color accentColor;
  final SubscriptionPlanType planType;
  final void Function(SubscriptionScheduleParams? params) onSubscribe;

  const CalendarPlanCard({
    super.key,
    required this.title,
    required this.price,
    required this.period,
    required this.features,
    required this.isPopular,
    required this.accentColor,
    required this.planType,
    required this.onSubscribe,
  });

  @override
  ConsumerState<CalendarPlanCard> createState() => _CalendarPlanCardState();
}

class _CalendarPlanCardState extends ConsumerState<CalendarPlanCard> {
  CardViewState _currentView = CardViewState.details;
  DateTime? _selectedDate;
  String? _selectedDepartureTime;
  String? _selectedReturnTime;
  String? _selectedTripType; // Make nullable to allow no selection
  late DateTime _currentMonth; // Track current month being displayed

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  }

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

  DateTime get _startDate => DateTime.now();
  DateTime get _endDate =>
      _startDate.add(Duration(days: widget.planType.durationDays));

  void _onCalendarIconTap() {
    setState(() {
      _currentView = CardViewState.calendar;
    });
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
      _currentView = CardViewState.timeSelection;
    });
  }

  void _onBackToCalendar() {
    setState(() {
      _currentView = CardViewState.calendar;
      _selectedDate = null;
      _selectedDepartureTime = null;
      _selectedReturnTime = null;
    });
  }

  void _onBackToDetails() {
    setState(() {
      _currentView = CardViewState.details;
      _selectedDate = null;
      _selectedDepartureTime = null;
      _selectedReturnTime = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: widget.isPopular ? widget.accentColor : Colors.grey.shade200,
          width: widget.isPopular ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
              child: child,
            ),
          );
        },
        child: _buildCurrentView(),
      ),
    );
  }

  Widget _buildCurrentView() {
    switch (_currentView) {
      case CardViewState.details:
        return _buildDetailsView();
      case CardViewState.calendar:
        return _buildCalendarView();
      case CardViewState.timeSelection:
        return _buildTimeSelectionView();
    }
  }

  Widget _buildDetailsView() {
    return Column(
      key: const ValueKey('details'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Card Header
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.title,
                    style: AppTheme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (widget.isPopular)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: widget.accentColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'الاكثر توفيرا',
                        style: TextStyle(
                          color: widget.accentColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.none,
                          decorationColor: Colors.transparent,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    widget.price,
                    style: AppTheme.textTheme.displayLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'ج.م',
                    style: AppTheme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Text(
                    ' / ${widget.period}',
                    style: AppTheme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  // Calendar Icon Button
                  GestureDetector(
                    onTap: _onCalendarIconTap,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: widget.accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        CupertinoIcons.calendar,
                        color: widget.accentColor,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        // Features List
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(24),
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.features.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    CupertinoIcons.checkmark_alt,
                    color: widget.isPopular ? widget.accentColor : Colors.black,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.features[index],
                      style: AppTheme.textTheme.bodyMedium?.copyWith(
                        color: Colors.black87,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),

        // Action Button
        Padding(
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => widget.onSubscribe(null),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.isPopular
                    ? widget.accentColor
                    : Colors.black,
                foregroundColor: widget.isPopular ? Colors.black : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'اشترك الآن',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarView() {
    return Column(
      key: const ValueKey('calendar'),
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              GestureDetector(
                onTap: _onBackToDetails,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(CupertinoIcons.chevron_back, size: 20),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'اختار يوم الرحلة',
                  style: AppTheme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),

        const Divider(height: 1),

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

    final canGoPrevious = _currentMonth.isAfter(_startDate);
    final canGoNext = DateTime(
      _currentMonth.year,
      _currentMonth.month + 1,
      1,
    ).isBefore(_endDate);

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
                  CupertinoIcons.chevron_back,
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
                                color: AppTheme.textSecondary,
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
                            date.isAfter(_endDate) || date.isBefore(_startDate);
                        final isAvailable =
                            !isFriday && !isPast && !isOutOfRange;

                        return Expanded(
                          child: GestureDetector(
                            onTap: isAvailable
                                ? () => _onDateSelected(date)
                                : null,
                            child: Container(
                              margin: const EdgeInsets.all(4),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isToday
                                    ? widget.accentColor.withValues(alpha: 0.15)
                                    : (isAvailable
                                          ? Colors.grey.shade50
                                          : Colors.transparent),
                                borderRadius: BorderRadius.circular(12),
                                border: isToday
                                    ? Border.all(
                                        color: widget.accentColor,
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
                                                  ? widget.accentColor
                                                  : Colors.black)
                                            : AppTheme.textTertiary,
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

  Widget _buildTimeSelectionView() {
    return Column(
      key: const ValueKey('timeSelection'),
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              GestureDetector(
                onTap: _onBackToCalendar,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(CupertinoIcons.chevron_back, size: 20),
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
                      ),
                    ),
                    if (_selectedDate != null)
                      Text(
                        DateFormat('EEEE، d MMMM', 'ar').format(_selectedDate!),
                        style: AppTheme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        // Time Selection Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Trip Type Selector
                Text(
                  'نوع الرحلة',
                  style: AppTheme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildTripTypeSelector(),
                const SizedBox(height: 24),

                // Departure Time (if applicable)
                if (_selectedTripType != 'return_only') ...[
                  Text(
                    'ميعاد الذهاب',
                    style: AppTheme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildTimeSelector(
                    times: _departureTimes,
                    selectedTime: _selectedDepartureTime,
                    onSelect: (time) {
                      setState(() {
                        if (_selectedDepartureTime == time) {
                          _selectedDepartureTime = null;
                        } else {
                          _selectedDepartureTime = time;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                ],

                // Return Time (if applicable)
                if (_selectedTripType != 'departure_only') ...[
                  Text(
                    'ميعاد العودة',
                    style: AppTheme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildTimeSelector(
                    times: _returnTimes,
                    selectedTime: _selectedReturnTime,
                    onSelect: (time) {
                      setState(() {
                        if (_selectedReturnTime == time) {
                          _selectedReturnTime = null;
                        } else {
                          _selectedReturnTime = time;
                        }
                      });
                    },
                  ),
                ],
              ],
            ),
          ),
        ),

        // Confirm Button
        Padding(
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _canConfirm()
                  ? () {
                      // Get user data
                      final user = ref.read(authProvider);

                      // Create params with user's university as temporary scheduleId
                      // TODO: Replace with actual route selection in future
                      final params = SubscriptionScheduleParams(
                        startDate: _selectedDate!,
                        tripType:
                            _selectedTripType ??
                            'round_trip', // Default to round_trip if null
                        departureTime: _selectedDepartureTime,
                        returnTime: _selectedReturnTime,
                        scheduleId: user
                            ?.universityId, // Use university as temp scheduleId
                        pickupStationId:
                            null, // TODO: Get from user profile or route selection
                        dropoffStationId:
                            null, // TODO: Get from user profile or route selection
                      );
                      widget.onSubscribe(params);
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.accentColor,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                disabledBackgroundColor: Colors.grey.shade300,
              ),
              child: const Text(
                'تأكيد الحجز',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
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
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: types.map((type) {
          final isSelected = _selectedTripType == type['value'];
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  // Toggle behavior: if already selected, deselect it
                  if (_selectedTripType == type['value']) {
                    _selectedTripType = null; // Deselect
                  } else {
                    _selectedTripType = type['value'] as String;
                  }
                  // Clear selected times when changing trip type
                  if (_selectedTripType == 'return_only') {
                    _selectedDepartureTime = null;
                  } else if (_selectedTripType == 'departure_only') {
                    _selectedReturnTime = null;
                  } else if (_selectedTripType == null) {
                    // Clear both when deselecting
                    _selectedDepartureTime = null;
                    _selectedReturnTime = null;
                  }
                });
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
                    color: isSelected ? Colors.black : AppTheme.textSecondary,
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
                color: isSelected ? widget.accentColor : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? Border.all(color: widget.accentColor, width: 2)
                    : Border.all(color: Colors.transparent, width: 2),
              ),
              child: Text(
                time,
                style: AppTheme.textTheme.bodyMedium?.copyWith(
                  color: isSelected ? Colors.black : AppTheme.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  bool _canConfirm() {
    // If no trip type selected, require both times
    if (_selectedTripType == null) {
      return _selectedDepartureTime != null && _selectedReturnTime != null;
    }

    if (_selectedTripType == 'departure_only') {
      return _selectedDepartureTime != null;
    } else if (_selectedTripType == 'return_only') {
      return _selectedReturnTime != null;
    } else {
      // round_trip
      return _selectedDepartureTime != null && _selectedReturnTime != null;
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
