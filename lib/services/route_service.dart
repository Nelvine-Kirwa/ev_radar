import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

/// Result of a routing call.
class RouteResult {
  final List<LatLng> polyline;
  final String distanceText;   // e.g. "6.4 km"
  final String durationText;   // e.g. "12 min"
  final int distanceMeters;
  final int durationSeconds;
  final LatLngBounds bounds;

  const RouteResult({
    required this.polyline,
    required this.distanceText,
    required this.durationText,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.bounds,
  });
}

/// Free routing via the public OSRM demo server.
/// No API key, no billing.
/// Docs: http://project-osrm.org/docs/v5.24.0/api/
class RouteService {
  static const String _base =
      'https://router.project-osrm.org/route/v1/driving';

  Future<RouteResult?> getRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    // OSRM wants lng,lat (not lat,lng)
    final coords =
        '${origin.longitude},${origin.latitude};${destination.longitude},${destination.latitude}';

    final uri = Uri.parse('$_base/$coords').replace(queryParameters: {
      'overview': 'full',
      'geometries': 'polyline',
      'steps': 'false',
    });

    try {
      final res = await http.get(uri);
      if (res.statusCode != 200) {
        debugPrint('[RouteService/OSRM] HTTP ${res.statusCode}');
        return null;
      }

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final code = data['code'] as String?;
      if (code != 'Ok') {
        debugPrint('[RouteService/OSRM] code=$code');
        return null;
      }

      final routes = data['routes'] as List?;
      if (routes == null || routes.isEmpty) return null;
      final route = routes.first as Map<String, dynamic>;

      final geometry = route['geometry'] as String?;
      if (geometry == null) return null;

      final points = _decodePolyline(geometry);
      if (points.isEmpty) return null;

      final distanceMeters = (route['distance'] as num?)?.toInt() ?? 0;
      final durationSeconds = (route['duration'] as num?)?.toInt() ?? 0;

      // Compute bounds from polyline
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
      final bounds = LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      );

      return RouteResult(
        polyline: points,
        distanceText: _formatDistance(distanceMeters),
        durationText: _formatDuration(durationSeconds),
        distanceMeters: distanceMeters,
        durationSeconds: durationSeconds,
        bounds: bounds,
      );
    } catch (e) {
      debugPrint('[RouteService/OSRM] Error: $e');
      return null;
    }
  }

  // -----------------------------------------------------------
  // Helpers — OSRM returns Google-encoded polyline strings
  // -----------------------------------------------------------
  List<LatLng> _decodePolyline(String encoded) {
    final points = <LatLng>[];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int shift = 0;
      int result = 0;
      int b;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dLat = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lat += dLat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dLng = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lng += dLng;

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return points;
  }

  String _formatDistance(int meters) {
    if (meters < 1000) return '${meters} m';
    final km = meters / 1000.0;
    return '${km.toStringAsFixed(km >= 10 ? 0 : 1)} km';
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final min = (seconds / 60).round();
    if (min < 60) return '$min min';
    final h = min ~/ 60;
    final m = min % 60;
    return '${h}h ${m}m';
  }
}