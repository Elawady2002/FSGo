import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/ios_components.dart';

class TopUpSheet extends StatefulWidget {
  const TopUpSheet({super.key});

  @override
  State<TopUpSheet> createState() => _TopUpSheetState();
}

class _TopUpSheetState extends State<TopUpSheet> {
  final _amountController = TextEditingController();
  String _selectedMethod = 'InstaPay';

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              Text(
                'شحن الرصيد',
                style: AppTheme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Amount Input
              Text(
                'المبلغ',
                style: AppTheme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                textAlign: TextAlign.center,
                style: AppTheme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  hintText: '0',
                  suffix: Text(
                    'ج.م',
                    style: AppTheme.textTheme.bodyLarge,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF5F5F7),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Payment Method Selection
              Text(
                'وسيلة الدفع',
                style: AppTheme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildMethodButton('InstaPay'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMethodButton('Vodafone Cash'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Confirm Button
              IOSButton(
                text: 'متابعة',
                onPressed: () {
                  final amount = _amountController.text.trim();
                  if (amount.isEmpty || double.tryParse(amount) == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('يرجى إدخال مبلغ صحيح'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  final amountValue = double.parse(amount);
                  if (amountValue <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('يرجى إدخال مبلغ أكبر من صفر'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  Navigator.pop(context, {
                    'amount': amount,
                    'method': _selectedMethod,
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMethodButton(String method) {
    final isSelected = _selectedMethod == method;
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = method),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : const Color(0xFFE5E5EA),
            width: 2,
          ),
        ),
        child: Text(
          method,
          style: AppTheme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.black : AppTheme.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
