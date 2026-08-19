/// STEP 75 — the detailed Kuja Dosha / Manglik section of the full
/// compatibility report. Purely a display transform over
/// [CompatibilityReport.kujaDosha] — nothing here derives Mars' house,
/// applies a cancellation rule, or computes a percentage. The backend's own
/// terminology (MILD/MODERATE/STRONG/CANCELLED/BALANCED_WITH_PARTNER) is
/// used exactly as returned.
library;

import 'package:flutter/material.dart';

import '../data/models/compatibility_astrology_modules.dart'
    show KujaCancellationFinding, KujaDosha, KujaReferenceFinding, PartnerKujaResult;
import '../theme/app_theme.dart';
import 'compatibility_status_ui.dart';
import 'ui_kit.dart';

class KujaDoshaSection extends StatelessWidget {
  const KujaDoshaSection({super.key, required this.kujaDosha});

  final KujaDosha? kujaDosha;

  @override
  Widget build(BuildContext context) {
    final k = kujaDosha;
    if (k == null) {
      return const CompatibilityUnavailableNotice(
        title: 'Kuja Dosha not available',
        message: 'This report does not include a Kuja Dosha (Manglik) result.',
      );
    }

    final visual = kujaDoshaStatusVisual(k.comparison.status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CompatibilitySectionHeader(
                eyebrow: 'Kuja Dosha / Manglik',
                title: 'Pair Result',
                trailing: Pill(visual.label, fg: visual.color, icon: visual.icon),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _partnerCard('Bride', k.bride),
        const SizedBox(height: 10),
        _partnerCard('Groom', k.groom),
      ],
    );
  }

  Widget _partnerCard(String who, PartnerKujaResult p) {
    final visual = kujaDoshaStatusVisual(p.status);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(who, style: body(14, weight: FontWeight.w700, color: AppColors.forest900))),
              Pill(visual.label, fg: visual.color, icon: visual.icon),
            ],
          ),
          if (p.marsRashiName != null) ...[
            const SizedBox(height: 6),
            Text('Mars in ${p.marsRashiName}', style: body(12, color: AppColors.textMuted)),
          ],
          if (p.explanation.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(p.explanation, style: body(12, color: AppColors.textMuted, height: 1.4)),
          ],
          const SizedBox(height: 8),
          if (p.fromLagna != null) _referenceRow('From Lagna', p.fromLagna!),
          if (p.fromMoon != null) _referenceRow('From Moon', p.fromMoon!),
          if (p.fromVenus != null) _referenceRow('From Venus', p.fromVenus!),
          if (p.cancellationFindings.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Cancellation findings',
                style: body(12, weight: FontWeight.w700, color: AppColors.gold700, letterSpacing: 0.6)),
            for (final c in p.cancellationFindings) _cancellationRow(c),
          ],
        ],
      ),
    );
  }

  Widget _referenceRow(String label, KujaReferenceFinding f) {
    final valueParts = <String>[
      if (f.marsHouse != null) 'House ${f.marsHouse}',
      if (f.affected != null) (f.affected! ? 'Affected' : 'Not affected'),
    ];
    return FindingRow(
      title: label,
      visual: moduleStatusVisual(f.status),
      valueLabel: valueParts.isEmpty ? null : valueParts.join(' · '),
      explanation: f.explanation,
    );
  }

  Widget _cancellationRow(KujaCancellationFinding c) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.verified_rounded, size: 16, color: AppColors.forest700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(c.explanation.isNotEmpty ? c.explanation : humanizeCode(c.ruleId),
                style: body(12, color: AppColors.textMuted, height: 1.35)),
          ),
        ],
      ),
    );
  }
}
