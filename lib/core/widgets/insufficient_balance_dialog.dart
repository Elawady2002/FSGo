import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../features/profile/presentation/widgets/top_up_sheet.dart';
import '../../features/payment/presentation/pages/payment_page.dart';

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
    final shortage = requiredAmount - currentBalance;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Warning Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.exclamationmark_triangle_fill,
                color: Colors.orange,
                size: 48,
              ),
            ),

            const SizedBox(height: 20),

            // Title
            Text(
              'رصيد غير كافي',
              style: AppTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            // Balance Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildBalanceRow(
                    'الرصيد الحالي',
                    currentBalance,
                    Colors.black,
                  ),
                  const SizedBox(height: 12),
                  _buildBalanceRow(
                    'المبلغ المطلوب',
                    requiredAmount,
                    Colors.red,
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),
                  _buildBalanceRow(
                    'تحتاج',
                    shortage,
                    AppTheme.primaryColor,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'إلغاء',
                        textAlign: TextAlign.center,
                        style: AppTheme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: CustomButton(
                    text: 'شحن الرصيد',
                    onPressed: () async {
                      Navigator.pop(context); // Close this dialog first
                      
                      final result = await showModalBottomSheet<Map<String, String>>(
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
                              planName: 'شحن الرصيد',
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
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceRow(String label, double amount, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTheme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              amount.toStringAsFixed(2),
              style: AppTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'ج.م',
              style: AppTheme.textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
