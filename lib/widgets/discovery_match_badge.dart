import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Display-only label/colour for the backend's `matchLevel` string
/// (`discoveryMatch.matchLevel` / Discover Matches' `matchLevel`). The
/// bucketing — which level a percentage falls into — is decided server-side
/// in `matchLevelFor()`; this only decides how an already-decided level is
/// worded and coloured. Shared by the Matrimonial Hub card and the Discover
/// Matches card so the same pair of profiles never shows two different
/// numbers in two different places.
const Map<String, String> matchLevelLabels = {
  'EXCELLENT': 'Excellent Match',
  'HIGH': 'High Match',
  'GOOD': 'Good Match',
  'MODERATE': 'Moderate Match',
  'LOW': 'Low Match',
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

    final level = (dm['matchLevel'] ?? '').toString();
    final levelLabel = matchLevelLabels[level] ?? level;
    final levelColor = matchLevelColors[level] ?? AppColors.hint;

    return Row(
      children: [
        Text('$percentage%',
            style: body(14, weight: FontWeight.w800, color: levelColor)),
        const SizedBox(width: 6),
        Text('Match', style: body(12, weight: FontWeight.w600, color: AppColors.textMuted)),
        if (levelLabel.isNotEmpty) ...[
          const SizedBox(width: 8),
          Text('· $levelLabel',
              style: body(12, weight: FontWeight.w700, color: levelColor)),
        ],
      ],
    );
  }
}

/// `discoveryMatch.factors[].factor` (a DiscoveryMatchFactor key from the
/// backend) → display name. Naming only — which factors exist and how they're
/// weighted is entirely server-side (see discovery-match-rules.ts).
const Map<String, String> _factorLabels = {
  'marriageIntention': 'Marriage Intention',
  'childrenPreference': 'Children',
  'familyPreference': 'Family Type',
  'relocationPreference': 'Relocation',
  'foodPreference': 'Food Preference',
  'interests': 'Interests',
  'location': 'Location',
  'age': 'Age',
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

    final level = (dm['matchLevel'] ?? '').toString();
    final levelLabel = matchLevelLabels[level] ?? level;
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
          for (final f in factors) _factorRow(f),
        ],
        const SizedBox(height: 10),
        Text(
          'Based on the marriage preferences, food, interests, location and '
          'age you and they have both filled in. It is a comparison of '
          'stated preferences, not advice.',
          style: body(11, color: AppColors.textMuted, height: 1.4),
        ),
      ],
    );
  }

  Widget _factorRow(Map<String, dynamic> f) {
    final key = (f['factor'] ?? '').toString();
    final label = _factorLabels[key] ?? key;
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
              child: Text('$label — not enough information to compare',
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
            child: Text('$label — $factorPercentage% aligned',
                style: body(13, color: AppColors.label, height: 1.35)),
          ),
        ],
      ),
    );
  }
}
