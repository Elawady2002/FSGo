import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/domain/entities/city_entity.dart';
import '../../../../core/domain/entities/user_entity.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_input.dart';
import '../../../../core/widgets/custom_toast.dart';
import '../../../../core/widgets/searchable_city_picker.dart';
import '../providers/auth_provider.dart';
import '../../../home/presentation/pages/home_page.dart';
import 'login_page.dart';

class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _entityNameController = TextEditingController();
  CityEntity? _selectedCity;

  UserType _selectedRole = UserType.driver;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _entityNameController.dispose();
    super.dispose();
  }

  String get _entityNameHint {
    if (_selectedRole == UserType.coordinator) return 'اسم المكتب أو المحطة';
    return '';
  }

  bool get _showEntityName => _selectedRole == UserType.coordinator;

  Future<void> _handleSignup() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedRole == UserType.coordinator && _selectedCity == null) {
        _showError('الرجاء اختيار المدينة');
        return;
      }

      setState(() => _isLoading = true);

      try {
        final error = await ref.read(authProvider.notifier).signup(
              _nameController.text.trim(),
              _emailController.text.trim(),
              _passwordController.text.trim(),
              _phoneController.text.trim(),
              userType: _selectedRole.toJson(),
              city: _selectedCity?.nameAr,
              cityId: _selectedCity?.id,
              officeName: _selectedRole == UserType.coordinator
                  ? _entityNameController.text.trim()
                  : null,
              stationName: _selectedRole == UserType.coordinator
                  ? _entityNameController.text.trim()
                  : null,
            );

        if (!mounted) return;

        if (error == null) {
          Navigator.pushAndRemoveUntil(
            context,
            CupertinoPageRoute(builder: (_) => const HomePage()),
            (route) => false,
          );
        } else {
          // Parse complex JSON error messages if they happen
          String displayError = error;
          if (error.contains('"message":')) {
            try {
              // Extract message more gracefully
              final start = error.indexOf('"message":"') + 11;
              final end = error.indexOf('"', start);
              displayError = error.substring(start, end);
            } catch (_) {}
          }
          _showError(displayError);
        }
      } catch (e) {
        if (mounted) {
          _showError('حدث خطأ غير متوقع: $e');
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "حساب جديد",
                style: AppTheme.textTheme.displayLarge?.copyWith(
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "انضم لينا وابدأ رحلتك.",
                style: AppTheme.textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // Role Selector
              _RoleSelector(
                selected: _selectedRole,
                onChanged: (role) => setState(() {
                  _selectedRole = role;
                  _entityNameController.clear();
                }),
              ),
              const SizedBox(height: 24),

              Form(
                key: _formKey,
                child: Column(
                  children: [
                    CustomInput(
                      controller: _nameController,
                      hintText: "الاسم بالكامل",
                      prefixIcon: CupertinoIcons.person,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'الرجاء إدخال الاسم';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    CustomInput(
                      controller: _emailController,
                      hintText: "البريد الإلكتروني",
                      prefixIcon: CupertinoIcons.mail,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'الرجاء إدخال البريد الإلكتروني';
                        }
                        if (!value.contains('@')) {
                          return 'البريد الإلكتروني غير صحيح';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    CustomInput(
                      controller: _phoneController,
                      hintText: "رقم الموبايل",
                      prefixIcon: CupertinoIcons.phone,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'الرجاء إدخال رقم الموبايل';
                        }
                        if (value.length < 11) {
                          return 'رقم الموبايل غير صحيح';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    CustomInput(
                      controller: _passwordController,
                      hintText: "كلمة السر",
                      prefixIcon: CupertinoIcons.lock,
                      isPassword: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'الرجاء إدخال كلمة السر';
                        }
                        if (value.length < 6) {
                          return 'كلمة السر يجب أن تكون 6 أحرف على الأقل';
                        }
                        return null;
                      },
                    ),
                    if (_showEntityName) ...[
                      const SizedBox(height: 16),
                      CustomInput(
                        controller: _entityNameController,
                        hintText: _entityNameHint,
                        prefixWidget: GestureDetector(
                          onTap: () => SearchableCityPicker.show(
                            context,
                            initialCityId: _selectedCity?.id,
                            onCitySelected: (city) =>
                                setState(() => _selectedCity = city),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border(
                                left: BorderSide(
                                  color: Colors.grey.shade200,
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _selectedCity == null
                                      ? CupertinoIcons.location_solid
                                      : CupertinoIcons.location_fill,
                                  color: _selectedCity == null
                                      ? CupertinoColors.systemGrey
                                      : AppTheme.primaryColor,
                                  size: 18,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _selectedCity?.nameAr ?? 'المدينة',
                                  style: GoogleFonts.cairo(
                                    fontSize: 14,
                                    color: _selectedCity == null
                                        ? CupertinoColors.systemGrey
                                        : AppTheme.primaryColor,
                                    fontWeight: _selectedCity == null
                                        ? FontWeight.normal
                                        : FontWeight.bold,
                                  ),
                                ),
                                const Icon(
                                  CupertinoIcons.chevron_down,
                                  size: 14,
                                  color: CupertinoColors.systemGrey,
                                ),
                                const SizedBox(width: 8),
                              ],
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'الرجاء إدخال $_entityNameHint';
                          }
                          return null;
                        },
                      ).animate().fadeIn(duration: 200.ms).slideY(begin: -0.1),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),
              _isLoading
                  ? const Center(child: CupertinoActivityIndicator())
                  : CustomButton(text: "إنشاء حساب", onPressed: _handleSignup),
              const SizedBox(height: 24),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    "عندك حساب بالفعل؟ ",
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                      decoration: TextDecoration.none,
                      decorationColor: Colors.transparent,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(builder: (_) => const LoginPage()),
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'سجل دخول',
                      style: AppTheme.textTheme.bodyLarge?.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleSelector extends StatelessWidget {
  final UserType selected;
  final ValueChanged<UserType> onChanged;

  const _RoleSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const roles = [
      (label: 'سائق', role: UserType.driver, icon: CupertinoIcons.car_fill),
      (
        label: 'منظم الرحلات',
        role: UserType.coordinator,
        icon: CupertinoIcons.briefcase_fill
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'نوع الحساب',
          style: AppTheme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: roles.map((entry) {
            final isSelected = selected == entry.role;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: GestureDetector(
                  onTap: () => onChanged(entry.role),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryColor : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          entry.icon,
                          color: isSelected ? AppTheme.accentColor : Colors.grey,
                          size: 24,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          entry.label,
                          style: TextStyle(
                            color: isSelected ? AppTheme.accentColor : Colors.grey,
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
