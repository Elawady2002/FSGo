import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class TimeGridSelector extends StatelessWidget {
  final List<String> times;
  final String? selectedTime;
  final ValueChanged<String?> onSelect;

  const TimeGridSelector({
    super.key,
    required this.times,
    required this.selectedTime,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: times.map((time) {
        final isSelected = selectedTime == time;
        return ChoiceChip(
          label: Text(time),
          selected: isSelected,
          onSelected: (selected) {
            onSelect(selected ? time : null);
          },
          selectedColor: AppTheme.primaryColor,
          labelStyle: TextStyle(
            color: isSelected ? Colors.black : AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.none,
          ),
          backgroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        );
      }).toList(),
    );
  }
}
