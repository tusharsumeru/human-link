import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../theme/app_theme.dart';

/// A labelled text field with place autocomplete powered by OpenStreetMap's
/// Nominatim search API. As the user types (debounced), matching places are
/// suggested; tapping one fills the field. Mirrors the web `fetchPlaces` call:
/// `https://nominatim.openstreetmap.org/search?format=json&q=<text>`.
class PlaceField extends StatefulWidget {
  const PlaceField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.onPlaceSelected,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;

  /// Fires with the structured Nominatim result for whichever suggestion the
  /// user tapped — `{city, state, country, countryCode, latitude, longitude}`
  /// — so a caller that needs more than free text (e.g. birthplace geocoding)
  /// doesn't have to re-search. Optional: existing callers that only want the
  /// place name in [controller] can leave this unset.
  final void Function(Map<String, dynamic> place)? onPlaceSelected;

  @override
  State<PlaceField> createState() => _PlaceFieldState();
}

class _PlaceFieldState extends State<PlaceField> {
  Timer? _debounce;
  List<Map<String, dynamic>> _suggestions = [];
  bool _loading = false;
  bool _suppress = false; // skip the search triggered by our own selection

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    if (_suppress) {
      _suppress = false;
      return;
    }
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
      // addressdetails=1 so callers that need structured city/state/country
      // (not just the display string) can use it — see [onPlaceSelected].
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?format=json&addressdetails=1&limit=6&q=${Uri.encodeComponent(q)}',
      );
      final res = await http.get(uri, headers: {
        // Nominatim requires an identifying User-Agent.
        'User-Agent': 'DaivajnaSamaja/1.0 (flutter app)',
      });
      if (!mounted) return;
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List;
        setState(() {
          _suggestions = data
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .where((e) => (e['display_name'] ?? '').toString().isNotEmpty)
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

  void _select(Map<String, dynamic> place) {
    final name = place['display_name'].toString();
    _suppress = true;
    widget.controller.text = name;
    widget.controller.selection =
        TextSelection.collapsed(offset: name.length);
    setState(() => _suggestions = []);
    FocusScope.of(context).unfocus();

    final onPlaceSelected = widget.onPlaceSelected;
    if (onPlaceSelected == null) return;
    final address = place['address'];
    final addr = address is Map ? address : const {};
    // Broader results (a district, a state) don't carry city/town/village —
    // fall back through county/state_district, then finally the searched
    // place's own name, so a selection never comes back with an empty city.
    final city = (addr['city'] ??
            addr['town'] ??
            addr['village'] ??
            addr['municipality'] ??
            addr['county'] ??
            addr['state_district'] ??
            place['name'] ??
            '')
        .toString();
    final state = (addr['state'] ?? '').toString();
    final country = (addr['country'] ?? '').toString();
    final countryCode = (addr['country_code'] ?? '').toString();
    final lat = double.tryParse((place['lat'] ?? '').toString());
    final lon = double.tryParse((place['lon'] ?? '').toString());
    onPlaceSelected({
      'displayName': name,
      'city': city,
      'state': state,
      'country': country,
      'countryCode': countryCode,
      'latitude': lat,
      'longitude': lon,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label,
            style:
                body(12, weight: FontWeight.w600, color: AppColors.forest800)),
        const SizedBox(height: 6),
        TextField(
          controller: widget.controller,
          onChanged: _onChanged,
          style: body(14, color: AppColors.ink),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: body(14, color: AppColors.hint),
            filled: true,
            fillColor: Colors.white,
            suffixIcon: _loading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : const Icon(Icons.place_outlined,
                    size: 18, color: AppColors.gold700),
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
        if (_suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
              boxShadow: AppShadows.soft,
            ),
            child: Column(
              children: [
                for (final s in _suggestions)
                  InkWell(
                    onTap: () => _select(s),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 15, color: AppColors.gold700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(s['display_name'].toString(),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: body(12, color: AppColors.ink)),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
