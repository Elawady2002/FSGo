import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/custom_button.dart';
import '../../../domain/entities/subscription_entity.dart';

class PlanDetailsView extends StatelessWidget {
  final String title;
  final String price;
  final String period;
  final List<String> features;
  final bool isPopular;
  final Color accentColor;
  final VoidCallback onCalendarTap;
  final VoidCallback onSubscribeTap;

  const PlanDetailsView({
    super.key,
    required this.title,
    required this.price,
    required this.period,
    required this.features,
    required this.isPopular,
    required this.accentColor,
    required this.onCalendarTap,
    required this.onSubscribeTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('details'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Card Header
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: AppTheme.textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      fontSize: 32,
                      letterSpacing: -1,
                      color: Colors.white,
                    ),
                  ),
                  if (isPopular)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor, // Lime green
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Text(
                        'الأكثر توفيراً',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    price,
                    style: AppTheme.textTheme.displayLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      fontSize: 64,
                      height: 0.9,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ج.م',
                          style: AppTheme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          period,
                          style: AppTheme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Calendar Icon Button
                  GestureDetector(
                    onTap: onCalendarTap,
                    child: Icon(
                      CupertinoIcons.calendar,
                      color: AppTheme.primaryColor,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const Divider(height: 1, color: Colors.white24),

        // Features List
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(24),
            // physics: const NeverScrollableScrollPhysics(), // Removed to allow scrolling
            itemCount: features.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    CupertinoIcons.checkmark_alt,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      features[index],
                      style: AppTheme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),

        // Action Button
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: CustomButton(
            text: 'اشترك الآن',
            onPressed: onSubscribeTap,
            backgroundColor: AppTheme.primaryColor,
            textColor: Colors.black,
          ),
        ),
      ],
    );
  }
}
