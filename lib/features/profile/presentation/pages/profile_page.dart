import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_app/core/theme/app_theme.dart';
import 'package:my_app/l10n/app_localizations.dart';
import 'package:my_app/core/providers/locale_provider.dart';
import 'personal_data_page.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/pages/login_page.dart';
import 'wallet_page.dart';
import 'ride_history_page.dart';
import 'help_center_page.dart';
import '../../../subscription/presentation/pages/my_subscription_page.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Using a soft off-white background for a cleaner, easier-on-the-eyes look
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.chevron_right, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppLocalizations.of(context)!.profile,
          style: AppTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          children: [
            // Profile Header
            const _ProfileHeader(),
            const SizedBox(height: 32),

            // Account & Settings
            _buildSectionTitle(
              ref,
              AppLocalizations.of(context)!.appName,
            ), // Or any other title
            _buildSection([
              _MenuItem(
                icon: CupertinoIcons.ticket,
                title: AppLocalizations.of(context)!.mySubscription,
                subtitle: ref.read(localeProvider).languageCode == 'ar'
                    ? 'إدارة اشتراكك الحالي'
                    : 'Manage your current subscription',
                onTap: () => Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (_) => const MySubscriptionPage(),
                  ),
                ),
              ),
              _MenuItem(
                icon: CupertinoIcons.person,
                title: AppLocalizations.of(context)!.personalData,
                subtitle: ref.read(localeProvider).languageCode == 'ar'
                    ? 'الاسم، رقم الهاتف، البريد الإلكتروني'
                    : 'Name, phone, email',
                onTap: () => Navigator.push(
                  context,
                  CupertinoPageRoute(builder: (_) => const PersonalDataPage()),
                ),
              ),
              _MenuItem(
                icon: CupertinoIcons.globe,
                title: AppLocalizations.of(context)!.language,
                trailingText: ref.watch(localeProvider).languageCode == 'ar'
                    ? 'العربية'
                    : 'English',
                onTap: () => _showLanguageSheet(context, ref),
              ),
              _MenuItem(
                icon: CupertinoIcons.bell,
                title: AppLocalizations.of(context)!.notifications,
                isSwitch: true,
                onTap: () {},
              ),
            ]),
            const SizedBox(height: 24),

            // Wallet & Payments
            _buildSectionTitle(ref, AppLocalizations.of(context)!.wallet),
            _buildSection([
              _MenuItem(
                icon: CupertinoIcons.money_dollar_circle,
                title: AppLocalizations.of(context)!.walletBalance,
                trailingText: '150 ${AppLocalizations.of(context)!.egp}',
                trailingTextColor: AppTheme.primaryDark,
                onTap: () => Navigator.push(
                  context,
                  CupertinoPageRoute(builder: (_) => const WalletPage()),
                ),
              ),
            ]),
            const SizedBox(height: 24),

            // Activity
            _buildSectionTitle(ref, AppLocalizations.of(context)!.rideHistory),
            _buildSection([
              _MenuItem(
                icon: CupertinoIcons.ticket,
                title: AppLocalizations.of(context)!.rideHistory,
                subtitle: ref.read(localeProvider).languageCode == 'ar'
                    ? 'عرض الرحلات السابقة والقادمة'
                    : 'View past and upcoming rides',
                onTap: () => Navigator.push(
                  context,
                  CupertinoPageRoute(builder: (_) => const RideHistoryPage()),
                ),
              ),
            ]),
            const SizedBox(height: 24),

            // Support & Legal
            _buildSectionTitle(ref, AppLocalizations.of(context)!.helpCenter),
            _buildSection([
              _MenuItem(
                icon: CupertinoIcons.question_circle,
                title: AppLocalizations.of(context)!.helpCenter,
                onTap: () => Navigator.push(
                  context,
                  CupertinoPageRoute(builder: (_) => const HelpCenterPage()),
                ),
              ),
              _MenuItem(
                icon: CupertinoIcons.phone,
                title: AppLocalizations.of(context)!.contactUs,
                onTap: () {
                  _showContactDialog(context);
                },
              ),
              _MenuItem(
                icon: CupertinoIcons.doc_text,
                title: AppLocalizations.of(context)!.termsAndConditions,
                onTap: () {
                  _showTermsDialog(context);
                },
              ),
            ]),
            const SizedBox(height: 32),

            // Logout
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                // No shadow, just a clean flat look
              ),
              child: TextButton(
                onPressed: () => _showLogoutDialog(context, ref),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context)!.logout,
                  style: AppTheme.textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFFFF3B30),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'الإصدار 1.0.0',
              style: AppTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.textTertiary,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showLanguageSheet(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.read(localeProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context)!.chooseLanguage,
              style: AppTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text(AppLocalizations.of(context)!.arabic),
              trailing: currentLocale.languageCode == 'ar'
                  ? const Icon(Icons.check_circle, color: AppTheme.primaryColor)
                  : null,
              onTap: () {
                ref
                    .read(localeProvider.notifier)
                    .setLocale(const Locale('ar', 'EG'));
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text(AppLocalizations.of(context)!.english),
              trailing: currentLocale.languageCode == 'en'
                  ? const Icon(Icons.check_circle, color: AppTheme.primaryColor)
                  : null,
              onTap: () {
                ref.read(localeProvider.notifier).setLocale(const Locale('en'));
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showContactDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('تواصل معنا'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 8),
            Text('يمكنك التواصل معنا عبر:'),
            SizedBox(height: 12),
            Text(
              'البريد الإلكتروني:\nsupport@fielsekka.com',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'الهاتف:\n01000000000',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
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

  void _showTermsDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('الشروط والأحكام'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 8),
              Text(
                '1. استخدام الخدمة مخصص للطلاب فقط\n\n'
                '2. يجب الالتزام بمواعيد الرحلات\n\n'
                '3. الدفع مقدماً قبل الحجز\n\n'
                '4. يمكن إلغاء الحجز قبل 24 ساعة\n\n'
                '5. الحفاظ على النظافة داخل الباص',
                textAlign: TextAlign.right,
              ),
            ],
          ),
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

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.white,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 55),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF3B30).withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: Color(0xFFFF3B30),
                  size: 26,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'تسجيل الخروج',
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'هل تريد الخروج من حسابك؟',
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'إلغاء',
                        style: GoogleFonts.cairo(
                          color: Colors.black54,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(dialogContext);
                        await ref.read(authProvider.notifier).logout();
                        if (context.mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            CupertinoPageRoute(builder: (_) => const LoginPage()),
                            (route) => false,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF3B30),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'خروج',
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
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

  Widget _buildSectionTitle(WidgetRef ref, String title) {
    final isAr = ref.read(localeProvider).languageCode == 'ar';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, right: 12, left: 12),
      child: Align(
        alignment: isAr ? Alignment.centerRight : Alignment.centerLeft,
        child: Text(
          title,
          style: AppTheme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildSection(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        // Removed shadow for a flatter, cleaner look
      ),
      child: Column(
        children: children.asMap().entries.map((entry) {
          final index = entry.key;
          final widget = entry.value;
          return Column(
            children: [
              widget,
              if (index != children.length - 1)
                Padding(
                  padding: const EdgeInsets.only(right: 52), // Indent divider
                  child: Divider(
                    height: 1,
                    color: Colors.grey.withValues(alpha: 0.1),
                  ),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _ProfileHeader extends ConsumerStatefulWidget {
  const _ProfileHeader();

  @override
  ConsumerState<_ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends ConsumerState<_ProfileHeader> {
  bool _isUploading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _isUploading = true;
      });

      final file = File(pickedFile.path);
      final error = await ref
          .read(authProvider.notifier)
          .uploadProfileImage(file);

      if (mounted) {
        setState(() {
          _isUploading = false;
        });

        if (error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error), backgroundColor: Colors.red),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم تحديث الصورة بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    }
  }

  Future<void> _removeImage() async {
    // Show confirmation dialog
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('حذف الصورة'),
        content: const Text('هل تريد حذف صورة الملف الشخصي؟'),
        actions: [
          CupertinoDialogAction(
            child: const Text('إلغاء'),
            onPressed: () => Navigator.pop(context, false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('حذف'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isUploading = true;
      });

      final error = await ref.read(authProvider.notifier).removeProfileImage();

      if (mounted) {
        setState(() {
          _isUploading = false;
        });

        if (error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error), backgroundColor: Colors.red),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم حذف الصورة بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).valueOrNull;
    final userName = user?.fullName ?? 'مستخدم';
    final university = user?.universityId ?? 'غير محدد';
    final avatarUrl = user?.avatarUrl;

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Avatar image - always opens image picker when tapped
            GestureDetector(
              onTap: _isUploading ? null : _pickImage,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[200],
                  image: avatarUrl != null
                      ? DecorationImage(
                          image: NetworkImage(avatarUrl),
                          fit: BoxFit.cover,
                        )
                      : const DecorationImage(
                          image: AssetImage(
                            'assets/images/avatar_placeholder.png',
                          ),
                          fit: BoxFit.cover,
                        ),
                ),
                child: _isUploading
                    ? const Center(child: CircularProgressIndicator())
                    : null,
              ),
            ),
            // Icon button - uploads if no image, deletes if image exists
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _isUploading
                    ? null
                    : (avatarUrl != null ? _removeImage : _pickImage),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: avatarUrl != null
                        ? const Color(0xFFFF3B30)
                        : AppTheme.primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFF5F5F7),
                      width: 3,
                    ),
                  ),
                  child: Icon(
                    avatarUrl != null
                        ? CupertinoIcons.trash_fill
                        : CupertinoIcons.camera_fill,
                    size: 14,
                    color: avatarUrl != null ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          userName,
          style: AppTheme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          university,
          style: AppTheme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? trailingText;
  final Color? trailingTextColor;
  final bool isSwitch;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailingText,
    this.trailingTextColor,
    this.isSwitch = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isSwitch ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Simple Icon without background container
              Icon(icon, color: Colors.black87, size: 22),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTheme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: AppTheme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.textTertiary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailingText != null)
                Text(
                  trailingText!,
                  style: AppTheme.textTheme.bodyMedium?.copyWith(
                    color: trailingTextColor ?? AppTheme.textSecondary,
                  ),
                ),
              if (isSwitch)
                CupertinoSwitch(
                  value: true,
                  activeTrackColor: AppTheme.primaryColor,
                  onChanged: (val) {},
                )
              else ...[
                if (trailingText != null) const SizedBox(width: 8),
                const Icon(
                  CupertinoIcons.chevron_left,
                  size: 16,
                  color: Color(0xFFC7C7CC),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
