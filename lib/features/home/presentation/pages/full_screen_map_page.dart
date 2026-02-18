import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/theme/app_theme.dart';

class FullScreenMapPage extends StatefulWidget {
  final LatLng startLocation;
  final LatLng endLocation;
  final LatLng currentBusLocation;
  final String? avatarUrl;

  const FullScreenMapPage({
    super.key,
    required this.startLocation,
    required this.endLocation,
    required this.currentBusLocation,
    this.avatarUrl,
  });

  @override
  State<FullScreenMapPage> createState() => _FullScreenMapPageState();
}

class _FullScreenMapPageState extends State<FullScreenMapPage> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double distance = _calculateDistance(widget.startLocation, widget.endLocation);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: CupertinoPageScaffold(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            // Full Screen Map
            Hero(
              tag: 'trip-map',
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: widget.startLocation,
                  initialZoom: 15,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
                    subdomains: const ['a', 'b', 'c', 'd'],
                    userAgentPackageName: 'com.abdallahalawdy.fi_el_sekka',
                  ),
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: [widget.startLocation, widget.endLocation],
                        strokeWidth: 4.0,
                        color: const Color(0xFF007AFF), // Pure Blue
                        strokeCap: StrokeCap.round,
                      ),
                    ],
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: widget.endLocation,
                        width: 40,
                        height: 40,
                        child: const Icon(
                          CupertinoIcons.location_solid,
                          color: Colors.red,
                          size: 35,
                        ),
                      ),
                      Marker(
                        point: widget.startLocation,
                        width: 70,
                        height: 70,
                        child: PulsingLiveMarker(
                          controller: _pulseController,
                          imageUrl: widget.avatarUrl,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Distance Overlay (Bottom Center)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(CupertinoIcons.placemark_fill, color: AppTheme.primaryColor, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        'المسافة المتبقية: ${distance.toStringAsFixed(1)} كم',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          decoration: TextDecoration.none, // Removes the yellow underline
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Back ButtonOverlay
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Icon(
                      CupertinoIcons.back,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371;
    final double lat1Rad = point1.latitude * (3.141592653589793 / 180);
    final double lat2Rad = point2.latitude * (3.141592653589793 / 180);
    final double deltaLat = (point2.latitude - point1.latitude) * (3.141592653589793 / 180);
    final double deltaLon = (point2.longitude - point1.longitude) * (3.141592653589793 / 180);
    final double a = (math.sin(deltaLat / 2) * math.sin(deltaLat / 2)) +
        (math.cos(lat1Rad) * math.cos(lat2Rad) * math.sin(deltaLon / 2) * math.sin(deltaLon / 2));
    final double c = 2 * math.asin(math.sqrt(a));
    return earthRadius * c;
  }
}

class PulsingLiveMarker extends StatelessWidget {
  final AnimationController controller;
  final String? imageUrl;

  const PulsingLiveMarker({
    super.key,
    required this.controller,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Pulse effect
            Container(
              width: 40 + (20 * controller.value),
              height: 40 + (20 * controller.value),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF007AFF).withValues(alpha: 1 - controller.value),
                  width: 2,
                ),
              ),
            ),
            // Avatar with blue stroke
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF007AFF), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF007AFF).withValues(alpha: 0.4),
                    blurRadius: 10,
                  ),
                ],
                image: imageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(imageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
                color: imageUrl == null ? Colors.grey.shade200 : null,
              ),
              child: imageUrl == null
                  ? const Icon(CupertinoIcons.person_fill, color: Colors.grey, size: 20)
                  : null,
            ),
          ],
        );
      },
    );
  }
}
