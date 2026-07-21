import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The compatibility score from `match: {score, reasons, blockers}` on a
/// matrimonial card, drawn as a labelled progress bar.
///
/// The number is never shown on its own — [MatchDetail] spells out what drove
/// it. A percentage with no explanation invites more trust than a preference
/// comparison deserves.
class MatchBar extends StatelessWidget {
  const MatchBar({super.key, required this.match, this.compact = false});

  /// The `match` object from the API. Null when the viewer has no profile of
  /// their own to compare against — nothing is drawn in that case.
  final Map<String, dynamic>? match;
  final bool compact;

  int get _score => (match?['score'] as num?)?.toInt() ?? 0;

  static Color colorFor(int score) {
    if (score >= 75) return AppColors.forest600;
    if (score >= 50) return AppColors.gold500;
    return AppColors.hint;
  }

  static String labelFor(int score) {
    if (score >= 75) return 'Strong match';
    if (score >= 50) return 'Good match';
    if (score >= 25) return 'Some overlap';
    return 'Low match';
  }

  @override
  Widget build(BuildContext context) {
    if (match == null) return const SizedBox.shrink();
    final score = _score;
    final color = colorFor(score);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.favorite_rounded, size: compact ? 12 : 14, color: color),
            const SizedBox(width: 5),
            Text(
              compact ? '$score% match' : '$score% · ${labelFor(score)}',
              style: body(compact ? 11 : 13,
                  weight: FontWeight.w700, color: color),
            ),
          ],
        ),
        SizedBox(height: compact ? 4 : 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: score / 100,
            minHeight: compact ? 4 : 7,
            backgroundColor: AppColors.creamDark,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

/// The reasons behind a score — what lined up, and what did not.
class MatchDetail extends StatelessWidget {
  const MatchDetail({super.key, required this.match});

  final Map<String, dynamic>? match;

  List<String> _list(String key) =>
      ((match?[key] as List?) ?? const []).map((e) => e.toString()).toList();

  @override
  Widget build(BuildContext context) {
    if (match == null) return const SizedBox.shrink();
    final reasons = _list('reasons');
    final blockers = _list('blockers');
    if (reasons.isEmpty && blockers.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MatchBar(match: match),
        const SizedBox(height: 14),
        for (final r in reasons)
          _row(Icons.check_circle_rounded, AppColors.forest600, r),
        for (final b in blockers)
          _row(Icons.remove_circle_outline_rounded, AppColors.gold700, b),
        const SizedBox(height: 10),
        Text(
          'Based on the preferences you and they have filled in — age, gotra, location and mangal dosha. It is a comparison of stated preferences, not advice.',
          style: body(11, color: AppColors.textMuted, height: 1.4),
        ),
      ],
    );
  }

  Widget _row(IconData icon, Color color, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(text,
                  style: body(13, color: AppColors.label, height: 1.35)),
            ),
          ],
        ),
      );
}
