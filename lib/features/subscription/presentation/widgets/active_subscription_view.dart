import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../domain/entities/subscription_entity.dart';
import '../providers/subscription_provider.dart';

class ActiveSubscriptionView extends ConsumerStatefulWidget {
  final SubscriptionEntity subscription;

  const ActiveSubscriptionView({super.key, required this.subscription});

  @override
  ConsumerState<ActiveSubscriptionView> createState() =>
      _ActiveSubscriptionViewState();
}

class _ActiveSubscriptionViewState
    extends ConsumerState<ActiveSubscriptionView> {
  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d MMM yyyy', 'ar');
    final planName =
        widget.subscription.planType == SubscriptionPlanType.monthly
        ? 'باقة الشهر'
        : 'باقة الترم';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Plan Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    CupertinoIcons.ticket_fill,
                    size: 40,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 20),

                // Plan Name
                Text(
                  planName,
                  style: AppTheme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color:
                        widget.subscription.status == SubscriptionStatus.active
                        ? const Color(0xFFFEF08A)
                        : Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.subscription.status == SubscriptionStatus.active
                        ? 'نشط'
                        : 'قيد المراجعة',
                    style: AppTheme.textTheme.bodyMedium?.copyWith(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Details Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildDetailRow(
                  'تاريخ البدء',
                  dateFormat.format(widget.subscription.startDate),
                ),
                const SizedBox(height: 16),
                Divider(color: Colors.grey.withValues(alpha: 0.2)),
                const SizedBox(height: 16),
                _buildDetailRow(
                  'تاريخ الانتهاء',
                  dateFormat.format(widget.subscription.endDate),
                ),
                const SizedBox(height: 16),
                Divider(color: Colors.grey.withValues(alpha: 0.2)),
                const SizedBox(height: 16),
                _buildDetailRow(
                  'السعر',
                  '${widget.subscription.amount.toStringAsFixed(0)} ج.م',
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Cancel Button
          CustomButton(
            text: 'إلغاء الاشتراك',
            onPressed: () => _showCancelDialog(widget.subscription.id!),
            backgroundColor: Colors.red.withValues(alpha: 0.1),
            textColor: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTheme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
        Text(
          value,
          style: AppTheme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _showCancelDialog(String subscriptionId) {
    showCupertinoDialog(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('إلغاء الاشتراك'),
        content: const Text(
          'هل أنت متأكد من رغبتك في إلغاء الاشتراك؟ سيتم إيقاف الخدمة فوراً.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('تراجع'),
            onPressed: () => Navigator.pop(dialogContext),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('تأكيد الإلغاء'),
            onPressed: () async {
              Navigator.pop(dialogContext); // Close dialog

              // Show loading
              if (!mounted) return;
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (loadingContext) =>
                    const Center(child: CupertinoActivityIndicator()),
              );

              try {
                final result = await ref
                    .read(subscriptionRepositoryProvider)
                    .cancelSubscription(subscriptionId);

                if (!mounted) return;
                if (context.mounted) Navigator.pop(context); // Close loading

                result.fold(
                  (failure) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(failure.message),
                        backgroundColor: Colors.red,
                      ),
                    );
                  },
                  (_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم إلغاء الاشتراك بنجاح'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    // Refresh subscription state
                    ref.invalidate(userSubscriptionsProvider);
                    ref.invalidate(activeSubscriptionProvider);
                  },
                );
              } catch (e) {
                if (!mounted) return;
                if (context.mounted) Navigator.pop(context); // Close loading

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('حدث خطأ: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
