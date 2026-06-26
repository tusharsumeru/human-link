import 'package:flutter/material.dart';

import '../data/repository.dart';
import '../theme/app_theme.dart';
import '../widgets/app_shell.dart';
import '../widgets/pexels_image.dart';
import '../widgets/ui_kit.dart';

/// Elder · Community Member Registry — ported from
/// `src/app/elder/members/page.tsx`. Admin registry with search, branch
/// filter chips, a verified-only toggle, summary stats and per-member rows.
class ElderMembersScreen extends StatefulWidget {
  const ElderMembersScreen({super.key});

  @override
  State<ElderMembersScreen> createState() => _ElderMembersScreenState();
}

class _ElderMembersScreenState extends State<ElderMembersScreen> {
  static const _branches = [
    'All',
    'Kundapura',
    'Kumta',
    'Mangaluru',
    'Bengaluru',
    'Udupi',
    'Out-of-State',
  ];

  final TextEditingController _searchCtrl = TextEditingController();
  String _search = '';
  String _branch = 'All';
  bool _verifiedOnly = false;

  late final List<Map<String, dynamic>> _all =
      Repository.instance.communityMembers();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _search.toLowerCase();
    return _all.where((m) {
      final matchBranch = _branch == 'All' || m['branch'] == _branch;
      final matchVerified = !_verifiedOnly || (m['verified'] as bool);
      final matchSearch = q.isEmpty ||
          (m['name'] as String).toLowerCase().contains(q) ||
          (m['occupation'] as String).toLowerCase().contains(q) ||
          (m['gotra'] as String).toLowerCase().contains(q) ||
          (m['location'] as String).toLowerCase().contains(q);
      return matchBranch && matchVerified && matchSearch;
    }).toList();
  }

  int _branchCount(String b) =>
      b == 'All' ? _all.length : _all.where((m) => m['branch'] == b).length;

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.forest800,
        behavior: SnackBarBehavior.floating,
      ));
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final total = _all.length;
    final verified = _all.where((m) => m['verified'] as bool).length;
    final pending = total - verified;

    return AppShell(
      title: 'Community',
      currentRoute: '/elder/members',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _statsBanner(filtered.length, total, verified, pending),
          const SizedBox(height: 16),
          // Search
          TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _search = v),
            decoration: InputDecoration(
              hintText: 'Search by name, gotra, occupation…',
              hintStyle: body(13, color: AppColors.hint),
              prefixIcon: const Icon(Icons.search_rounded,
                  size: 18, color: AppColors.hint),
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              filled: true,
              fillColor: Colors.white,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.forest700),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Branch chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final b in _branches) ...[
                  _branchChip(b),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Verified-only toggle
          Row(
            children: [
              Switch.adaptive(
                value: _verifiedOnly,
                activeThumbColor: AppColors.forest700,
                onChanged: (v) => setState(() => _verifiedOnly = v),
              ),
              const SizedBox(width: 4),
              Text('Verified members only',
                  style: body(13,
                      weight: FontWeight.w600, color: AppColors.label)),
              const Spacer(),
              Text('${filtered.length} shown',
                  style: body(12, color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: 12),
          if (filtered.isEmpty)
            _emptyState()
          else
            ...filtered.map(_memberRow),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _statsBanner(int shown, int total, int verified, int pending) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppGradients.deepForest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('DAIVAJNA SAMAJA BANGALORE',
              style: body(11,
                  weight: FontWeight.w700,
                  color: AppColors.forest300,
                  letterSpacing: 1.6)),
          const SizedBox(height: 6),
          Text('Community Member Registry',
              style: display(22, color: Colors.white)),
          const SizedBox(height: 4),
          Text('Showing $shown of 1,428 registered members',
              style: body(13, color: AppColors.forest300)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _stat('$total', 'Total'),
              _stat('$verified', 'Verified'),
              _stat('$pending', 'Pending'),
              _stat('6', 'Branches'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(value,
              style: body(18, weight: FontWeight.w700, color: Colors.white)),
          Text(label, style: body(11, color: AppColors.forest300)),
        ],
      ),
    );
  }

  Widget _branchChip(String b) {
    final active = _branch == b;
    return GestureDetector(
      onTap: () => setState(() => _branch = b),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.forest800 : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
              color: active ? AppColors.forest800 : AppColors.border),
        ),
        child: Text('$b (${_branchCount(b)})',
            style: body(13,
                weight: FontWeight.w600,
                color: active ? Colors.white : AppColors.label)),
      ),
    );
  }

  Widget _memberRow(Map<String, dynamic> m) {
    final verified = m['verified'] as bool;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PexelsImage(
                url: m['photo'] as String, name: m['name'] as String, size: 56),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(m['name'] as String,
                            style: body(15,
                                weight: FontWeight.w700,
                                color: AppColors.forest900)),
                      ),
                      if (verified)
                        const Icon(Icons.verified,
                            size: 18, color: AppColors.gold500)
                      else
                        const Pill('Unverified',
                            bg: Color(0xFFFEF3C7),
                            fg: Color(0xFFD97706),
                            icon: Icons.error_outline_rounded),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                      '${m['age']} yrs · ${m['gender'] == 'M' ? 'Male' : 'Female'}',
                      style: body(12, color: AppColors.textMuted)),
                  const SizedBox(height: 4),
                  Text(m['occupation'] as String,
                      style: body(12,
                          weight: FontWeight.w500, color: AppColors.label)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 12, color: AppColors.hint),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(m['location'] as String,
                            style: body(12, color: AppColors.textMuted)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      Pill('${m['branch']} Branch',
                          bg: const Color(0xFFF0FBF4),
                          fg: AppColors.forest800),
                      Pill('${m['gotra']} Gotra',
                          bg: const Color(0xFFF7F0E8), fg: AppColors.gold700),
                      Pill('Since ${m['joinedYear']}',
                          bg: AppColors.creamDark, fg: AppColors.gold700),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded,
                  size: 20, color: AppColors.hint),
              onSelected: (v) => _toast('$v · ${m['name']}'),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'View profile', child: Text('View profile')),
                PopupMenuItem(
                    value: 'Promote to Elder',
                    child: Text('Promote to Elder')),
                PopupMenuItem(
                    value: 'Suspend member', child: Text('Suspend member')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48),
      alignment: Alignment.center,
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 32, color: AppColors.hint),
          const SizedBox(height: 10),
          Text('No members match your filter',
              style: body(14,
                  weight: FontWeight.w600, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}
