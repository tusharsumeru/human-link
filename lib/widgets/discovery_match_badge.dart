import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../theme/app_theme.dart';

/// Display-only label/colour for the backend's `matchLevel` string
/// (`discoveryMatch.matchLevel` / Discover Matches' `matchLevel`). The
/// bucketing — which level a percentage falls into — is decided server-side
/// in `matchLevelFor()`; this only decides how an already-decided level is
/// worded and coloured. Shared by the Matrimonial Hub card and the Discover
/// Matches card so the same pair of profiles never shows two different
/// numbers in two different places. Localized at call time — the keys are
/// the stable wire values sent by the backend.
Map<String, String> matchLevelLabelsOf(AppLocalizations t) => {
      'EXCELLENT': t.matchLevelExcellent,
      'HIGH': t.matchLevelHigh,
      'GOOD': t.matchLevelGood,
      'MODERATE': t.matchLevelModerate,
      'LOW': t.matchLevelLow,
    };

const Map<String, Color> matchLevelColors = {
  'EXCELLENT': AppColors.forest700,
  'HIGH': AppColors.forest600,
  'GOOD': AppColors.gold700,
  'MODERATE': AppColors.gold500,
  'LOW': AppColors.hint,
};

/// Compact "78% · Good Match" row, reading `matchPercentage`/`matchLevel`
/// straight from a `discoveryMatch` map (`{matchPercentage, matchLevel, ...}`)
/// as returned by the backend. Null when there's no discovery match data
/// (viewer has no profile yet) — callers should skip rendering it then.
class DiscoveryMatchBadge extends StatelessWidget {
  const DiscoveryMatchBadge({super.key, required this.discoveryMatch});

  final Map<String, dynamic>? discoveryMatch;

  @override
  Widget build(BuildContext context) {
    final dm = discoveryMatch;
    if (dm == null) return const SizedBox.shrink();

    final percentage =
        (dm['matchPercentage'] is num) ? (dm['matchPercentage'] as num).round() : null;
    if (percentage == null) return const SizedBox.shrink();

    final t = AppLocalizations.of(context);
    final level = (dm['matchLevel'] ?? '').toString();
    final levelLabel = matchLevelLabelsOf(t)[level] ?? level;
    final levelColor = matchLevelColors[level] ?? AppColors.hint;

    return Row(
      children: [
        Text('$percentage%',
            style: body(20, weight: FontWeight.w800, color: levelColor)),
        const SizedBox(width: 7),
        Text(t.matchBadgeMatch, style: body(15, weight: FontWeight.w600, color: AppColors.textMuted)),
        if (levelLabel.isNotEmpty) ...[
          const SizedBox(width: 8),
          Text('· $levelLabel',
              style: body(15, weight: FontWeight.w700, color: levelColor)),
        ],
      ],
    );
  }
}

/// `discoveryMatch.factors[].factor` (a DiscoveryMatchFactor key from the
/// backend) → display name. Naming only — which factors exist and how they're
/// weighted is entirely server-side (see discovery-match-rules.ts). Localized
/// at call time — the keys are the stable wire values from the backend.
Map<String, String> _factorLabelsOf(AppLocalizations t) => {
      'marriageIntention': t.matchFactorMarriageIntention,
      'childrenPreference': t.matchFactorChildren,
      'familyPreference': t.matchFactorFamilyType,
      'relocationPreference': t.matchFactorRelocation,
      'foodPreference': t.matchFactorFoodPreference,
      'interests': t.matchFactorInterests,
      'location': t.matchFactorLocation,
      'age': t.matchFactorAge,
    };

/// The full Discovery Match breakdown for the Candidate Profile screen: the
/// same percentage/level shown on the Hub and Discover Matches cards (via
/// [DiscoveryMatchBadge]'s underlying numbers), plus a progress bar and a
/// per-factor readout. Every number here — the overall percentage, the level,
/// and each factor's own 0–100 score — comes straight from the backend's
/// `discoveryMatch` object; nothing is computed or bucketed here. Replaces
/// the older `MatchDetail`/`match.score` display, which compared a different,
/// narrower set of fields (age/gotra/location/mangal) and could disagree with
/// the percentage shown elsewhere for the same pair.
class DiscoveryMatchDetail extends StatelessWidget {
  const DiscoveryMatchDetail({super.key, required this.discoveryMatch});

  final Map<String, dynamic>? discoveryMatch;

  @override
  Widget build(BuildContext context) {
    final dm = discoveryMatch;
    if (dm == null) return const SizedBox.shrink();

    final percentage =
        (dm['matchPercentage'] is num) ? (dm['matchPercentage'] as num).round() : null;
    if (percentage == null) return const SizedBox.shrink();

    final t = AppLocalizations.of(context);
    final level = (dm['matchLevel'] ?? '').toString();
    final levelLabel = matchLevelLabelsOf(t)[level] ?? level;
    final levelColor = matchLevelColors[level] ?? AppColors.hint;
    final factors = ((dm['factors'] as List?) ?? const [])
        .whereType<Map>()
        .map((f) => Map<String, dynamic>.from(f))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.favorite_rounded, size: 14, color: levelColor),
            const SizedBox(width: 5),
            Text('$percentage%${levelLabel.isNotEmpty ? ' · $levelLabel' : ''}',
                style: body(13, weight: FontWeight.w700, color: levelColor)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: percentage / 100,
            minHeight: 7,
            backgroundColor: AppColors.creamDark,
            valueColor: AlwaysStoppedAnimation<Color>(levelColor),
          ),
        ),
        if (factors.isNotEmpty) ...[
          const SizedBox(height: 14),
          for (final f in factors) _factorRow(f, t),
        ],
      ],
    );
  }

  Widget _factorRow(Map<String, dynamic> f, AppLocalizations t) {
    final key = (f['factor'] ?? '').toString();
    final label = _factorLabelsOf(t)[key] ?? key;
    final applicable = f['applicable'] == true;
    final score = (f['score'] is num) ? (f['score'] as num) : null;

    if (!applicable || score == null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.remove_circle_outline_rounded,
                size: 15, color: AppColors.hint),
            const SizedBox(width: 8),
            Expanded(
              child: Text(t.matchFactorNotEnoughInfo(label),
                  style: body(13, color: AppColors.textMuted, height: 1.35)),
            ),
          ],
        ),
      );
    }

    final factorPercentage = (score * 100).round();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.circle, size: 8, color: AppColors.gold700),
          const SizedBox(width: 10),
          Expanded(
            child: Text(t.matchFactorAligned(label, factorPercentage),
                style: body(13, color: AppColors.label, height: 1.35)),
          ),
        ],
      ),
    );
  }
}
