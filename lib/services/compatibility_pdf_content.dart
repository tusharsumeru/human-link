/// STEP 77–78 -pure, PDF-independent content builders for the Marriage
/// Compatibility PDF. Every function here only reads an already-parsed
/// [CompatibilityReport] (or one of its sections) and turns it into plain
/// display strings/rows -nothing here computes a Nakshatra, a score, a
/// percentage, or a discussion point. Kept separate from the actual `pdf`
/// package widget tree (compatibility_pdf.dart) so the content itself is
/// unit-testable without rendering a PDF.
library;

import '../data/models/compatibility_astrology_modules.dart';
import '../data/models/compatibility_models.dart';
import '../data/models/compatibility_summary.dart';
import '../data/models/kundli_chart.dart';
import '../data/models/parampara.dart';
import '../data/models/south_indian_jataka.dart';
import '../widgets/compatibility_status_ui.dart' show formatCompatDate, humanizeCode, humanizeKey;

const String kNotAvailable = 'Not Available';
const String kNotCalculable = 'Not Calculable';
const String kReviewRequired = 'Review Required';

String _pct(int? value) => value != null ? '$value%' : kNotAvailable;
String _pctD(double? value) => value != null ? '${value.toStringAsFixed(1)}%' : kNotAvailable;

String moduleStatusLabel(AstrologyModuleStatus status) => switch (status) {
      AstrologyModuleStatus.calculated => 'Calculated',
      AstrologyModuleStatus.reviewRequired => kReviewRequired,
      AstrologyModuleStatus.notCalculable => kNotCalculable,
      AstrologyModuleStatus.unknown => 'Unknown',
    };

String favorabilityStatusLabel(AstrologyFavorabilityStatus status) => switch (status) {
      AstrologyFavorabilityStatus.supportive => 'Supportive',
      AstrologyFavorabilityStatus.neutral => 'Neutral',
      AstrologyFavorabilityStatus.caution => 'Caution',
      AstrologyFavorabilityStatus.reviewRequired => kReviewRequired,
      AstrologyFavorabilityStatus.notCalculable => kNotCalculable,
      AstrologyFavorabilityStatus.unknown => 'Unknown',
    };

String kujaDoshaStatusLabel(KujaDoshaStatus status) => switch (status) {
      KujaDoshaStatus.notPresent => 'Not Present',
      KujaDoshaStatus.mild => 'Mild',
      KujaDoshaStatus.moderate => 'Moderate',
      KujaDoshaStatus.strong => 'Strong',
      KujaDoshaStatus.cancelled => 'Cancelled',
      KujaDoshaStatus.balancedWithPartner => 'Balanced With Partner',
      KujaDoshaStatus.reviewRequired => kReviewRequired,
      KujaDoshaStatus.notCalculable => kNotCalculable,
      KujaDoshaStatus.unknown => 'Unknown',
    };

String dashaComparisonStatusLabel(DashaComparisonStatus status) => switch (status) {
      DashaComparisonStatus.supportive => 'Supportive',
      DashaComparisonStatus.neutral => 'Neutral',
      DashaComparisonStatus.sensitiveTransition => 'Sensitive Transition',
      DashaComparisonStatus.reviewRequired => kReviewRequired,
      DashaComparisonStatus.notCalculable => kNotCalculable,
      DashaComparisonStatus.unknown => 'Unknown',
    };

String paramparaComparisonStatusLabel(ParamparaComparisonStatus status) => switch (status) {
      ParamparaComparisonStatus.match => 'Match',
      ParamparaComparisonStatus.informational => 'Informational',
      ParamparaComparisonStatus.reviewRequired => kReviewRequired,
      ParamparaComparisonStatus.notCalculable => kNotCalculable,
      ParamparaComparisonStatus.unknown => 'Unknown',
    };

String paramparaFieldStatusLabel(ParamparaFieldComparisonStatus status) => switch (status) {
      ParamparaFieldComparisonStatus.match => 'Match',
      ParamparaFieldComparisonStatus.different => 'Different',
      ParamparaFieldComparisonStatus.notCalculable => kNotCalculable,
      ParamparaFieldComparisonStatus.unknown => 'Unknown',
    };

String poruthamStatusLabel(PoruthamStatus status) => switch (status) {
      PoruthamStatus.matched => 'Matched',
      PoruthamStatus.partial => 'Partial',
      PoruthamStatus.notMatched => 'Not Matched',
      PoruthamStatus.reviewRequired => kReviewRequired,
      PoruthamStatus.notCalculable => kNotCalculable,
      PoruthamStatus.unknown => 'Unknown',
    };

// ── Overall / Profile / Astrology summary ───────────────────────────────────

List<List<String>> overallSummaryRows(CompatibilityReport report) {
  final overall = report.overallCompatibility;
  return [
    ['Overall Compatibility', _pct(overall.percentage)],
    ['Profile Compatibility', _pct(report.profileCompatibility?.percentage)],
    ['Astrology Compatibility', _pct(report.astrologyCompatibility?.percentage)],
    ['Status', moduleStatusLabel(overall.status)],
  ];
}

/// [ProfileCompatibility] section -percentage, status, coverage, and each
/// available category's own result. Never a fabricated 0% for a null score.
List<String> profileCompatibilityLines(ProfileCompatibility? p) {
  if (p == null) {
    return ['Profile Compatibility could not be calculated for this report.'];
  }
  final lines = <String>[
    'Percentage: ${_pct(p.percentage)}',
    'Status: ${moduleStatusLabel(p.status)}',
    'Coverage: ${p.coverage}%',
    if (p.explanation.isNotEmpty) p.explanation,
  ];
  for (final c in p.categories) {
    lines.add(
      '${humanizeCode(c.category)}: ${c.score != null ? '${c.score}' : kNotAvailable} '
      '(${c.answeredQuestions}/${c.totalQuestions} answered, ${moduleStatusLabel(c.status)})',
    );
  }
  return lines;
}

// ── Karnataka 10 Porutham ───────────────────────────────────────────────────

List<String> karnatakaSummaryLines(CompatibilityJataka? jataka) {
  if (jataka == null) return ['Karnataka 10 Porutham could not be calculated for this report.'];
  return [
    'Result: ${jataka.matched}/10 matched (${jataka.verdictLabel})',
    'Normalized score: ${jataka.normalizedPercentage != null ? '${jataka.normalizedPercentage}%' : kNotAvailable}',
    'Partial: ${jataka.partial}, Not matched: ${jataka.notMatched}, Review required: ${jataka.reviewRequired}, '
        'Unavailable: ${jataka.notCalculable}',
  ];
}

List<List<String>> karnatakaPoruthamRows(CompatibilityJataka? jataka) {
  if (jataka == null) return const [];
  return [
    for (final p in jataka.poruthams)
      [poruthamLabel(p.code), poruthamStatusLabel(p.status), p.explanation],
  ];
}

// ── Ashtakoota 36 Guna ───────────────────────────────────────────────────────

List<String> ashtakootaSummaryLines(AshtakootaResult? a, AstrologyAshtakootaSummary? summary) {
  if (a == null) return ['Ashtakoota (36 Guna) could not be calculated for this report.'];
  if (a.isUnavailable) {
    return [a.requiresReview ? 'Ashtakoota is incomplete - one or more Kootas require review.' : 'Ashtakoota calculation is currently unavailable.'];
  }
  final pct = (summary != null && summary.earned == a.earned) ? _pctD(summary.percentage) : null;
  return [
    'Score: ${a.earned} / ${a.maximum}${pct != null ? ' ($pct)' : ''}',
  ];
}

List<List<String>> ashtakootaKootaRows(AshtakootaResult? a) {
  if (a == null) return const [];
  return [
    for (final k in orderedKootas(a.kootas))
      [kootaLabel(k.code), k.earned != null ? '${k.earned}/${k.maximum}' : kNotAvailable, poruthamStatusLabel(k.status), k.explanation],
  ];
}

// ── Advanced Jataka ──────────────────────────────────────────────────────────

const _natalFindingLabels = <String>[
  'Lagna', 'Lagna Lord', '7th House', '7th Lord', '7th House Occupants', //
  '7th House Aspects (Graha Drishti)', 'Venus', 'Jupiter', 'Moon', 'Mars',
];
const _navamshaFindingLabels = <String>['D9 Lagna', 'D9 7th House', 'D9 7th Lord', 'D9 Venus', 'D9 Jupiter'];

List<String> advancedJatakaSummaryLines(AdvancedJataka? aj) {
  if (aj == null) return ['Advanced Jataka could not be calculated for this report.'];
  return [
    'Status: ${favorabilityStatusLabel(aj.status)}',
    if (aj.explanation.isNotEmpty) aj.explanation,
  ];
}

List<List<String>> advancedJatakaFindingRows(PartnerAdvancedJataka? partner) {
  if (partner == null) return const [];
  final rows = <List<String>>[];
  for (var i = 0; i < partner.natalFindings.length; i++) {
    rows.add(_advancedFindingRow(_natalFindingLabels[i], partner.natalFindings[i]));
  }
  for (var i = 0; i < partner.navamshaFindings.length; i++) {
    rows.add(_advancedFindingRow(_navamshaFindingLabels[i], partner.navamshaFindings[i]));
  }
  return rows;
}

List<String> _advancedFindingRow(String label, AdvancedJatakaFinding f) {
  var explanation = f.explanation;
  if (explanation.isEmpty && (f.data?.isNotEmpty ?? false)) {
    explanation = f.data!.entries.map((e) => '${humanizeKey(e.key)}: ${e.value}').join('; ');
  }
  return [label, moduleStatusLabel(f.status), explanation];
}

// ── Kuja Dosha ────────────────────────────────────────────────────────────────

List<String> kujaDoshaSummaryLines(KujaDosha? k) {
  if (k == null) return ['Kuja Dosha could not be calculated for this report.'];
  return [
    'Pair result: ${kujaDoshaStatusLabel(k.comparison.status)}',
    if (k.comparison.explanation.isNotEmpty) k.comparison.explanation,
  ];
}

List<String> kujaDoshaPartnerLines(PartnerKujaResult? p) {
  if (p == null) return [kNotAvailable];
  final lines = <String>[
    'Severity: ${kujaDoshaStatusLabel(p.status)}',
    if (p.marsRashiName != null) 'Mars in ${p.marsRashiName}',
    if (p.explanation.isNotEmpty) p.explanation,
  ];
  for (final (label, f) in [('From Lagna', p.fromLagna), ('From Moon', p.fromMoon), ('From Venus', p.fromVenus)]) {
    if (f == null) continue;
    final parts = <String>[
      if (f.marsHouse != null) 'House ${f.marsHouse}',
      if (f.affected != null) (f.affected! ? 'Affected' : 'Not affected'),
    ];
    lines.add('$label: ${moduleStatusLabel(f.status)}${parts.isEmpty ? '' : ' (${parts.join(', ')})'}'
        '${f.explanation.isEmpty ? '' : ' - ${f.explanation}'}');
  }
  for (final c in p.cancellationFindings) {
    lines.add('Cancellation: ${c.explanation.isNotEmpty ? c.explanation : humanizeCode(c.ruleId)}');
  }
  return lines;
}

// ── Dasha Compatibility ──────────────────────────────────────────────────────

List<String> dashaSummaryLines(DashaCompatibility? d) {
  if (d == null) return ['Dasha Compatibility could not be calculated for this report.'];
  return [
    'Assessment date: ${formatCompatDate(d.assessmentDate)}',
    'Pair result: ${dashaComparisonStatusLabel(d.comparison.status)}',
    if (d.comparison.explanation.isNotEmpty) d.comparison.explanation,
  ];
}

List<String> dashaPartnerLines(PartnerDashaResult? p) {
  if (p == null) return [kNotAvailable];
  final lines = <String>[
    if (p.birthNakshatraName != null) 'Birth Nakshatra: ${p.birthNakshatraName}',
    if (p.currentMahadasha != null)
      'Current Mahadasha: ${humanizeCode(p.currentMahadasha!.lord)} '
          '(${formatCompatDate(p.currentMahadasha!.startDate)} - ${formatCompatDate(p.currentMahadasha!.endDate)})',
    if (p.currentAntardasha != null)
      'Current Antardasha: ${humanizeCode(p.currentAntardasha!.lord)} '
          '(${formatCompatDate(p.currentAntardasha!.startDate)} - ${formatCompatDate(p.currentAntardasha!.endDate)})',
    if (p.nextMahadasha != null)
      'Next Mahadasha: ${humanizeCode(p.nextMahadasha!.lord)} starting ${formatCompatDate(p.nextMahadasha!.startDate)}',
  ];
  final sig = p.marriageSignificatorDasha;
  if (sig != null) {
    final matches = [
      ...sig.matchedMahadashaSignificators.map((m) => 'Mahadasha: ${humanizeCode(m)}'),
      ...sig.matchedAntardashaSignificators.map((m) => 'Antardasha: ${humanizeCode(m)}'),
    ];
    lines.add('Marriage-significator Dasha: ${moduleStatusLabel(sig.status)}'
        '${matches.isEmpty ? '' : ' (${matches.join(', ')})'}${sig.explanation.isEmpty ? '' : ' - ${sig.explanation}'}');
  }
  for (final s in p.sandhiFindings) {
    lines.add('Sandhi ${humanizeCode(s.previousMahadashaLord)} -> ${humanizeCode(s.nextMahadashaLord)}: '
        '${moduleStatusLabel(s.status)}${s.explanation.isEmpty ? '' : ' - ${s.explanation}'}');
  }
  return lines;
}

/// The full Mahadasha timeline, as a table -kept separate from
/// [dashaPartnerLines] so a long timeline doesn't crowd the headline facts.
List<List<String>> dashaMahadashaTimelineRows(PartnerDashaResult? p) {
  if (p == null) return const [];
  return [
    for (final m in p.mahadashas)
      [humanizeCode(m.lord), formatCompatDate(m.startDate), formatCompatDate(m.endDate)],
  ];
}

// ── Vivaha Kala Bala ─────────────────────────────────────────────────────────

List<String> vivahaKalaBalaSummaryLines(VivahaKalaBala? v) {
  if (v == null) return ['Vivaha Kala Bala could not be calculated for this report.'];
  return [
    'Assessment date: ${formatCompatDate(v.assessmentDate)}',
    'Status: ${favorabilityStatusLabel(v.status)}',
    if (v.explanation.isNotEmpty) v.explanation,
  ];
}

List<String> _balaLines(String title, BalaFinding b) => [
      '$title: ${moduleStatusLabel(b.status)}${b.explanation.isEmpty ? '' : ' - ${b.explanation}'}',
      '  Bride: ${b.bride.classification != null ? humanizeCode(b.bride.classification!) : moduleStatusLabel(b.bride.status)}',
      '  Groom: ${b.groom.classification != null ? humanizeCode(b.groom.classification!) : moduleStatusLabel(b.groom.status)}',
    ];

List<String> vivahaKalaBalaDetailLines(VivahaKalaBala v) => [
      ..._balaLines('Guru Bala', v.guruBala),
      ..._balaLines('Shukra Bala', v.shukraBala),
      ..._balaLines('Chandra Bala', v.chandraBala),
      'Tara Bala: ${moduleStatusLabel(v.taraBala.status)}${v.taraBala.explanation.isEmpty ? '' : ' - ${v.taraBala.explanation}'}',
      '  Bride: ${v.taraBala.bride.taraPosition != null ? 'Tara ${v.taraBala.bride.taraPosition}' : kNotAvailable}'
          '${v.taraBala.bride.classification != null ? ' (${humanizeCode(v.taraBala.bride.classification!)})' : ''}',
      '  Groom: ${v.taraBala.groom.taraPosition != null ? 'Tara ${v.taraBala.groom.taraPosition}' : kNotAvailable}'
          '${v.taraBala.groom.classification != null ? ' (${humanizeCode(v.taraBala.groom.classification!)})' : ''}',
      'Gochar (Transits): ${moduleStatusLabel(v.gochar.status)}${v.gochar.explanation.isEmpty ? '' : ' - ${v.gochar.explanation}'}',
      'Dasha Timing: ${moduleStatusLabel(v.dashaTiming.status)}',
      '  Bride: ${_dashaTimingSummary(v.dashaTiming.bride)}',
      '  Groom: ${_dashaTimingSummary(v.dashaTiming.groom)}',
    ];

String _dashaTimingSummary(PartnerDashaTimingFinding p) {
  final parts = <String>[
    if (p.currentMahadashaLord != null) 'MD ${humanizeCode(p.currentMahadashaLord!)}',
    if (p.currentAntardashaLord != null) 'AD ${humanizeCode(p.currentAntardashaLord!)}',
  ];
  final classification = p.timingClassification != null ? humanizeCode(p.timingClassification!) : moduleStatusLabel(p.status);
  return parts.isEmpty ? classification : '${parts.join(', ')} ($classification)';
}

// ── Daivagna Parampara ───────────────────────────────────────────────────────

List<String> paramparaSummaryLines(DaivagnaParampara? p) {
  if (p == null) return ['Daivagna Parampara could not be calculated for this report.'];
  final lines = <String>[
    'Comparison: ${paramparaComparisonStatusLabel(p.status)}',
    if (p.comparison.explanation.isNotEmpty) p.comparison.explanation,
  ];
  for (final f in p.comparison.fieldFindings) {
    lines.add('${humanizeCode(f.field)}: ${paramparaFieldStatusLabel(f.status)}${f.explanation.isEmpty ? '' : ' - ${f.explanation}'}');
  }
  return lines;
}

List<List<String>> paramparaPartnerRows(PartnerParamparaResult? p) {
  if (p == null) return const [];
  return [
    ['Gotra', _declaredValue(p.gotra)],
    ['Pravara', _declaredValue(p.pravara)],
    ['Kuladevata', _declaredValue(p.kuladevata)],
    ['Kuladevi', _declaredValue(p.kuladevi)],
  ];
}

String _declaredValue(ParamparaDeclaredValue v) => switch (v.status) {
      ParamparaValueStatus.provided => (v.customValue?.trim().isNotEmpty ?? false) ? v.customValue!.trim() : 'Not provided',
      ParamparaValueStatus.unknown => 'Unknown',
      ParamparaValueStatus.notProvided => 'Not provided',
    };

// ── Kundli / Janma Kundali Chart ────────────────────────────────────────────
//
// STEP 80 §17 — a graphical South Indian chart was judged technically
// difficult to render reliably inside the `pdf` package's widget tree (the
// same fixed-grid layout [SouthIndianKundliChart] draws on-screen), so the
// PDF instead gets a clean tabular planetary-position table: Lagna + all 9
// Grahas' D1 Rashi/Nakshatra/Pada/Retrograde, and the D9 (Navamsha)
// equivalent when the report has it. Same underlying [KundliChart] data as
// the in-app chart — no separate calculation, just a different presentation.

List<String> kundliChartSummaryLines(KundliChart? k) {
  if (k == null || k.bride == null || k.groom == null) {
    return ['Kundli chart could not be included in this report.'];
  }
  return const [
    'D1 (natal) planetary positions for both partners, and D9 (Navamsha) '
        'where available, are listed in tabular form below.',
  ];
}

List<List<String>> kundliPlanetRows(PartnerKundliChart? p) {
  if (p == null) return const [];
  final rows = <List<String>>[
    ['Lagna', p.lagnaRashiName, '', '', ''],
  ];
  for (final planet in orderedKundliPlanets(p.planets)) {
    rows.add([
      grahaFullName(planet.graha),
      planet.rashiName,
      planet.nakshatraName,
      planet.nakshatraPada > 0 ? '${planet.nakshatraPada}' : '',
      planet.isRetrograde ? 'Retrograde' : '',
    ]);
  }
  return rows;
}

List<List<String>> kundliNavamshaRows(PartnerKundliChart? p) {
  if (p == null || !p.hasNavamsha) return const [];
  return [
    for (final n in p.navamsha) [n.isLagna ? 'Lagna' : grahaFullName(n.point), n.rashiName],
  ];
}

// ── Discussion Points / Disclaimer ──────────────────────────────────────────

List<String> discussionPointLines(List<DiscussionPoint> points) =>
    [for (final p in points) '${p.severity == 'REVIEW' ? '[Review] ' : ''}${p.message}'];
