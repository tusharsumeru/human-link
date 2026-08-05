import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/api_client.dart';
import '../data/repository.dart';
import '../theme/app_theme.dart';
import '../widgets/app_shell.dart';
import '../widgets/pexels_image.dart';
import '../widgets/ui_kit.dart';

/// Display-only label/colour for the backend's `matchLevel` string. The
/// bucketing (which level a percentage falls into) is decided server-side —
/// this only decides how each already-decided level is worded and coloured.
const Map<String, String> _matchLevelLabels = {
  'EXCELLENT': 'Excellent Match',
  'HIGH': 'High Match',
  'GOOD': 'Good Match',
  'MODERATE': 'Moderate Match',
  'LOW': 'Low Match',
};

const Map<String, Color> _matchLevelColors = {
  'EXCELLENT': AppColors.forest700,
  'HIGH': AppColors.forest600,
  'GOOD': AppColors.gold700,
  'MODERATE': AppColors.gold500,
  'LOW': AppColors.hint,
};

/// Matrimony → Discover Matches. Same eligible pool as the Matrimonial Hub,
/// but sorted by the backend's Discovery Match percentage (highest first)
/// and rendered exactly as returned — no client-side sorting or scoring.
class DiscoverMatchesScreen extends StatefulWidget {
  const DiscoverMatchesScreen({super.key});

  @override
  State<DiscoverMatchesScreen> createState() => _DiscoverMatchesScreenState();
}

class _DiscoverMatchesScreenState extends State<DiscoverMatchesScreen> {
  static const _pageSize = 20;

  final List<Map<String, dynamic>> _matches = [];
  int _skip = 0;
  int? _totalCount;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await Repository.instance
          .discoverMatches(limit: _pageSize, skip: 0);
      if (!mounted) return;
      final matches = result['matches'] as List<Map<String, dynamic>>;
      setState(() {
        _matches
          ..clear()
          ..addAll(matches);
        _skip = matches.length;
        _totalCount = result['count'] as int?;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is ApiException ? e.message : 'Could not load matches';
        _loading = false;
      });
    }
  }

  bool get _hasMore =>
      _totalCount == null ? false : _matches.length < _totalCount!;

  Future<void> _loadMore() async {
    if (_loadingMore) return;
    setState(() => _loadingMore = true);
    try {
      final result = await Repository.instance
          .discoverMatches(limit: _pageSize, skip: _skip);
      if (!mounted) return;
      final matches = result['matches'] as List<Map<String, dynamic>>;
      setState(() {
        _matches.addAll(matches);
        _skip += matches.length;
        _totalCount = result['count'] as int?;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            e is ApiException ? e.message : 'Could not load more matches'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Discover Matches',
      currentRoute: '/matrimonial/discover',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Intro(),
          const SizedBox(height: 16),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            _errorState(_error!)
          else if (_matches.isEmpty)
            _emptyState()
          else ...[
            ..._matches.map((m) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _MatchCard(match: m),
                )),
            if (_hasMore) _loadMoreButton(),
          ],
        ],
      ),
    );
  }

  Widget _loadMoreButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Center(
        child: _loadingMore
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: CircularProgressIndicator(),
              )
            : OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.forest800),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                ),
                onPressed: _loadMore,
                child: Text('Load more',
                    style: body(13,
                        weight: FontWeight.w700, color: AppColors.forest800)),
              ),
      ),
    );
  }

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          const Icon(Icons.favorite_border_rounded,
              size: 30, color: AppColors.hint),
          const SizedBox(height: 10),
          Text('No matches to show yet',
              style:
                  body(15, weight: FontWeight.w600, color: AppColors.hint)),
          const SizedBox(height: 6),
          Text(
            'Complete your marriage preferences and interests for better matches.',
            textAlign: TextAlign.center,
            style: body(13, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _errorState(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          const Icon(Icons.wifi_off_rounded, size: 30, color: AppColors.hint),
          const SizedBox(height: 10),
          Text(message,
              textAlign: TextAlign.center,
              style: body(14, color: AppColors.textMuted)),
          const SizedBox(height: 10),
          TextButton(
            onPressed: _load,
            child: Text('Try again',
                style: body(13,
                    weight: FontWeight.w700, color: AppColors.forest800)),
          ),
        ],
      ),
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppGradients.deepForest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: AppGradients.gold,
              borderRadius: BorderRadius.circular(12),
            ),
            child:
                const Icon(Icons.auto_awesome_rounded, size: 20, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Discover Matches', style: display(16, color: Colors.white)),
                const SizedBox(height: 6),
                Text(
                  'Ranked by how well each profile fits your marriage preferences, food, interests, location and age — highest match first.',
                  style: body(12, color: AppColors.forest300, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({required this.match});
  final Map<String, dynamic> match;

  @override
  Widget build(BuildContext context) {
    final m = match;
    final id = (m['profileId'] ?? '').toString();
    final name = (m['name'] ?? '').toString();
    final age = m['age'];
    final location = (m['location'] as String?)?.trim();
    final occupation = (m['occupation'] as String?)?.trim();
    final percentage = (m['matchPercentage'] is num)
        ? (m['matchPercentage'] as num).round()
        : null;
    final level = (m['matchLevel'] ?? '').toString();
    final levelLabel = _matchLevelLabels[level] ?? level;
    final levelColor = _matchLevelColors[level] ?? AppColors.hint;
    final sharedInterests = ((m['sharedInterests'] as List?) ?? const [])
        .map((e) => _titleCase(e.toString()))
        .toList();

    return AppCard(
      padding: EdgeInsets.zero,
      onTap: id.isEmpty ? null : () => context.push('/matrimonial/$id'),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 200,
              child: PexelsImage(
                url: m['profileImage'] as String?,
                name: name,
                size: 200,
                radius: BorderRadius.zero,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(age == null ? name : '$name, $age',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: display(17, color: AppColors.forest900)),
                  const SizedBox(height: 6),
                  if (location != null && location.isNotEmpty)
                    _detailRow(Icons.place_outlined, location),
                  if (occupation != null && occupation.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    _detailRow(Icons.business_center_outlined, occupation),
                  ],
                  const SizedBox(height: 12),
                  if (percentage != null)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text('$percentage%',
                            style: display(22, color: levelColor)),
                        const SizedBox(width: 8),
                        Text('Match',
                            style: body(13,
                                weight: FontWeight.w600,
                                color: AppColors.textMuted)),
                      ],
                    ),
                  if (levelLabel.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(levelLabel,
                        style: body(13,
                            weight: FontWeight.w700, color: levelColor)),
                  ],
                  if (sharedInterests.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(sharedInterests.join(' • '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: body(12, color: AppColors.gold700)),
                  ],
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ForestButton(
                      label: 'View Profile',
                      icon: Icons.favorite_rounded,
                      onPressed:
                          id.isEmpty ? null : () => context.push('/matrimonial/$id'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.hint),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: body(12, color: AppColors.textMuted)),
        ),
      ],
    );
  }

  static String _titleCase(String wire) {
    if (wire.isEmpty) return wire;
    final lower = wire.toLowerCase().replaceAll('_', ' ');
    return lower[0].toUpperCase() + lower.substring(1);
  }
}
