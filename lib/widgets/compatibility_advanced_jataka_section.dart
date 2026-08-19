/// STEP 75 — the detailed Advanced Jataka section of the full compatibility
/// report. Purely a display transform over
/// [CompatibilityReport.advancedJataka] — nothing here derives a Lagna,
/// house occupant, aspect, or Navamsha placement; every finding is rendered
/// exactly as the backend computed it. `status` never becomes a percentage.
library;

import 'package:flutter/material.dart';

import '../data/models/compatibility_astrology_modules.dart'
    show AdvancedJataka, AdvancedJatakaFinding, PartnerAdvancedJataka;
import '../theme/app_theme.dart';
import 'compatibility_status_ui.dart';
import 'ui_kit.dart';

const _natalLabels = <String>[
  'Lagna',
  'Lagna Lord',
  '7th House',
  '7th Lord',
  '7th House Occupants',
  '7th House Aspects (Graha Drishti)',
  'Venus',
  'Jupiter',
  'Moon',
  'Mars',
];

const _navamshaLabels = <String>[
  'D9 Lagna',
  'D9 7th House',
  'D9 7th Lord',
  'D9 Venus',
  'D9 Jupiter',
];

class AdvancedJatakaSection extends StatelessWidget {
  const AdvancedJatakaSection({super.key, required this.advancedJataka});

  final AdvancedJataka? advancedJataka;

  @override
  Widget build(BuildContext context) {
    final aj = advancedJataka;
    if (aj == null) {
      return const CompatibilityUnavailableNotice(
        title: 'Advanced Jataka not available',
        message: 'This report does not include an Advanced Jataka result.',
      );
    }

    final visual = favorabilityStatusVisual(aj.status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CompatibilitySectionHeader(
                eyebrow: 'Advanced Jataka',
                title: 'Chart Comparison',
                trailing: Pill(visual.label, fg: visual.color, icon: visual.icon),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _partnerSection('Bride', aj.bride),
        const SizedBox(height: 10),
        _partnerSection('Groom', aj.groom),
      ],
    );
  }

  Widget _partnerSection(String who, PartnerAdvancedJataka p) {
    return CompatibilityExpandableSection(
      title: who,
      subtitle: 'Natal chart + Navamsha (D9) findings',
      children: [
        Text('Natal Chart', style: body(12, weight: FontWeight.w700, color: AppColors.gold700, letterSpacing: 0.6)),
        for (var i = 0; i < p.natalFindings.length; i++) _findingRow(_natalLabels[i], p.natalFindings[i]),
        const SizedBox(height: 8),
        Text('Navamsha (D9)', style: body(12, weight: FontWeight.w700, color: AppColors.gold700, letterSpacing: 0.6)),
        for (var i = 0; i < p.navamshaFindings.length; i++) _findingRow(_navamshaLabels[i], p.navamshaFindings[i]),
      ],
    );
  }

  Widget _findingRow(String label, AdvancedJatakaFinding finding) {
    return FindingRow(
      title: label,
      visual: moduleStatusVisual(finding.status),
      explanation: _explanationFor(finding),
    );
  }

  String _explanationFor(AdvancedJatakaFinding f) {
    if (f.explanation.isNotEmpty) return f.explanation;
    final data = f.data;
    if (data == null || data.isEmpty) return '';
    return data.entries.map((e) => '${humanizeKey(e.key)}: ${e.value}').join(' · ');
  }
}
