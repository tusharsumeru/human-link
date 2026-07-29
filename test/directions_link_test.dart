import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:daivajna_census/data/invitation_member.dart';

/// The maps link is the hand-off between the planned route and turn-by-turn
/// navigation: if the parameters are wrong the route silently reorders itself
/// or drops stops, which is not something a map screenshot would show.
void main() {
  final home = LatLng(13.0228, 77.5978);
  final stops = [
    LatLng(12.9906, 77.5512), // Rajajinagar
    LatLng(12.9419, 77.5732), // Basavanagudi
    LatLng(12.9784, 77.6408), // Indiranagar
  ];

  test('keeps the planned order: last stop is the destination', () {
    final link = directionsLink(origin: home, stops: stops);
    final q = link.url.queryParameters;

    expect(q['origin'], '13.022800,77.597800');
    expect(q['destination'], '12.978400,77.640800');
    expect(q['waypoints'], '12.990600,77.551200|12.941900,77.573200');
    expect(q['travelmode'], 'driving');
    expect(link.dropped, 0);
  });

  test('works without an origin — maps starts from where the phone is', () {
    final link = directionsLink(stops: stops);
    expect(link.url.queryParameters.containsKey('origin'), isFalse);
    expect(link.url.queryParameters['destination'], '12.978400,77.640800');
  });

  test('a single stop needs no waypoints', () {
    final link = directionsLink(origin: home, stops: [stops.first]);
    expect(link.url.queryParameters.containsKey('waypoints'), isFalse);
    expect(link.url.queryParameters['destination'], '12.990600,77.551200');
  });

  test('truncates past the ten stops the URL scheme carries', () {
    final many = [
      for (var i = 0; i < 14; i++) LatLng(12.9 + i / 100, 77.5 + i / 100),
    ];
    final link = directionsLink(origin: home, stops: many);

    expect(link.dropped, 4);
    // 9 waypoints + 1 destination = the 10 that made it.
    expect(link.url.queryParameters['waypoints']!.split('|').length, 9);
    expect(link.url.queryParameters['destination'],
        '${many[9].latitude.toStringAsFixed(6)},'
        '${many[9].longitude.toStringAsFixed(6)}');
  });
}
