import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/subscription_entity.dart';

enum CardViewState { details, calendar, timeSelection }

class CalendarPlanCard extends StatefulWidget {
  final String title;
  final String price;
  final String period;
  final List<String> features;
  final bool isPopular;
  final Color accentColor;
  final SubscriptionPlanType planType;
  final VoidCallback onSubscribe;

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
  State<CalendarPlanCard> createState() => _CalendarPlanCardState();
}

class _CalendarPlanCardState extends State<CalendarPlanCard> {
  CardViewState _currentView = CardViewState.details;
  DateTime? _selectedDate;
  String? _selectedDepartureTime;
  String? _selectedReturnTime;
  String _selectedTripType =
      'round_trip'; // departure_only, return_only, round_trip

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
              onPressed: widget.onSubscribe,
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
    final daysInRange = _endDate.difference(_startDate).inDays + 1;
    final weeks = (daysInRange / 7).ceil();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
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
                  final dayOffset = weekIndex * 7 + dayIndex;
                  if (dayOffset >= daysInRange) {
                    return const Expanded(child: SizedBox());
                  }

                  final date = _startDate.add(Duration(days: dayOffset));
                  final isToday = _isSameDay(date, DateTime.now());
                  final isAvailable = date.isAfter(
                    DateTime.now().subtract(const Duration(days: 1)),
                  );

                  return Expanded(
                    child: GestureDetector(
                      onTap: isAvailable ? () => _onDateSelected(date) : null,
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
                              ? Border.all(color: widget.accentColor, width: 2)
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            '${date.day}',
                            style: AppTheme.textTheme.bodyMedium?.copyWith(
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
                    onSelect: (time) =>
                        setState(() => _selectedDepartureTime = time),
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
                    onSelect: (time) =>
                        setState(() => _selectedReturnTime = time),
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
              onPressed: _canConfirm() ? widget.onSubscribe : null,
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
              onTap: () =>
                  setState(() => _selectedTripType = type['value'] as String),
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
        return GestureDetector(
          onTap: () => onSelect(time),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? widget.accentColor : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: widget.accentColor, width: 2)
                  : null,
            ),
            child: Text(
              time,
              style: AppTheme.textTheme.bodyMedium?.copyWith(
                color: isSelected ? Colors.black : AppTheme.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  bool _canConfirm() {
    if (_selectedTripType == 'departure_only') {
      return _selectedDepartureTime != null;
    } else if (_selectedTripType == 'return_only') {
      return _selectedReturnTime != null;
    } else {
      return _selectedDepartureTime != null && _selectedReturnTime != null;
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
