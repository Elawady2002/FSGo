import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../booking/domain/entities/booking_entity.dart';
import '../../../tracking/presentation/providers/tracking_provider.dart';
import 'package:my_app/l10n/app_localizations.dart';
import '../../../booking/presentation/widgets/transfer_ticket_sheet.dart';

class TripMapSheet extends ConsumerStatefulWidget {
  final BookingEntity booking;

  const TripMapSheet({super.key, required this.booking});

  @override
  ConsumerState<TripMapSheet> createState() => _TripMapSheetState();
}

class _TripMapSheetState extends ConsumerState<TripMapSheet> {
  final MapController _mapController = MapController();
  LatLng? _userLocation;
  // Default locations (Madinaty & GUC)
  final LatLng _stationLocation = const LatLng(30.0910, 31.6370); // Madinaty

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    // Start live tracking simulation
    Future.microtask(() {
      ref.read(trackingStateProvider.notifier).startTracking();
    });
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      // Fixed location near Madinaty for testing
      _userLocation = const LatLng(30.0920, 31.6380);
    });

    _fitBounds();
  }

  void _fitBounds() {
    if (_userLocation == null) return;

    final bounds = LatLngBounds.fromPoints([_userLocation!, _stationLocation]);

    _mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(80)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trackingState = ref.watch(trackingStateProvider);
    final busLocation = trackingState.busLocation;

    return Container(
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

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مسار الرحلة',
                      style: AppTheme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      'تتبع حافلتك في الوقت الفعلي',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
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
              ],
            ),
          ),

          // Map
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(0),
              ),
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _stationLocation,
                  initialZoom: 15,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
                    userAgentPackageName: 'com.abdallahalawdy.my_app',
                  ),
                  // Route Path from Bus to Station
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: [busLocation, _stationLocation],
                        strokeWidth: 5.0,
                        color: const Color(0xFF4285F4),
                        strokeCap: StrokeCap.round,
                        strokeJoin: StrokeJoin.round,
                      ),
                    ],
                  ),
                  MarkerLayer(
                    markers: [
                      // Station Marker
                      Marker(
                        point: _stationLocation,
                        width: 60,
                        height: 60,
                        alignment: Alignment.topCenter,
                        child: _buildGooglePin(
                          icon: CupertinoIcons.location_solid,
                          color: const Color(0xFFEA4335),
                          label: 'المحطة',
                        ),
                      ),
                      // Bus/Driver Marker (Live)
                      Marker(
                        point: busLocation,
                        width: 50,
                        height: 50,
                        child: _buildBusMarker(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Info Panel with Driver Details
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                // Driver Profile Section
                _buildDriverSection(),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 24),
                _buildInfoRow(
                  icon: CupertinoIcons.location_solid,
                  color: Colors.red,
                  title: 'نقطة التجمع',
                  subtitle: 'محطة مدينتي الرئيسية',
                ),
                const SizedBox(height: 16),
                _buildInfoRow(
                  icon: CupertinoIcons.bus,
                  color: AppTheme.primaryColor,
                  title: 'مسافة السائق',
                  subtitle:
                      '${_calculateDistance(busLocation, _stationLocation).toStringAsFixed(2)} كم تقريباً - ${trackingState.estimatedArrival}',
                ),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildDriverSection() {
    return Row(
      children: [
        // Driver Avatar with Badge
        Stack(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.2),
                  width: 2,
                ),
                image: const DecorationImage(
                  image: NetworkImage('https://i.pravatar.cc/150?u=driver'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.checkmark_seal_fill,
                  color: Color(0xFF4285F4),
                  size: 16,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'أحمد محمد',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB300).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          CupertinoIcons.star_fill,
                          color: Color(0xFFFFB300),
                          size: 12,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '4.9',
                          style: TextStyle(
                            color: Color(0xFFFFB300),
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'سائق موثق بالكامل',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // Transfer Button
        GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => TransferTicketSheet(booking: widget.booking),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              CupertinoIcons.arrow_right_arrow_left,
              color: AppTheme.primaryColor,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBusMarker() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Icon(CupertinoIcons.bus, color: Colors.black, size: 24),
    );
  }

  Widget _buildGooglePin({
    required IconData icon,
    required Color color,
    required String label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Icon(
          CupertinoIcons.location_solid,
          color: color,
          size: 40,
          shadows: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371;

    final double lat1Rad = point1.latitude * (math.pi / 180);
    final double lat2Rad = point2.latitude * (math.pi / 180);
    final double deltaLat =
        (point2.latitude - point1.latitude) * (math.pi / 180);
    final double deltaLon =
        (point2.longitude - point1.longitude) * (math.pi / 180);

    final double a =
        math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1Rad) *
            math.cos(lat2Rad) *
            math.sin(deltaLon / 2) *
            math.sin(deltaLon / 2);
    final double c = 2 * math.asin(math.sqrt(a));

    return earthRadius * c;
  }
}
