import '../models/trip_plan.dart';

class TripPlannerService {
  /// Returns a hardcoded demo plan for Nairobi -> Mombasa.
  /// Swap the internals for a real routing API when ready.
  TripPlan getNairobiToMombasa() {
    return const TripPlan(
      origin: 'Current Location - Kilimani, Nairobi',
      destination: 'Mombasa, Mombasa County',
      vehicleName: 'Tesla Model 3',
      startBatteryPercent: 78,
      departureLabel: 'Departs now',
      distanceKm: 485,
      durationLabel: '5h 45m',
      stopsCount: 1,
      totalChargingMin: 35,
      arrivalBatteryPercent: 18,
      energyNeededKwh: 58,
      routeViable: true,
      elevationProfile: [
        ElevationPoint(progress: 0.00, elevationM: 1795, batteryPercent: 78),
        ElevationPoint(progress: 0.15, elevationM: 1500, batteryPercent: 70),
        ElevationPoint(progress: 0.30, elevationM: 1100, batteryPercent: 60),
        ElevationPoint(progress: 0.45, elevationM: 800, batteryPercent: 48),
        ElevationPoint(progress: 0.52, elevationM: 620, batteryPercent: 42),
        ElevationPoint(progress: 0.60, elevationM: 600, batteryPercent: 80),
        ElevationPoint(progress: 0.75, elevationM: 400, batteryPercent: 62),
        ElevationPoint(progress: 0.88, elevationM: 200, batteryPercent: 38),
        ElevationPoint(progress: 1.00, elevationM: 50, batteryPercent: 18),
      ],
      totalAscentLabel: 'Total ascent 340m',
      totalDescentLabel: 'Total descent 2,085m',
      chargingStops: [
        ChargingStop(
          stationName: 'Mtito Andei Charging Hub',
          location: 'Mombasa Road',
          powerDetail: '22 kW AC + 50 kW DC',
          arrivalSoc: 42,
          chargeDurationMin: 35,
          departureSoc: 80,
          estimatedCostKsh: 1740,
        ),
      ],
      timelineSteps: [
        TimelineStep(
          title: 'Depart Nairobi',
          subtitle: 'Kilimani, 78% SOC',
        ),
        TimelineStep(
          title: 'Mtito Andei',
          subtitle: 'Charging stop, 35 min',
          isCharging: true,
        ),
        TimelineStep(
          title: 'Mombasa Road',
          subtitle: 'Continue to destination',
        ),
        TimelineStep(
          title: 'Arrive Mombasa',
          subtitle: '18% SOC remaining',
          isArrival: true,
        ),
      ],
      waypointLeft: 'Nairobi (1,795m)',
      waypointMid: 'Mtito Andei (600m)',
      waypointRight: 'Mombasa (50m)',
    );
  }
}