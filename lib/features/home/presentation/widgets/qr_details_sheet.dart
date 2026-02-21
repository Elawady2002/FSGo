import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../booking/domain/entities/booking_entity.dart';
import '../../../subscription/domain/entities/subscription_entity.dart';
import '../providers/home_provider.dart';

class QRDetailsSheet extends ConsumerWidget {
  final BookingEntity? booking;
  final SubscriptionEntity? subscription;

  const QRDetailsSheet({
    super.key,
    this.booking,
    this.subscription,
  }) : assert(booking != null || subscription != null);

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
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isSubscription = booking == null;
    final lang = ref.watch(localeProvider).languageCode;
    
    final id = isSubscription ? subscription!.id : booking!.id;
    final shortId = '#${id?.substring(0, 8).toUpperCase() ?? "N/A"}';
    
    final stations = ref.watch(allStationsProvider).valueOrNull ?? [];
    final universities = ref.watch(allUniversitiesProvider).valueOrNull ?? [];

    // Determine trip label
    String tripLabel;
    final tripType = isSubscription ? subscription!.tripType : booking!.tripType;
    final pickupId = isSubscription ? subscription!.pickupStationId : booking!.pickupStationId;
    final dropoffId = isSubscription ? subscription!.dropoffStationId : booking!.dropoffStationId;

    final pickupStation = stations.where((s) => s.id == pickupId).firstOrNull;
    final dropoffStation = stations.where((s) => s.id == dropoffId).firstOrNull;
    final universityName = universities.isNotEmpty ? universities.first.getLocalizedName(lang) : 'الجامعة';

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

    String routeInfo = '';
    if (tripType == 'departure_only') {
      routeInfo = '${pickupStation?.getLocalizedName(lang) ?? l10n.madinaty} ← ${dropoffStation?.getLocalizedName(lang) ?? universityName}';
    } else if (tripType == 'return_only') {
      routeInfo = '$universityName ← ${dropoffStation?.getLocalizedName(lang) ?? pickupStation?.getLocalizedName(lang) ?? l10n.madinaty}';
    } else {
      routeInfo = '${pickupStation?.getLocalizedName(lang) ?? l10n.madinaty} ← $universityName';
    }

    final date = isSubscription ? subscription!.startDate : booking!.bookingDate;
    final formattedDate = _formatDateSafe(date);
    final formattedTime = (!isSubscription && booking!.departureTime != null)
        ? _formatTime(booking!.departureTime!) 
        : null;

    final primaryColor = const Color(0xFFCCFF00); // Lime green for the badge

    return Material(
      type: MaterialType.transparency,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 20,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            // Drag Handle
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            // Header/Close button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft, // Assuming RTL app, close on left for Arabic or Right for LTR. The user's screenshot had it on the top right.
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      CupertinoIcons.multiply,
                      color: Colors.grey.shade600,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    
                    // Ticket Box (The stylized parts on white background)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1C1E),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Column(
                        children: [
                          // Badge
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
                              isSubscription ? 'تذكرة الاشتراك' : tripLabel,
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // ID
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

                          // QR Code
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: QrImageView(
                              data: id ?? '',
                              version: QrVersions.auto,
                              size: 180,
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

                          const SizedBox(height: 40),

                          // Detail Grid
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: _buildDetailItem(
                                  CupertinoIcons.clock,
                                  "الرحلة الساعة كام؟",
                                  formattedTime ?? "-",
                                  color: Colors.white,
                                  labelColor: Colors.white70,
                                ),
                              ),
                              if (!isSubscription && (booking?.passengerCount ?? 1) > 1)
                                Expanded(
                                  child: _buildDetailItem(
                                    CupertinoIcons.person_2,
                                    "عدد المقاعد",
                                    "${booking!.passengerCount}",
                                    color: Colors.white,
                                    labelColor: Colors.white70,
                                  ),
                                ),
                              Expanded(
                                child: _buildDetailItem(
                                  CupertinoIcons.calendar,
                                  "امتى؟",
                                  formattedDate,
                                  color: Colors.white,
                                  labelColor: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 32),

                          _buildDetailItem(
                            CupertinoIcons.bus,
                            "نوع الرحلة",
                            routeInfo,
                            isFullWidth: true,
                            color: Colors.white,
                            labelColor: Colors.white70,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value, {bool isFullWidth = false, Color? color, Color? labelColor}) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                label,
                style: GoogleFonts.cairo(
                  color: labelColor ?? Colors.grey.shade500,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Icon(icon, color: color?.withValues(alpha: 0.5) ?? Colors.grey.shade400, size: 20),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.cairo(
              color: color ?? Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}
