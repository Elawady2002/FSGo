import 'package:flutter/material.dart';

/// Represents an item in the navigation drawer
class DrawerItem {
  final String title;
  final IconData icon;
  final VoidCallback? onTap;
  final bool isEnabled;
  final bool isDestructive;

  const DrawerItem({
    required this.title,
    required this.icon,
    this.onTap,
    this.isEnabled = true,
    this.isDestructive = false,
  });
}
