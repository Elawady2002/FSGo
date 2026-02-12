import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/insufficient_balance_dialog.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../payment/presentation/pages/payment_page.dart';
import '../../../profile/presentation/providers/wallet_provider.dart';
import '../../../profile/presentation/widgets/digital_ticket.dart';
import '../../domain/entities/subscription_entity.dart';
import '../providers/subscription_provider.dart';

class SubscriptionPlansPage extends ConsumerStatefulWidget {
  const SubscriptionPlansPage({super.key});

  @override
  ConsumerState<SubscriptionPlansPage> createState() =>
      _SubscriptionPlansPageState();
}

class _SubscriptionPlansPageState extends ConsumerState<SubscriptionPlansPage> {
  int _selectedPlanIndex = 1; // 0 = Monthly, 1 = Semester (default to popular)
  bool _isProcessing = false;

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
      'planType': SubscriptionPlanType.monthly,
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
      'planType': SubscriptionPlanType.semester,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final selectedPlan = _plans[_selectedPlanIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Header with close button
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 40), // Spacer for centering
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        CupertinoIcons.xmark,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 8),

                    // Icon
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        CupertinoIcons.star_fill,
                        color: AppTheme.primaryColor,
                        size: 32,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Title
                    Text(
                      selectedPlan['title'],
                      style: AppTheme.textTheme.displayMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 32,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 8),

                    // Subtitle
                    Text(
                      'وفر فلوسك واستمتع بمزايا حصرية',
                      style: AppTheme.textTheme.bodyLarge?.copyWith(
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 32),

                    // Tab Switcher
                    _buildTabSwitcher(),

                    const SizedBox(height: 32),

                    // Feature Comparison Table
                    _buildFeatureTable(),

                    const SizedBox(height: 100), // Space for button
                  ],
                ),
              ),
            ),

            // Upgrade Button (Fixed at bottom)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withValues(alpha: 0), Colors.black],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: _isProcessing ? null : _handleUpgrade,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'اشترك مقابل ${selectedPlan['price']} ج.م',
                        style: AppTheme.textTheme.titleMedium?.copyWith(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'يتجدد تلقائياً. يمكن الإلغاء في أي وقت.',
                    style: AppTheme.textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabSwitcher() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTab(
              title: 'باقة الشهر',
              isSelected: _selectedPlanIndex == 0,
              onTap: () => setState(() => _selectedPlanIndex = 0),
            ),
          ),
          Expanded(
            child: _buildTab(
              title: 'باقة الترم',
              isSelected: _selectedPlanIndex == 1,
              onTap: () => setState(() => _selectedPlanIndex = 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: AppTheme.textTheme.bodyMedium?.copyWith(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureTable() {
    final selectedPlan = _plans[_selectedPlanIndex];
    final features = selectedPlan['features'] as List<String>;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Header Row
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  'المميزات',
                  style: AppTheme.textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(
                width: 60,
                child: Text(
                  'مجاني',
                  style: AppTheme.textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(
                width: 60,
                child: Text(
                  selectedPlan['title'] == 'باقة الشهر' ? 'شهري' : 'ترم',
                  style: AppTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 16),

          // Feature Rows
          ...features.asMap().entries.map((entry) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: entry.key < features.length - 1 ? 16 : 0,
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      entry.value,
                      style: AppTheme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 60,
                    child: Text(
                      '–',
                      style: TextStyle(color: Colors.white30, fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(
                    width: 60,
                    child: Icon(
                      CupertinoIcons.checkmark_alt,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _handleUpgrade() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final activeSubscription = await ref.read(
        activeSubscriptionProvider.future,
      );

      if (activeSubscription != null) {
        setState(() => _isProcessing = false);

        if (!mounted) return;
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

      final selectedPlan = _plans[_selectedPlanIndex];
      final amount = double.parse(selectedPlan['price']);
      final walletState = ref.read(walletProvider);

      // Check wallet balance
      if (walletState.balance < amount) {
        setState(() => _isProcessing = false);

        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => InsufficientBalanceDialog(
            currentBalance: walletState.balance,
            requiredAmount: amount,
          ),
        );
        return;
      }

      // Deduct from wallet
      final success = await ref
          .read(walletProvider.notifier)
          .deductAmount(amount, 'اشتراك ${selectedPlan['title']}');

      if (!success) {
        setState(() => _isProcessing = false);

        if (!mounted) return;
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('خطأ'),
            content: const Text(
              'حدث خطأ أثناء خصم المبلغ. يرجى المحاولة مرة أخرى.',
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

      // Create subscription
      final subscriptionRepository = ref.read(subscriptionRepositoryProvider);
      final user = ref.read(authProvider).value;

      if (user == null) {
        setState(() => _isProcessing = false);
        return;
      }

      final result = await subscriptionRepository.createSubscription(
        userId: user.id,
        planType: selectedPlan['planType'],
        paymentProofUrl: null, // No proof needed for wallet payment
        transferNumber: null, // No transfer number for wallet payment
        isInstallment: false,
        scheduleParams: null,
      );

      setState(() => _isProcessing = false);

      result.fold(
        (failure) {
          if (!mounted) return;
          showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text('خطأ'),
              content: Text(failure.message),
              actions: [
                CupertinoDialogAction(
                  child: const Text('حسناً'),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          );
        },
        (_) {
          if (!mounted) return;

          // Refresh providers
          ref.invalidate(activeSubscriptionProvider);
          ref.invalidate(userSubscriptionsProvider);

          // Close subscription page
          Navigator.pop(context);

          // Show digital ticket
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => Dialog(
              backgroundColor: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DigitalTicket(
                    title: selectedPlan['title'],
                    date: DateTime.now(),
                    amount: amount,
                    status: 'مدفوع',
                    type: 'subscription',
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        CupertinoIcons.xmark,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      debugPrint('Error checking subscription: $e');
      setState(() => _isProcessing = false);

      if (!mounted) return;
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
  }
}
