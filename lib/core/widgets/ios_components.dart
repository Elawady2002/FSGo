import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

// InDrive-style Button - Large, Bold, Lime Green
class IOSButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? textColor;
  final bool isFilled;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;

  const IOSButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.color,
    this.textColor,
    this.isFilled = true,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppTheme.primaryColor;
    final effectiveTextColor =
        textColor ?? (isFilled ? AppTheme.accentColor : effectiveColor);

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: isLoading ? null : onPressed,
      child: Container(
        constraints: BoxConstraints(
          minWidth: isFullWidth ? double.infinity : 100,
          maxWidth: isFullWidth ? double.infinity : 200,
        ),
        height: 56,
        decoration: BoxDecoration(
          color: isFilled ? effectiveColor : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
          border: isFilled ? null : Border.all(color: effectiveColor, width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
          children: [
            if (isLoading) ...[
              CupertinoActivityIndicator(color: effectiveTextColor),
            ] else ...[
              if (icon != null) ...[
                Icon(icon, color: effectiveTextColor, size: 22),
                const SizedBox(width: 10),
              ],
              Text(
                text,
                style: GoogleFonts.cairo(
                  color: effectiveTextColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.none,
                  decorationColor: Colors.transparent,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// InDrive-style Card - Clean white with subtle shadow
class IOSCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onPressed;

  const IOSCard({super.key, required this.child, this.padding, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );

    if (onPressed != null) {
      return CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        child: card,
      );
    }

    return card;
  }
}

// InDrive Search Bar - Floating search with icon
class InDriveSearchBar extends StatelessWidget {
  final String hintText;
  final VoidCallback? onTap;
  final IconData icon;

  const InDriveSearchBar({
    super.key,
    required this.hintText,
    this.onTap,
    this.icon = CupertinoIcons.search,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppTheme.floatingShadow,
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.textSecondary, size: 22),
            const SizedBox(width: 12),
            Text(
              hintText,
              style: GoogleFonts.cairo(
                color: AppTheme.textSecondary,
                fontSize: 17,
                decoration: TextDecoration.none,
                decorationColor: Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// InDrive Bottom Sheet Base
class InDriveBottomSheet extends StatelessWidget {
  final Widget child;
  final double? height;
  final String? title;

  const InDriveBottomSheet({
    super.key,
    required this.child,
    this.height,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: height ?? screenHeight * 0.85,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.bottomSheetRadius),
        ),
        boxShadow: AppTheme.bottomSheetShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title if provided
          if (title != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Text(title!, style: AppTheme.textTheme.titleLarge),
            ),
            const Divider(height: 1),
          ],

          // Content
          Expanded(child: child),
        ],
      ),
    );
  }
}

// Glass effect for overlays
class IOSGlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final Color? color;
  final BorderRadius? borderRadius;

  const IOSGlassContainer({
    super.key,
    required this.child,
    this.blur = 20,
    this.opacity = 0.7,
    this.color,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(AppTheme.cardRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: (color ?? Colors.white).withValues(alpha: opacity),
            borderRadius:
                borderRadius ?? BorderRadius.circular(AppTheme.cardRadius),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.7),
              width: 0.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

// Simple List Tile
class IOSListTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showDivider;

  const IOSListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: showDivider
                ? const Border(
                    bottom: BorderSide(
                      color: AppTheme.dividerColor,
                      width: 0.5,
                    ),
                  )
                : null,
          ),
          child: Row(
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 16)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTheme.textTheme.bodyLarge),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(subtitle!, style: AppTheme.textTheme.bodyMedium),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ] else if (onTap != null) ...[
                const SizedBox(width: 8),
                const Icon(
                  CupertinoIcons.chevron_forward,
                  color: AppTheme.textTertiary,
                  size: 20,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
