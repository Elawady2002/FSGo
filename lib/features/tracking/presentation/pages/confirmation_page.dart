import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/ticket_card.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../../../booking/presentation/providers/booking_provider.dart';

class ConfirmationPage extends ConsumerStatefulWidget {
  const ConfirmationPage({super.key});

  @override
  ConsumerState<ConfirmationPage> createState() => _ConfirmationPageState();
}

class _ConfirmationPageState extends ConsumerState<ConfirmationPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _translateAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _opacityAnimation;
  double _dragOffsetY = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _translateAnimation = Tween<double>(
      begin: 0,
      end: 200,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _rotateAnimation = Tween<double>(
      begin: 0,
      end: 0.1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _opacityAnimation = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
          (route) => false,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookingState = ref.watch(bookingStateProvider);
    final bookingNotifier = ref.read(bookingStateProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFDBCA00), // Updated background color
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Top Part of Ticket
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TicketCard(
                        part: TicketPart.top,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 32),
                              // Header
                              Center(
                                child: Text(
                                  "تذكرة الحجز",
                                  style: AppTheme.textTheme.headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                ),
                              ),
                              const SizedBox(height: 32),

                              // Features / Checks
                              _buildCheckItem(context, "تم الدفع بنجاح"),
                              const SizedBox(height: 12),
                              _buildCheckItem(context, "تم حجز المقعد"),
                              const SizedBox(height: 12),
                              _buildCheckItem(context, "الفاتورة جاهزة"),

                              const SizedBox(height: 32),

                              // Price Tag
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF08A), // Yellow bg
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  "مدفوع",
                                  style: AppTheme.textTheme.labelMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "${bookingNotifier.totalPrice.toStringAsFixed(0)} جنيه",
                                style: AppTheme.textTheme.displayMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                      fontSize: 48,
                                    ),
                              ),

                              const SizedBox(height: 24),

                              // Trip Details
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "التاريخ",
                                        style: AppTheme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: AppTheme.textSecondary,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        DateFormat(
                                          'd MMM',
                                          'ar_EG',
                                        ).format(bookingState.selectedDate),
                                        style: AppTheme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        "نوع الرحلة",
                                        style: AppTheme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: AppTheme.textSecondary,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        bookingState.tripType.displayName,
                                        style: AppTheme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),
                      // Bottom Part of Ticket (Interactive Tear)
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          // Combine drag offset and animation offset
                          final double yOffset =
                              _dragOffsetY + _translateAnimation.value;
                          final double rotation =
                              (_dragOffsetY / 1000) + // Slight rotation on drag
                              (_rotateAnimation.value * (math.pi / 180));

                          return Transform.translate(
                            offset: Offset(0, yOffset),
                            child: Transform.rotate(
                              angle: rotation,
                              child: Opacity(
                                opacity: _opacityAnimation.value,
                                child: child,
                              ),
                            ),
                          );
                        },
                        child: GestureDetector(
                          onVerticalDragUpdate: (details) {
                            if (_controller.isAnimating ||
                                _controller.isCompleted) {
                              return;
                            }

                            setState(() {
                              // Only allow dragging downwards
                              _dragOffsetY = math.max(
                                0,
                                _dragOffsetY + details.delta.dy,
                              );
                            });

                            // Haptic feedback to simulate tearing texture
                            // Increased intensity and adjusted interval for better feel
                            if (_dragOffsetY > 0 && _dragOffsetY < 100) {
                              if (_dragOffsetY % 8 < 2) {
                                HapticFeedback.mediumImpact();
                              }
                            }
                          },
                          onVerticalDragEnd: (details) {
                            if (_controller.isAnimating ||
                                _controller.isCompleted) {
                              return;
                            }

                            if (_dragOffsetY > 100) {
                              // Complete the tear
                              HapticFeedback.heavyImpact();
                              _controller.forward();
                            } else {
                              // Snap back
                              setState(() {
                                _dragOffsetY = 0.0;
                              });
                            }
                          },
                          child: TicketCard(
                            part: TicketPart.bottom,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              // Decoration removed to allow TicketPainter to handle the shape (punches)
                              child: Column(
                                children: [
                                  const SizedBox(height: 16),
                                  Text(
                                    "اسحب للرئيسية",
                                    style: AppTheme.textTheme.bodyMedium
                                        ?.copyWith(
                                          color: AppTheme.textSecondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: AppTheme.textSecondary,
                                    size: 24,
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckItem(BuildContext context, String text) {
    return Row(
      children: [
        const Icon(
          Icons.check_circle,
          color: Color(0xFF65A30D), // Green
          size: 24,
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: AppTheme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}
