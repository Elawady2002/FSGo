import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_input.dart';
import '../../../../core/widgets/custom_toast.dart';
import '../providers/auth_provider.dart';
import 'signup_page.dart';
import 'forgot_password_page.dart';
import '../../../home/presentation/pages/home_page.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final error = await ref
          .read(authProvider.notifier)
          .login(_emailController.text.trim(), _passwordController.text);

      if (mounted) {
        setState(() => _isLoading = false);

        if (error == null) {
          Navigator.pushReplacement(
            context,
            CupertinoPageRoute(builder: (_) => const HomePage()),
          );
        } else {
          _showError(error);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('حدث خطأ غير متوقع: $e');
      }
    }
  }

  void _showError(String message) {
    CustomToast.show(context, message, isError: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                Text(
                  "أهلاً بيك!",
                  style: AppTheme.textTheme.displayLarge?.copyWith(
                    color: Colors.black,
                    decoration: TextDecoration.none,
                  ),
                ).animate().fadeIn().slideX(),
                const SizedBox(height: 8),
                Text(
                  "سجل دخولك عشان تكمل رحلتك.",
                  style: AppTheme.textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ).animate().fadeIn(delay: 200.ms).slideX(),
                const SizedBox(height: 48),

                // Email field with validation
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
                const SizedBox(height: 16),

                // Password field with validation
                CustomInput(
                  controller: _passwordController,
                  hintText: "كلمة السر",
                  isPassword: true,
                  prefixIcon: CupertinoIcons.lock,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء إدخال كلمة السر';
                    }
                    if (value.length < 6) {
                      return 'كلمة السر يجب أن تكون 6 أحرف على الأقل';
                    }
                    return null;
                  },
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
                const SizedBox(height: 16),

                // Forgot password button
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (_) => const ForgotPasswordPage(),
                        ),
                      );
                    },
                    child: const Text(
                      "نسيت كلمة السر؟",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 500.ms),
                const SizedBox(height: 16),

                // Login button
                _isLoading
                    ? const Center(child: CupertinoActivityIndicator())
                    : CustomButton(text: "تسجيل الدخول", onPressed: _handleLogin)
                          .animate()
                          .fadeIn(delay: 600.ms)
                          .slideY(begin: 0.2, end: 0),
                const SizedBox(height: 24),

                // Signup link
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      "معندكش حساب؟ ",
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                        decoration: TextDecoration.none,
                        decorationColor: Colors.transparent,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (context) => const SignupPage(),
                          ),
                        );
                      },
                      child: const Text(
                        "سجل دلوقتي",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          decoration: TextDecoration.none,
                          decorationColor: Colors.transparent,
                        ),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 700.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
