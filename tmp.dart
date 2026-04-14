      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _ToggleOption(
            label: 'شهري',
            isSelected: value == 'monthly',
            accentColor: accentColor,
            onTap: () => onChanged('monthly'),
          ),
          _ToggleOption(
            label: 'فصل دراسي',
            isSelected: value == 'semester',
            accentColor: accentColor,
            onTap: () => onChanged('semester'),
          ),
        ],
      ),
    );
  }
}

class _ToggleOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;

  const _ToggleOption({
    required this.label,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? accentColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              color: isSelected ? Colors.white : _kSubText,
              fontSize: 14,
              fontWeight:
                  isSelected ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Shared Widgets ─────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.cairo(
        color: _kSubText,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _DarkField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final Color accentColor;
  final String? Function(String?)? validator;

  const _DarkField({
    required this.controller,
    required this.hint,
    required this.accentColor,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.cairo(color: _kText, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.cairo(color: _kSubText, fontSize: 15),
        filled: true,
        fillColor: _kCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accentColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
