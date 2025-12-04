import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../payment/presentation/pages/payment_page.dart';
import 'calendar_plan_card.dart';
import '../../domain/entities/subscription_entity.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/subscription_provider.dart';

class SubscriptionPlansSheet extends ConsumerStatefulWidget {
  const SubscriptionPlansSheet({super.key});

  @override
  ConsumerState<SubscriptionPlansSheet> createState() =>
      _SubscriptionPlansSheetState();
}

class _SubscriptionPlansSheetState
    extends ConsumerState<SubscriptionPlansSheet> {
  final PageController _pageController = PageController(viewportFraction: 0.9);
  // _currentPage removed as it was unused
  bool _isInstallmentEnabled = false; // Moved by instruction
  bool _isProcessing = false; // Added by instruction

  final List<Map<String, dynamic>> _plans = [
    {
      'title': 'باقة الشهر',
      'price': '600',
      'period': 'شهرياً',
      'features': [
        'رحلات يومية للجامعة',
        'توفير 10% من المصاريف',
        'أولوية في حجز المقاعد',
        'إمكانية تغيير المواعيد',
        'دعم فني مخصص',
      ],
      'isPopular': false,
      'color': Colors.white,
      'accentColor': Colors.blue,
    },
    {
      'title': 'باقة الترم',
      'price': '2000',
      'period': 'للترم',
      'features': [
        'رحلات غير محدودة طوال الترم',
        'توفير 25% من المصاريف',
        'مقعد مميز محجوز باسمك',
        'مرونة كاملة في المواعيد',
        'إلغاء مجاني في أي وقت',
        'هدايا ومفاجآت حصرية',
      ],
      'isPopular': true,
      'color': Colors
          .white, // Will be overridden by logic for popular card if needed
      'accentColor': AppTheme.primaryColor,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle Bar
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Column(
              children: [
                Text(
                  'باقات الطلاب',
                  style: AppTheme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'اختار الباقة المناسبة ليك ووفر فلوسك',
                  textAlign: TextAlign.center,
                  style: AppTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Plans PageView
          SizedBox(
            height: 540, // Increased height for the cards
            child: PageView.builder(
              controller: _pageController,
              itemCount: _plans.length,
              itemBuilder: (context, index) {
                final plan = _plans[index];
                final isSemester = plan['title'] == 'باقة الترم';

                // Calculate price based on installment
                String displayPrice = plan['price'];
                String displayPeriod = plan['period'];

                if (isSemester && _isInstallmentEnabled) {
                  // Semester plan with installment: 2000 + 5% = 2100 / 3 = 700
                  displayPrice = '700';
                  displayPeriod = 'القسط الأول';
                }

                // Determine plan type
                SubscriptionPlanType planType = plan['title'] == 'باقة الشهر'
                    ? SubscriptionPlanType.monthly
                    : SubscriptionPlanType.semester;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: CalendarPlanCard(
                    title: plan['title'],
                    price: displayPrice,
                    period: displayPeriod,
                    features: plan['features'],
                    isPopular: plan['isPopular'],
                    accentColor: plan['accentColor'],
                    planType: planType,
                    onSubscribe: (params) async {
                      // Prevent double clicks
                      if (_isProcessing) return;

                      setState(() {
                        _isProcessing = true;
                      });

                      try {
                        // Check for active subscription using activeSubscriptionProvider
                        final activeSubscription = await ref.read(
                          activeSubscriptionProvider.future,
                        );

                        if (activeSubscription != null) {
                          setState(() {
                            _isProcessing = false;
                          });

                          if (!context.mounted) return;
                          showCupertinoDialog(
                            context: context,
                            builder: (context) => CupertinoAlertDialog(
                              title: const Text('تنبيه'),
                              content: const Text(
                                'لديك اشتراك نشط بالفعل. يجب إلغاء الاشتراك الحالي أو انتظار انتهائه قبل الاشتراك في باقة جديدة.',
                              ),
                              actions: [
                                CupertinoDialogAction(
                                  child: const Text('حسناً'),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ],
                            ),
                          );
                          return;
                        }

                        // No active subscription, proceed to payment
                        if (!context.mounted) return;
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (_) => PaymentPage(
                              planName: plan['title'],
                              amount: displayPrice,
                              isSubscription: true,
                              scheduleParams: params,
                            ),
                          ),
                        ).then((_) {
                          // Reset processing state when returning
                          if (mounted) {
                            setState(() {
                              _isProcessing = false;
                            });
                          }
                        });
                      } catch (e) {
                        print('Error checking subscription: $e');
                        setState(() {
                          _isProcessing = false;
                        });

                        if (!context.mounted) return;
                        showCupertinoDialog(
                          context: context,
                          builder: (context) => CupertinoAlertDialog(
                            title: const Text('خطأ'),
                            content: const Text(
                              'حدث خطأ أثناء التحقق من الاشتراك. يرجى المحاولة مرة أخرى.',
                            ),
                            actions: [
                              CupertinoDialogAction(
                                child: const Text('حسناً'),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
