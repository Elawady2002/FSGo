import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../payment/presentation/pages/payment_page.dart';
import 'calendar_plan_card.dart';
import '../../domain/entities/subscription_entity.dart';

class SubscriptionPlansSheet extends StatefulWidget {
  const SubscriptionPlansSheet({super.key});

  @override
  State<SubscriptionPlansSheet> createState() => _SubscriptionPlansSheetState();
}

class _SubscriptionPlansSheetState extends State<SubscriptionPlansSheet> {
  final PageController _pageController = PageController(viewportFraction: 0.9);

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

  // State to track if installment is enabled for semester plan
  bool _isInstallmentEnabled = false;

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
                    onSubscribe: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (_) => PaymentPage(
                            planName: plan['title'],
                            amount: displayPrice,
                            isSubscription: true,
                            isInstallment: isSemester && _isInstallmentEnabled,
                          ),
                        ),
                      );
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
