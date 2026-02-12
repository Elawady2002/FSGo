import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/custom_button.dart';
import '../../../domain/entities/subscription_entity.dart';

class PlanTimeSelectionView extends StatefulWidget {
  final DateTime selectedDate;
  final Color accentColor;
  final String? universityId;
  final ValueChanged<SubscriptionScheduleParams> onConfirm;
  final VoidCallback onBack;

  const PlanTimeSelectionView({
    super.key,
    required this.selectedDate,
    required this.accentColor,
    required this.universityId,
    required this.onConfirm,
    required this.onBack,
  });

  @override
  State<PlanTimeSelectionView> createState() => _PlanTimeSelectionViewState();
}

class _PlanTimeSelectionViewState extends State<PlanTimeSelectionView> {
  String? _selectedDepartureTime;
  String? _selectedReturnTime;
  String? _selectedTripType;

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

  bool _canConfirm() {
    if (_selectedTripType == null) return false;

    if (_selectedTripType == 'departure_only') {
      return _selectedDepartureTime != null;
    }

    if (_selectedTripType == 'return_only') {
      return _selectedReturnTime != null;
    }

    if (_selectedTripType == 'round_trip') {
      return _selectedDepartureTime != null && _selectedReturnTime != null;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('timeSelection'),
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              GestureDetector(
                onTap: widget.onBack,
                child: const Icon(
                  CupertinoIcons.chevron_right,
                  size: 24,
                  color: Colors.white,
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
                      DateFormat(
                        'EEEE، d MMMM',
                        'ar',
                      ).format(widget.selectedDate),
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

        const Divider(height: 1, color: Colors.white24),

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
                    color: Colors.white,
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
                      color: Colors.white,
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
                      color: Colors.white,
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
          child: CustomButton(
            text: 'تأكيد الحجز',
            onPressed: _canConfirm()
                ? () {
                    final params = SubscriptionScheduleParams(
                      startDate: widget.selectedDate,
                      tripType: _selectedTripType ?? 'round_trip',
                      departureTime: _selectedDepartureTime,
                      returnTime: _selectedReturnTime,
                      scheduleId: widget.universityId,
                      pickupStationId: null,
                      dropoffStationId: null,
                    );
                    widget.onConfirm(params);
                  }
                : null,
            backgroundColor: AppTheme.primaryColor,
            textColor: Colors.black,
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
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: types.map((type) {
          final isSelected = _selectedTripType == type['value'];
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  if (_selectedTripType == type['value']) {
                    _selectedTripType = null;
                  } else {
                    _selectedTripType = type['value'] as String;
                  }
                  if (_selectedTripType == 'return_only') {
                    _selectedDepartureTime = null;
                  } else if (_selectedTripType == 'departure_only') {
                    _selectedReturnTime = null;
                  } else if (_selectedTripType == null) {
                    _selectedDepartureTime = null;
                    _selectedReturnTime = null;
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : Colors.transparent,
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
                    color: isSelected ? Colors.black : Colors.white70,
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
                color: isSelected
                    ? AppTheme.primaryColor
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? Border.all(color: AppTheme.primaryColor, width: 2)
                    : Border.all(color: Colors.transparent, width: 2),
              ),
              child: Text(
                time,
                style: TextStyle(
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
