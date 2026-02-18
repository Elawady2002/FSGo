import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_app/core/utils/digit_converter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/booking_entity.dart';

class BookingSuccessPage extends StatefulWidget {
  final BookingEntity? booking;
  final double amount;
  final String tripType;
  final DateTime date;

  const BookingSuccessPage({
    super.key,
    this.booking,
    required this.amount,
    required this.tripType,
    required this.date,
  });

  @override
  State<BookingSuccessPage> createState() => _BookingSuccessPageState();
}

class _BookingSuccessPageState extends State<BookingSuccessPage>
    with SingleTickerProviderStateMixin {
  double _dragOffset = 0;
  late AnimationController _controller;
  bool _isExiting = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (_isExiting) return;
    setState(() {
      _dragOffset += details.primaryDelta!;
      if (_dragOffset < 0) _dragOffset = 0; // Prevent upward drag
    });
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (_isExiting) return;
    if (_dragOffset > 150 || details.primaryVelocity! > 500) {
      _exitToHome();
    } else {
      // Snap back
      _controller.duration = const Duration(milliseconds: 200);
      _animateBack();
    }
  }

  void _animateBack() {
    final start = _dragOffset;
    final animation = Tween<double>(begin: start, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    animation.addListener(() {
      setState(() {
        _dragOffset = animation.value;
      });
    });
    _controller.forward(from: 0);
  }

  void _exitToHome() {
    if (_isExiting) return;
    _isExiting = true;
    final start = _dragOffset;
    final animation = Tween<double>(begin: start, end: 1000).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    animation.addListener(() {
      setState(() {
        _dragOffset = animation.value;
      });
    });
    _controller.duration = const Duration(milliseconds: 400);
    _controller.forward(from: 0).then((_) {
      if (mounted) {
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Background / Bottom Layer (Wait/Success Text can be here)
            Center(
              child: Opacity(
                opacity: (1 - (_dragOffset / 300)).clamp(0.0, 1.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      CupertinoIcons.check_mark_circled_solid,
                      color: Colors.white,
                      size: 80,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'تم الحجز بنجاح',
                      style: AppTheme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Draggable Ticket
            Transform.translate(
              offset: Offset(0, _dragOffset),
              child: GestureDetector(
                onVerticalDragUpdate: _onVerticalDragUpdate,
                onVerticalDragEnd: _onVerticalDragEnd,
                child: Column(
                  children: [
                    const Spacer(),
                    // Ticket Card
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 32),
                          Text(
                            'تذكرة الحجز',
                            style: AppTheme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Status Checkmarks
                          _buildStatusRow('تم الدفع بنجاح'),
                          const SizedBox(height: 12),
                          _buildStatusRow('تم حجز المقعد'),
                          const SizedBox(height: 12),
                          _buildStatusRow('الفاتورة جاهزة'),

                          const SizedBox(height: 32),

                          // Paid Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF9C4), // Light yellow
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'مدفوع',
                              style: AppTheme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Price
                          Text(
                            'EGP ${widget.amount.toStringAsFixed(0)}',
                            style: AppTheme.textTheme.displayLarge?.copyWith(
                              fontSize: 42,
                              fontWeight: FontWeight.w800,
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Details
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildDetailColumn('نوع الرحلة', widget.tripType),
                                _buildDetailColumn(
                                  'التاريخ',
                                  DateFormat('d MMMM', 'ar_EG')
                                      .format(widget.date)
                                      .w,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Dashed Line
                          CustomPaint(
                            painter: DashedLinePainter(),
                            size: const Size(double.infinity, 1),
                          ),

                          const SizedBox(height: 24),

                          // Dismiss Hint
                          Column(
                            children: [
                              Text(
                                'اسحب للرئيسية',
                                style: AppTheme.textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Icon(
                                CupertinoIcons.chevron_down,
                                color: AppTheme.textSecondary,
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            text,
            style: AppTheme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Icon(
            CupertinoIcons.checkmark_alt_circle_fill,
            color: Color(0xFF4CAF50), // Green
            size: 28,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    double dashWidth = 8, dashSpace = 5, startX = 0;
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1;
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
