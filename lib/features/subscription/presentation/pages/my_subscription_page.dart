import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/subscription_provider.dart';
import '../../domain/entities/subscription_entity.dart';
import '../../../home/presentation/pages/home_page.dart';

class MySubscriptionPage extends ConsumerStatefulWidget {
  const MySubscriptionPage({super.key});

  @override
  ConsumerState<MySubscriptionPage> createState() => _MySubscriptionPageState();
}

class _MySubscriptionPageState extends ConsumerState<MySubscriptionPage> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    final subscriptionState = ref.watch(userSubscriptionsProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: CupertinoNavigationBar(
        backgroundColor: AppTheme.backgroundColor,
        border: null,
        middle: Text(
          'اشتراكي',
          style: AppTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(CupertinoIcons.back, color: Colors.black),
        ),
      ),
      body: user == null
          ? const Center(child: Text('يرجى تسجيل الدخول'))
          : subscriptionState.when(
              data: (subscriptions) {
                print(
                  'DEBUG MySubscriptionPage: Found ${subscriptions.length} subscriptions',
                );
                for (var sub in subscriptions) {
                  print(
                    '  - ID: ${sub.id}, Status: ${sub.status}, Type: ${sub.planType}',
                  );
                }

                // Find active or pending subscription
                final activeSubscription = subscriptions.firstWhere(
                  (sub) =>
                      sub.status == SubscriptionStatus.active ||
                      sub.status == SubscriptionStatus.pending,
                  orElse: () => SubscriptionEntity(
                    id: '',
                    userId: '',
                    planType: SubscriptionPlanType.monthly,
                    amount: 0,
                    startDate: DateTime.now(),
                    endDate: DateTime.now(),
                    createdAt: DateTime.now(),
                    status: SubscriptionStatus.expired,
                    paymentProofUrl: '',
                  ),
                );

                if (activeSubscription.id == null ||
                    activeSubscription.id!.isEmpty) {
                  print(
                    'DEBUG MySubscriptionPage: No active/pending subscription found',
                  );
                  return _buildNoActiveSubscription();
                }

                print(
                  'DEBUG MySubscriptionPage: Showing subscription ${activeSubscription.id}',
                );
                return _buildActiveSubscription(activeSubscription);
              },
              loading: () => const Center(child: CupertinoActivityIndicator()),
              error: (error, stack) => Center(child: Text('حدث خطأ: $error')),
            ),
    );
  }

  Widget _buildNoActiveSubscription() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                CupertinoIcons.ticket,
                size: 48,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              'لا يوجد اشتراك نشط حالياً',
              textAlign: TextAlign.center,
              style: AppTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),

            // Subtitle
            Text(
              'اشترك في باقة الطلاب للاستفادة من المزايا',
              textAlign: TextAlign.center,
              style: AppTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 32),

            // Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close current page
                  showCupertinoModalPopup(
                    context: context,
                    builder: (context) => const LocationSelectionDrawer(
                      navigateToSubscription: true,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'اشترك الآن',
                  style: AppTheme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveSubscription(SubscriptionEntity subscription) {
    final dateFormat = DateFormat('d MMM yyyy', 'ar');
    final planName = subscription.planType == SubscriptionPlanType.monthly
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
                    color: subscription.status == SubscriptionStatus.active
                        ? const Color(0xFFFEF08A)
                        : Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    subscription.status == SubscriptionStatus.active
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
                  dateFormat.format(subscription.startDate),
                ),
                const SizedBox(height: 16),
                Divider(color: Colors.grey.withValues(alpha: 0.2)),
                const SizedBox(height: 16),
                _buildDetailRow(
                  'تاريخ الانتهاء',
                  dateFormat.format(subscription.endDate),
                ),
                const SizedBox(height: 16),
                Divider(color: Colors.grey.withValues(alpha: 0.2)),
                const SizedBox(height: 16),
                _buildDetailRow(
                  'السعر',
                  '${subscription.amount.toStringAsFixed(0)} ج.م',
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Cancel Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showCancelDialog(subscription.id!),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.red.withValues(alpha: 0.1),
                foregroundColor: Colors.red,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'إلغاء الاشتراك',
                style: AppTheme.textTheme.bodyLarge?.copyWith(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
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
      builder: (context) => CupertinoAlertDialog(
        title: const Text('إلغاء الاشتراك'),
        content: const Text(
          'هل أنت متأكد من رغبتك في إلغاء الاشتراك؟ سيتم إيقاف الخدمة فوراً.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('تراجع'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('تأكيد الإلغاء'),
            onPressed: () async {
              Navigator.pop(context); // Close dialog

              // Show loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) =>
                    const Center(child: CupertinoActivityIndicator()),
              );

              try {
                final result = await ref
                    .read(subscriptionRepositoryProvider)
                    .cancelSubscription(subscriptionId);

                if (!mounted) return;
                Navigator.pop(context); // Close loading

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
                Navigator.pop(context); // Close loading

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
