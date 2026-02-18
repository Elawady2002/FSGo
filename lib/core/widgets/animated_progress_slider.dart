import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:my_app/l10n/app_localizations.dart';
import '../theme/app_theme.dart';

class AnimatedProgressSlider extends StatefulWidget {
  final int currentStep;
  final int totalSteps;
  final List<String> labels;

  const AnimatedProgressSlider({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.labels,
  });

  @override
  State<AnimatedProgressSlider> createState() => _AnimatedProgressSliderState();
}

class _AnimatedProgressSliderState extends State<AnimatedProgressSlider>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Yamanote Green Color
    const Color activeColor = Color(0xFFB2FF59); // Bright Green
    const Color inactiveColor = Color(0xFF424242); // Dark Grey

    final l10n = AppLocalizations.of(context)!;


    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                const Icon(
                  CupertinoIcons.ticket_fill,
                  color: activeColor,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Text(
                  l10n.selectDestination,
                  style: AppTheme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD740), // Amber accent
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    l10n.now,
                    style: AppTheme.textTheme.labelSmall?.copyWith(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Slider Section
            LayoutBuilder(
              builder: (context, constraints) {
                final double width = constraints.maxWidth;
                final double padding = 16.0;
                final double availableWidth = width - (padding * 2);
                final double stepWidth =
                    availableWidth / (widget.totalSteps - 1);
                final double targetFillWidth =
                    (widget.currentStep < 0 ? 0 : widget.currentStep) *
                    stepWidth;

                return SizedBox(
                  height: 60,
                  child: Stack(
                    children: [
                      // Background Track
                      Positioned(
                        top: 12,
                        left: padding,
                        right: padding,
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: inactiveColor,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),

                      // Animated Fill Track
                      PositionedDirectional(
                        top: 12,
                        start: padding,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOutBack,
                          height: 6,
                          width: targetFillWidth,
                          decoration: BoxDecoration(
                            color: activeColor,
                            borderRadius: BorderRadius.circular(3),
                            boxShadow: [
                              BoxShadow(
                                color: activeColor.withValues(alpha: 0.6),
                                blurRadius: 12,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Dots and Labels
                      ...List.generate(widget.totalSteps, (index) {
                        final bool isActive = index == widget.currentStep;
                        final bool isCompleted = index <= widget.currentStep;
                        final double centerPos = padding + (index * stepWidth);
                        final double dotSize = 20.0;
                        final double labelWidth = 80.0;

                        return PositionedDirectional(
                          start: centerPos - (labelWidth / 2),
                          top: 5,
                          child: SizedBox(
                            width: labelWidth,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Dot
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    if (isActive)
                                      AnimatedBuilder(
                                        animation: _pulseAnimation,
                                        builder: (context, child) {
                                          return Transform.scale(
                                            scale: _pulseAnimation.value,
                                            child: Container(
                                              width: dotSize,
                                              height: dotSize,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: activeColor.withValues(
                                                    alpha: 0.5,
                                                  ),
                                                  width: 1,
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 400,
                                      ),
                                      width: dotSize,
                                      height: dotSize,
                                      decoration: BoxDecoration(
                                        color: isCompleted
                                            ? activeColor
                                            : inactiveColor,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.black,
                                          width: 3,
                                        ),
                                      ),
                                      child: isActive
                                          ? Center(
                                              child: Container(
                                                width: 6,
                                                height: 6,
                                                decoration: const BoxDecoration(
                                                  color: Colors.white,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                            )
                                          : null,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 300),
                                  style: AppTheme.textTheme.labelSmall!
                                      .copyWith(
                                        color: isActive
                                            ? activeColor
                                            : Colors.grey,
                                        fontWeight: isActive
                                            ? FontWeight.w900
                                            : FontWeight.normal,
                                        fontSize: isActive ? 12 : 11,
                                      ),
                                  child: Text(
                                    widget.labels.length > index
                                        ? widget.labels[index]
                                        : '',
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
