import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../models/charging_station.dart';
import '../providers/charging_provider.dart';
import '../screens/station_detail_screen.dart';
import '../services/location_service.dart';

class StationMapView extends StatefulWidget {
  const StationMapView({super.key});

  @override
  State<StationMapView> createState() => _StationMapViewState();
}

class _StationMapViewState extends State<StationMapView> {
  GoogleMapController? _controller;
  bool _mapReady = false;

  static const CameraPosition _defaultCamera = CameraPosition(
    target: LatLng(-1.286389, 36.817223),
    zoom: 12,
  );

  CameraPosition _camera = _defaultCamera;
  bool _locating = false;

  // Kenya bounds (used to detect runaway drift)
  static const double _minLat = -5.0;
  static const double _maxLat = 5.5;
  static const double _minLng = 33.5;
  static const double _maxLng = 42.0;

  bool _userIsMoving = false;
  DateTime? _lastDriftFix;

  Set<Marker> _buildMarkers(List<ChargingStation> stations) {
    final markers = <Marker>{};
    for (final s in stations) {
      final status = s.statusTier;
      final hue = status == 'available'
          ? BitmapDescriptor.hueGreen
          : (status == 'busy'
              ? BitmapDescriptor.hueOrange
              : BitmapDescriptor.hueRed);
      markers.add(
        Marker(
          markerId: MarkerId(s.id),
          position: LatLng(s.lat, s.lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(hue),
          infoWindow: InfoWindow(
            title: s.name,
            snippet:
                '${s.powerKw.toStringAsFixed(0)} kW \u00B7 ${s.connectorType}',
            onTap: () => _openStation(s),
          ),
          onTap: () => _openStation(s),
        ),
      );
    }
    return markers;
  }

  void _openStation(ChargingStation s) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StationDetailScreen(stationId: s.id),
      ),
    );
  }

  Future<void> _fitToStations(List<ChargingStation> stations) async {
    if (_controller == null || stations.isEmpty) return;
    final points = stations.map((s) => LatLng(s.lat, s.lng)).toList();
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;
    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    const pad = 0.01;
    final bounds = LatLngBounds(
      southwest: LatLng(minLat - pad, minLng - pad),
      northeast: LatLng(maxLat + pad, maxLng + pad),
    );
    await _controller!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 60));
  }

  Future<void> _goToUser() async {
    if (_controller == null || _locating) return;
    setState(() => _locating = true);
    try {
      final pos = await LocationService().getCurrentLocation();
      if (pos == null) {
        _snack('Location permission denied.');
        return;
      }
      final here = LatLng(pos.latitude, pos.longitude);
      await _controller!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: here, zoom: 14),
        ),
      );
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  void _onCameraMove(CameraPosition pos) {
    _camera = pos;
    if (_userIsMoving) return;

    final lat = pos.target.latitude;
    final lng = pos.target.longitude;
    final outside = lat < _minLat || lat > _maxLat ||
                    lng < _minLng || lng > _maxLng;
    if (!outside) return;

    final now = DateTime.now();
    if (_lastDriftFix != null &&
        now.difference(_lastDriftFix!).inMilliseconds < 800) {
      return;
    }
    _lastDriftFix = now;
    _controller?.animateCamera(
      CameraUpdate.newCameraPosition(_defaultCamera),
    );
  }

  void _onCameraMoveStarted() => _userIsMoving = true;
  void _onCameraIdle() => _userIsMoving = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChargingProvider>();
    final stations = provider.visibleStations;

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: _camera,
          markers: _buildMarkers(stations),
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          compassEnabled: false,
          mapToolbarEnabled: false,
          minMaxZoomPreference: const MinMaxZoomPreference(9, 18),
          onMapCreated: (c) {
            _controller = c;
            setState(() => _mapReady = true);
            c.setMapStyle(_darkMapStyle);
            _fitToStations(stations);
          },
          onCameraMove: _onCameraMove,
          onCameraMoveStarted: _onCameraMoveStarted,
          onCameraIdle: _onCameraIdle,
        ),

        if (!_mapReady)
          const Center(
            child: CircularProgressIndicator(color: Color(0xFF00C853)),
          ),

        // ── Green crosshair (bottom-right) — matches nav screen
        if (_mapReady)
          Positioned(
            right: 12,
            bottom: 12,
            child: GestureDetector(
              onTap: _locating ? null : _goToUser,
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Color(0xCC0A0E1A),
                  shape: BoxShape.circle,
                ),
                child: _locating
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF00C853),
                        ),
                      )
                    : const Icon(Icons.my_location,
                        color: Color(0xFF00C853), size: 20),
              ),
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