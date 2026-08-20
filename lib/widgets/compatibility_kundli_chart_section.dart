/// STEP 80 — the detailed Kundli / Janma Kundali (birth chart) section of
/// the full compatibility report. Purely a display transform over
/// [CompatibilityReport.kundliChart] — nothing here derives a Graha, Rashi,
/// Nakshatra, Pada, or Lagna position; every placement shown is exactly what
/// the backend snapshotted at calculation time. A purely presentational
/// addition — carries no status/verdict/score, and is never combined with
/// any of the seven traditional-astrology systems elsewhere in this report.
library;

import 'package:flutter/material.dart';

import '../data/models/kundli_chart.dart';
import '../theme/app_theme.dart';
import 'compatibility_status_ui.dart';
import 'south_indian_kundli_chart.dart';
import 'ui_kit.dart';

class KundliChartSection extends StatelessWidget {
  const KundliChartSection({super.key, required this.kundliChart});

  final KundliChart? kundliChart;

  @override
  Widget build(BuildContext context) {
    final k = kundliChart;
    final bride = k?.bride;
    final groom = k?.groom;
    if (k == null || bride == null || groom == null) {
      return const CompatibilityUnavailableNotice(
        title: 'Kundli chart not available',
        message: 'This report does not include a Kundli chart result.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          child: CompatibilitySectionHeader(
            eyebrow: 'Kundli Chart',
            title: 'Birth Chart (South Indian Style)',
          ),
        ),
        const SizedBox(height: 12),
        _PartnerKundliCard(who: 'Bride', chart: bride),
        const SizedBox(height: 10),
        _PartnerKundliCard(who: 'Groom', chart: groom),
      ],
    );
  }
}

class _PartnerKundliCard extends StatelessWidget {
  const _PartnerKundliCard({required this.who, required this.chart});

  final String who;
  final PartnerKundliChart chart;

  @override
  Widget build(BuildContext context) {
    final navamshaLagna = chart.navamshaLagna;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(who, style: body(14, weight: FontWeight.w700, color: AppColors.forest900)),
          const SizedBox(height: 2),
          Text('Lagna: ${chart.lagnaRashiName}', style: body(12, color: AppColors.textMuted)),
          const SizedBox(height: 14),
          Center(
            child: SouthIndianKundliChart(
              lagnaRashiId: chart.lagnaId,
              planetLabelsByRashi: _planetLabelsByRashi(chart.planets),
              rashiNamesById: _d1RashiNames(chart),
              chartLabel: 'D1',
              size: 300,
            ),
          ),
          const SizedBox(height: 12),
          CompatibilityExpandableSection(
            title: 'View Planet Details',
            subtitle: '${chart.planets.length} Grahas',
            children: [
              for (final planet in orderedKundliPlanets(chart.planets)) _planetDetailRow(planet),
            ],
          ),
          const SizedBox(height: 10),
          if (chart.hasNavamsha)
            CompatibilityExpandableSection(
              title: 'Navamsha (D9) Chart',
              subtitle: navamshaLagna != null ? 'Lagna: ${navamshaLagna.rashiName}' : null,
              children: [
                Center(
                  child: SouthIndianKundliChart(
                    lagnaRashiId: navamshaLagna?.rashiId ?? 0,
                    planetLabelsByRashi: _navamshaLabelsByRashi(chart.navamsha),
                    rashiNamesById: _d9RashiNames(chart.navamsha),
                    chartLabel: 'D9',
                    size: 280,
                  ),
                ),
              ],
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                'Navamsha chart is not available for this report.',
                style: body(12, color: AppColors.hint, height: 1.4),
              ),
            ),
        ],
      ),
    );
  }

  Widget _planetDetailRow(KundliPlanetPosition p) {
    final parts = <String>[grahaFullName(p.graha)];
    final valueParts = <String>[p.rashiName];
    if (p.nakshatraName.isNotEmpty) {
      valueParts.add('${p.nakshatraName} Pada ${p.nakshatraPada}');
    }
    if (p.isRetrograde) valueParts.add('Retrograde');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(parts.join(), style: body(13, weight: FontWeight.w700, color: AppColors.ink)),
          ),
          Expanded(
            child: Text(valueParts.join(' · '), style: body(12, color: AppColors.textMuted)),
          ),
        ],
      ),
    );
  }

  Map<int, List<String>> _planetLabelsByRashi(List<KundliPlanetPosition> planets) {
    final map = <int, List<String>>{};
    for (final p in orderedKundliPlanets(planets)) {
      final label = grahaShortLabel(p.graha) + (p.isRetrograde ? '(R)' : '');
      map.putIfAbsent(p.rashiId, () => []).add(label);
    }
    return map;
  }

  Map<int, String> _d1RashiNames(PartnerKundliChart chart) {
    final map = <int, String>{};
    for (final p in chart.planets) {
      if (p.rashiName.isNotEmpty) map[p.rashiId] = p.rashiName;
    }
    if (chart.lagnaRashiName.isNotEmpty) map[chart.lagnaId] = chart.lagnaRashiName;
    return map;
  }

  Map<int, List<String>> _navamshaLabelsByRashi(List<KundliNavamshaPosition> navamsha) {
    final map = <int, List<String>>{};
    for (final n in navamsha) {
      if (n.isLagna) continue; // the Lagna cell is marked via lagnaRashiId, not as a "planet" label
      map.putIfAbsent(n.rashiId, () => []).add(grahaShortLabel(n.point));
    }
    return map;
  }

  Map<int, String> _d9RashiNames(List<KundliNavamshaPosition> navamsha) {
    final map = <int, String>{};
    for (final n in navamsha) {
      if (n.rashiName.isNotEmpty) map[n.rashiId] = n.rashiName;
    }
    return map;
  }
}
