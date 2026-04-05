import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:fielsekkia_driver/core/utils/digit_converter.dart';
import 'premium_calendar_sheet.dart';

class BookingDateCard extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final bool isLadies;

  const BookingDateCard({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    this.isLadies = false,
  });

  void _showDatePicker(BuildContext context) async {
    final now = DateTime.now();
    // If it's after 7 AM, today is not allowed
    final firstAllowedDate = now.hour >= 7
        ? DateTime(now.year, now.month, now.day + 1)
        : DateTime(now.year, now.month, now.day);

    final initialDate = selectedDate.isBefore(firstAllowedDate)
        ? firstAllowedDate
        : selectedDate;

    final pickedDate = await PremiumCalendarSheet.show(
      context: context,
      initialDate: initialDate,
      firstDate: firstAllowedDate,
      lastDate: DateTime(now.year + 1),
    );

    if (pickedDate != null) {
      onDateSelected(pickedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color iconColor = isLadies ? Colors.white : AppTheme.primaryColor;
    final Color iconBg = isLadies
        ? Colors.white.withValues(alpha: 0.15)
        : AppTheme.primaryColor.withValues(alpha: 0.15);
    final Color subtitleColor = isLadies
        ? Colors.white.withValues(alpha: 0.7)
        : Colors.white.withValues(alpha: 0.4);
    final Color yearBg = isLadies
        ? Colors.white.withValues(alpha: 0.15)
        : Colors.white.withValues(alpha: 0.06);
    final Color yearText = isLadies
        ? Colors.white.withValues(alpha: 0.8)
        : Colors.white.withValues(alpha: 0.5);

    return GestureDetector(
      onTap: () => _showDatePicker(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: isLadies ? 0.1 : 0.04),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                CupertinoIcons.calendar,
                color: iconColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'تاريخ الرحلة',
                    style: AppTheme.textTheme.bodySmall?.copyWith(
                      color: subtitleColor,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    DateFormat('EEEE، d MMMM', 'ar_EG').format(selectedDate).w,
                    style: AppTheme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: yearBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                DateFormat('yyyy', 'ar_EG').format(selectedDate).w,
                style: AppTheme.textTheme.bodySmall?.copyWith(
                  color: yearText,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
