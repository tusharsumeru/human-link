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
  });

  final String label;
  final TextEditingController controller;
  final String? hint;

  @override
  State<PlaceField> createState() => _PlaceFieldState();
}

class _PlaceFieldState extends State<PlaceField> {
  Timer? _debounce;
  List<String> _suggestions = [];
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
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?format=json&addressdetails=0&limit=6&q=${Uri.encodeComponent(q)}',
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

  void _select(String place) {
    _suppress = true;
    widget.controller.text = place;
    widget.controller.selection =
        TextSelection.collapsed(offset: place.length);
    setState(() => _suggestions = []);
    FocusScope.of(context).unfocus();
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
                            child: Text(s,
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
