import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';

class EmptyBookingsWidget extends StatelessWidget {
  const EmptyBookingsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                CupertinoIcons.calendar_badge_minus,
                color: AppTheme.textSecondary.withValues(alpha: 0.5),
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noBookedTrips,
              // Using l10n.noBookedTrips as it's cleaner, checking l10n first or hardcoding per request.
              // Given the request specifically asked for "message simple in the middle... no trips for example"
              // I will use a simple localized string if available or fallback.
              // l10n.noBookedTrips seems appropriate.
              style: AppTheme.textTheme.bodyLarge?.copyWith(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
