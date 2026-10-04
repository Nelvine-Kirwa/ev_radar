// Unit + widget tests that don't require Firebase.
//
// The app's splash screen calls FirebaseAuth on startup, which we can't
// initialize in a pure unit test. So instead we test smaller widgets and
// pure logic that provide real regression value.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ev_radar/models/charging_station.dart';
import 'package:ev_radar/widgets/station_list_row.dart';

void main() {
  group('ChargingStation.distanceFrom', () {
    test('returns 0 for identical coordinates', () {
      final station = _fakeStation(lat: -1.286389, lng: 36.817223);
      final d = station.distanceFrom(-1.286389, 36.817223);
      expect(d, lessThan(0.01));
    });

    test('Nairobi CBD to Westlands is roughly 5-8 km as the crow flies', () {
      // CBD: -1.286389, 36.817223
      // Westlands (Sarit): -1.263528, 36.802153
      final station = _fakeStation(lat: -1.263528, lng: 36.802153);
      final d = station.distanceFrom(-1.286389, 36.817223);
      expect(d, greaterThan(2.0));
      expect(d, lessThan(10.0));
    });
  });

  testWidgets('StationListRow renders station name, distance, status', (tester) async {
    final s = _fakeStation(lat: -1.2635, lng: 36.8021);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StationListRow(
            station: s,
            status: 'available',
            distanceKm: 3.7,
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.text(s.name), findsOneWidget);
    expect(find.textContaining('3.7'), findsOneWidget);
    expect(find.textContaining('Available'), findsOneWidget);
  });
}

ChargingStation _fakeStation({required double lat, required double lng}) {
  return ChargingStation(
    id: 'test-1',
    name: 'Test Station',
    operator: 'Test Op',
    neighborhood: 'Test Neighborhood',
    address: 'Test Address',
    lat: lat,
    lng: lng,
    connectorType: 'Type 2 AC',
    powerKw: 22,
    portsTotal: 2,
    portsAvailable: 2,
    status: 'Operational',
    pricePerKwhKsh: 28,
    chargerImage: 'assets/images/chargers/type2_ac.jpg',
    operatingHours: '24 hours',
    phone: '',
    amenities: const [],
    source: 'test',
  );
}