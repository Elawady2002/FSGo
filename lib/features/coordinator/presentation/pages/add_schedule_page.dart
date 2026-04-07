import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/domain/entities/user_entity.dart';
import '../providers/coordinator_provider.dart';

const _kBg = Colors.white;
const _kCard = Color(0xFFF5F5F5);
const _kLime = Color(0xFF1A1A1A);
const _kText = Color(0xFF1A1A1A);
const _kSubText = Color(0xFF666666);

class AddSchedulePage extends ConsumerStatefulWidget {
  final UserEntity coordinator;
  const AddSchedulePage({super.key, required this.coordinator});

  @override
  ConsumerState<AddSchedulePage> createState() => _AddSchedulePageState();
}

class _AddSchedulePageState extends ConsumerState<AddSchedulePage> {
  final _formKey = GlobalKey<FormState>();
  final _originCtrl = TextEditingController();
  final _destCtrl = TextEditingController();
  final _fareCtrl = TextEditingController();
  final _capacityCtrl = TextEditingController(text: '20');

  TimeOfDay _departureTime = const TimeOfDay(hour: 7, minute: 0);
  final Set<String> _selectedDays = {};
  bool _isSaving = false;

  static const _days = [
    ('sunday', 'الأحد'),
    ('monday', 'الاثنين'),
    ('tuesday', 'الثلاثاء'),
    ('wednesday', 'الأربعاء'),
    ('thursday', 'الخميس'),
    ('friday', 'الجمعة'),
    ('saturday', 'السبت'),
  ];

  @override
  void dispose() {
    _originCtrl.dispose();
    _destCtrl.dispose();
    _fareCtrl.dispose();
    _capacityCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        title: Text(
          'موعد جديد',
          style: GoogleFonts.cairo(
            color: _kText,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: _kText),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionLabel('المسار'),
              const SizedBox(height: 8),
              _DarkField(
                controller: _originCtrl,
                hint: 'نقطة الانطلاق (مثال: بلبيس)',
                validator: (v) =>
                    v == null || v.isEmpty ? 'مطلوب' : null,
              ),
              const SizedBox(height: 10),
              _DarkField(
                controller: _destCtrl,
                hint: 'الوجهة (مثال: السلام)',
                validator: (v) =>
                    v == null || v.isEmpty ? 'مطلوب' : null,
              ),
              const SizedBox(height: 20),
              _SectionLabel('وقت الانطلاق'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickTime,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: _kCard,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(CupertinoIcons.clock,
                          color: _kLime, size: 18),
                      const SizedBox(width: 10),
                      Text(
                        _departureTime.format(context),
                        style: GoogleFonts.cairo(
                            color: _kText, fontSize: 16),
                      ),
                      const Spacer(),
                      const Icon(CupertinoIcons.chevron_right,
                          color: _kSubText, size: 14),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _SectionLabel('أيام التشغيل'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _days.map((day) {
                  final isSelected = _selectedDays.contains(day.$1);
                  return GestureDetector(
                    onTap: () => setState(() {
                      if (isSelected) {
                        _selectedDays.remove(day.$1);
                      } else {
                        _selectedDays.add(day.$1);
                      }
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _kLime.withValues(alpha: 0.15)
                            : _kCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? _kLime : Colors.black12,
                        ),
                      ),
                      child: Text(
                        day.$2,
                        style: GoogleFonts.cairo(
                          color: isSelected ? _kLime : _kSubText,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w400,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionLabel('السعر (جنيه)'),
                        const SizedBox(height: 8),
                        _DarkField(
                          controller: _fareCtrl,
                          hint: '0',
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'مطلوب';
                            if (double.tryParse(v) == null) return 'رقم فقط';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionLabel('الطاقة الاستيعابية'),
                        const SizedBox(height: 8),
                        _DarkField(
                          controller: _capacityCtrl,
                          hint: '20',
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'مطلوب';
                            if (int.tryParse(v) == null) return 'رقم صحيح';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _kLime.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _kLime.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(CupertinoIcons.info_circle,
                        color: _kLime, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'سيتم إرسال الموعد للمراجعة. بعد موافقة الإدارة يمكنك تعيين سائق.',
                        style: GoogleFonts.cairo(
                            color: _kLime.withValues(alpha: 0.8),
                            fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kLime,
                    foregroundColor: _kBg,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _isSaving ? null : _submit,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: _kBg,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'إرسال للموافقة',
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _departureTime,
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(
            primary: _kLime,
            onPrimary: Colors.white,
            onSurface: _kText,
            secondary: _kLime,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: _kLime,
              textStyle: GoogleFonts.cairo(fontWeight: FontWeight.w700),
            ),
          ),
          timePickerTheme: TimePickerThemeData(
            backgroundColor: Colors.white,
            hourMinuteColor: _kCard,
            hourMinuteTextColor: _kText,
            dayPeriodColor: _kCard,
            dayPeriodTextColor: _kText,
            dialHandColor: _kLime,
            dialBackgroundColor: _kCard,
            dialTextColor: _kText,
            entryModeIconColor: _kLime,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _departureTime = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('اختر يوماً واحداً على الأقل',
              style: GoogleFonts.cairo()),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final timeStr =
        '${_departureTime.hour.toString().padLeft(2, '0')}:${_departureTime.minute.toString().padLeft(2, '0')}';

    final error = await ref
        .read(coordinatorScheduleProvider(widget.coordinator.id).notifier)
        .createSchedule(
          origin: _originCtrl.text.trim(),
          destination: _destCtrl.text.trim(),
          departureTime: timeStr,
          availableDays: _selectedDays.toList(),
          capacity: int.parse(_capacityCtrl.text.trim()),
          baseFare: double.parse(_fareCtrl.text.trim()),
        );

    setState(() => _isSaving = false);

    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ: $error', style: GoogleFonts.cairo()),
          backgroundColor: Colors.redAccent,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم إرسال الموعد بنجاح — في انتظار الموافقة',
              style: GoogleFonts.cairo()),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }
}

// ── Shared dark widgets ────────────────────────────────────────

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
        letterSpacing: 0.5,
      ),
    );
  }
}

class _DarkField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const _DarkField({
    required this.controller,
    required this.hint,
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
          borderSide: const BorderSide(color: _kLime, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
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
