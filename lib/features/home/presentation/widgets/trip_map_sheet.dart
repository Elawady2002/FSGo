import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../booking/domain/entities/booking_entity.dart';
import '../../../tracking/presentation/providers/tracking_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../pages/full_screen_map_page.dart';

class TripMapSheet extends ConsumerStatefulWidget {
  final BookingEntity booking;

  const TripMapSheet({super.key, required this.booking});

  @override
  ConsumerState<TripMapSheet> createState() => _TripMapSheetState();
}

class _TripMapSheetState extends ConsumerState<TripMapSheet> with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  late AnimationController _pulseController;
  LatLng? _userLocation;
  // Default locations (Madinaty & GUC)
  final LatLng _stationLocation = const LatLng(30.0910, 31.6370); // Madinaty

  bool _isMapExpanded = false; // State to toggle map visibility

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    // Start live tracking simulation
    Future.microtask(() {
      ref.read(trackingStateProvider.notifier).startTracking();
    });

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

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return;
    } 

    final position = await Geolocator.getCurrentPosition();

    if (mounted) {
      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
      });
      _fitBounds();
    }
  }

  bool _isMapReady = false;

  void _fitBounds() {
    if (_userLocation == null || !_isMapReady) return;

    final bounds = LatLngBounds.fromPoints([_userLocation!, _stationLocation]);

    _mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(80)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trackingState = ref.watch(trackingStateProvider);
    final busLocation = trackingState.busLocation;
    final user = ref.watch(authProvider).valueOrNull;
    final avatarUrl = user?.avatarUrl;

    return Material(
      type: MaterialType.transparency,
      child: Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white, // Restored to white
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
                        color: Colors.black, // Restored to black
                      ),
                    ),
                    Text(
                      'تتبع حافلتك في الوقت الفعلي',
                      style: TextStyle(
                        color: Colors.grey.shade500, // Restored to grey
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
                      color: Colors.grey.shade600, // Restored to grey
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          _buildRouteTimeline(avatarUrl),
          const SizedBox(height: 12), // Reduced gap

          // Info Panel with Driver Details - Now a floating card mirroring the Route Card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24), // Match Route Card margins
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24), // Match Route Card corners (all around)
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                // Driver Profile Section
                _buildDriverSection(),
                const SizedBox(height: 24),
                const Divider(color: AppTheme.dividerColor),
                const SizedBox(height: 24),
                _buildVehicleGallery(),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
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
                  color: AppTheme.primaryColor.withOpacity(0.2),
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

  Widget _buildRouteTimeline(String? avatarUrl) {
    return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top Section - Toggle Expansion
            GestureDetector(
              onTap: () {
                setState(() {
                  _isMapExpanded = !_isMapExpanded;
                });
              },
              behavior: HitTestBehavior.opaque,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildPathPoint(
                        label: 'موقف الركوب',
                        value: 'الرحاب كلوب',
                        isFirst: true,
                      ),
                      _buildPathPoint(
                        label: 'الجامعة',
                        value: 'الجامعة الألمانية (GUC)',
                        isLast: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Visual Path Line with Arrow
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        height: 2,
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        color: Colors.white24,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildAnimatedDot(isFirst: true),
                          _buildDirectionArrow(),
                          _buildAnimatedDot(isLast: true),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Collapsible Section (Divider + Map Kit)
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: _isMapExpanded
                  ? Column(
                      children: [
                        const SizedBox(height: 24),
                        // Dashed Divider
                        Row(
                          children: List.generate(
                            30,
                            (i) => Expanded(
                              child: Container(
                                height: 1,
                                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                                color: i.isEven
                                    ? Colors.white.withValues(alpha: 0.12)
                                    : Colors.transparent,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Map Kit Visualization
                        _buildMapKit(avatarUrl),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      );
  }

  Widget _buildMapKit(String? avatarUrl) {
    final trackingState = ref.watch(trackingStateProvider);
    final busLocation = trackingState.busLocation;
    final double distance = _userLocation != null 
        ? _calculateDistance(_userLocation!, _stationLocation)
        : 0.0;

    return Container(
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E), 
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // The Map
          Hero(
            tag: 'trip-map',
            child: AbsorbPointer(
              child: FlutterMap(
              options: MapOptions(
                onMapReady: () {
                  _isMapReady = true;
                  _fitBounds();
                },
                initialCenter: _userLocation ?? busLocation,
                initialZoom: 15,
                interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c', 'd'],
                  userAgentPackageName: 'com.abdallahalawdy.fi_el_sekka',
                ),
                if (_userLocation != null)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: [_userLocation!, _stationLocation],
                        strokeWidth: 4.0,
                        color: const Color(0xFF007AFF), // Pure Blue
                        strokeCap: StrokeCap.round,
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _stationLocation,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        CupertinoIcons.location_solid,
                        color: Colors.red,
                        size: 30,
                      ),
                    ),
                    if (_userLocation != null)
                      Marker(
                        point: _userLocation!,
                        width: 50,
                        height: 50,
                        child: PulsingLiveMarker(
                          controller: _pulseController,
                          imageUrl: avatarUrl,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            ),
          ),
          // Distance Overlay (Bottom Center)
          if (_userLocation != null)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(CupertinoIcons.placemark_fill, color: AppTheme.primaryColor, size: 12),
                      const SizedBox(width: 6),
                      Text(
                        '${distance.toStringAsFixed(1)} كم للمحطة',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.none, // Removes the yellow underline
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // Top-most GestureDetector to catch the tap instantly
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.of(context, rootNavigator: true).push(
                    PageRouteBuilder(
                      transitionDuration: const Duration(milliseconds: 400),
                      reverseTransitionDuration: const Duration(milliseconds: 400),
                      pageBuilder: (context, animation, secondaryAnimation) {
                        return FullScreenMapPage(
                          startLocation: _userLocation ?? const LatLng(30.0920, 31.6380),
                          endLocation: _stationLocation,
                          currentBusLocation: busLocation,
                          avatarUrl: avatarUrl,
                        );
                      },
                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                        final curveAnimation = CurvedAnimation(
                          parent: animation,
                          curve: Curves.fastLinearToSlowEaseIn,
                        );
                        return FadeTransition(
                          opacity: curveAnimation,
                          child: ScaleTransition(
                            scale: Tween<double>(begin: 0.95, end: 1.0).animate(curveAnimation),
                            child: child,
                          ),
                        );
                      },
                    ),
                  );
                },
                splashColor: Colors.white10,
                highlightColor: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildPathPoint({
    required String label,
    required String value,
    bool isFirst = false,
    bool isLast = false,
    bool isLadies = false,
  }) {
    final Color labelColor = isLadies
        ? Colors.white.withValues(alpha: 0.7)
        : Colors.white.withValues(alpha: 0.5);

    return Expanded(
      child: Column(
        crossAxisAlignment: isFirst
            ? CrossAxisAlignment.start
            : isLast
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: AppTheme.textTheme.bodySmall?.copyWith(
              color: labelColor,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: isFirst
                ? TextAlign.start
                : isLast
                    ? TextAlign.end
                    : TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.textTheme.bodyMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedDot({
    bool isFirst = false,
    bool isLast = false,
    bool isLadies = false,
  }) {
    final Color dotColor = isLadies ? Colors.white : AppTheme.primaryColor;

    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isFirst || isLast ? dotColor : (isLadies ? Colors.transparent : Colors.black),
        border: Border.all(
          color: dotColor,
          width: 2,
        ),
      ),
    );
  }

  Widget _buildDirectionArrow({bool isLadies = false}) {
    final Color bgColor = isLadies
        ? Colors.white.withValues(alpha: 0.2)
        : Colors.black;
    final Color borderColor = isLadies
        ? Colors.white.withValues(alpha: 0.5)
        : AppTheme.primaryColor.withValues(alpha: 0.5);
    final Color arrowColor = isLadies
        ? Colors.white
        : AppTheme.primaryColor;

    return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: bgColor,
          border: Border.all(
            color: borderColor,
            width: 1,
          ),
        ),
        child: Icon(
          CupertinoIcons.arrow_left, // Arabic is RTL, so arrow points left
          color: arrowColor,
          size: 14,
        ),
    );
  }

  Widget _buildVehicleGallery() {
    final vehicleImages = [
      'https://images.unsplash.com/photo-1544620347-c4fd4a3d5957',
      'https://images.unsplash.com/photo-1570125909232-eb263c188f7e',
      'https://images.unsplash.com/photo-1494515843206-f3117d3f51b7',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(CupertinoIcons.info_circle_fill, size: 20, color: Colors.black87),
            const SizedBox(width: 8),
            Text(
              'صور الحافلة',
              style: AppTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 180, // Increased height
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(), // Smoother scroll
            itemCount: vehicleImages.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return Container(
                width: 240, // Increased width
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.grey.shade100,
                  border: Border.all(color: Colors.grey.shade200),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.network(
                  vehicleImages[index],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Icon(CupertinoIcons.photo, color: Colors.grey, size: 30),
                  ),
                ),
              );
            },
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


