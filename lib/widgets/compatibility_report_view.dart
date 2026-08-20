import 'package:flutter/material.dart';

import '../data/models/compatibility_models.dart';
import '../theme/app_theme.dart';
import 'compatibility_advanced_jataka_section.dart';
import 'compatibility_ashtakoota_section.dart';
import 'compatibility_dasha_section.dart';
import 'compatibility_kuja_dosha_section.dart';
import 'compatibility_kundli_chart_section.dart';
import 'compatibility_parampara_section.dart';
import 'compatibility_vivaha_kala_bala_section.dart';
import 'ui_kit.dart';

/// Renders a [CompatibilityReport]'s Jataka section — extracted from
/// CompatibilityScreen (STEP 25D) so both the "calculate now" flow and
/// [CompatibilityReportScreen]'s "fetch a saved report by id" flow render it
/// identically without duplicating this logic. Purely a display transform:
/// every value shown comes straight off the API response — nothing here
/// computes a Nakshatra, Rashi, Porutham result, or any score.
class CompatibilityReportView extends StatelessWidget {
  const CompatibilityReportView({super.key, required this.report});

  final CompatibilityReport report;

  @override
  Widget build(BuildContext context) {
    final jataka = report.jataka;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (jataka == null)
          _notice(
            icon: Icons.info_outline_rounded,
            title: 'No Jataka result',
            message: 'The report was generated but did not include a Jataka section.',
          )
        else
          ..._karnatakaSections(jataka),
        const SizedBox(height: 14),
        AshtakootaSection(ashtakoota: report.ashtakoota, summary: report.astrologyCompatibility?.ashtakoota),
        const SizedBox(height: 14),
        AdvancedJatakaSection(advancedJataka: report.advancedJataka),
        const SizedBox(height: 14),
        KujaDoshaSection(kujaDosha: report.kujaDosha),
        const SizedBox(height: 14),
        DashaCompatibilitySection(dasha: report.dasha),
        const SizedBox(height: 14),
        VivahaKalaBalaSection(vivahaKalaBala: report.vivahaKalaBala),
        const SizedBox(height: 14),
        DaivagnaParamparaSection(parampara: report.daivagnaParampara),
        const SizedBox(height: 14),
        KundliChartSection(kundliChart: report.kundliChart),
        if (report.disclaimer.isNotEmpty) ...[
          const SizedBox(height: 14),
          _disclaimerCard(report.disclaimer),
        ],
        if (report.notImplementedInclude.isNotEmpty) ...[
          const SizedBox(height: 14),
          _notImplementedCard(report.notImplementedInclude),
        ],
      ],
    );
  }

  List<Widget> _karnatakaSections(CompatibilityJataka jataka) {
    final boundaryRiskCard = _boundaryRiskCard(jataka);
    return [
      if (boundaryRiskCard != null) ...[boundaryRiskCard, const SizedBox(height: 14)],
      _verdictCard(jataka),
      const SizedBox(height: 14),
      _countsRow(jataka),
      const SizedBox(height: 14),
      if (jataka.criticalAlerts.isNotEmpty) ...[
        _criticalAlertsCard(jataka.criticalAlerts),
        const SizedBox(height: 14),
      ],
      _poruthamListCard(jataka),
    ];
  }

  Widget _disclaimerCard(String disclaimer) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.creamDark,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.hint),
          const SizedBox(width: 8),
          Expanded(child: Text(disclaimer, style: body(11, color: AppColors.hint, height: 1.4))),
        ],
      ),
    );
  }

  Widget _notice({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return AppCard(
      color: const Color(0xFFFFF8E8),
      border: false,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.gold700),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: body(14, weight: FontWeight.w700, color: AppColors.gold700)),
                const SizedBox(height: 4),
                Text(message, style: body(13, color: AppColors.textMuted, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// STEP 25D §4 — a module the request asked for but the backend has no
  /// engine for yet (e.g. PROFILE/FAMILY/PERSONALITY today) always lands
  /// here, never as a request failure: the report above is still valid for
  /// whatever WAS calculated.
  Widget _notImplementedCard(List<String> modules) {
    return _notice(
      icon: Icons.hourglass_top_rounded,
      title: 'Not yet available',
      message:
          '${modules.join(', ')} compatibility isn\'t implemented yet - this report only '
          'covers what could actually be calculated above.',
    );
  }

  /// The confidence/review message for birth-time uncertainty (compatibility
  /// spec §10) — shown only when the backend actually signaled some risk.
  /// Never computed here: [CompatibilityJataka.nakshatraBoundaryRiskOverride]
  /// and each side's [BoundaryRisk] flags come straight from the API: this
  /// widget only chooses how to *display* them, never whether they're true.
  Widget? _boundaryRiskCard(CompatibilityJataka jataka) {
    final bride = jataka.brideBoundaryRisk;
    final groom = jataka.groomBoundaryRisk;
    if (bride == null || groom == null) return null;

    final anyRisk = jataka.nakshatraBoundaryRiskOverride || bride.hasAnyRisk || groom.hasAnyRisk;
    if (!anyRisk) return null;

    // Nakshatra-level risk is the severe case — the backend already forced
    // every Porutham to REVIEW_REQUIRED because of it. Anything less (only
    // Pada/Rashi/Lagna/Navamsha uncertain) is a softer "lower confidence"
    // note, matching spec §10: "If only Lagna changes... low confidence,"
    // not a full review-required state.
    final critical = jataka.nakshatraBoundaryRiskOverride;
    final bg = critical ? const Color(0xFFFEF2F2) : const Color(0xFFFFF8E8);
    final fg = critical ? Colors.red.shade700 : AppColors.gold700;

    return AppCard(
      color: bg,
      border: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(critical ? Icons.warning_amber_rounded : Icons.info_outline_rounded,
                  size: 18, color: fg),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  critical
                      ? 'Review required - birth-time uncertainty'
                      : 'Reduced confidence - birth-time uncertainty',
                  style: body(13, weight: FontWeight.w700, color: fg),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            critical
                ? "One or both birth times aren't precise enough to rule out a "
                    'different Nakshatra - every Porutham below is marked '
                    '"Review required" rather than trusting a single estimate.'
                : 'Birth-time uncertainty may affect some factors below (e.g. '
                    'Lagna) - treat those as lower-confidence.',
            style: body(12, color: AppColors.textMuted, height: 1.4),
          ),
          const SizedBox(height: 10),
          _boundaryRiskRow('Bride', bride),
          const SizedBox(height: 6),
          _boundaryRiskRow('Groom', groom),
        ],
      ),
    );
  }

  Widget _boundaryRiskRow(String who, BoundaryRisk risk) {
    final flags = <String>[
      if (risk.nakshatraMayChange) 'Nakshatra',
      if (risk.padaMayChange) 'Pada',
      if (risk.rashiMayChange) 'Rashi',
      if (risk.lagnaMayChange) 'Lagna',
      if (risk.navamshaMayChange) 'Navamsha',
    ];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 46,
          child: Text(who, style: body(11, weight: FontWeight.w700, color: AppColors.ink)),
        ),
        Expanded(
          child: Text(
            '${birthTimeAccuracyLabels[risk.birthTimeAccuracy]} '
            '(${(risk.confidence * 100).round()}% confidence)'
            '${flags.isEmpty ? '' : ' - may affect: ${flags.join(', ')}'}',
            style: body(11, color: AppColors.textMuted, height: 1.35),
          ),
        ),
      ],
    );
  }

  Widget _verdictCard(CompatibilityJataka jataka) {
    final (Color bg, Color fg, IconData icon) = switch (jataka.verdict) {
      TraditionalVerdictCode.strong =>
        (const Color(0xFFF0FBF4), AppColors.forest700, Icons.favorite_rounded),
      TraditionalVerdictCode.good => (
          const Color(0xFFF0FBF4),
          AppColors.forest700,
          Icons.favorite_outline_rounded
        ),
      TraditionalVerdictCode.moderate =>
        (const Color(0xFFFFF8E8), AppColors.gold700, Icons.balance_rounded),
      TraditionalVerdictCode.low =>
        (const Color(0xFFFEF2F2), Colors.red.shade700, Icons.trending_down_rounded),
      TraditionalVerdictCode.criticalReview =>
        (const Color(0xFFFEF2F2), Colors.red.shade700, Icons.warning_amber_rounded),
      TraditionalVerdictCode.expertReviewRequired || TraditionalVerdictCode.unknown =>
        (const Color(0xFFFFF8E8), AppColors.gold700, Icons.hourglass_top_rounded),
    };
    return AppCard(
      color: bg,
      border: false,
      child: Row(
        children: [
          Icon(icon, size: 28, color: fg),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('South Indian Jataka',
                    style: body(11,
                        weight: FontWeight.w700, color: fg, letterSpacing: 1)),
                const SizedBox(height: 3),
                Text('${jataka.matched}/10 matched',
                    style: display(20, color: AppColors.forest900)),
                const SizedBox(height: 4),
                Text(jataka.verdictLabel,
                    style: body(13, weight: FontWeight.w600, color: fg)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _countsRow(CompatibilityJataka jataka) {
    final items = [
      ('Matched', jataka.matched, AppColors.forest700),
      ('Partial', jataka.partial, AppColors.gold700),
      ('Not matched', jataka.notMatched, Colors.red.shade700),
      if (jataka.reviewRequired > 0)
        ('Review', jataka.reviewRequired, AppColors.gold700),
      if (jataka.notCalculable > 0)
        ('Unavailable', jataka.notCalculable, AppColors.hint),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (label, count, color) in items)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.border),
            ),
            child: Text('$label: $count',
                style: body(12, weight: FontWeight.w700, color: color)),
          ),
      ],
    );
  }

  Widget _criticalAlertsCard(List<PoruthamResult> alerts) {
    return AppCard(
      color: const Color(0xFFFEF2F2),
      border: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, size: 18, color: Colors.red.shade700),
              const SizedBox(width: 8),
              Text('Important traditional concern',
                  style: body(14, weight: FontWeight.w700, color: Colors.red.shade800)),
            ],
          ),
          const SizedBox(height: 8),
          for (final a in alerts)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('${poruthamLabel(a.code)} did not match',
                  style: body(13, color: Colors.red.shade800)),
            ),
        ],
      ),
    );
  }

  Widget _poruthamListCard(CompatibilityJataka jataka) {
    final pending = jataka.poruthams.any((p) => p.status == PoruthamStatus.notCalculable);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('The 10 Poruthams', style: display(15, color: AppColors.forest900)),
          const SizedBox(height: 4),
          Text('Rule version: ${jataka.ruleVersion}',
              style: body(11, color: AppColors.textMuted)),
          if (jataka.normalizedPercentage != null) ...[
            const SizedBox(height: 2),
            Text('Normalized score: ${jataka.normalizedPercentage}%',
                style: body(11, color: AppColors.textMuted)),
          ],
          const SizedBox(height: 10),
          for (final p in jataka.poruthams) _poruthamRow(p),
          if (pending) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E8), borderRadius: BorderRadius.circular(10)),
              child: Text(
                'Some Poruthams show "Unavailable" because their Karnataka rule '
                'tables are still awaiting astrologer approval - not an error.',
                style: body(12, color: AppColors.gold700, height: 1.4),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Status → indicator icon/color/label. This only maps what the API
  /// returned in `status` — it never infers or recomputes a status itself.
  Widget _poruthamRow(PoruthamResult p) {
    final (IconData icon, Color color, String label) = switch (p.status) {
      PoruthamStatus.matched => (Icons.check_circle_rounded, AppColors.forest700, 'Matched'),
      PoruthamStatus.partial =>
        (Icons.adjust_rounded, AppColors.gold700, 'Partial'),
      PoruthamStatus.notMatched =>
        (Icons.cancel_rounded, Colors.red.shade700, 'Not matched'),
      PoruthamStatus.reviewRequired =>
        (Icons.rate_review_outlined, AppColors.gold700, 'Review required'),
      PoruthamStatus.notCalculable =>
        (Icons.remove_circle_outline_rounded, AppColors.hint, 'Unavailable'),
      PoruthamStatus.unknown => (Icons.help_outline_rounded, AppColors.hint, 'Unknown'),
    };
    final explanation = _explanationFor(p);
    final critical = p.isCritical;

    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(poruthamLabel(p.code),
                        style: body(13,
                            weight: FontWeight.w700,
                            color: critical ? Colors.red.shade800 : AppColors.ink)),
                  ),
                  if (critical) ...[
                    Icon(Icons.priority_high_rounded, size: 14, color: Colors.red.shade700),
                    const SizedBox(width: 2),
                  ],
                  Text(label, style: body(12, weight: FontWeight.w700, color: color)),
                ],
              ),
              // The backend's own explanation for this result — the computed
              // inputs (distance, tara position, gana/yoni compared, …) and,
              // for an unavailable result, the reason no rule matched. Shown
              // only when the API actually sent something.
              if (explanation.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(explanation, style: body(11, color: AppColors.textMuted, height: 1.3)),
              ],
            ],
          ),
        ),
      ],
    );

    if (!critical) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: content,
      );
    }

    // Rajju mismatches must always be prominent — a red-bordered card, not
    // just a small icon buried in the list.
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: content,
    );
  }

  /// The backend's explanation for one Porutham result: its computed
  /// `details` (free-form per Porutham — distance, tara position, gana/yoni
  /// compared, …), plus a readable form of `ruleId` when it's an
  /// "unavailable" reason code (e.g. "DINA_RULE_NOT_FOUND") rather than an
  /// approved rule-table row id. Purely a display transform — the underlying
  /// status/data always comes straight from the API.
  String _explanationFor(PoruthamResult p) {
    final parts = <String>[];
    if (p.details.isNotEmpty) {
      parts.add(p.details.entries
          .map((e) => '${_humanizeKey(e.key)}: ${e.value}')
          .join(' · '));
    }
    if (p.status == PoruthamStatus.notCalculable && p.ruleId.isNotEmpty) {
      parts.add(_humanizeReasonCode(p.ruleId));
    }
    return parts.join(' - ');
  }

  String _humanizeKey(String key) {
    final spaced = key.replaceAllMapped(
        RegExp(r'([a-z0-9])([A-Z])'), (m) => '${m[1]} ${m[2]}');
    return spaced.isEmpty
        ? spaced
        : spaced[0].toUpperCase() + spaced.substring(1).toLowerCase();
  }

  String _humanizeReasonCode(String code) {
    return code
        .split('_')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0] + w.substring(1).toLowerCase())
        .join(' ');
  }
}
