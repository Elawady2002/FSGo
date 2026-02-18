import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_input.dart';
import '../../../../core/widgets/custom_toast.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final error = await ref
        .read(authProvider.notifier)
        .resetPassword(_emailController.text.trim());

    if (mounted) {
      if (error == null) {
        setState(() {
          _isLoading = false;
          _emailSent = true;
        });
      } else {
        setState(() => _isLoading = false);
        CustomToast.show(context, error, isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.pop(context),
          child: const Icon(
            CupertinoIcons.chevron_back,
            color: Colors.black,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: _emailSent ? _buildSuccessView() : _buildFormView(),
        ),
      ),
    );
  }

  Widget _buildFormView() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          // Icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              CupertinoIcons.lock_rotation,
              color: AppTheme.primaryColor,
              size: 32,
            ),
          ).animate().fadeIn().scale(),

          const SizedBox(height: 24),

          Text(
            "نسيت كلمة السر؟",
            style: AppTheme.textTheme.displayLarge?.copyWith(
              color: Colors.black,
              decoration: TextDecoration.none,
            ),
          ).animate().fadeIn(delay: 100.ms).slideX(),

          const SizedBox(height: 8),

          Text(
            "ادخل بريدك الإلكتروني وهنبعتلك رابط لإعادة تعيين كلمة السر.",
            style: AppTheme.textTheme.bodyLarge?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ).animate().fadeIn(delay: 200.ms).slideX(),

          const SizedBox(height: 40),

          CustomInput(
            controller: _emailController,
            hintText: "البريد الإلكتروني",
            keyboardType: TextInputType.emailAddress,
            prefixIcon: CupertinoIcons.mail,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'الرجاء إدخال البريد الإلكتروني';
              }
              if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$')
                  .hasMatch(value)) {
                return 'البريد الإلكتروني غير صحيح';
              }
              return null;
            },
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),

          const SizedBox(height: 32),

          _isLoading
              ? const Center(child: CupertinoActivityIndicator())
              : CustomButton(
                  text: "إرسال رابط إعادة التعيين",
                  onPressed: _handleResetPassword,
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 60),

        // Success icon
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            CupertinoIcons.checkmark_circle_fill,
            color: AppTheme.primaryColor,
            size: 56,
          ),
        ).animate().fadeIn().scale(begin: const Offset(0.5, 0.5)),

        const SizedBox(height: 32),

        Text(
          "تم الإرسال! 🎉",
          style: AppTheme.textTheme.displayLarge?.copyWith(
            color: Colors.black,
            decoration: TextDecoration.none,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 200.ms),

        const SizedBox(height: 12),

        Text(
          "اتحقق من بريدك الإلكتروني\n${_emailController.text.trim()}\nوافتح الرابط اللي بعتناهولك.",
          style: AppTheme.textTheme.bodyLarge?.copyWith(
            color: AppTheme.textSecondary,
            height: 1.6,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 300.ms),

        const SizedBox(height: 48),

        CustomButton(
          text: "رجوع لتسجيل الدخول",
          onPressed: () => Navigator.pop(context),
        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),

        const SizedBox(height: 16),

        // Resend option
        TextButton(
          onPressed: () {
            setState(() {
              _emailSent = false;
            });
          },
          child: Text(
            "إعادة إرسال الرابط",
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
              decoration: TextDecoration.none,
            ),
          ),
        ).animate().fadeIn(delay: 500.ms),
      ],
    );
  }
}
