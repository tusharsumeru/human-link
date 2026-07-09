import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../data/demo_data.dart';
import '../theme/app_theme.dart';
import '../widgets/app_shell.dart';
import '../widgets/pexels_image.dart';
import '../widgets/ui_kit.dart';

/// Member Directory — ported from `src/app/directory/page.tsx` +
/// `src/components/DirectoryMap.tsx` (Leaflet → flutter_map).
class DirectoryScreen extends StatefulWidget {
  const DirectoryScreen({super.key});

  @override
  State<DirectoryScreen> createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends State<DirectoryScreen> {
  static const _branches = [
    'All',
    'Kundapura',
    'Kumta',
    'Mangaluru',
    'Bengaluru',
    'Udupi',
    'Out-of-State',
  ];
  static const _gotras = [
    'Gotra: All',
    'Kashyap',
    'Bharadwaja',
    'Vasishtha',
    'Atreya',
  ];

  // Approximate branch-city coordinates (Karnataka + neighbouring).
  static const _branchCoords = <String, LatLng>{
    'Kundapura': LatLng(13.62, 74.69),
    'Kumta': LatLng(14.43, 74.42),
    'Mangaluru': LatLng(12.91, 74.86),
    'Bengaluru': LatLng(12.97, 77.59),
    'Udupi': LatLng(13.34, 74.74),
    'Out-of-State': LatLng(18.52, 73.85), // Pune
  };

  final TextEditingController _searchCtrl = TextEditingController();
  String _search = '';
  String _branch = 'All';
  String _gotra = 'Gotra: All';
  bool _mapView = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _search.toLowerCase();
    return kCommunityMembers.where((m) {
      final matchBranch = _branch == 'All' || m['branch'] == _branch;
      final matchGotra = _gotra == 'Gotra: All' || m['gotra'] == _gotra;
      final matchSearch = q.isEmpty ||
          (m['name'] as String).toLowerCase().contains(q) ||
          (m['occupation'] as String).toLowerCase().contains(q) ||
          (m['location'] as String).toLowerCase().contains(q);
      return matchBranch && matchGotra && matchSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('DAIVAJNA SAMAJA · GLOBAL NETWORK',
                    style: body(11,
                        weight: FontWeight.w700,
                        color: AppColors.gold700,
                        letterSpacing: 2)),
                const SizedBox(height: 4),
                Text('Community Directory',
                    style: display(22, color: AppColors.forest900)),
                const SizedBox(height: 16),
                _searchField(),
                const SizedBox(height: 12),
                _gotraDropdown(),
                const SizedBox(height: 12),
                _branchChips(),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text.rich(
                      TextSpan(children: [
                        TextSpan(
                          text: '${filtered.length}',
                          style: body(13,
                              weight: FontWeight.w700,
                              color: AppColors.forest800),
                        ),
                        TextSpan(
                          text: ' families nearby',
                          style: body(13, color: AppColors.textMuted),
                        ),
                      ]),
                    ),
                    const Spacer(),
                    _viewToggle(),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
          Expanded(
            child: _mapView
                ? _MapView(filtered: filtered, branchCoords: _branchCoords)
                : _ListView(filtered: filtered),
          ),
        ],
      ),
    );
  }

  Widget _searchField() {
    return TextField(
      controller: _searchCtrl,
      onChanged: (v) => setState(() => _search = v),
      style: body(14, color: AppColors.ink),
      decoration: InputDecoration(
        isDense: true,
        hintText: 'Search by name or family ID…',
        hintStyle: body(14, color: AppColors.hint),
        prefixIcon: const Icon(Icons.search_rounded,
            size: 18, color: AppColors.hint),
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
    );
  }

  Widget _gotraDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _gotra,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.hint),
          style: body(14, color: AppColors.ink),
          items: [
            for (final g in _gotras)
              DropdownMenuItem(value: g, child: Text(g)),
          ],
          onChanged: (v) => setState(() => _gotra = v ?? 'Gotra: All'),
        ),
      ),
    );
  }

  Widget _branchChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final b in _branches)
          _ChipButton(
            label: b,
            active: _branch == b,
            onTap: () => setState(() => _branch = b),
          ),
      ],
    );
  }

  Widget _viewToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _toggleSegment('List', Icons.view_list_rounded, !_mapView,
              () => setState(() => _mapView = false)),
          _toggleSegment('Map', Icons.map_rounded, _mapView,
              () => setState(() => _mapView = true)),
        ],
      ),
    );
  }

  Widget _toggleSegment(
      String label, IconData icon, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.forest800 : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14,
                color: active ? Colors.white : AppColors.textMuted),
            const SizedBox(width: 6),
            Text(label,
                style: body(13,
                    weight: FontWeight.w600,
                    color: active ? Colors.white : AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

class _ChipButton extends StatelessWidget {
  const _ChipButton(
      {required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: active ? AppColors.forest800 : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
              color: active ? AppColors.forest800 : AppColors.border),
        ),
        child: Text(label,
            style: body(13,
                weight: FontWeight.w600,
                color: active ? Colors.white : AppColors.label)),
      ),
    );
  }
}

const _areaLabels = <String, String>{
  'Kundapura': 'KUNDAPURA · UDUPI',
  'Kumta': 'KUMTA · UTTARA KANNADA',
  'Mangaluru': 'MANGALURU CENTRAL',
  'Bengaluru': 'BENGALURU URBAN',
  'Udupi': 'UDUPI CENTRAL',
  'Out-of-State': 'OUT OF STATE',
};

class _ListView extends StatelessWidget {
  const _ListView({required this.filtered});
  final List<Map<String, dynamic>> filtered;

  @override
  Widget build(BuildContext context) {
    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.groups_rounded, size: 28, color: AppColors.hint),
            const SizedBox(height: 8),
            Text('No members found',
                style: body(14,
                    weight: FontWeight.w600, color: AppColors.hint)),
          ],
        ),
      );
    }

    // Group by branch, preserving the canonical branch order.
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final m in filtered) {
      grouped.putIfAbsent(m['branch'] as String, () => []).add(m);
    }

    final children = <Widget>[];
    grouped.forEach((branch, members) {
      children.add(Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
        child: Text(_areaLabels[branch] ?? branch.toUpperCase(),
            style: body(11,
                weight: FontWeight.w700,
                color: AppColors.gold700,
                letterSpacing: 2)),
      ));
      for (final m in members) {
        children.add(Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _MemberCard(member: m),
        ));
      }
    });

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: children,
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({required this.member});
  final Map<String, dynamic> member;

  @override
  Widget build(BuildContext context) {
    final verified = member['verified'] == true;
    final location = (member['location'] as String).split(',').first;
    final gender = member['gender'] == 'F' ? 'Female' : 'Male';

    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: () => context.push('/profile/6'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PexelsImage(
            url: member['photo'] as String?,
            name: member['name'] as String,
            size: 48,
            radius: BorderRadius.circular(12),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(member['name'] as String,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: body(14,
                              weight: FontWeight.w700,
                              color: AppColors.forest900)),
                    ),
                    if (verified) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.verified,
                          size: 15, color: AppColors.forest600),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text('${member['age']} · $gender · ${member['occupation']}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: body(12, color: AppColors.textMuted)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 11, color: AppColors.hint),
                        const SizedBox(width: 2),
                        Text(location, style: body(11, color: AppColors.hint)),
                      ],
                    ),
                    Pill(member['branch'] as String,
                        bg: const Color(0xFFF0FBF4),
                        fg: AppColors.forest800,
                        fontSize: 10),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MapView extends StatelessWidget {
  const _MapView({required this.filtered, required this.branchCoords});
  final List<Map<String, dynamic>> filtered;
  final Map<String, LatLng> branchCoords;

  @override
  Widget build(BuildContext context) {
    // Count members per branch (from the filtered set).
    final counts = <String, int>{};
    for (final m in filtered) {
      final b = m['branch'] as String;
      counts[b] = (counts[b] ?? 0) + 1;
    }

    final markers = <Marker>[];
    branchCoords.forEach((branch, coord) {
      final count = counts[branch] ?? 0;
      if (count == 0) return;
      markers.add(
        Marker(
          point: coord,
          width: 70,
          height: 70,
          child: _BranchMarker(branch: branch, count: count),
        ),
      );
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
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
                  child: Text('No members in this filter',
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
              style: body(15,
                  weight: FontWeight.w700, color: Colors.white)),
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
              style: body(8,
                  weight: FontWeight.w700, color: AppColors.forest800)),
        ),
      ],
    );
  }
}
