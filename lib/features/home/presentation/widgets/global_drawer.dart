import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/domain/entities/user_entity.dart';
import '../../domain/entities/drawer_item.dart';
import '../pages/profile_page.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

const _kBg = Color(0xFF1A1A1A);
const _kCard = Color(0xFF242424);
const _kLime = Color(0xFFC9D420);
const _kText = Colors.white;
const _kSubText = Color(0xFF9E9E9E);

/// Global Navigation Drawer for authenticated users
/// Provides access to Profile, Logout, and other navigation items
class GlobalDrawer extends ConsumerWidget {
  final UserEntity? user;
  final int selectedIndex;

  const GlobalDrawer({super.key, this.user, this.selectedIndex = 0});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      backgroundColor: _kBg,
      elevation: 0,
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Header with User Info
            _buildHeader(context),
            const Divider(color: Colors.white12, height: 1),
            // Navigation Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  // Profile Item
                  _buildDrawerItem(
                    context,
                    DrawerItem(
                      title: 'الملف الشخصي',
                      icon: CupertinoIcons.person,
                      onTap: () => _navigateToProfile(context),
                    ),
                    isSelected: selectedIndex == 0,
                  ),
                  // Divider
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Divider(color: Colors.white12),
                  ),
                  // Logout Item
                  _buildDrawerItem(
                    context,
                    DrawerItem(
                      title: 'تسجيل الخروج',
                      icon: CupertinoIcons.arrow_right_square,
                      onTap: () => _handleLogout(context, ref),
                      isDestructive: true,
                    ),
                    isSelected: false,
                  ),
                ],
              ),
            ),
            // App Version at bottom
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'في السكة v1.0.0',
                style: GoogleFonts.cairo(
                  color: _kSubText.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final displayName = user?.fullName ?? 'سائق';
    final phone = user?.phone ?? '';
    final hasAvatar = user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _kLime,
              border: Border.all(color: _kLime, width: 2),
              image: hasAvatar
                  ? DecorationImage(
                      image: NetworkImage(user!.avatarUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: !hasAvatar
                ? Icon(CupertinoIcons.person, color: _kBg, size: 32)
                : null,
          ),
          const SizedBox(width: 16),
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: GoogleFonts.cairo(
                    color: _kText,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (phone.isNotEmpty)
                  Text(
                    phone,
                    style: GoogleFonts.cairo(color: _kSubText, fontSize: 14),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context,
    DrawerItem item, {
    required bool isSelected,
  }) {
    final color = item.isDestructive ? Colors.redAccent : _kText;
    final selectedColor = item.isDestructive ? Colors.redAccent : _kLime;

    return ListTile(
      enabled: item.isEnabled,
      leading: Icon(item.icon, color: isSelected ? selectedColor : color),
      title: Text(
        item.title,
        style: GoogleFonts.cairo(
          color: isSelected ? selectedColor : color,
          fontSize: 16,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      selected: isSelected,
      selectedTileColor: _kLime.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onTap: () {
        if (!item.isDestructive) {
          Navigator.of(context).pop();
        }
        item.onTap?.call();
      },
    );
  }

  void _navigateToProfile(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const ProfilePage()));
  }

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    // Show confirmation dialog
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(
          'تسجيل الخروج',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'هل أنت متأكد أنك تريد تسجيل الخروج؟',
          style: GoogleFonts.cairo(),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('إلغاء', style: GoogleFonts.cairo()),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('خروج', style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show loading indicator
    if (!context.mounted) return;
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CupertinoActivityIndicator(radius: 15)),
    );

    // Perform logout
    final error = await ref.read(authProvider.notifier).logout();

    if (context.mounted) {
      // Close loading indicator
      Navigator.of(context).pop();

      if (error != null) {
        // Show error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطأ في تسجيل الخروج: $error',
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      // Note: No manual navigation here.
      // AuthWrapper will handle the transition automatically when the user state becomes null.
    }
  }
}
