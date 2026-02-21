import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

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
    final ticketColor = const Color(0xFF1C1C1E);

    return Material(
      type: MaterialType.transparency,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
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
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: ticketColor,
                        borderRadius: BorderRadius.circular(32),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const SizedBox(height: 32),
                          // Badge
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: primaryColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                isSubscription ? 'تذكرة الاشتراك' : tripLabel,
                                style: GoogleFonts.cairo(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              shortId,
                              style: GoogleFonts.cairo(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // QR Code
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: QrImageView(
                                data: id ?? '',
                                version: QrVersions.auto,
                                size: 160,
                                eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
                                dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          _buildDashedDivider(),
                          const SizedBox(height: 24),
                          // Detail Grid
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    _buildDetailItem(
                                      CupertinoIcons.clock,
                                      "وقت الرحلة",
                                      formattedTime ?? "-",
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 48),
                                    _buildDetailItem(
                                      CupertinoIcons.calendar,
                                      "التاريخ",
                                      formattedDate,
                                      color: Colors.white,
                                    ),
                                  ],
                                ),
                                if (!isSubscription && (booking?.passengerCount ?? 1) > 1) ...[
                                  const SizedBox(height: 24),
                                  _buildDetailItem(
                                    CupertinoIcons.person_2,
                                    "عدد المقاعد المحجوزة",
                                    "${booking!.passengerCount} مقاعد",
                                    color: Colors.white,
                                    isFullWidth: true,
                                  ),
                                ],
                                const SizedBox(height: 24),
                                _buildDashedDivider(),
                                const SizedBox(height: 24),
                                _buildDetailItem(
                                  CupertinoIcons.bus,
                                  "خط السير",
                                  routeInfo,
                                  isFullWidth: true,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
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

  Widget _buildDashedDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(
          30,
          (index) => Expanded(
            child: Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value, {bool isFullWidth = false, Color? color}) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white.withValues(alpha: 0.3), size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.cairo(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.cairo(
              color: color ?? Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
