import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fielsekkia_driver/core/utils/digit_converter.dart';
import '../theme/app_theme.dart';

enum UnifiedCalendarMode {
  singleSelection, // Just picking a date
  eventView,       // Viewing and picking days with events
}

class CalendarEvent {
  final DateTime date;
  final Color color;
  final bool isHighlight; // If true, background is filled. If false, shows a dot.
  final bool isOutline; // If true, bordered.
  final dynamic payload;

  const CalendarEvent({
    required this.date,
    required this.color,
    this.isHighlight = false,
    this.isOutline = false,
    this.payload,
  });
}

class UnifiedCalendarWidget extends StatefulWidget {
  final UnifiedCalendarMode mode;
  final DateTime initialDate;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final List<CalendarEvent> events;
  final ValueChanged<DateTime>? onDateSelected;
  final Color? accentColor;
  final bool showHeaderArrows;
  final bool showHeaderCenterAligned; // If true, centers text and hides arrows
  final bool transparentBackground;
  
  // Styling
  final TextStyle? monthHeaderStyle;
  final TextStyle? weekdayHeaderStyle;
  final TextStyle? dayTextStyle;
  final Color? defaultDayColor;
  final Color? disabledDayColor;
  final bool Function(DateTime)? selectableDayPredicate;

  const UnifiedCalendarWidget({
    super.key,
    this.mode = UnifiedCalendarMode.singleSelection,
    required this.initialDate,
    this.firstDate,
    this.lastDate,
    this.events = const [],
    this.onDateSelected,
    this.accentColor,
    this.showHeaderArrows = true,
    this.showHeaderCenterAligned = false,
    this.transparentBackground = false,
    this.monthHeaderStyle,
    this.weekdayHeaderStyle,
    this.dayTextStyle,
    this.defaultDayColor,
    this.disabledDayColor,
    this.selectableDayPredicate,
  });

  @override
  State<UnifiedCalendarWidget> createState() => _UnifiedCalendarWidgetState();
}

class _UnifiedCalendarWidgetState extends State<UnifiedCalendarWidget> {
  late DateTime _displayedMonth;
  late DateTime _selectedDate;
  late PageController _pageController;
  final int _initialPage = 1200; // Large center value to allow endless scrolling

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _displayedMonth = DateTime(widget.initialDate.year, widget.initialDate.month, 1);
    
    // We calculate offset if the user passed an initialDate that isn't today
    final now = DateTime.now();
    final monthDiff = (_displayedMonth.year - now.year) * 12 + (_displayedMonth.month - now.month);
    _pageController = PageController(initialPage: _initialPage + monthDiff);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isSelectable(DateTime date) {
    if (widget.firstDate != null && date.isBefore(DateTime(widget.firstDate!.year, widget.firstDate!.month, widget.firstDate!.day))) return false;
    if (widget.lastDate != null && date.isAfter(DateTime(widget.lastDate!.year, widget.lastDate!.month, widget.lastDate!.day))) return false;
    
    // In Event mode, you typically can only select from today onwards
    if (widget.mode == UnifiedCalendarMode.eventView) {
      final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
      if (date.isBefore(today)) return false;
    }
    
    if (widget.selectableDayPredicate != null) {
      if (!widget.selectableDayPredicate!(date)) return false;
    }
    
    return true;
  }

  void _onDaySelected(DateTime date) {
    if (!_isSelectable(date)) return;
    
    setState(() {
      _selectedDate = date;
    });
    
    if (widget.onDateSelected != null) {
      widget.onDateSelected!(date);
    }
  }

  void _goToPreviousMonth() {
    _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  void _goToNextMonth() {
    _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = widget.accentColor ?? AppTheme.primaryColor;
    final defDayColor = widget.defaultDayColor ?? (widget.transparentBackground ? Colors.white : Colors.black);
    final disDayColor = widget.disabledDayColor ?? (widget.transparentBackground ? Colors.white30 : Colors.grey.shade400);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            mainAxisAlignment: widget.showHeaderCenterAligned ? MainAxisAlignment.center : MainAxisAlignment.spaceBetween,
            children: [
              if (widget.showHeaderArrows && !widget.showHeaderCenterAligned)
                _buildNavButton(CupertinoIcons.chevron_right, _goToNextMonth), // Right arrow goes to next for RTL
              
              Text(
                DateFormat('MMMM yyyy', 'ar_EG').format(_displayedMonth).w,
                style: widget.monthHeaderStyle ?? AppTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: widget.transparentBackground ? Colors.white : Colors.black,
                ),
              ),
              
              if (widget.showHeaderArrows && !widget.showHeaderCenterAligned)
                _buildNavButton(CupertinoIcons.chevron_left, _goToPreviousMonth),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Weekdays
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['ح', 'ن', 'ث', 'ر', 'خ', 'ج', 'س'].map((day) => Expanded(
              child: Center(
                child: Text(
                  day,
                  style: widget.weekdayHeaderStyle ?? AppTheme.textTheme.bodySmall?.copyWith(
                    color: widget.transparentBackground ? Colors.white70 : AppTheme.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )).toList(),
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Calendar Grid
        SizedBox(
          height: 320,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              final monthOffset = index - _initialPage;
              final now = DateTime.now();
              setState(() {
                _displayedMonth = DateTime(now.year, now.month + monthOffset, 1);
              });
            },
            itemBuilder: (context, index) {
              final monthOffset = index - _initialPage;
              final now = DateTime.now();
              final monthDate = DateTime(now.year, now.month + monthOffset, 1);
              final daysInMonth = DateUtils.getDaysInMonth(monthDate.year, monthDate.month);
              final firstDayOffset = monthDate.weekday % 7; // Sunday = 0, Monday = 1 ... Saturday = 6 (adjust based on locale, Arabic week starts Sat, so Sat=0)
              
              // In Dart, weekday: 1=Mon, 2=Tue, ... 7=Sun
              // Arabic week starts on Saturday. Let's map it:
              // Mon=1 -> 2, Tue=2 -> 3, Wed=3 -> 4, Thu=4 -> 5, Fri=5 -> 6, Sat=6 -> 0, Sun=7 -> 1
              int mappedOffset = (monthDate.weekday + 1) % 7;

              return GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 0.85,
                ),
                itemCount: mappedOffset + daysInMonth,
                itemBuilder: (context, gridIndex) {
                  if (gridIndex < mappedOffset) return const SizedBox();
                  
                  final day = gridIndex - mappedOffset + 1;
                  final date = DateTime(monthDate.year, monthDate.month, day);
                  
                  final isToday = _isSameDay(date, DateTime.now());
                  final isSelected = _isSameDay(date, _selectedDate);
                  final isSelectable = _isSelectable(date);
                  
                  // Check for events
                  final eventsOnDay = widget.events.where((e) => _isSameDay(e.date, date)).toList();
                  final hasEvent = eventsOnDay.isNotEmpty;
                  final event = hasEvent ? eventsOnDay.first : null;
                  
                  Color? bgColor;
                  BoxBorder? border;
                  Color textColor = isSelectable ? defDayColor : disDayColor;
                  FontWeight fontWeight = isSelectable ? FontWeight.w500 : FontWeight.normal;
                  
                  if (isSelected) {
                    bgColor = themeColor;
                    textColor = Colors.black;
                    fontWeight = FontWeight.bold;
                  } else if (hasEvent) {
                    if (event!.isHighlight) {
                      bgColor = event.color;
                      textColor = Colors.black;
                      fontWeight = FontWeight.bold;
                    } else if (event.isOutline) {
                      bgColor = Colors.transparent;
                      border = Border.all(color: event.color, width: 2);
                      textColor = event.color;
                      fontWeight = FontWeight.bold;
                    } else {
                      bgColor = widget.transparentBackground ? Colors.white.withAlpha(20) : themeColor.withAlpha(25);
                      textColor = isSelectable ? defDayColor : disDayColor;
                      if (!widget.transparentBackground && isSelectable) {
                         border = Border.all(color: themeColor, width: 1);
                      }
                    }
                  } else if (isToday) {
                    if (!widget.transparentBackground) {
                      bgColor = themeColor.withAlpha(30);
                      border = Border.all(color: themeColor, width: 1.5);
                    }
                  }
                  
                  return GestureDetector(
                    onTap: () => _onDaySelected(date),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(12),
                              border: border,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '$day',
                              style: widget.dayTextStyle?.copyWith(color: textColor, fontWeight: fontWeight) 
                                ?? AppTheme.textTheme.bodyMedium?.copyWith(
                                color: textColor,
                                fontWeight: fontWeight,
                              ),
                            ),
                          ),
                        ),
                        if (widget.mode == UnifiedCalendarMode.eventView || isToday) ...[
                          const SizedBox(height: 4),
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: isToday && !isSelected ? const Color(0xFFFF3B30) : (hasEvent && !event!.isHighlight && !event.isOutline ? event.color : Colors.transparent),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ]
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

  Widget _buildNavButton(IconData icon, VoidCallback onTap) {
    if (widget.transparentBackground) {
      return IconButton(
        icon: Icon(icon, color: Colors.white, size: 20),
        onPressed: onTap,
      );
    }
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.black87, size: 18),
      ),
    );
  }
}
