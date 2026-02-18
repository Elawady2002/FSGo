import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/trip_type.dart';

class TripTypeSelector extends StatelessWidget {
  final TripType selectedType;
  final ValueChanged<TripType> onSelect;

  const TripTypeSelector({
    super.key,
    required this.selectedType,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: TripType.values
            .where((t) => t != TripType.roundTrip)
            .map((type) {
          final isSelected = type == selectedType;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelect(type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
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
                child: Column(
                  children: [
                    Text(
                      _getTripTypeLabel(context, type),
                      textAlign: TextAlign.center,
                      style: AppTheme.textTheme.bodyMedium?.copyWith(
                        color: isSelected
                            ? Colors.black
                            : AppTheme.textSecondary,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${type.price.toStringAsFixed(0)} ${AppLocalizations.of(context)!.egp}',
                      style: AppTheme.textTheme.bodySmall?.copyWith(
                        color: isSelected
                            ? AppTheme.primaryDark
                            : AppTheme.textTertiary,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _getTripTypeLabel(BuildContext context, TripType type) {
    final l10n = AppLocalizations.of(context)!;
    switch (type) {
      case TripType.departureOnly:
        return l10n.departureOnly;
      case TripType.returnOnly:
        return l10n.returnOnly;
      case TripType.roundTrip:
        return l10n.roundTrip;
    }
  }
}
