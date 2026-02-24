import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import 'top_up_proof_page.dart';

class TopUpAmountPage extends ConsumerStatefulWidget {
  const TopUpAmountPage({super.key});

  @override
  ConsumerState<TopUpAmountPage> createState() => _TopUpAmountPageState();
}

class _TopUpAmountPageState extends ConsumerState<TopUpAmountPage>
    with TickerProviderStateMixin {
  final TextEditingController _amountController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _selectedMethod = 'Vodafone Cash';

  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _chipBounceController;
  late Animation<double> _pulseAnimation;

  String _displayAmount = '0';

  @override
  void initState() {
    super.initState();

    // Subtle breathing pulse for the amount display
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);

    // Bounce for chip selection
    _chipBounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _amountController.addListener(_onAmountChanged);
  }

  void _onAmountChanged() {
    setState(() {
      _displayAmount = _amountController.text.isEmpty
          ? '0'
          : _amountController.text;
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _chipBounceController.dispose();
    _amountController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // Dynamically compute font size based on text length
  double _getFontSize() {
    final len = _displayAmount.length;
    if (len <= 2) return 72;
    if (len == 3) return 64;
    if (len == 4) return 56;
    if (len == 5) return 48;
    return 40;
  }

  void _selectQuickAmount(int amount) {
    HapticFeedback.lightImpact();

    // Trigger a small bounce
    _chipBounceController.forward(from: 0.0);

    setState(() {
      _amountController.text = amount.toString();
      _amountController.selection = TextSelection.fromPosition(
        TextPosition(offset: _amountController.text.length),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool hasAmount =
        _amountController.text.isNotEmpty && _amountController.text != '0';

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(CupertinoIcons.chevron_right, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'شحن الرصيد',
            style: AppTheme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 12),

              // ─── Amount Display Area ───
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Text(
                      'المبلغ المراد شحنه',
                      style: AppTheme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Main amount display — tap to toggle keyboard
                    GestureDetector(
                      onTap: () {
                        if (_focusNode.hasFocus) {
                          _focusNode.unfocus();
                        } else {
                          _focusNode.requestFocus();
                        }
                      },
                      child: AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: child,
                          );
                        },
                        child: SizedBox(
                          height: 100,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Currency label
                              AnimatedOpacity(
                                opacity: hasAmount ? 1.0 : 0.4,
                                duration: const Duration(milliseconds: 300),
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    'ج.م',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: hasAmount
                                          ? AppTheme.primaryDark
                                          : Colors.grey.shade400,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // The animated number
                              AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOutCubic,
                                style: TextStyle(
                                  fontSize: _getFontSize(),
                                  fontWeight: FontWeight.w800,
                                  color: hasAmount
                                      ? Colors.black
                                      : Colors.grey.shade300,
                                  letterSpacing: -2,
                                  height: 1.0,
                                ),
                                child: Text(_displayAmount),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Hidden TextField to capture keyboard input
                    SizedBox(
                      height: 0,
                      child: Opacity(
                        opacity: 0,
                        child: TextField(
                          controller: _amountController,
                          focusNode: _focusNode,
                          keyboardType: TextInputType.number,
                          autofocus: true,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(6),
                          ],
                        ),
                      ),
                    ),

                    // Subtle animated line under the amount
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutCubic,
                      height: 3,
                      width: hasAmount ? 80 : 40,
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: hasAmount
                            ? AppTheme.primaryColor
                            : Colors.grey.shade200,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ─── Quick Selection Chips ───
                    _buildQuickChips(),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              // ─── Payment Methods ───
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'طريقة الدفع',
                        style: AppTheme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildPaymentMethodOption(
                        'Vodafone Cash',
                        'lib/assets/image/launcher_icons/vodafone_cash.png',
                        isSelected: _selectedMethod == 'Vodafone Cash',
                      ),
                      const SizedBox(height: 12),
                      _buildPaymentMethodOption(
                        'InstaPay',
                        'lib/assets/image/launcher_icons/instapay.png',
                        isSelected: _selectedMethod == 'InstaPay',
                      ),
                    ],
                  ),
                ),
              ),

              // ─── Continue Button ───
              _buildContinueButton(hasAmount),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickChips() {
    final amounts = [50, 100, 200, 500];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: amounts.map((amount) {
        final isSelected = _amountController.text == amount.toString();
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: GestureDetector(
            onTap: () => _selectQuickAmount(amount),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryColor.withValues(alpha: 0.15)
                    : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : Colors.grey.shade200,
                  width: 1.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              child: Text(
                '$amount',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? AppTheme.primaryDark
                      : Colors.grey.shade600,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildContinueButton(bool hasAmount) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).padding.bottom > 0
            ? MediaQuery.of(context).padding.bottom + 8
            : 24,
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: hasAmount ? AppTheme.primaryColor : Colors.grey.shade200,
            boxShadow: hasAmount
                ? [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: hasAmount
                  ? () {
                      HapticFeedback.mediumImpact();
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (_) => TopUpProofPage(
                            amount: _amountController.text,
                            method: _selectedMethod,
                          ),
                        ),
                      );
                    }
                  : null,
              child: Center(
                child: Text(
                  'متابعة',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: hasAmount ? Colors.black : Colors.grey.shade400,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodOption(
    String title,
    String imagePath, {
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedMethod = title);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withValues(alpha: 0.06)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor.withValues(alpha: 0.4)
                : Colors.grey.shade100,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            // Logo
            Container(
              width: 44,
              height: 44,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Image.asset(
                imagePath,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.account_balance_wallet,
                    color: Colors.grey,
                  );
                },
              ),
            ),

            const SizedBox(width: 14),

            // Name
            Text(
              title == 'Vodafone Cash' ? 'فودافون كاش' : 'انستا باي',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: isSelected ? Colors.black : Colors.grey.shade700,
              ),
            ),

            const Spacer(),

            // Radio-style indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : Colors.grey.shade300,
                  width: 2,
                ),
              ),
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isSelected ? 12 : 0,
                  height: isSelected ? 12 : 0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? AppTheme.primaryColor
                        : Colors.transparent,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
