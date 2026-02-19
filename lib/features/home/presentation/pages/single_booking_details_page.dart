import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../booking/domain/entities/booking_entity.dart';
import '../../../subscription/domain/entities/subscription_entity.dart';

class SingleBookingDetailsPage extends StatefulWidget {
  final BookingEntity? booking;
  final SubscriptionEntity? subscription;

  const SingleBookingDetailsPage({
    super.key,
    this.booking,
    this.subscription,
  }) : assert(booking != null || subscription != null);

  @override
  State<SingleBookingDetailsPage> createState() =>
      _SingleBookingDetailsPageState();
}

class _SingleBookingDetailsPageState extends State<SingleBookingDetailsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleClose() {
    HapticFeedback.lightImpact();
    _animationController.reverse().then((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  String _formatDateSafe(DateTime date) {
    try {
      return DateFormat('d MMMM', 'ar_EG').format(date);
    } catch (e) {
      return "${date.day}/${date.month}";
    }
  }

  String _formatTime(String time) {
    try {
      final parts = time.split(':');
      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        final period = hour < 12 ? 'ص' : 'م';
        final displayHour = hour % 12 == 0 ? 12 : hour % 12;
        return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
      }
      return time;
    } catch (e) {
      return time;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isSubscription = widget.booking == null;
    
    final primaryColor = isSubscription ? const Color(0xFF8E8E93) : const Color(0xFFCCFF00); 
    final id = isSubscription ? widget.subscription!.id : widget.booking!.id;
    final shortId = '#${id?.substring(0, 8).toUpperCase() ?? "N/A"}';
    
    // Determine trip label
    String tripLabel;
    final tripType = isSubscription ? widget.subscription!.tripType : widget.booking!.tripType;
    final dropoffId = isSubscription ? widget.subscription!.dropoffStationId : widget.booking!.dropoffStationId;

    if (dropoffId != null) {
      tripLabel = l10n.stationToStation;
    } else {
      switch (tripType) {
        case 'departure_only':
          tripLabel = l10n.departureOnly;
          break;
        case 'return_only':
          tripLabel = l10n.returnOnly;
          break;
        default:
          tripLabel = l10n.roundTrip;
      }
    }

    final date = isSubscription ? widget.subscription!.startDate : widget.booking!.bookingDate;
    final formattedDate = _formatDateSafe(date);
    final formattedTime = (!isSubscription && widget.booking!.departureTime != null)
        ? _formatTime(widget.booking!.departureTime!) 
        : null;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 16,
              right: 20,
              child: GestureDetector(
                onTap: _handleClose,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),

            Center(
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Opacity(
                      opacity: _fadeAnimation.value,
                      child: child,
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C1C1E),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(color: Colors.white10),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.15),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: primaryColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                isSubscription ? 'تذكرة الاشتراك' : 'تذكرة الركوب',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),

                            const SizedBox(height: 32),

                            Text(
                              shortId,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                                letterSpacing: 2,
                              ),
                            ),

                            const SizedBox(height: 24),

                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: QrImageView(
                                data: id ?? '',
                                version: QrVersions.auto,
                                size: 200,
                                eyeStyle: const QrEyeStyle(
                                  eyeShape: QrEyeShape.square,
                                  color: Colors.black,
                                ),
                                dataModuleStyle: const QrDataModuleStyle(
                                  dataModuleShape: QrDataModuleShape.square,
                                  color: Colors.black,
                                ),
                              ),
                            ),

                            const SizedBox(height: 32),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildDetailItem(
                                  Icons.calendar_today,
                                  isSubscription ? l10n.startDate : l10n.date,
                                  formattedDate,
                                ),
                                if (formattedTime != null)
                                  _buildDetailItem(
                                    Icons.access_time,
                                    l10n.tripTime,
                                    formattedTime,
                                  ),
                              ],
                            ),
                            
                            const SizedBox(height: 24),
                             _buildDetailItem(
                                  Icons.directions_bus,
                                  l10n.tripType,
                                  tripLabel,
                                ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.white54, size: 20),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
