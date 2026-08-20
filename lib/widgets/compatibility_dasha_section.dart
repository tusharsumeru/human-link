/// STEP 76 — the detailed Dasha Compatibility section of the full
/// compatibility report. Purely a display transform over
/// [CompatibilityReport.dasha] — nothing here recomputes a Vimshottari
/// Mahadasha/Antardasha timeline, a Sandhi window, or a marriage-significator
/// rule. `assessmentDate` is shown exactly as the backend persisted it.
library;

import 'package:flutter/material.dart';

import '../data/models/compatibility_astrology_modules.dart'
    show DashaCompatibility, DashaSandhiFinding, MarriageSignificatorDashaFinding, PartnerDashaResult;
import '../theme/app_theme.dart';
import 'compatibility_status_ui.dart';
import 'ui_kit.dart';

class DashaCompatibilitySection extends StatelessWidget {
  const DashaCompatibilitySection({super.key, required this.dasha});

  final DashaCompatibility? dasha;

  @override
  Widget build(BuildContext context) {
    final d = dasha;
    if (d == null) {
      return const CompatibilityUnavailableNotice(
        title: 'Dasha Compatibility not available',
        message: 'This report does not include a Dasha Compatibility result.',
      );
    }

    final visual = dashaComparisonStatusVisual(d.comparison.status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CompatibilitySectionHeader(
                eyebrow: 'Dasha Compatibility',
                title: 'Pair Result',
                trailing: Pill(visual.label, fg: visual.color, icon: visual.icon),
              ),
              if (d.comparison.explanation.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(d.comparison.explanation, style: body(13, color: AppColors.textMuted, height: 1.4)),
              ],
              const SizedBox(height: 8),
              Text('Assessment date: ${formatCompatDate(d.assessmentDate)}',
                  style: body(11, color: AppColors.hint)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _partnerSection('Bride', d.bride),
        const SizedBox(height: 10),
        _partnerSection('Groom', d.groom),
      ],
    );
  }

  Widget _partnerSection(String who, PartnerDashaResult p) {
    return CompatibilityExpandableSection(
      title: who,
      subtitle: p.birthNakshatraName != null ? 'Birth Nakshatra: ${p.birthNakshatraName}' : null,
      children: [
        if (p.currentMahadasha != null)
          _periodRow('Current Mahadasha', p.currentMahadasha!.lord, p.currentMahadasha!.startDate, p.currentMahadasha!.endDate),
        if (p.currentAntardasha != null)
          _periodRow('Current Antardasha', p.currentAntardasha!.lord, p.currentAntardasha!.startDate, p.currentAntardasha!.endDate),
        if (p.nextMahadasha != null)
          _periodRow('Next Mahadasha', p.nextMahadasha!.lord, p.nextMahadasha!.startDate, p.nextMahadasha!.endDate),
        if (p.nextAntardasha != null)
          _periodRow('Next Antardasha', p.nextAntardasha!.lord, p.nextAntardasha!.startDate, p.nextAntardasha!.endDate),
        if (p.marriageSignificatorDasha != null) ...[
          const SizedBox(height: 6),
          _marriageSignificatorRow(p.marriageSignificatorDasha!),
        ],
        if (p.sandhiFindings.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('Sandhi findings',
              style: body(12, weight: FontWeight.w700, color: AppColors.gold700, letterSpacing: 0.6)),
          for (final s in p.sandhiFindings) _sandhiRow(s),
        ],
        if (p.mahadashas.isNotEmpty) ...[
          const SizedBox(height: 10),
          CompatibilityExpandableSection(
            title: 'Full Mahadasha Timeline',
            children: [for (final m in p.mahadashas) _timelineRow(m.lord, m.startDate, m.endDate)],
          ),
        ],
      ],
    );
  }

  Widget _periodRow(String label, String lord, DateTime? start, DateTime? end) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(label, style: body(13, weight: FontWeight.w700, color: AppColors.ink)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(humanizeCode(lord), style: body(13, weight: FontWeight.w700, color: AppColors.forest700)),
                Text('${formatCompatDate(start)} - ${formatCompatDate(end)}',
                    style: body(11, color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _timelineRow(String lord, DateTime? start, DateTime? end) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(humanizeCode(lord), style: body(12, weight: FontWeight.w600, color: AppColors.ink))),
          Text('${formatCompatDate(start)} - ${formatCompatDate(end)}',
              style: body(11, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Widget _sandhiRow(DashaSandhiFinding s) {
    return FindingRow(
      title: '${humanizeCode(s.previousMahadashaLord)} → ${humanizeCode(s.nextMahadashaLord)}',
      visual: moduleStatusVisual(s.status),
      valueLabel: s.withinWindow != null ? (s.withinWindow! ? 'Within window' : 'Outside window') : null,
      explanation: s.explanation,
    );
  }

  Widget _marriageSignificatorRow(MarriageSignificatorDashaFinding f) {
    final matches = <String>[
      ...f.matchedMahadashaSignificators.map((m) => 'Mahadasha: ${humanizeCode(m)}'),
      ...f.matchedAntardashaSignificators.map((m) => 'Antardasha: ${humanizeCode(m)}'),
    ];
    return FindingRow(
      title: 'Marriage-significator Dasha',
      visual: moduleStatusVisual(f.status),
      valueLabel: matches.isEmpty ? null : matches.join(', '),
      explanation: f.explanation,
    );
  }
}
