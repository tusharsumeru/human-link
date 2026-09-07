import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/api_client.dart';
import '../data/repository.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_shell.dart';
import '../widgets/discover_filter_sheet.dart';
import '../widgets/discovery_match_badge.dart';
import '../widgets/pexels_image.dart';
import '../widgets/ui_kit.dart';

/// Sort wire value (sent to the backend as-is) → its menu label, in render
/// order. The backend does the actual ordering — this only names the option
/// the member picked. Localized at call time (not `const`).
Map<String, String> _sortOptionsOf(AppLocalizations t) => {
  'BEST_MATCH': t.discSortBestMatch,
  'NEWEST': t.discSortNewest,
  'AGE_LOW_TO_HIGH': t.discSortAgeLowHigh,
  'AGE_HIGH_TO_LOW': t.discSortAgeHighLow,
};
const _defaultSort = 'BEST_MATCH';

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

  // Session-only Discover filters (Step 23B) — never written to the member's
  // saved matrimonial profile, and kept alive here for as long as this screen
  // instance stays on the navigation stack (i.e. across pushing into and
  // popping back from a profile).
  DiscoverFilters _filters = const DiscoverFilters();

  // Discover-session sort (Step 23D) — same lifetime/rules as [_filters]:
  // temporary to this screen instance, combined with whatever filters are
  // active, and never re-derived client-side. The backend does the ordering.
  String _sort = _defaultSort;

  // Bumped on every fresh _load() so a slow, superseded request can't clobber
  // state after a newer one (e.g. two filter applies in quick succession)
  // already landed.
  int _loadReqId = 0;

  // Fixed by the viewer's own gender, same rule as the Matrimonial Hub —
  // discovery only ever surfaces the opposite gender, never a filter the
  // member can turn off.
  late final String _gender;

  @override
  void initState() {
    super.initState();
    final myGender = context.read<AuthService>().user?.gender ?? '';
    _gender = myGender == 'M' ? 'F' : (myGender == 'F' ? 'M' : 'All');
    _load();
  }

  Future<void> _load() async {
    final reqId = ++_loadReqId;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await Repository.instance.discoverMatches(
        limit: _pageSize,
        skip: 0,
        gender: _gender,
        minAge: _filters.minAge,
        maxAge: _filters.maxAge,
        location: _filters.location,
        minMatchPercentage: _filters.minMatchPercentage,
        marriageIntention: _filters.marriageIntention,
        foodPreference: _filters.foodPreference,
        interests: _filters.interests,
        sort: _sort,
      );
      if (!mounted || reqId != _loadReqId) return;
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
      if (!mounted || reqId != _loadReqId) return;
      setState(() {
        _error = e is ApiException
            ? e.message
            : AppLocalizations.of(context).discCouldNotLoad;
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
      final result = await Repository.instance.discoverMatches(
        limit: _pageSize,
        skip: _skip,
        gender: _gender,
        minAge: _filters.minAge,
        maxAge: _filters.maxAge,
        location: _filters.location,
        minMatchPercentage: _filters.minMatchPercentage,
        marriageIntention: _filters.marriageIntention,
        foodPreference: _filters.foodPreference,
        interests: _filters.interests,
        sort: _sort,
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is ApiException
                ? e.message
                : AppLocalizations.of(context).discCouldNotLoadMore,
          ),
        ),
      );
    }
  }

  Future<void> _openFilters() async {
    final result = await showDiscoverFilterSheet(context, initial: _filters);
    if (result == null || !mounted) return;
    setState(() => _filters = result);
    _load();
  }

  void _clearFilters() {
    setState(() => _filters = const DiscoverFilters());
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return AppShell(
      title: t.discTitle,
      currentRoute: '/matrimonial/discover',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Intro(),
          const SizedBox(height: 14),
          _filterBar(t),
          const SizedBox(height: 14),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            _errorState(_error!, t)
          else if (_matches.isEmpty)
            _filters.isEmpty ? _emptyState(t) : _emptyFilteredState(t)
          else ...[
            ..._matches.map(
              (m) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _MatchCard(match: m),
              ),
            ),
            if (_hasMore) _loadMoreButton(t),
          ],
        ],
      ),
    );
  }

  Widget _filterBar(AppLocalizations t) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 10,
      runSpacing: 8,
      children: [
        if (_totalCount != null)
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '${_totalCount ?? 0}',
                  style: body(
                    13,
                    weight: FontWeight.w700,
                    color: AppColors.forest800,
                  ),
                ),
                TextSpan(
                  text: _totalCount == 1 ? t.discMatch : t.discMatches,
                  style: body(
                    13,
                    color: context.onBrightness(
                      light: AppColors.textMuted,
                      dark: AppColors.darkTextMuted,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          const SizedBox.shrink(),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [_filterButton(t), _sortButton(t)],
        ),
      ],
    );
  }

  Widget _filterButton(AppLocalizations t) {
    final count = _filters.activeGroupCount;
    final unfilledColor = context.onBrightness(
      light: AppColors.forest800,
      dark: AppColors.forest300,
    );
    return OutlinedButton.icon(
      onPressed: _loading ? null : _openFilters,
      style: OutlinedButton.styleFrom(
        side: BorderSide(
          color: count > 0
              ? AppColors.forest800
              : context.onBrightness(
                  light: AppColors.border,
                  dark: AppColors.darkBorder,
                ),
        ),
        backgroundColor: count > 0
            ? AppColors.forest800
            : context.onBrightness(
                light: Colors.white,
                dark: AppColors.darkSurface,
              ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      ),
      icon: Icon(
        Icons.tune_rounded,
        size: 16,
        color: count > 0 ? Colors.white : unfilledColor,
      ),
      label: Text(
        count > 0 ? t.discFilterCount(count) : t.discFilter,
        style: body(
          13,
          weight: FontWeight.w700,
          color: count > 0 ? Colors.white : unfilledColor,
        ),
      ),
    );
  }

  Widget _sortButton(AppLocalizations t) {
    return PopupMenuButton<String>(
      enabled: !_loading,
      initialValue: _sort,
      // Pinned to white so the always-ink menu-item text below stays
      // readable rather than following the app's dark theme surface.
      color: Colors.white,
      onSelected: (wire) {
        if (wire == _sort) return;
        setState(() => _sort = wire);
        _load();
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (_) => [
        for (final entry in _sortOptionsOf(t).entries)
          PopupMenuItem<String>(
            value: entry.key,
            child: Row(
              children: [
                Icon(
                  Icons.check_rounded,
                  size: 16,
                  color: entry.key == _sort
                      ? AppColors.forest800
                      : Colors.transparent,
                ),
                const SizedBox(width: 8),
                Text(entry.value, style: body(13, color: AppColors.ink)),
              ],
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: context.onBrightness(
            light: Colors.white,
            dark: AppColors.darkSurface,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: context.onBrightness(
              light: AppColors.border,
              dark: AppColors.darkBorder,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              t.discSortLabel(_sortOptionsOf(t)[_sort] ?? ''),
              style: body(
                13,
                weight: FontWeight.w700,
                color: context.onBrightness(
                  light: AppColors.forest800,
                  dark: AppColors.forest300,
                ),
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.arrow_drop_down_rounded,
              size: 18,
              color: context.onBrightness(
                light: AppColors.forest800,
                dark: AppColors.forest300,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _loadMoreButton(AppLocalizations t) {
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
                  side: BorderSide(
                    color: context.onBrightness(
                      light: AppColors.forest800,
                      dark: AppColors.forest300,
                    ),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                onPressed: _loadMore,
                child: Text(
                  t.discLoadMore,
                  style: body(
                    13,
                    weight: FontWeight.w700,
                    color: context.onBrightness(
                      light: AppColors.forest800,
                      dark: AppColors.forest300,
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _emptyState(AppLocalizations t) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(
            Icons.favorite_border_rounded,
            size: 30,
            color: context.onBrightness(
              light: AppColors.hint,
              dark: AppColors.darkTextMuted,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            t.discNoMatchesYet,
            style: body(
              15,
              weight: FontWeight.w600,
              color: context.onBrightness(
                light: AppColors.hint,
                dark: AppColors.darkText,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            t.discCompletePreferences,
            textAlign: TextAlign.center,
            style: body(
              13,
              color: context.onBrightness(
                light: AppColors.textMuted,
                dark: AppColors.darkTextMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyFilteredState(AppLocalizations t) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 30,
            color: context.onBrightness(
              light: AppColors.hint,
              dark: AppColors.darkTextMuted,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            t.discNoMatchesForFilters,
            textAlign: TextAlign.center,
            style: body(
              15,
              weight: FontWeight.w600,
              color: context.onBrightness(
                light: AppColors.hint,
                dark: AppColors.darkText,
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: _clearFilters,
            child: Text(
              t.discClearFilters,
              style: body(
                13,
                weight: FontWeight.w700,
                color: context.onBrightness(
                  light: AppColors.forest800,
                  dark: AppColors.forest300,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorState(String message, AppLocalizations t) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(
            Icons.wifi_off_rounded,
            size: 30,
            color: context.onBrightness(
              light: AppColors.hint,
              dark: AppColors.darkTextMuted,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: body(
              14,
              color: context.onBrightness(
                light: AppColors.textMuted,
                dark: AppColors.darkTextMuted,
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: _load,
            child: Text(
              t.commonRetry,
              style: body(
                13,
                weight: FontWeight.w700,
                color: context.onBrightness(
                  light: AppColors.forest800,
                  dark: AppColors.forest300,
                ),
              ),
            ),
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
    final t = AppLocalizations.of(context);
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
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.discTitle, style: display(16, color: Colors.white)),
                const SizedBox(height: 6),
                Text(
                  t.discIntroBody,
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
    final t = AppLocalizations.of(context);
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
    final levelLabel = matchLevelLabelsOf(t)[level] ?? level;
    final levelColor = matchLevelColorTone(
      context,
      matchLevelColors[level] ?? AppColors.hint,
    );

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
                  Text(
                    age == null ? name : '$name, $age',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: display(
                      17,
                      color: context.onBrightness(
                        light: AppColors.forest900,
                        dark: AppColors.darkText,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (location != null && location.isNotEmpty)
                    _detailRow(context, Icons.place_outlined, location),
                  if (occupation != null && occupation.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    _detailRow(
                      context,
                      Icons.business_center_outlined,
                      occupation,
                    ),
                  ],
                  const SizedBox(height: 12),
                  if (percentage != null)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          '$percentage%',
                          style: display(22, color: levelColor),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          t.discMatchLabel,
                          style: body(
                            13,
                            weight: FontWeight.w600,
                            color: context.onBrightness(
                              light: AppColors.textMuted,
                              dark: AppColors.darkTextMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (levelLabel.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      levelLabel,
                      style: body(
                        13,
                        weight: FontWeight.w700,
                        color: levelColor,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ForestButton(
                      label: t.discViewProfile,
                      icon: Icons.favorite_rounded,
                      onPressed: id.isEmpty
                          ? null
                          : () => context.push('/matrimonial/$id'),
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

  Widget _detailRow(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: context.onBrightness(
            light: AppColors.hint,
            dark: AppColors.darkTextMuted,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: body(
              12,
              color: context.onBrightness(
                light: AppColors.textMuted,
                dark: AppColors.darkTextMuted,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
