import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class TimeSelectionCard extends StatelessWidget {
  final String title;
  final String? selectedTime;
  final IconData icon;
  final VoidCallback? onTap;
  final bool isLadies;

  const TimeSelectionCard({
    super.key,
    required this.title,
    required this.selectedTime,
    required this.icon,
    this.onTap,
    this.isLadies = false,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedTime != null;

    final Color iconColor = isLadies
        ? Colors.white
        : (isSelected ? AppTheme.primaryColor : Colors.white.withValues(alpha: 0.3));
    final Color iconBg = isLadies
        ? Colors.white.withValues(alpha: 0.15)
        : (isSelected
            ? AppTheme.primaryColor.withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.06));
    final Color subtitleColor = isLadies
        ? Colors.white.withValues(alpha: 0.7)
        : Colors.white.withValues(alpha: 0.4);
    final Color timeColor = isLadies
        ? Colors.white
        : (isSelected ? Colors.white : Colors.white.withValues(alpha: 0.3));
    final Color chevronColor = isLadies
        ? Colors.white.withValues(alpha: 0.5)
        : Colors.white.withValues(alpha: 0.2);
    final Color borderColor = isLadies
        ? Colors.white.withValues(alpha: 0.25)
        : AppTheme.primaryColor.withValues(alpha: 0.4);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: isLadies ? 0.1 : 0.04),
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? Border.all(color: borderColor, width: 1)
              : null,
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
                icon,
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
                    title,
                    style: AppTheme.textTheme.bodySmall?.copyWith(
                      color: subtitleColor,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    selectedTime ?? 'اختار الميعاد',
                    style: AppTheme.textTheme.titleMedium?.copyWith(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: timeColor,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                CupertinoIcons.chevron_left,
                color: chevronColor,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }
}
