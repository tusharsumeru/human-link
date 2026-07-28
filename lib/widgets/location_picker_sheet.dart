import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../theme/app_theme.dart';

/// Raised when the current location can't be obtained, carrying a message fit to
/// show the user directly.
class LocationFailure implements Exception {
  const LocationFailure(this.message);
  final String message;
}

/// Reads the device's current GPS position and reverse-geocodes it to a place
/// name (OpenStreetMap). Handles the location-service + permission checks,
/// throwing [LocationFailure] with a user-facing message when it can't proceed.
/// Falls back to the raw coordinates if the reverse lookup returns nothing.
Future<String> currentLocationName() async {
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

  final pos = await Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
  );

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
