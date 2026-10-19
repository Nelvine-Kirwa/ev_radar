import 'dart:math' as math;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/charging_station.dart';
import '../models/trip_plan.dart';
import '../services/route_service.dart';
import '../utils/connector_utils.dart';

/// EV route planner: computes viable multi-stop plans, battery state per leg,
/// and depletion warnings.
class BatteryRoutePlannerService {
  // ── Vehicle profile (hardcoded until SOC slider is wired) ──
  static const double usableBatteryKwh = 60.0;
  static const double efficiencyKmPerKwh = 6.5;
  static const int safetyBufferSoc = 5;
  static const int minArrivalSoc = 10;
  static const int chargeTargetSoc = 80;
  static const double avgHwySpeedKmh = 90.0;
  static const int maxStops = 5;

  // ── Station filtering ──
  static const double maxDetourKm = 5.0;

  final RouteService _routeService = RouteService();

  Future<TripPlan> planRoute({
    required LatLng origin,
    required LatLng destination,
    required String originName,
    required String destinationName,
    required String vehicleName,
    required int startSoc,
    required List<ChargingStation> allStations,
    required List<String> carConnectorTypes,
  }) async {
    // ── 1) Total route distance ──
    final route = await _routeService.getRoute(
      origin: origin,
      destination: destination,
    );
    final totalKm = route != null
        ? route.distanceMeters / 1000.0
        : _haversineRoadKm(origin, destination);
    final totalDurationMin = route != null
        ? (route.durationSeconds / 60.0).round()
        : (totalKm / avgHwySpeedKmh * 60).round();

    // ── 2) Filter compatible + reachable-along-route stations ──
    final polyline = route?.polyline;
    final candidates = <_StationProjection>[];

    for (final s in allStations) {
      if (s.status.toLowerCase() == 'offline') continue;
      if (!ConnectorUtils.carMatchesStation(
        carConnectors: carConnectorTypes,
        stationConnector: s.connectorType,
      )) continue;

      final proj = _projectOntoRoute(
        LatLng(s.lat, s.lng),
        polyline,
        origin,
        destination,
      );
      if (proj.detourKm > maxDetourKm) continue;
      if (proj.alongKm > totalKm + 1.0) continue;  // beyond destination

      candidates.add(_StationProjection(
        station: s,
        alongKm: proj.alongKm,
        detourKm: proj.detourKm,
      ));
    }

    // Sort along-route ascending
    candidates.sort((a, b) => a.alongKm.compareTo(b.alongKm));

    // ── 3) Greedy forward-chaining: build legs ──
    final legs = <ChargingStop>[];
    int currentSoc = startSoc;
    double currentPosKm = 0.0;
    int currentLegStartSoc = startSoc;
    bool viabilityFailed = false;
    String? failureReason;
    int lastStopIdx = -1;

    for (int iter = 0; iter < maxStops; iter++) {
      final maxRangeKm = _maxRangeKm(currentSoc);
      final remainingKm = totalKm - currentPosKm;

      // Destination reachable from current position?
      if (remainingKm <= maxRangeKm - _safetyMarginKm()) {
        break;
      }

      // Prefer stations where we arrive with a comfortable buffer.
      // Strategy: in order, try arrival thresholds [15%, 10%, 5%].
      // Within the same threshold, pick the furthest reachable.
      const preferredArrivalSoc = [15, 10, 5];
      _StationProjection? bestStop;
      int bestIdx = -1;

      for (final minSoc in preferredArrivalSoc) {
        for (int i = lastStopIdx + 1; i < candidates.length; i++) {
          final c = candidates[i];
          if (c.alongKm <= currentPosKm + 1.0) continue;
          final distFromHere = c.alongKm - currentPosKm;
          if (distFromHere > maxRangeKm - _safetyMarginKm()) break;

          // Estimate arrival SOC at this stop
          final socDrop = _socDrop(distFromHere);
          final arrivalSoc = currentSoc - socDrop;
          if (arrivalSoc < minSoc) continue;  // too tight, skip

          bestStop = c;
          bestIdx = i;
        }
        if (bestStop != null) break;  // found a good one at this threshold
      }

      if (bestStop == null) {
        viabilityFailed = true;
        final maxLegKm = maxRangeKm - _safetyMarginKm();
        failureReason =
            'Cannot reach ' + destinationName.split(',').first +
            ' on ' + currentSoc.toString() + '% battery. '
            'Longest rechargeable leg is ' + maxLegKm.toStringAsFixed(0) +
            ' km. Charge before departing.';
        break;
      }

      // Add this stop
      final kmToStop = bestStop.alongKm - currentPosKm;
      final socDrop = _socDrop(kmToStop);
      final arrivalSoc = (currentSoc - socDrop).clamp(0, 100);
      final chargeTo = chargeTargetSoc.clamp(arrivalSoc, 100);
      final minutes = _chargeMinutes(arrivalSoc, chargeTo, bestStop.station.powerKw);

      legs.add(ChargingStop(
        stationName: bestStop.station.name,
        location: bestStop.station.neighborhood,
        powerDetail:
            '${bestStop.station.connectorType} - ${bestStop.station.powerKw.toStringAsFixed(0)} kW',
        arrivalSoc: arrivalSoc,
        chargeDurationMin: minutes,
        departureSoc: chargeTo,
        estimatedCostKsh:
            (_chargeCostKwh(arrivalSoc, chargeTo) * bestStop.station.pricePerKwhKsh).round(),
      ));

      currentSoc = chargeTo;
      currentPosKm = bestStop.alongKm;
      currentLegStartSoc = chargeTo;
      lastStopIdx = bestIdx;
    }

    // ── 4) Final leg SOC ──
    final finalLegKm = totalKm - currentPosKm;
    final finalArrivalSoc =
        (currentLegStartSoc - _socDrop(finalLegKm)).clamp(0, 100);

    // ── 5) Determine viability ──
    final arrivalUnderBuffer = finalArrivalSoc < minArrivalSoc;
    final viable = !viabilityFailed && !arrivalUnderBuffer;
    final warning = viabilityFailed
        ? failureReason
        : arrivalUnderBuffer
            ? 'Arrival battery is only ' + finalArrivalSoc.toString() +
                '%. Please add an extra charging stop.'
            : null;

    // ── 6) Build TripPlan ──
    final totalChargingMin =
        legs.fold<int>(0, (sum, s) => sum + s.chargeDurationMin);
    final energyNeededKwh = math.max(
      0.0,
      totalKm / efficiencyKmPerKwh,
    ).round();

    final timeline = <TimelineStep>[
      TimelineStep(
        title: 'Depart ' + originName.split(' - ').last,
        subtitle: startSoc.toString() + '% SOC',
      ),
      for (final stop in legs)
        TimelineStep(
          title: stop.stationName,
          subtitle: 'Charging stop, ' + stop.chargeDurationMin.toString() +
              ' min - arrive ' + stop.arrivalSoc.toString() +
              '%, depart ' + stop.departureSoc.toString() + '%',
          isCharging: true,
        ),
      TimelineStep(
        title: 'Arrive ' + destinationName.split(',').first,
        subtitle: finalArrivalSoc.toString() + '% SOC remaining',
        isArrival: true,
      ),
    ];

    final totalMin = totalDurationMin + totalChargingMin;
    final h = totalMin ~/ 60;
    final m = totalMin % 60;

    return TripPlan(
      origin: originName,
      destination: destinationName,
      vehicleName: vehicleName,
      startBatteryPercent: startSoc,
      departureLabel: 'Departs now',
      distanceKm: totalKm.round(),
      durationLabel: '${h}h ${m}m',
      stopsCount: legs.length,
      totalChargingMin: totalChargingMin,
      arrivalBatteryPercent: finalArrivalSoc,
      energyNeededKwh: energyNeededKwh,
      routeViable: viable,
      depletionWarning: warning,
      elevationProfile: const [],
      totalAscentLabel: '',
      totalDescentLabel: '',
      chargingStops: legs,
      timelineSteps: timeline,
      waypointLeft: originName.split(' - ').last,
      waypointMid: legs.isNotEmpty ? legs.first.stationName : '',
      waypointRight: destinationName.split(',').first,
    );
  }

  // ── Helpers ──

  double _maxRangeKm(int soc) => usableBatteryKwh * efficiencyKmPerKwh * (soc / 100.0);

  double _safetyMarginKm() => _maxRangeKm(safetyBufferSoc);

  int _socDrop(double km) => (km / efficiencyKmPerKwh / usableBatteryKwh * 100).round();

  double _chargeCostKwh(int fromSoc, int toSoc) => (toSoc - fromSoc) / 100.0 * usableBatteryKwh;

  int _chargeMinutes(int fromSoc, int toSoc, double powerKw) {
    if (powerKw <= 0) return 30;
    return (_chargeCostKwh(fromSoc, toSoc) / powerKw * 60).round();
  }

  double _haversineRoadKm(LatLng a, LatLng b) =>
      _haversineKm(a, b) * 1.2;

  double _haversineKm(LatLng a, LatLng b) {
    const r = 6371.0;
    final dLat = _toRad(b.latitude - a.latitude);
    final dLng = _toRad(b.longitude - a.longitude);
    final s = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(a.latitude)) *
            math.cos(_toRad(b.latitude)) *
            math.sin(dLng / 2) * math.sin(dLng / 2);
    return r * 2 * math.atan2(math.sqrt(s), math.sqrt(1 - s));
  }

  double _toRad(double d) => d * math.pi / 180.0;

  /// Projects a station onto the route polyline. Returns the along-route
  /// distance (km from origin) and the perpendicular detour (km from route).
  ///
  /// If polyline is null/empty, falls back to straight-line projection.
  _Projection _projectOntoRoute(
      LatLng station, List<LatLng>? polyline, LatLng origin, LatLng destination) {
    if (polyline == null || polyline.length < 2) {
      // Fallback: project onto straight line origin→dest
      final segKm = _haversineKm(origin, destination);
      final toStationKm = _haversineKm(origin, station);
      final detourKm = _pointToSegmentKm(station, origin, destination);
      // Approximate along: cos-law ratio
      final cosA = ((toStationKm * toStationKm + segKm * segKm) -
              (segKm * _haversineKm(destination, station) * 2) / 2) /
          (2 * toStationKm * segKm);
      final ratio = cosA.clamp(0.0, 1.0);
      return _Projection(alongKm: ratio * segKm, detourKm: detourKm);
    }

    double cumulative = 0.0;
    double bestDetour = double.infinity;
    double bestAlong = 0.0;

    for (int i = 1; i < polyline.length; i++) {
      final a = polyline[i - 1];
      final b = polyline[i];
      final segKm = _haversineKm(a, b);
      if (segKm < 0.001) continue;

      // Project station onto segment a→b
      final proj = _projectPointOntoSegmentKm(station, a, b);
      if (proj.detourKm < bestDetour) {
        bestDetour = proj.detourKm;
        bestAlong = cumulative + segKm * proj.tRatio;
      }
      cumulative += segKm;
    }

    return _Projection(alongKm: bestAlong, detourKm: bestDetour);
  }

  _Projection _projectPointOntoSegmentKm(LatLng p, LatLng a, LatLng b) {
    // Treat as flat-earth for small distances
    final lat0 = _toRad(a.latitude);
    final x_p = _toRad(p.longitude - a.longitude) * math.cos(lat0);
    final y_p = _toRad(p.latitude - a.latitude);
    final x_b = _toRad(b.longitude - a.longitude) * math.cos(lat0);
    final y_b = _toRad(b.latitude - a.latitude);

    final segLen2 = x_b * x_b + y_b * y_b;
    double t = 0.0;
    if (segLen2 > 0) {
      t = ((x_p * x_b + y_p * y_b) / segLen2).clamp(0.0, 1.0);
    }
    final projX = t * x_b;
    final projY = t * y_b;
    final dx = x_p - projX;
    final dy = y_p - projY;
    final degDist = math.sqrt(dx * dx + dy * dy);
    return _Projection(
      alongKm: 0, // computed by caller
      detourKm: degDist * 111.32,
      tRatio: t,
    );
  }

  double _pointToSegmentKm(LatLng p, LatLng a, LatLng b) {
    final ab = _haversineKm(a, b);
    if (ab < 0.001) return _haversineKm(p, a);
    final ap = _haversineKm(a, p);
    final bp = _haversineKm(p, b);
    if (ap * ap + ab * ab < bp * bp) return ap;
    if (bp * bp + ab * ab < ap * ap) return bp;
    final s = (ap + bp + ab) / 2;
    final area = math.sqrt(s * (s - ap) * (s - bp) * (s - ab));
    return 2 * area / ab;
  }
}

class _StationProjection {
  final ChargingStation station;
  final double alongKm;
  final double detourKm;
  const _StationProjection({
    required this.station,
    required this.alongKm,
    required this.detourKm,
  });
}

class _Projection {
  final double alongKm;
  final double detourKm;
  final double tRatio;
  const _Projection({
    required this.alongKm,
    required this.detourKm,
    this.tRatio = 0,
  });
}