/// STEP 76 — the detailed Vivaha Kala Bala (marriage timing) section of the
/// full compatibility report. Purely a display transform over
/// [CompatibilityReport.vivahaKalaBala] — nothing here derives a Bala
/// classification, Tara position, transit, or Dasha timing; every value
/// shown is exactly what the backend computed. `status` never becomes a
/// percentage.
library;

import 'package:flutter/material.dart';

import '../data/models/compatibility_astrology_modules.dart'
    show
        BalaFinding,
        DashaTimingFinding,
        GocharFinding,
        PartnerBalaFinding,
        PartnerDashaTimingFinding,
        PartnerTaraBalaFinding,
        PartnerVivahaTimingResult,
        TaraBalaFinding,
        TransitPositionSummary,
        VivahaKalaBala;
import '../theme/app_theme.dart';
import 'compatibility_status_ui.dart';
import 'ui_kit.dart';

class VivahaKalaBalaSection extends StatelessWidget {
  const VivahaKalaBalaSection({super.key, required this.vivahaKalaBala});

  final VivahaKalaBala? vivahaKalaBala;

  @override
  Widget build(BuildContext context) {
    final v = vivahaKalaBala;
    if (v == null) {
      return const CompatibilityUnavailableNotice(
        title: 'Vivaha Kala Bala not available',
        message: 'This report does not include a marriage-timing (Vivaha Kala Bala) result.',
      );
    }

    final visual = favorabilityStatusVisual(v.status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CompatibilitySectionHeader(
                eyebrow: 'Vivaha Kala Bala',
                title: 'Marriage Timing',
                trailing: Pill(visual.label, fg: visual.color, icon: visual.icon),
              ),
              const Divider(height: 24),
              _timingResultRow('Bride', v.bride),
              _timingResultRow('Groom', v.groom),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _balaCard('Guru Bala', v.guruBala),
        const SizedBox(height: 10),
        _balaCard('Shukra Bala', v.shukraBala),
        const SizedBox(height: 10),
        _balaCard('Chandra Bala', v.chandraBala),
        const SizedBox(height: 10),
        _taraBalaCard(v.taraBala),
        const SizedBox(height: 10),
        _gocharCard(v.gochar),
        const SizedBox(height: 10),
        _dashaTimingCard(v.dashaTiming),
      ],
    );
  }

  Widget _timingResultRow(String who, PartnerVivahaTimingResult r) {
    return FindingRow(title: who, visual: moduleStatusVisual(r.status), explanation: r.explanation);
  }

  Widget _balaCard(String title, BalaFinding b) {
    final visual = moduleStatusVisual(b.status);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: body(14, weight: FontWeight.w700, color: AppColors.forest900))),
              Pill(visual.label, fg: visual.color, icon: visual.icon),
            ],
          ),
          if (b.explanation.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(b.explanation, style: body(12, color: AppColors.textMuted, height: 1.4)),
          ],
          if (b.transitPosition != null) ...[
            const SizedBox(height: 6),
            Text(_positionLabel(b.transitPosition!), style: body(11, color: AppColors.hint)),
          ],
          const SizedBox(height: 6),
          _balaPartnerRow('Bride', b.bride),
          _balaPartnerRow('Groom', b.groom),
        ],
      ),
    );
  }

  Widget _balaPartnerRow(String who, PartnerBalaFinding p) {
    return FindingRow(
      title: who,
      visual: moduleStatusVisual(p.status),
      valueLabel: p.classification != null ? humanizeCode(p.classification!) : null,
      explanation: p.explanation,
    );
  }

  Widget _taraBalaCard(TaraBalaFinding t) {
    final visual = moduleStatusVisual(t.status);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Tara Bala', style: body(14, weight: FontWeight.w700, color: AppColors.forest900))),
              Pill(visual.label, fg: visual.color, icon: visual.icon),
            ],
          ),
          if (t.explanation.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(t.explanation, style: body(12, color: AppColors.textMuted, height: 1.4)),
          ],
          if (t.transitMoonPosition != null) ...[
            const SizedBox(height: 6),
            Text('Transiting Moon - ${_positionLabel(t.transitMoonPosition!)}', style: body(11, color: AppColors.hint)),
          ],
          const SizedBox(height: 6),
          _taraPartnerRow('Bride', t.bride),
          _taraPartnerRow('Groom', t.groom),
        ],
      ),
    );
  }

  Widget _taraPartnerRow(String who, PartnerTaraBalaFinding p) {
    final valueParts = <String>[
      if (p.taraPosition != null) 'Tara ${p.taraPosition}',
      if (p.classification != null) humanizeCode(p.classification!),
    ];
    return FindingRow(
      title: who,
      visual: moduleStatusVisual(p.status),
      valueLabel: valueParts.isEmpty ? null : valueParts.join(' · '),
      explanation: p.explanation,
    );
  }

  Widget _gocharCard(GocharFinding g) {
    final visual = moduleStatusVisual(g.status);
    final positions = g.transitPositions;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Gochar (Transits)', style: body(14, weight: FontWeight.w700, color: AppColors.forest900))),
              Pill(visual.label, fg: visual.color, icon: visual.icon),
            ],
          ),
          if (g.explanation.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(g.explanation, style: body(12, color: AppColors.textMuted, height: 1.4)),
          ],
          if (positions != null && positions.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final entry in positions.entries)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Expanded(child: Text(humanizeCode(entry.key), style: body(12, weight: FontWeight.w600, color: AppColors.ink))),
                    Text(_positionLabel(entry.value), style: body(11, color: AppColors.textMuted)),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _dashaTimingCard(DashaTimingFinding d) {
    final visual = moduleStatusVisual(d.status);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Dasha Timing', style: body(14, weight: FontWeight.w700, color: AppColors.forest900))),
              Pill(visual.label, fg: visual.color, icon: visual.icon),
            ],
          ),
          if (d.explanation.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(d.explanation, style: body(12, color: AppColors.textMuted, height: 1.4)),
          ],
          const SizedBox(height: 6),
          _dashaTimingPartnerRow('Bride', d.bride),
          _dashaTimingPartnerRow('Groom', d.groom),
        ],
      ),
    );
  }

  Widget _dashaTimingPartnerRow(String who, PartnerDashaTimingFinding p) {
    final valueParts = <String>[
      if (p.currentMahadashaLord != null) 'MD: ${humanizeCode(p.currentMahadashaLord!)}',
      if (p.currentAntardashaLord != null) 'AD: ${humanizeCode(p.currentAntardashaLord!)}',
    ];
    return FindingRow(
      title: who,
      visual: moduleStatusVisual(p.status),
      valueLabel: p.timingClassification != null ? humanizeCode(p.timingClassification!) : null,
      explanation: valueParts.isEmpty ? p.explanation : '${valueParts.join(' · ')}${p.explanation.isEmpty ? '' : ' - ${p.explanation}'}',
    );
  }

  String _positionLabel(TransitPositionSummary p) {
    return 'Rashi ${p.rashiId} · Nakshatra ${p.nakshatraId} Pada ${p.nakshatraPada}'
        '${p.isRetrograde ? ' · Retrograde' : ''}';
  }
}
