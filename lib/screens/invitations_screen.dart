import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../data/demo_data.dart';
import '../theme/app_theme.dart';
import '../widgets/app_shell.dart';
import '../widgets/pexels_image.dart';
import '../widgets/ui_kit.dart';

/// Invitations — ported from `src/app/invitations/page.tsx` +
/// `src/components/RouteMap.tsx` (Leaflet → flutter_map). A route planner: a
/// map up top with numbered pins for the selected families and a polyline
/// connecting the stops in order, then a selectable list of families and a
/// summary bar with a "Start Navigation" action.
class InvitationsScreen extends StatefulWidget {
  const InvitationsScreen({super.key});

  @override
  State<InvitationsScreen> createState() => _InvitationsScreenState();
}

class _InvitationsScreenState extends State<InvitationsScreen> {
  // Selected family ids in route order (matches web default selection).
  final List<String> _order = ['if7', 'if8', 'if1'];

  Map<String, dynamic> _byId(String id) =>
      kInvitationFamilies.firstWhere((f) => f['id'] == id);

  List<Map<String, dynamic>> get _orderedFamilies =>
      _order.map(_byId).toList();

  bool _isSelected(String id) => _order.contains(id);

  int _stopNumber(String id) => _order.indexOf(id) + 1;

  void _toggle(String id) {
    setState(() {
      if (_order.contains(id)) {
        _order.remove(id);
      } else {
        _order.add(id);
      }
    });
  }

  /// Sums the estimated visit minutes across selected stops ("—" => 0).
  int get _totalVisitMinutes {
    var total = 0;
    for (final f in _orderedFamilies) {
      final v = f['estimatedVisit'] as String;
      if (v != '—') {
        total += int.tryParse(v.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      }
    }
    return total;
  }

  String get _estTimeLabel {
    final m = _totalVisitMinutes;
    final h = m ~/ 60;
    final mm = m % 60;
    if (h == 0) return '${mm}m';
    return '${h}h ${mm}m';
  }

  void _startNavigation() {
    final first = _orderedFamilies.isNotEmpty ? _orderedFamilies.first : null;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          backgroundColor: AppColors.forest800,
          behavior: SnackBarBehavior.floating,
          content: Text(
            first == null
                ? 'Select at least one family to begin.'
                : 'Navigation started — first stop: ${first['name']} (${first['area']}).',
            style: body(13, weight: FontWeight.w600, color: Colors.white),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Invitations',
      currentRoute: '/invitations',
      scrollable: false,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _MapPanel(orderedFamilies: _orderedFamilies),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              children: [
                Text('SMART INVITATION PLANNER',
                    style: body(11,
                        weight: FontWeight.w700,
                        color: AppColors.gold700,
                        letterSpacing: 2)),
                const SizedBox(height: 4),
                Text('Route Planner',
                    style: display(22, color: AppColors.forest900)),
                const SizedBox(height: 4),
                Text('Select families · plan the visiting route',
                    style: body(12, color: AppColors.textMuted)),
                const SizedBox(height: 14),
                for (final fam in kInvitationFamilies)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _FamilyCard(
                      family: fam,
                      selected: _isSelected(fam['id'] as String),
                      stopNumber: _stopNumber(fam['id'] as String),
                      onToggle: () => _toggle(fam['id'] as String),
                    ),
                  ),
              ],
            ),
          ),
          _SummaryBar(
            stops: _order.length,
            estTime: _estTimeLabel,
            onStart: _startNavigation,
          ),
        ],
      ),
    );
  }
}

/// The top map: numbered pins for each selected family + a route polyline.
class _MapPanel extends StatelessWidget {
  const _MapPanel({required this.orderedFamilies});
  final List<Map<String, dynamic>> orderedFamilies;

  @override
  Widget build(BuildContext context) {
    final points = <LatLng>[
      for (final f in orderedFamilies)
        LatLng(f['lat'] as double, f['lng'] as double),
    ];

    final markers = <Marker>[
      for (var i = 0; i < orderedFamilies.length; i++)
        Marker(
          point: points[i],
          width: 34,
          height: 34,
          child: _NumberedPin(number: i + 1),
        ),
    ];

    return SizedBox(
      height: 280,
      child: Stack(
        children: [
          FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(12.97, 77.59),
              initialZoom: 11,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.daivajna.daivajna_census',
              ),
              if (points.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: points,
                      strokeWidth: 4,
                      color: AppColors.forest700,
                    ),
                  ],
                ),
              MarkerLayer(markers: markers),
            ],
          ),
          if (orderedFamilies.isEmpty)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  color: const Color(0xFFF0FBF4).withValues(alpha: 0.85),
                  alignment: Alignment.center,
                  child: Text('Select families to plan a route',
                      style: body(13,
                          weight: FontWeight.w600, color: AppColors.hint)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NumberedPin extends StatelessWidget {
  const _NumberedPin({required this.number});
  final int number;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppGradients.forest,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text('$number',
          style: body(13, weight: FontWeight.w800, color: Colors.white)),
    );
  }
}

class _FamilyCard extends StatelessWidget {
  const _FamilyCard({
    required this.family,
    required this.selected,
    required this.stopNumber,
    required this.onToggle,
  });

  final Map<String, dynamic> family;
  final bool selected;
  final int stopNumber;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final estimate = family['estimatedVisit'] as String;
    return AppCard(
      padding: const EdgeInsets.all(12),
      color: selected ? const Color(0xFFF0FBF4) : Colors.white,
      shadow: const [],
      onTap: onToggle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stop number badge (when selected) or hollow circle.
              Container(
                width: 26,
                height: 26,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  gradient: selected ? AppGradients.forest : null,
                  color: selected ? null : const Color(0xFFF3F4F6),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: selected
                    ? Text('$stopNumber',
                        style: body(12,
                            weight: FontWeight.w800, color: Colors.white))
                    : null,
              ),
              const SizedBox(width: 10),
              PexelsImage(
                url: family['photo'] as String?,
                name: family['name'] as String,
                size: 46,
                borderColor:
                    selected ? AppColors.forest700 : AppColors.border,
                borderWidth: 2,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(family['name'] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: body(14,
                            weight: FontWeight.w700,
                            color: AppColors.forest900)),
                    const SizedBox(height: 2),
                    Text(family['relation'] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: body(12, color: AppColors.textMuted)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 12, color: AppColors.hint),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            '${family['area']} · ${estimate != '—' ? estimate : 'Start'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: body(11, color: AppColors.hint),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Include-in-route toggle.
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: selected ? AppColors.forest800 : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: selected
                      ? null
                      : Border.all(color: const Color(0xFFD1D5DB), width: 2),
                ),
                child: selected
                    ? const Icon(Icons.check_rounded,
                        size: 16, color: Colors.white)
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: 36),
            child: Text(family['address'] as String,
                style: body(11, color: AppColors.textMuted, height: 1.3)),
          ),
        ],
      ),
    );
  }
}

class _SummaryBar extends StatelessWidget {
  const _SummaryBar({
    required this.stops,
    required this.estTime,
    required this.onStart,
  });

  final int stops;
  final String estTime;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: AppColors.cream,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.groups_rounded,
                        size: 15, color: AppColors.forest700),
                    const SizedBox(width: 5),
                    Text(
                        '$stops ${stops == 1 ? "stop" : "stops"}',
                        style: body(14,
                            weight: FontWeight.w700,
                            color: AppColors.forest900)),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.schedule_rounded,
                        size: 13, color: AppColors.textMuted),
                    const SizedBox(width: 5),
                    Text('≈ $estTime visiting',
                        style: body(11, color: AppColors.textMuted)),
                  ],
                ),
              ],
            ),
            const Spacer(),
            ForestButton(
              label: 'Start Navigation',
              icon: Icons.navigation_rounded,
              onPressed: onStart,
            ),
          ],
        ),
      ),
    );
  }
}
