import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/api_client.dart';
import '../data/invitation_member.dart';
import '../data/repository.dart';
import '../theme/app_theme.dart';
import '../widgets/app_shell.dart';
import '../widgets/location_picker_sheet.dart';
import '../widgets/pexels_image.dart';
import '../widgets/ui_kit.dart';

/// Invitations — a route planner for hand-delivering invitations.
///
/// `GET /api/user/map` lists the members who can be visited: everyone whose
/// current address has been geocoded (the server does that with OpenStreetMap
/// when they save it), nearest to you first. Pick the families to invite and
/// `POST /api/user/route` works out the order to visit them in — the shortest
/// round from where you are, ending at the last family rather than back home.
///
/// The order stops are *picked* in is not the order they are visited in: the
/// numbers on the pins come from the plan, not from the taps.
///
/// Ported from `src/app/invitations/page.tsx` + `src/components/RouteMap.tsx`
/// (Leaflet → flutter_map).
class InvitationsScreen extends StatefulWidget {
  const InvitationsScreen({super.key});

  @override
  State<InvitationsScreen> createState() => _InvitationsScreenState();
}

class _InvitationsScreenState extends State<InvitationsScreen> {
  final _mapController = MapController();
  final _searchCtrl = TextEditingController();

  bool _loading = true;
  String _error = '';
  bool _mapReady = false;

  InvitationMember? _me;
  List<InvitationMember> _all = const [];

  /// Members with an address the server hasn't geocoded yet — they show up on a
  /// later refresh, so an empty map says "still mapping", not "nobody here".
  int _unmapped = 0;

  /// Selected member ids, in the order they were picked.
  final List<String> _order = [];
  String _query = '';

  // ── Route planning ────────────────────────────────────────────────────────
  RoutePlan? _plan;
  bool _planning = false;
  String _planError = '';
  Timer? _debounce;

  /// Bumped per request so a slow reply for an older selection is dropped
  /// instead of overwriting a newer route.
  int _planSeq = 0;

  /// Start the round from the device's position instead of the saved address.
  bool _useGps = false;
  LatLng? _gpsOrigin;
  bool _locating = false;

  LatLng? get _origin => _useGps ? _gpsOrigin : _me?.point;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final data = await Repository.instance.invitationMap();
      if (!mounted) return;
      setState(() {
        _me = data.me;
        _all = data.members;
        _unmapped = data.unmapped;
        // Drop selections for anyone no longer on the map.
        _order.removeWhere((id) => !data.members.any((m) => m.id == id));
        _loading = false;
      });
      _fitRoute();
      _schedulePlan();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is ApiException ? e.message : 'Could not load the map';
        _loading = false;
      });
    }
  }

  // ── Selection ─────────────────────────────────────────────────────────────

  List<InvitationMember> get _visible {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _all;
    return _all
        .where((m) =>
            m.name.toLowerCase().contains(q) ||
            m.area.toLowerCase().contains(q) ||
            m.city.toLowerCase().contains(q) ||
            m.gotra.toLowerCase().contains(q) ||
            m.samajId.toLowerCase().contains(q))
        .toList();
  }

  InvitationMember? _byId(String id) {
    for (final m in _all) {
      if (m.id == id) return m;
    }
    return null;
  }

  /// The selected members, in the order they were picked.
  List<InvitationMember> get _selected =>
      [for (final id in _order) _byId(id)].whereType<InvitationMember>().toList();

  /// The selected members in *visiting* order.
  ///
  /// While a new plan is in flight the last one still stands, so the numbers
  /// don't flicker on every tap: stops it no longer covers are dropped, and a
  /// member selected since is appended until the new plan lands.
  List<InvitationMember> get _orderedStops {
    final selected = _selected;
    final plan = _plan;
    if (plan == null) return selected;

    final pending = {for (final m in selected) m.id: m};
    final ordered = <InvitationMember>[];
    for (final stop in plan.stops) {
      final m = pending.remove(stop.member.id);
      if (m != null) ordered.add(m);
    }
    return [...ordered, ...pending.values];
  }

  bool _isSelected(String id) => _order.contains(id);

  void _toggle(String id) {
    setState(() {
      if (!_order.remove(id)) _order.add(id);
    });
    _schedulePlan();
  }

  // ── The optimised route ───────────────────────────────────────────────────

  /// Re-plans shortly after the selection settles — one request per burst of
  /// taps rather than one per tap.
  void _schedulePlan() {
    _debounce?.cancel();
    if (_order.isEmpty) {
      setState(() {
        _plan = null;
        _planError = '';
        _planning = false;
      });
      _fitRoute();
      return;
    }
    if (_useGps && _gpsOrigin == null) return; // waiting on the fix
    setState(() => _planning = true);
    _debounce = Timer(const Duration(milliseconds: 350), _planRoute);
  }

  Future<void> _planRoute() async {
    final seq = ++_planSeq;
    final ids = List<String>.from(_order);
    try {
      final plan = await Repository.instance.planRoute(
        ids,
        // Omitted for the saved address — the server starts there by default.
        origin: _useGps ? _gpsOrigin : null,
      );
      if (!mounted || seq != _planSeq) return;
      setState(() {
        _plan = plan;
        _planError = '';
        _planning = false;
      });
      _fitRoute();
    } catch (e) {
      if (!mounted || seq != _planSeq) return;
      setState(() {
        _planError = e is ApiException ? e.message : 'Could not plan the route';
        _planning = false;
      });
    }
  }

  /// Switches the starting point between the saved address and the device.
  Future<void> _setUseGps(bool useGps) async {
    if (!useGps) {
      setState(() => _useGps = false);
      _schedulePlan();
      return;
    }
    setState(() {
      _useGps = true;
      _locating = true;
    });
    try {
      final here = await currentLatLng();
      if (!mounted) return;
      setState(() {
        _gpsOrigin = here;
        _locating = false;
      });
      _schedulePlan();
    } on LocationFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _useGps = false;
        _locating = false;
      });
      _snack(e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _useGps = false;
        _locating = false;
      });
      _snack('Could not read your location');
    }
  }

  /// The line on the map: the roads OSRM routed along, or straight hops when
  /// there is no plan yet.
  List<LatLng> get _routeLine {
    final plan = _plan;
    if (plan != null && plan.geometry.length >= 2) return plan.geometry;
    return [
      ?_origin,
      for (final m in _orderedStops) m.point,
    ];
  }

  void _fitRoute() {
    if (!_mapReady) return;
    final pts = _routeLine;
    if (pts.isEmpty) return;
    if (pts.length == 1) {
      _mapController.move(pts.first, 14);
      return;
    }
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(pts),
        padding: const EdgeInsets.all(44),
        maxZoom: 15,
      ),
    );
  }

  /// Hands the planned round to the phone's maps app for turn-by-turn driving.
  ///
  /// The stops go across in the order the server worked out, so the navigation
  /// follows the optimised route rather than re-deciding it.
  Future<void> _startNavigation() async {
    final stops = _orderedStops;
    if (stops.isEmpty) {
      _snack('Select at least one family to begin.');
      return;
    }

    final link = directionsLink(
      origin: _origin,
      stops: [for (final m in stops) m.point],
    );

    try {
      final opened = await launchUrl(
        link.url,
        mode: LaunchMode.externalApplication,
      );
      if (!opened) {
        _snack('No maps app could open the route');
        return;
      }
      if (link.dropped > 0) {
        _snack(
          'Navigating the first 10 stops — maps can only take that many at once '
          '(${link.dropped} left for the next trip).',
        );
      }
    } catch (_) {
      _snack('Could not open a maps app');
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          backgroundColor: AppColors.forest800,
          behavior: SnackBarBehavior.floating,
          content:
              Text(msg, style: body(13, weight: FontWeight.w600, color: Colors.white)),
        ),
      );
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Invitations',
      currentRoute: '/invitations',
      scrollable: false,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _MapPanel(
            controller: _mapController,
            origin: _origin,
            originIsGps: _useGps,
            stops: _orderedStops,
            routeLine: _routeLine,
            loading: _loading,
            onReady: () {
              _mapReady = true;
              _fitRoute();
            },
          ),
          Expanded(child: _body()),
          _SummaryBar(
            stops: _order.length,
            plan: _plan,
            planning: _planning,
            onStart: _startNavigation,
          ),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error.isNotEmpty) {
      return _message(
        icon: Icons.cloud_off_rounded,
        title: _error,
        detail: 'Check your connection and try again.',
        action: 'Retry',
      );
    }
    if (_all.isEmpty) {
      // An address only becomes a pin once it has been geocoded, and the server
      // works through the backlog a few members at a time — so "none yet" and
      // "none ever" are different answers, and the member deserves the right one.
      return _unmapped > 0
          ? _message(
              icon: Icons.travel_explore_rounded,
              title: 'Putting $_unmapped members on the map',
              detail:
                  'Their addresses are being looked up now — a few at a time, '
                  'which is all the maps service allows. Refresh in a moment to '
                  'see them.',
              action: 'Refresh',
            )
          : _message(
              icon: Icons.person_pin_circle_outlined,
              title: 'No members on the map yet',
              detail:
                  'A member appears here once they save their current address — '
                  'the address is what puts them on the map.',
              action: 'Refresh',
            );
    }

    final visible = _visible;
    final ordered = _orderedStops;
    final legs = {
      for (final s in _plan?.stops ?? const <RouteStop>[]) s.member.id: s.legKm,
    };

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        children: [
          Text('SMART INVITATION PLANNER',
              style: body(11,
                  weight: FontWeight.w700,
                  color: AppColors.gold700,
                  letterSpacing: 2)),
          const SizedBox(height: 4),
          Text('Route Planner', style: display(22, color: AppColors.forest900)),
          const SizedBox(height: 4),
          Text('Select families · the route orders itself',
              style: body(12, color: AppColors.textMuted)),
          if (_unmapped > 0) ...[
            const SizedBox(height: 6),
            Text(
              '$_unmapped more ${_unmapped == 1 ? 'member is' : 'members are'} '
              'still being mapped — refresh shortly to see them.',
              style: body(11, color: AppColors.gold700, height: 1.4),
            ),
          ],
          const SizedBox(height: 12),
          _originPicker(),
          if (_planError.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(_planError, style: body(11, color: AppColors.gold700)),
          ],
          const SizedBox(height: 12),
          _searchField(),
          const SizedBox(height: 12),
          if (visible.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Center(
                child: Text('No members match "$_query"',
                    style: body(13, color: AppColors.hint)),
              ),
            ),
          for (final m in visible)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _MemberCard(
                member: m,
                selected: _isSelected(m.id),
                // Position in the planned route, not in the taps.
                stopNumber: ordered.indexWhere((s) => s.id == m.id) + 1,
                legKm: legs[m.id],
                distanceKmFromOrigin:
                    _origin == null ? null : distanceKm(_origin!, m.point),
                onToggle: () => _toggle(m.id),
              ),
            ),
        ],
      ),
    );
  }

  /// Where the round starts. The saved address is the default; the device's
  /// position is for planning while already out.
  Widget _originPicker() {
    final hasAddress = _me != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('START FROM',
            style: body(10,
                weight: FontWeight.w700,
                color: AppColors.textMuted,
                letterSpacing: 1.4)),
        const SizedBox(height: 6),
        Row(
          children: [
            ChoiceChip(
              label: Text('My address', style: body(12)),
              selected: !_useGps && hasAddress,
              onSelected: hasAddress ? (_) => _setUseGps(false) : null,
              selectedColor: AppColors.forest300,
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              avatar: _locating
                  ? const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location_rounded, size: 14),
              label: Text(_locating ? 'Locating…' : 'Current location',
                  style: body(12)),
              selected: _useGps,
              onSelected: _locating ? null : (_) => _setUseGps(true),
              selectedColor: AppColors.forest300,
            ),
          ],
        ),
        if (!hasAddress && !_useGps) ...[
          const SizedBox(height: 6),
          Text(
            'Your profile has no mapped address yet — add one, or start from your '
            'current location.',
            style: body(11, color: AppColors.gold700, height: 1.4),
          ),
        ],
      ],
    );
  }

  Widget _searchField() {
    return TextField(
      controller: _searchCtrl,
      onChanged: (v) => setState(() => _query = v),
      style: body(14, color: AppColors.ink),
      decoration: InputDecoration(
        hintText: 'Search by name, area or Samaj ID',
        hintStyle: body(13, color: AppColors.hint),
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.hint),
        suffixIcon: _query.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: () {
                  _searchCtrl.clear();
                  setState(() => _query = '');
                },
              ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.forest700, width: 1.5),
        ),
      ),
    );
  }

  Widget _message({
    required IconData icon,
    required String title,
    required String detail,
    required String action,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 34, color: AppColors.hint),
            const SizedBox(height: 12),
            Text(title,
                textAlign: TextAlign.center,
                style: body(14,
                    weight: FontWeight.w700, color: AppColors.forest900)),
            const SizedBox(height: 6),
            Text(detail,
                textAlign: TextAlign.center,
                style: body(12, color: AppColors.textMuted, height: 1.4)),
            const SizedBox(height: 14),
            TextButton(onPressed: _load, child: Text(action)),
          ],
        ),
      ),
    );
  }
}

/// The top map: where you start, numbered pins in visiting order, and the route
/// through them.
class _MapPanel extends StatelessWidget {
  const _MapPanel({
    required this.controller,
    required this.origin,
    required this.originIsGps,
    required this.stops,
    required this.routeLine,
    required this.loading,
    required this.onReady,
  });

  final MapController controller;
  final LatLng? origin;
  final bool originIsGps;
  final List<InvitationMember> stops;
  final List<LatLng> routeLine;
  final bool loading;
  final VoidCallback onReady;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 280,
      child: Stack(
        children: [
          FlutterMap(
            mapController: controller,
            options: MapOptions(
              // Centred on where the round starts, else on the first stop, else
              // on Bengaluru — the community's centre.
              initialCenter: origin ??
                  (stops.isNotEmpty
                      ? stops.first.point
                      : const LatLng(12.97, 77.59)),
              initialZoom: 11,
              onMapReady: onReady,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.daivajna.daivajna_census',
              ),
              if (routeLine.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: routeLine,
                      strokeWidth: 4,
                      color: AppColors.forest700,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  if (origin != null)
                    Marker(
                      point: origin!,
                      width: 34,
                      height: 34,
                      child: _OriginPin(isGps: originIsGps),
                    ),
                  for (var i = 0; i < stops.length; i++)
                    Marker(
                      point: stops[i].point,
                      width: 34,
                      height: 34,
                      child: _NumberedPin(number: i + 1),
                    ),
                ],
              ),
            ],
          ),
          if (loading || stops.isEmpty)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  color: const Color(0xFFF0FBF4).withValues(alpha: 0.85),
                  alignment: Alignment.center,
                  child: Text(
                    loading
                        ? 'Loading the map…'
                        : 'Select families to plan a route',
                    style:
                        body(13, weight: FontWeight.w600, color: AppColors.hint),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Where the route starts — the member's address, or the device's position.
class _OriginPin extends StatelessWidget {
  const _OriginPin({required this.isGps});
  final bool isGps;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.gold700,
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
      child: Icon(isGps ? Icons.my_location_rounded : Icons.home_rounded,
          size: 16, color: Colors.white),
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

class _MemberCard extends StatelessWidget {
  const _MemberCard({
    required this.member,
    required this.selected,
    required this.stopNumber,
    required this.legKm,
    required this.distanceKmFromOrigin,
    required this.onToggle,
  });

  final InvitationMember member;
  final bool selected;

  /// Position in the planned route; 0 when this member is not a stop.
  final int stopNumber;

  /// Road distance from the previous stop, once the route covers this member.
  final double? legKm;
  final double? distanceKmFromOrigin;
  final VoidCallback onToggle;

  static String _km(double km) =>
      km < 10 ? '${km.toStringAsFixed(1)} km' : '${km.round()} km';

  String get _localityLine {
    final leg = legKm;
    final away = distanceKmFromOrigin;
    final distance = selected && leg != null
        ? (stopNumber == 1
            ? '${_km(leg)} from the start'
            : '${_km(leg)} from stop ${stopNumber - 1}')
        : away == null
            ? ''
            : '${_km(away)} away';
    return [member.locality, distance].where((s) => s.isNotEmpty).join(' · ');
  }

  @override
  Widget build(BuildContext context) {
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
                child: selected && stopNumber > 0
                    ? Text('$stopNumber',
                        style: body(12,
                            weight: FontWeight.w800, color: Colors.white))
                    : null,
              ),
              const SizedBox(width: 10),
              PexelsImage(
                url: member.profileUrl,
                name: member.name,
                size: 46,
                borderColor: selected ? AppColors.forest700 : AppColors.border,
                borderWidth: 2,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(member.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: body(14,
                            weight: FontWeight.w700,
                            color: AppColors.forest900)),
                    const SizedBox(height: 2),
                    Text(member.subtitle,
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
                          child: Text(_localityLine,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: body(11, color: AppColors.hint)),
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
          if (member.addressLine.isNotEmpty) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 36),
              child: Text(member.addressLine,
                  style: body(11, color: AppColors.textMuted, height: 1.3)),
            ),
          ],
          // Only members who chose to publish their number have one here.
          if (member.phone.isNotEmpty) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 36),
              child: Row(
                children: [
                  const Icon(Icons.call_outlined,
                      size: 12, color: AppColors.hint),
                  const SizedBox(width: 4),
                  Text(member.phone, style: body(11, color: AppColors.hint)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryBar extends StatelessWidget {
  const _SummaryBar({
    required this.stops,
    required this.plan,
    required this.planning,
    required this.onStart,
  });

  final int stops;
  final RoutePlan? plan;
  final bool planning;
  final VoidCallback onStart;

  /// The trip in one line: distance, driving time, and — when OSRM could not be
  /// reached — that these are straight lines rather than roads.
  String get _tripLine {
    if (planning) return 'Optimising the route…';
    final p = plan;
    if (p == null || p.stops.isEmpty) return 'Pick the families to visit';
    final km =
        p.totalKm < 10 ? p.totalKm.toStringAsFixed(1) : p.totalKm.round().toString();
    final mins = p.totalMinutes;
    final time = mins >= 60 ? '${mins ~/ 60}h ${mins % 60}m' : '${mins}m';
    return '$km km · $time${p.isEstimate ? ' (straight-line estimate)' : ''}';
  }

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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.groups_rounded,
                          size: 15, color: AppColors.forest700),
                      const SizedBox(width: 5),
                      Text('$stops ${stops == 1 ? "stop" : "stops"}',
                          style: body(14,
                              weight: FontWeight.w700,
                              color: AppColors.forest900)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(planning ? Icons.sync_rounded : Icons.route_rounded,
                          size: 13, color: AppColors.textMuted),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(_tripLine,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: body(11, color: AppColors.textMuted)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
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
