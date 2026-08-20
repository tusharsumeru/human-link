/// STEP 74 — the detailed Ashtakoota (36 Guna) section of the full
/// compatibility report. Purely a display transform over
/// [CompatibilityReport.ashtakoota]/`astrologyCompatibility.ashtakoota` —
/// nothing here recomputes a Koota, an earned score, or a percentage.
library;

import 'package:flutter/material.dart';

import '../data/models/compatibility_summary.dart' show AstrologyAshtakootaSummary;
import '../data/models/south_indian_jataka.dart'
    show AshtakootaResult, KootaResult, kootaLabel, orderedKootas;
import '../theme/app_theme.dart';
import 'compatibility_status_ui.dart';
import 'ui_kit.dart';

class AshtakootaSection extends StatelessWidget {
  const AshtakootaSection({super.key, required this.ashtakoota, this.summary});

  final AshtakootaResult? ashtakoota;

  /// The Astrology Compatibility summary's own Ashtakoota slice — carries
  /// the rounded percentage figure the plain [AshtakootaResult] doesn't.
  /// Shown alongside `earned/maximum` only when it agrees with them (same
  /// underlying calculation) — never independently trusted.
  final AstrologyAshtakootaSummary? summary;

  @override
  Widget build(BuildContext context) {
    final a = ashtakoota;
    if (a == null) {
      return const CompatibilityUnavailableNotice(
        title: 'Ashtakoota not available',
        message: 'This report does not include an Ashtakoota (36 Guna) result.',
      );
    }

    if (a.isUnavailable) {
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CompatibilitySectionHeader(eyebrow: 'Ashtakoota / 36 Guna', title: 'Ashtakoota Score'),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.hourglass_top_rounded, size: 18, color: AppColors.hint),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    a.requiresReview
                        ? 'Ashtakoota is incomplete - one or more Kootas require review.'
                        : 'Ashtakoota calculation is currently unavailable.',
                    style: body(13, color: AppColors.textMuted, height: 1.4),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    final pct = (summary != null && summary!.earned == a.earned) ? summary!.percentage : null;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CompatibilitySectionHeader(eyebrow: 'Ashtakoota / 36 Guna', title: 'Ashtakoota Score'),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('${a.earned} / ${a.maximum}', style: display(26, color: AppColors.forest900)),
              if (pct != null) ...[
                const SizedBox(width: 10),
                Text('${pct.toStringAsFixed(1)}%', style: body(14, weight: FontWeight.w700, color: AppColors.gold700)),
              ],
            ],
          ),
          const SizedBox(height: 12),
          for (final koota in orderedKootas(a.kootas)) _kootaRow(koota),
        ],
      ),
    );
  }

  Widget _kootaRow(KootaResult k) {
    final visual = poruthamStatusVisual(k.status);
    return FindingRow(
      title: kootaLabel(k.code),
      visual: visual,
      valueLabel: k.earned != null ? '${k.earned}/${k.maximum}' : null,
      explanation: k.explanation,
    );
  }
}
