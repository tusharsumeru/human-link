import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../theme/app_theme.dart';

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

/// Instagram-style location picker. Opens a bottom sheet, searches places as the
/// user types (OpenStreetMap Nominatim, debounced), and returns the selected
/// place name — or null if the user backs out.
Future<String?> pickLocation(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.cream,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (_) => const _LocationPickerSheet(),
  );
}

class _LocationPickerSheet extends StatefulWidget {
  const _LocationPickerSheet();

  @override
  State<_LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<_LocationPickerSheet> {
  final _controller = TextEditingController();
  Timer? _debounce;
  List<String> _suggestions = [];
  bool _loading = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    final q = value.trim();
    if (q.length < 3) {
      setState(() {
        _suggestions = [];
        _loading = false;
      });
      return;
    }
    // Nominatim asks for <=1 request/sec, so debounce keystrokes.
    _debounce = Timer(const Duration(milliseconds: 450), () => _fetch(q));
  }

  Future<void> _fetch(String q) async {
    setState(() => _loading = true);
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?format=json&addressdetails=0&limit=8&q=${Uri.encodeComponent(q)}',
      );
      final res = await http.get(uri, headers: {
        'User-Agent': 'DaivajnaSamaja/1.0 (flutter app)',
      });
      if (!mounted) return;
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List;
        setState(() {
          _suggestions = data
              .map((e) => (e['display_name'] ?? '').toString())
              .where((s) => s.isNotEmpty)
              .toList();
          _loading = false;
        });
      } else {
        setState(() {
          _suggestions = [];
          _loading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _suggestions = [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final query = _controller.text.trim();
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Text('Add location',
                      style: display(18, color: AppColors.forest900)),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _controller,
                autofocus: true,
                onChanged: _onChanged,
                style: body(14, color: AppColors.ink),
                decoration: InputDecoration(
                  hintText: 'Search villages, temples, cities…',
                  hintStyle: body(14, color: AppColors.hint),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon:
                      const Icon(Icons.search_rounded, color: AppColors.hint),
                  suffixIcon: _loading
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : null,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.forest700, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    // Let the user attach exactly what they typed, even if it
                    // isn't in the suggestions (a hall name, a family home…).
                    if (query.isNotEmpty)
                      _Row(
                        icon: Icons.add_location_alt_outlined,
                        text: 'Use "$query"',
                        onTap: () => Navigator.of(context).pop(query),
                      ),
                    for (final s in _suggestions)
                      _Row(
                        icon: Icons.location_on_outlined,
                        text: s,
                        onTap: () => Navigator.of(context).pop(s),
                      ),
                    if (query.length < 3 && _suggestions.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: Text('Type to search for a place',
                              style: body(13, color: AppColors.hint)),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.text, required this.onTap});
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.gold700),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: body(13, color: AppColors.ink)),
            ),
          ],
        ),
      ),
    );
  }
}
