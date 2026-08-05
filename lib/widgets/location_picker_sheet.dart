import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Raised when the current location can't be obtained, carrying a message fit to
/// show the user directly.
class LocationFailure implements Exception {
  const LocationFailure(this.message);
  final String message;
}

/// The device's current position, after the location-service and permission
/// checks. Throws [LocationFailure] with a message fit to show the user.
Future<Position> _currentPosition() async {
  final serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    throw const LocationFailure('Turn on location services to use this.');
  }
  var perm = await Geolocator.checkPermission();
  if (perm == LocationPermission.denied) {
    perm = await Geolocator.requestPermission();
  }
  if (perm == LocationPermission.denied) {
    throw const LocationFailure('Location permission was denied.');
  }
  if (perm == LocationPermission.deniedForever) {
    throw const LocationFailure(
        'Location permission is blocked. Enable it in Settings.');
  }

  return Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
  );
}

/// The device's current position as a map point — no reverse lookup, for
/// callers that want coordinates and nothing else (the invitation route starts
/// from here when the member asks it to).
///
/// Throws [LocationFailure] with a message fit to show the user.
Future<LatLng> currentLatLng() async {
  final pos = await _currentPosition();
  return LatLng(pos.latitude, pos.longitude);
}

/// Reads the device's current GPS position and reverse-geocodes it to the
/// address parts the profile stores — `{country, state, district, taluk, city,
/// area, street, pincode, location}`, the same shape the server holds under
/// `currentAddress`.
///
/// The coordinates are the device's own fix, so they are always present even
/// when the reverse lookup names nothing: a position we measured beats one
/// geocoded from text, which is why they are sent along with the parts.
///
/// Throws [LocationFailure] if the position can't be read at all.
Future<Map<String, dynamic>> currentAddressParts() async {
  final pos = await _currentPosition();
  final result = <String, dynamic>{
    'location': {'latitude': pos.latitude, 'longitude': pos.longitude},
  };

  try {
    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse'
      '?format=json&addressdetails=1&zoom=18'
      '&lat=${pos.latitude}&lon=${pos.longitude}',
    );
    final res = await http.get(uri, headers: {
      'User-Agent': 'DaivajnaSamaja/1.0 (flutter app)',
    });
    if (res.statusCode != 200) return result;

    final body = jsonDecode(res.body);
    final a = (body is Map ? body['address'] : null);
    if (a is! Map) return result;

    // Nominatim names the same rung of the hierarchy differently from place to
    // place — a city may come back as town or village, a taluk as county. Take
    // the first key that carries anything.
    String pick(List<String> keys) {
      for (final k in keys) {
        final v = (a[k] ?? '').toString().trim();
        if (v.isNotEmpty) return v;
      }
      return '';
    }

    final district = pick(['state_district', 'district', 'county']);
    // Only a county distinct from the district is really a taluk; when they are
    // the same value, Nominatim just gave us the district twice.
    final county = pick(['county']);

    result.addAll({
      'country': pick(['country']),
      'state': pick(['state']),
      'district': district,
      'taluk': county == district ? '' : county,
      'city': pick(['city', 'town', 'village', 'municipality']),
      'area': pick(['suburb', 'neighbourhood', 'city_district', 'hamlet']),
      'street': pick(['road']),
      'pincode': pick(['postcode']),
    });
  } catch (_) {
    // Keep the coordinates; the member fills in the parts by hand.
  }
  return result;
}

/// Reads the device's current GPS position and reverse-geocodes it to a place
/// name (OpenStreetMap). Handles the location-service + permission checks,
/// throwing [LocationFailure] with a user-facing message when it can't proceed.
/// Falls back to the raw coordinates if the reverse lookup returns nothing.
Future<String> currentLocationName() async {
  final pos = await _currentPosition();

  try {
    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse'
      '?format=json&zoom=14&lat=${pos.latitude}&lon=${pos.longitude}',
    );
    final res = await http.get(uri, headers: {
      'User-Agent': 'DaivajnaSamaja/1.0 (flutter app)',
    });
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final name = (data['display_name'] ?? '').toString();
      if (name.isNotEmpty) return name;
    }
  } catch (_) {
    // Fall through to coordinates below.
  }
  return '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';
}
