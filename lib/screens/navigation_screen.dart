import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/charging_station.dart';
import '../services/route_service.dart';

class NavigationScreen extends StatefulWidget {
  final LatLng origin;
  final ChargingStation destination;

  const NavigationScreen({
    super.key,
    required this.origin,
    required this.destination,
  });

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  GoogleMapController? _controller;
  RouteResult? _route;
  bool _loading = true;
  String? _error;

  bool _started = false;
  StreamSubscription<Position>? _positionSub;
  LatLng _currentPos = const LatLng(0, 0);

  @override
  void initState() {
    super.initState();
    _currentPos = widget.origin;
    _loadRoute();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }

  Future<void> _loadRoute() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final dest = LatLng(widget.destination.lat, widget.destination.lng);
    final result = await RouteService().getRoute(
      origin: _currentPos,
      destination: dest,
    );
    if (!mounted) return;
    setState(() {
      _route = result;
      _loading = false;
      if (result == null) {
        _error = 'Could not load route. Try again.';
      }
    });
    if (result != null && _controller != null && !_started) {
      await _controller!.animateCamera(
        CameraUpdate.newLatLngBounds(result.bounds, 60),
      );
    }
  }

  Future<void> _startNavigation() async {
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
    } catch (_) {}

    setState(() => _started = true);

    _controller?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _currentPos, zoom: 17, tilt: 45, bearing: 0),
      ),
    );

    _positionSub?.cancel();
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((pos) {
      if (!mounted) return;
      final here = LatLng(pos.latitude, pos.longitude);
      setState(() => _currentPos = here);
      _controller?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: here, zoom: 17, tilt: 45),
        ),
      );
    });
  }

  void _stopNavigation() {
    _positionSub?.cancel();
    _positionSub = null;
    setState(() => _started = false);
    if (_route != null && _controller != null) {
      _controller!.animateCamera(
        CameraUpdate.newLatLngBounds(_route!.bounds, 60),
      );
    }
  }

  void _recenter() {
    if (_currentPos.latitude == 0 && _currentPos.longitude == 0) return;
    _controller?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: _currentPos,
          zoom: _started ? 17 : 15,
          tilt: _started ? 45 : 0,
        ),
      ),
    );
  }

  double _remainingMeters() {
    final dest = LatLng(widget.destination.lat, widget.destination.lng);
    return Geolocator.distanceBetween(
      _currentPos.latitude,
      _currentPos.longitude,
      dest.latitude,
      dest.longitude,
    );
  }

  String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.round()} m';
    final km = meters / 1000;
    return '${km.toStringAsFixed(km >= 10 ? 0 : 1)} km';
  }

  Set<Polyline> _polylines() {
    if (_route == null) return {};
    return {
      Polyline(
        polylineId: const PolylineId('route'),
        points: _route!.polyline,
        color: const Color(0xFF00C853),
        width: 6,
      ),
    };
  }

  Set<Marker> _markers() {
    return {
      Marker(
        markerId: const MarkerId('__me__'),
        position: _currentPos,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'You'),
      ),
      Marker(
        markerId: const MarkerId('__dest__'),
        position: LatLng(widget.destination.lat, widget.destination.lng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(title: widget.destination.name),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final dest = LatLng(widget.destination.lat, widget.destination.lng);
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: dest, zoom: 13),
            markers: _markers(),
            polylines: _polylines(),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: false,
            mapToolbarEnabled: false,
            onMapCreated: (c) {
              _controller = c;
              c.setMapStyle(_darkMapStyle);
            },
            padding: EdgeInsets.only(bottom: _started ? 160 : 220),
          ),

          // Back button (top-left)
          Positioned(
            top: 0,
            left: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: GestureDetector(
                  onTap: () {
                    _positionSub?.cancel();
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0xCC000000),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back,
                        color: Colors.white, size: 20),
                  ),
                ),
              ),
            ),
          ),

          // Recenter FAB (bottom-right, stacked on top of info panel)
          Positioned(
            right: 16,
            bottom: _started ? 190 : 250,
            child: GestureDetector(
              onTap: _recenter,
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Color(0xCC0A0E1A),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.my_location,
                    color: Color(0xFF00C853), size: 20),
              ),
            ),
          ),

          // Bottom info panel
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                decoration: const BoxDecoration(
                  color: Color(0xF20A0E1A),
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border(
                    top: BorderSide(color: Color(0xFF1F2937), width: 1),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.destination.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.destination.address,
                      style: const TextStyle(
                        color: Color(0xFF8892B0),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_loading)
                      const Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF00C853),
                            ),
                          ),
                          SizedBox(width: 10),
                          Text('Loading route...',
                              style: TextStyle(color: Color(0xFF8892B0))),
                        ],
                      )
                    else if (_error != null)
                      Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: Color(0xFFD32F2F), size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(_error!,
                                style: const TextStyle(
                                    color: Color(0xFFD32F2F))),
                          ),
                          TextButton(
                            onPressed: _loadRoute,
                            child: const Text('Retry',
                                style:
                                    TextStyle(color: Color(0xFF00C853))),
                          ),
                        ],
                      )
                    else if (_started)
                      Row(
                        children: [
                          _metric(
                            'REMAINING',
                            _formatDistance(_remainingMeters()),
                            const Color(0xFF00C853),
                          ),
                          const SizedBox(width: 24),
                          _metric(
                            'TO',
                            widget.destination.name.split(' ').first,
                            Colors.white,
                          ),
                          const Spacer(),
                          ElevatedButton.icon(
                            onPressed: _stopNavigation,
                            icon: const Icon(Icons.stop_circle_outlined,
                                size: 16),
                            label: const Text('End'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD32F2F),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                          ),
                        ],
                      )
                    else if (_route != null)
                      Row(
                        children: [
                          _metric(
                            'ETA',
                            _route!.durationText,
                            const Color(0xFF00C853),
                          ),
                          const SizedBox(width: 24),
                          _metric(
                            'DRIVE DIST',
                            _route!.distanceText,
                            Colors.white,
                          ),
                          const Spacer(),
                          ElevatedButton.icon(
                            onPressed: _startNavigation,
                            icon: const Icon(Icons.navigation, size: 16),
                            label: const Text('Start'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00C853),
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF8892B0),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

const String _darkMapStyle = '''
[
  {"elementType": "geometry", "stylers": [{"color": "#0A0E1A"}]},
  {"elementType": "labels.text.fill", "stylers": [{"color": "#8892B0"}]},
  {"elementType": "labels.text.stroke", "stylers": [{"color": "#0A0E1A"}]},
  {"featureType": "administrative", "elementType": "geometry", "stylers": [{"color": "#1F2937"}]},
  {"featureType": "administrative.country", "elementType": "labels.text.fill", "stylers": [{"color": "#B8C7DA"}]},
  {"featureType": "poi", "elementType": "labels.text.fill", "stylers": [{"color": "#4A5568"}]},
  {"featureType": "poi.park", "elementType": "geometry", "stylers": [{"color": "#0E2A33"}]},
  {"featureType": "road", "elementType": "geometry", "stylers": [{"color": "#1F2937"}]},
  {"featureType": "road", "elementType": "geometry.stroke", "stylers": [{"color": "#111827"}]},
  {"featureType": "road", "elementType": "labels.text.fill", "stylers": [{"color": "#8892B0"}]},
  {"featureType": "road.highway", "elementType": "geometry", "stylers": [{"color": "#16344F"}]},
  {"featureType": "transit", "elementType": "labels.text.fill", "stylers": [{"color": "#4A5568"}]},
  {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#07111F"}]},
  {"featureType": "water", "elementType": "labels.text.fill", "stylers": [{"color": "#4A5568"}]}
]
''';