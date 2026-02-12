import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:my_app/core/theme/app_theme.dart';
import 'package:my_app/core/widgets/custom_button.dart';
import 'package:my_app/l10n/app_localizations.dart';
import 'package:my_app/features/profile/presentation/widgets/top_up_sheet.dart';
import 'package:my_app/features/payment/presentation/pages/payment_page.dart';

class InsufficientBalanceDialog extends StatelessWidget {
  final double currentBalance;
  final double requiredAmount;

  const InsufficientBalanceDialog({
    super.key,
    required this.currentBalance,
    required this.requiredAmount,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final shortage = requiredAmount - currentBalance;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Close Button
            Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.xmark,
                    color: Colors.black54,
                    size: 20,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Title
            Text(
              l10n.insufficientBalance,
              textAlign: TextAlign.center,
              style: AppTheme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 28,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              l10n.insufficientBalanceDesc,
              textAlign: TextAlign.center,
              style: AppTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 16),

            // Removed details container as requested
            const SizedBox(height: 24),

            // Button
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: l10n.topUp,
                onPressed: () async {
                  Navigator.pop(context); // Close this dialog first

                  final result =
                      await showModalBottomSheet<Map<String, String>>(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => const TopUpSheet(),
                      );

                  if (result != null && context.mounted) {
                    Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (_) => PaymentPage(
                          planName: l10n.topUp,
                          amount: result['amount']!,
                          isSubscription: false,
                          selectedMethod: result['method'],
                        ),
                      ),
                    );
                  }
                },
                backgroundColor: AppTheme.primaryColor,
                textColor: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
