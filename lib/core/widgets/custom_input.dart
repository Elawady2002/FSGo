import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

class CustomInput extends StatefulWidget {
  final String hintText;
  final IconData? prefixIcon;
  final bool isPassword;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final Widget? prefixWidget;
  final Color? backgroundColor;

  const CustomInput({
    super.key,
    required this.hintText,
    this.prefixIcon,
    this.isPassword = false,
    this.controller,
    this.validator,
    this.keyboardType,
    this.suffixIcon,
    this.prefixWidget,
    this.backgroundColor,
  });

  @override
  State<CustomInput> createState() => _CustomInputState();
}

class _CustomInputState extends State<CustomInput> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    // Show built-in toggle only if it's a password field and no custom suffixIcon passed
    final showBuiltInToggle = widget.isPassword && widget.suffixIcon == null;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: widget.controller,
        obscureText: widget.isPassword ? _obscure : false,
        keyboardType: widget.keyboardType,
        validator: widget.validator,
        style: GoogleFonts.cairo(color: AppTheme.textPrimary, fontSize: 16),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: GoogleFonts.cairo(
            color: CupertinoColors.systemGrey,
            fontSize: 14,
          ),
          fillColor: widget.backgroundColor ?? Colors.white,
          filled: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: AppTheme.primaryColor,
              width: 1.5,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.red, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.red, width: 1.5),
          ),
          prefixIcon: widget.prefixWidget ??
              (widget.prefixIcon != null
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Icon(
                        widget.prefixIcon,
                        color: CupertinoColors.systemGrey,
                        size: 20,
                      ),
                    )
                  : null),
          prefixIconConstraints: const BoxConstraints(minWidth: 40),
          suffixIcon: showBuiltInToggle
              ? GestureDetector(
                  onTap: () => setState(() => _obscure = !_obscure),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(
                      _obscure ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
                      color: CupertinoColors.systemGrey,
                      size: 20,
                    ),
                  ),
                )
              : widget.suffixIcon,
          suffixIconConstraints: const BoxConstraints(minWidth: 40),
        ),
      ),
    );
  }
}
