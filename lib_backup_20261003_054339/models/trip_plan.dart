class ChargingStop {
  final String stationName;
  final String location;
  final String powerDetail;
  final int arrivalSoc;
  final int chargeDurationMin;
  final int departureSoc;
  final int estimatedCostKsh;

  const ChargingStop({
    required this.stationName,
    required this.location,
    required this.powerDetail,
    required this.arrivalSoc,
    required this.chargeDurationMin,
    required this.departureSoc,
    required this.estimatedCostKsh,
  });
}

class TimelineStep {
  final String title;
  final String subtitle;
  final bool isCharging;
  final bool isArrival;

  const TimelineStep({
    required this.title,
    required this.subtitle,
    this.isCharging = false,
    this.isArrival = false,
  });
}

class ElevationPoint {
  final double progress; // 0..1
  final double elevationM;
  final double batteryPercent; // 0..100

  const ElevationPoint({
    required this.progress,
    required this.elevationM,
    required this.batteryPercent,
  });
}

class TripPlan {
  final String origin;
  final String destination;
  final String vehicleName;
  final int startBatteryPercent;
  final String departureLabel;
  final int distanceKm;
  final String durationLabel;
  final int stopsCount;
  final int totalChargingMin;
  final int arrivalBatteryPercent;
  final int energyNeededKwh;
  final bool routeViable;
  final List<ElevationPoint> elevationProfile;
  final String totalAscentLabel;
  final String totalDescentLabel;
  final List<ChargingStop> chargingStops;
  final List<TimelineStep> timelineSteps;
  final String waypointLeft;
  final String waypointMid;
  final String waypointRight;

  const TripPlan({
    required this.origin,
    required this.destination,
    required this.vehicleName,
    required this.startBatteryPercent,
    required this.departureLabel,
    required this.distanceKm,
    required this.durationLabel,
    required this.stopsCount,
    required this.totalChargingMin,
    required this.arrivalBatteryPercent,
    required this.energyNeededKwh,
    required this.routeViable,
    required this.elevationProfile,
    required this.totalAscentLabel,
    required this.totalDescentLabel,
    required this.chargingStops,
    required this.timelineSteps,
    required this.waypointLeft,
    required this.waypointMid,
    required this.waypointRight,
  });

  int get estimatedTotalCostKsh =>
      chargingStops.fold(0, (sum, s) => sum + s.estimatedCostKsh);
}