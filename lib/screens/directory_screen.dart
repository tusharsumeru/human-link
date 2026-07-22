import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../data/repository.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_shell.dart';
import '../widgets/pexels_image.dart';
import '../widgets/ui_kit.dart';

/// Member Directory — "Vamsha Vruksha" network. Real members from `/api/family`,
/// grouped/searched by area, gotra, or occupation, with a nearby rail, gotra-
/// based suggested connections, and a community map.
class DirectoryScreen extends StatefulWidget {
  const DirectoryScreen({super.key});

  @override
  State<DirectoryScreen> createState() => _DirectoryScreenState();
}

enum _Mode { all, area, gotra, occupation }

class _DirectoryScreenState extends State<DirectoryScreen> {
  // Approximate branch-city coordinates (Karnataka + neighbouring).
  static const _branchCoords = <String, LatLng>{
    'Kundapura': LatLng(13.62, 74.69),
    'Kumta': LatLng(14.43, 74.42),
    'Mangaluru': LatLng(12.91, 74.86),
    'Bengaluru': LatLng(12.97, 77.59),
    'Udupi': LatLng(13.34, 74.74),
    'Out-of-State': LatLng(18.52, 73.85),
  };

  final _searchCtrl = TextEditingController();
  String _search = '';
  _Mode _mode = _Mode.all;
  bool _mapView = false;

  List<Map<String, dynamic>> _members = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      // Registered members from the users collection (GET /api/user/directory).
      final list = await Repository.instance.usersDirectory(limit: 100);
      if (!mounted) return;
      setState(() {
        _members = list;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  String _str(Map m, String k) => (m[k] ?? '').toString().trim();

  List<Map<String, dynamic>> get _filtered {
    final q = _search.toLowerCase();
    if (q.isEmpty) return _members;
    return _members.where((m) {
      return _str(m, 'name').toLowerCase().contains(q) ||
          _str(m, 'gotra').toLowerCase().contains(q) ||
          _str(m, 'native').toLowerCase().contains(q) ||
          _str(m, 'occupation').toLowerCase().contains(q) ||
          _str(m, 'branch').toLowerCase().contains(q);
    }).toList();
  }

  /// Members sharing the signed-in user's gotra (real "SAME GOTRA" suggestion),
  /// excluding the user themselves.
  List<Map<String, dynamic>> _suggested(String? myGotra) {
    if (myGotra == null || myGotra.isEmpty) return const [];
    final myUser = (context.read<AuthService>().user?.userName ?? '').toLowerCase();
    return _filtered
        .where((m) =>
            _str(m, 'gotra').toLowerCase() == myGotra.toLowerCase() &&
            (myUser.isEmpty || _str(m, 'userName').toLowerCase() != myUser))
        .take(4)
        .toList();
  }

  /// Place key from a free-text native ("Kumta, Karnataka" → "kumta").
  String _placeKey(Object? native) =>
      (native ?? '').toString().split(',').first.trim().toLowerCase();

  /// "Nearby" without GPS: members from the signed-in user's native place lead,
  /// then everyone else. Excludes the user themselves.
  List<Map<String, dynamic>> _nearby(List<Map<String, dynamic>> list) {
    final me = context.read<AuthService>().user;
    final myPlace = _placeKey(me?.native);
    final myUser = (me?.userName ?? '').toLowerCase();
    final same = <Map<String, dynamic>>[];
    final rest = <Map<String, dynamic>>[];
    for (final m in list) {
      if (myUser.isNotEmpty && _str(m, 'userName').toLowerCase() == myUser) {
        continue; // skip self
      }
      if (myPlace.isNotEmpty && _placeKey(m['native']) == myPlace) {
        same.add(m);
      } else {
        rest.add(m);
      }
    }
    return [...same, ...rest];
  }

  @override
  Widget build(BuildContext context) {
    final myGotra = context.watch<AuthService>().user?.gotra;
    final filtered = _filtered;

    return AppShell(
      title: 'Member Directory',
      currentRoute: '/directory',
      scrollable: false,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _searchField(),
                const SizedBox(height: 12),
                _filterRow(),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.forest700, strokeWidth: 2))
                : _mapView
                    ? _MapView(filtered: filtered, branchCoords: _branchCoords)
                    : _content(filtered, myGotra),
          ),
        ],
      ),
    );
  }

  // ── Search + filters ────────────────────────────────────────────────────────
  Widget _searchField() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _search = v),
            style: body(14, color: AppColors.ink),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Search members, gotras, or locations…',
              hintStyle: body(14, color: AppColors.hint),
              prefixIcon:
                  const Icon(Icons.search_rounded, size: 18, color: AppColors.hint),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              filled: true,
              fillColor: Colors.white,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.forest700, width: 1.5),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => _toast(context, 'Advanced filters coming soon'),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.forest700,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.tune_rounded, color: Colors.white, size: 20),
          ),
        ),
      ],
    );
  }

  void _setMode(_Mode m) => setState(() {
        _mode = m;
        _mapView = false;
      });

  Widget _filterRow() {
    // Wrap so the chips flow onto a second line instead of overflowing.
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _chip('All Members', _mode == _Mode.all && !_mapView,
            () => _setMode(_Mode.all)),
        _chip('By Area', _mode == _Mode.area && !_mapView,
            () => _setMode(_Mode.area)),
        _chip('By Gotra', _mode == _Mode.gotra && !_mapView,
            () => _setMode(_Mode.gotra)),
        _chip('By Occupation', _mode == _Mode.occupation && !_mapView,
            () => _setMode(_Mode.occupation)),
        _mapChip(),
      ],
    );
  }

  Widget _mapChip() {
    return GestureDetector(
      onTap: () => setState(() => _mapView = !_mapView),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: _mapView ? AppColors.forest700 : const Color(0xFFFCEBDD),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
              color: _mapView ? AppColors.forest700 : const Color(0xFFEBC9AE)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map_outlined,
                size: 14, color: _mapView ? Colors.white : AppColors.gold700),
            const SizedBox(width: 5),
            Text('Map View',
                style: body(13,
                    weight: FontWeight.w700,
                    color: _mapView ? Colors.white : AppColors.gold700)),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: active ? AppColors.forest700 : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border:
              Border.all(color: active ? AppColors.forest700 : AppColors.border),
        ),
        child: Text(label,
            style: body(13,
                weight: FontWeight.w600,
                color: active ? Colors.white : AppColors.label)),
      ),
    );
  }

  // ── Content ─────────────────────────────────────────────────────────────────
  Widget _content(List<Map<String, dynamic>> filtered, String? myGotra) {
    if (filtered.isEmpty) {
      return _empty();
    }
    if (_mode != _Mode.all) {
      return _GroupedList(
          members: filtered,
          mode: _mode,
          onConnect: _connect,
          onView: _openMember);
    }

    final suggested = _suggested(myGotra);
    final nearby = _nearby(filtered);
    final myPlace = _placeKey(context.read<AuthService>().user?.native);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      children: [
        _sectionHeader('Nearby Members', trailing: 'View All →'),
        if (myPlace.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text('From your native place first',
                style: body(11, color: AppColors.textMuted)),
          ),
        const SizedBox(height: 10),
        if (nearby.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text('No other members yet.',
                style: body(13, color: AppColors.textMuted)),
          )
        else
          SizedBox(
            height: 208,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: nearby.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) => _NearbyCard(
                  member: nearby[i], onConnect: _connect, onView: _openMember),
            ),
        ),
        const SizedBox(height: 22),
        if (suggested.isNotEmpty) ...[
          _sectionHeader('Suggested Connections'),
          const SizedBox(height: 10),
          for (final m in suggested) ...[
            _SuggestedCard(
                member: m, onConnect: _connect, onView: _openMember),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 10),
        ],
        _CommunityMapCard(
          count: filtered.length,
          onTap: () => setState(() => _mapView = true),
        ),
      ],
    );
  }

  Widget _sectionHeader(String title, {String? trailing}) {
    return Row(
      children: [
        Text(title, style: display(18, color: AppColors.forest900)),
        const Spacer(),
        if (trailing != null)
          Text(trailing,
              style: body(12,
                  weight: FontWeight.w600, color: AppColors.forest700)),
      ],
    );
  }

  Widget _empty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.groups_outlined, size: 40, color: AppColors.hint),
          const SizedBox(height: 10),
          Text(_search.isEmpty ? 'No members yet' : 'No members found',
              style: display(16, color: AppColors.forest900)),
          const SizedBox(height: 4),
          Text('Members appear here as your Vamsha Vruksha grows.',
              textAlign: TextAlign.center,
              style: body(13, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  // "Connect" → friendly feedback (no user-to-user connection endpoint yet).
  void _connect(Map<String, dynamic> member) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(
      content: Text('Connection request sent to ${_str(member, 'name')}',
          style: body(13, color: Colors.white)),
      backgroundColor: AppColors.forest800,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));
  }

  // Tap a member → show their full details, fetched fresh via GET /api/user/:id.
  void _openMember(Map<String, dynamic> member) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => _MemberSheet(initial: member, onConnect: _connect),
    );
  }
}

// Known branch cities that have map coordinates; used to derive a member's
// area from their free-text native place.
const _knownBranches = ['Kundapura', 'Kumta', 'Mangaluru', 'Bengaluru', 'Udupi'];

String _branchOf(Map m) {
  final branch = (m['branch'] ?? '').toString().trim();
  if (branch.isNotEmpty) return branch;
  final native = (m['native'] ?? '').toString().toLowerCase();
  for (final c in _knownBranches) {
    if (native.contains(c.toLowerCase())) return c;
  }
  if (native.contains('bangalore')) return 'Bengaluru';
  return native.trim().isEmpty ? 'Other' : 'Out-of-State';
}

// ── Member cards ──────────────────────────────────────────────────────────────

String _placeOf(Map m) {
  final native = (m['native'] ?? '').toString().trim();
  if (native.isNotEmpty) return native.split(',').first.trim();
  final branch = (m['branch'] ?? '').toString().trim();
  return branch.isEmpty ? 'Samaj member' : branch;
}

class _NearbyCard extends StatelessWidget {
  const _NearbyCard(
      {required this.member, required this.onConnect, required this.onView});
  final Map<String, dynamic> member;
  final void Function(Map<String, dynamic>) onConnect;
  final void Function(Map<String, dynamic>) onView;

  @override
  Widget build(BuildContext context) {
    final name = (member['name'] ?? '').toString();
    final gotra = (member['gotra'] ?? '').toString();
    return GestureDetector(
      onTap: () => onView(member),
      child: Container(
      width: 182,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          PexelsImage(
              url: (member['profileUrl'] ?? '').toString(),
              name: name,
              size: 44,
              radius: BorderRadius.circular(12)),
          const SizedBox(height: 10),
          Text(name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: body(14, weight: FontWeight.w700, color: AppColors.forest900)),
          const SizedBox(height: 2),
          if (gotra.isNotEmpty)
            Text('$gotra Gotra',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: body(11, color: AppColors.textMuted)),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 11, color: AppColors.hint),
              const SizedBox(width: 3),
              Expanded(
                child: Text(_placeOf(member),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: body(11, color: AppColors.hint)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MiniButton(
                  label: 'Message',
                  filled: false,
                  onTap: () => _toast(context, 'Messaging coming soon'),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _MiniButton(
                  label: 'Connect',
                  filled: true,
                  onTap: () => onConnect(member),
                ),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }
}

class _SuggestedCard extends StatelessWidget {
  const _SuggestedCard(
      {required this.member, required this.onConnect, required this.onView});
  final Map<String, dynamic> member;
  final void Function(Map<String, dynamic>) onConnect;
  final void Function(Map<String, dynamic>) onView;

  @override
  Widget build(BuildContext context) {
    final name = (member['name'] ?? '').toString();
    final gotra = (member['gotra'] ?? '').toString();
    final occ = (member['occupation'] ?? '').toString().trim();
    final reason = occ.isNotEmpty
        ? '$occ · shares your $gotra gotra.'
        : 'Shares your $gotra gotra, rooted in ${_placeOf(member)}.';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FBF4),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('SAME GOTRA',
                style: body(9,
                    weight: FontWeight.w700,
                    color: AppColors.forest700,
                    letterSpacing: 1)),
          ),
          const SizedBox(height: 8),
          Text(name,
              style: body(15, weight: FontWeight.w700, color: AppColors.forest900)),
          const SizedBox(height: 4),
          Text(reason,
              style: body(12, color: AppColors.textMuted, height: 1.4)),
          const SizedBox(height: 12),
          Row(
            children: [
              _MiniButton(
                label: 'View Profile',
                filled: true,
                onTap: () => onView(member),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => onConnect(member),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FBF4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.person_add_alt_1_outlined,
                      size: 18, color: AppColors.forest700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CommunityMapCard extends StatelessWidget {
  const _CommunityMapCard({required this.count, required this.onTap});
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Community Map',
                    style: body(14,
                        weight: FontWeight.w700, color: AppColors.forest900)),
                const Spacer(),
                Text('$count members',
                    style: body(11, color: AppColors.textMuted)),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 130,
                color: const Color(0xFFE8EFE8),
                child: Stack(
                  children: [
                    const Positioned(
                        left: 40, top: 40, child: _MapDot()),
                    const Positioned(
                        right: 60, bottom: 40, child: _MapDot()),
                    const Positioned(
                        left: 120, bottom: 24, child: _MapDot()),
                    Positioned(
                      left: 12,
                      bottom: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Explore Region',
                                style: body(12,
                                    weight: FontWeight.w600,
                                    color: AppColors.forest800)),
                            const SizedBox(width: 4),
                            const Icon(Icons.open_in_full_rounded,
                                size: 12, color: AppColors.forest700),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapDot extends StatelessWidget {
  const _MapDot();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: const BoxDecoration(
          color: AppColors.forest700, shape: BoxShape.circle),
    );
  }
}

class _MiniButton extends StatelessWidget {
  const _MiniButton(
      {required this.label, required this.filled, required this.onTap});
  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? AppColors.forest700 : const Color(0xFFF1EFEA),
          borderRadius: BorderRadius.circular(9),
        ),
        // Scale the label down if the card is narrow, so it never truncates.
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(label,
              maxLines: 1,
              style: body(12,
                  weight: FontWeight.w700,
                  color: filled ? Colors.white : AppColors.forest800)),
        ),
      ),
    );
  }
}

// ── Grouped list (By Area / Gotra / Occupation) ───────────────────────────────

class _GroupedList extends StatelessWidget {
  const _GroupedList(
      {required this.members,
      required this.mode,
      required this.onConnect,
      required this.onView});
  final List<Map<String, dynamic>> members;
  final _Mode mode;
  final void Function(Map<String, dynamic>) onConnect;
  final void Function(Map<String, dynamic>) onView;

  String _key(Map m) => switch (mode) {
        _Mode.area => _branchOf(m),
        _Mode.gotra => (m['gotra'] ?? '').toString().trim().isEmpty
            ? 'Other'
            : (m['gotra']).toString(),
        _Mode.occupation => (m['occupation'] ?? '').toString().trim().isEmpty
            ? 'Not specified'
            : (m['occupation']).toString(),
        _Mode.all => 'All',
      };

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final m in members) {
      grouped.putIfAbsent(_key(m), () => []).add(m);
    }
    final keys = grouped.keys.toList()..sort();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      children: [
        for (final k in keys) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 8, 2, 8),
            child: Text('${k.toUpperCase()}  ·  ${grouped[k]!.length}',
                style: body(11,
                    weight: FontWeight.w700,
                    color: AppColors.gold700,
                    letterSpacing: 1.5)),
          ),
          for (final m in grouped[k]!) ...[
            _RowCard(member: m, onConnect: onConnect, onView: onView),
            const SizedBox(height: 8),
          ],
        ],
      ],
    );
  }
}

class _RowCard extends StatelessWidget {
  const _RowCard(
      {required this.member, required this.onConnect, required this.onView});
  final Map<String, dynamic> member;
  final void Function(Map<String, dynamic>) onConnect;
  final void Function(Map<String, dynamic>) onView;

  @override
  Widget build(BuildContext context) {
    final name = (member['name'] ?? '').toString();
    final gotra = (member['gotra'] ?? '').toString();
    final occ = (member['occupation'] ?? '').toString().trim();
    final sub = [
      if (gotra.isNotEmpty) '$gotra Gotra',
      if (occ.isNotEmpty) occ,
      _placeOf(member),
    ].join(' · ');

    return AppCard(
      padding: const EdgeInsets.all(12),
      onTap: () => onView(member),
      child: Row(
        children: [
          PexelsImage(
              url: (member['profileUrl'] ?? '').toString(),
              name: name,
              size: 46,
              radius: BorderRadius.circular(12)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: body(14,
                        weight: FontWeight.w700, color: AppColors.forest900)),
                const SizedBox(height: 2),
                Text(sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: body(12, color: AppColors.textMuted)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => onConnect(member),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFF0FBF4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.person_add_alt_1_outlined,
                  size: 18, color: AppColors.forest700),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Member detail sheet ───────────────────────────────────────────────────────

class _MemberSheet extends StatefulWidget {
  const _MemberSheet({required this.initial, required this.onConnect});
  final Map<String, dynamic> initial;
  final void Function(Map<String, dynamic>) onConnect;

  @override
  State<_MemberSheet> createState() => _MemberSheetState();
}

class _MemberSheetState extends State<_MemberSheet> {
  late Map<String, dynamic> _m = widget.initial;

  @override
  void initState() {
    super.initState();
    // Refresh from GET /api/user/:id (fuller bio/occupation than the list row).
    final id = (widget.initial['id'] ?? '').toString();
    if (id.isNotEmpty) {
      Repository.instance.userById(id).then((full) {
        if (mounted) setState(() => _m = {..._m, ...full});
      }).catchError((_) {});
    }
  }

  String _s(String k) => (_m[k] ?? '').toString().trim();

  @override
  Widget build(BuildContext context) {
    final name = _s('name');
    final userName = _s('userName');
    final verified = _m['verified'] == true;
    final bio = _s('bio');
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(999)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                PexelsImage(
                    url: _s('profileUrl'),
                    name: name,
                    size: 64,
                    radius: BorderRadius.circular(16)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: display(20, color: AppColors.forest900)),
                          ),
                          if (verified) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.verified,
                                size: 18, color: AppColors.forest600),
                          ],
                        ],
                      ),
                      if (userName.isNotEmpty)
                        Text('@$userName',
                            style: body(12, color: AppColors.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (_s('gotra').isNotEmpty)
              _detail(Icons.spa_outlined, 'Gotra', _s('gotra')),
            if (_s('native').isNotEmpty)
              _detail(Icons.place_outlined, 'Native', _s('native')),
            if (_s('occupation').isNotEmpty)
              _detail(Icons.work_outline, 'Occupation', _s('occupation')),
            if (bio.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(bio, style: body(13, color: AppColors.label, height: 1.5)),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ForestButton(
                    label: 'Connect',
                    icon: Icons.person_add_alt_1_rounded,
                    expand: true,
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onConnect(_m);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlineButtonX(
                    label: 'Message',
                    expand: true,
                    onPressed: () {
                      Navigator.of(context).pop();
                      _toast(context, 'Messaging coming soon');
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detail(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.gold700),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: body(11, color: AppColors.textMuted)),
                const SizedBox(height: 1),
                Text(value,
                    style: body(14, weight: FontWeight.w600, color: AppColors.ink)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Map view ──────────────────────────────────────────────────────────────────

class _MapView extends StatelessWidget {
  const _MapView({required this.filtered, required this.branchCoords});
  final List<Map<String, dynamic>> filtered;
  final Map<String, LatLng> branchCoords;

  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{};
    for (final m in filtered) {
      final b = _branchOf(m);
      if (b.isEmpty || b == 'Other') continue;
      counts[b] = (counts[b] ?? 0) + 1;
    }

    final markers = <Marker>[];
    branchCoords.forEach((branch, coord) {
      final count = counts[branch] ?? 0;
      if (count == 0) return;
      markers.add(Marker(
        point: coord,
        width: 70,
        height: 70,
        child: _BranchMarker(branch: branch, count: count),
      ));
    });

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            FlutterMap(
              options: const MapOptions(
                initialCenter: LatLng(13.5, 76.0),
                initialZoom: 6.5,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.daivajna.daivajna_census',
                ),
                MarkerLayer(markers: markers),
              ],
            ),
            if (markers.isEmpty)
              Positioned.fill(
                child: Container(
                  color: const Color(0xFFF0FBF4),
                  alignment: Alignment.center,
                  child: Text('No members to place on the map',
                      style: body(14,
                          weight: FontWeight.w600, color: AppColors.hint)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BranchMarker extends StatelessWidget {
  const _BranchMarker({required this.branch, required this.count});
  final String branch;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: AppGradients.forest,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text('$count',
              style: body(15, weight: FontWeight.w700, color: Colors.white)),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(branch,
              style: body(8, weight: FontWeight.w700, color: AppColors.forest800)),
        ),
      ],
    );
  }
}

void _toast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(msg, style: body(13, color: Colors.white)),
      backgroundColor: AppColors.forest800,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 1),
    ));
}
