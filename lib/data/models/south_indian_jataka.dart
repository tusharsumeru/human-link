/// STEP F1 — models for `GET /api/v1/compatibility/reports/:reportId/south-indian-jataka`
/// (the "Check Compatibility" screen's South Indian Jataka card). Matches the
/// backend's `SouthIndianJatakaView` / `CompatibilityAggregate` /
/// `CompatibilityReportAshtakoota` / `KootaResult` types exactly. Purely a
/// display transform over an already-computed, already-persisted report —
/// nothing here recomputes a Nakshatra, Rashi, Porutham, Koota, or any score.
library;

import 'compatibility_models.dart';

/// Matches `ModuleResultStatus`/`CompatibilityAggregateState` (the two share
/// the same 3-value vocabulary on the backend). Used for both the top-level
/// [SouthIndianJatakaResult.status] and [KarnatakaPoruthamResult.state].
enum AstrologyModuleStatus {
  calculated,
  reviewRequired,
  notCalculable,
  unknown;

  static AstrologyModuleStatus fromWire(String value) => switch (value) {
        'CALCULATED' => AstrologyModuleStatus.calculated,
        'REVIEW_REQUIRED' => AstrologyModuleStatus.reviewRequired,
        'NOT_CALCULABLE' => AstrologyModuleStatus.notCalculable,
        _ => AstrologyModuleStatus.unknown,
      };
}

/// The fixed Dina→Vedha evaluation order — matches the backend's
/// `PORUTHAM_CODES`. Never alphabetical; never re-derived from the response
/// itself, since a response could (in principle) arrive in any order.
const List<String> kPoruthamCodeOrder = [
  'DINA',
  'GANA',
  'MAHENDRA',
  'STREE_DEERGHA',
  'YONI',
  'RASHI',
  'RASHI_ADHIPATHI',
  'VASHYA',
  'RAJJU',
  'VEDHA',
];

/// The fixed Varna→Nadi evaluation order — matches the backend's
/// `KOOTA_CODES`.
const List<String> kKootaCodeOrder = [
  'VARNA',
  'VASHYA',
  'TARA',
  'YONI',
  'GRAHA_MAITRI',
  'GANA',
  'BHAKOOT',
  'NADI',
];

const kootaLabels = <String, String>{
  'VARNA': 'Varna',
  'VASHYA': 'Vashya',
  'TARA': 'Tara',
  'YONI': 'Yoni',
  'GRAHA_MAITRI': 'Graha Maitri',
  'GANA': 'Gana',
  'BHAKOOT': 'Bhakoot',
  'NADI': 'Nadi',
};

String kootaLabel(String code) => kootaLabels[code] ?? code;

/// Sorts by [kPoruthamCodeOrder]; anything with an unrecognized code is
/// appended at the end, in its original relative order, rather than dropped.
List<PoruthamResult> orderedPoruthams(List<PoruthamResult> results) {
  final sorted = [...results];
  sorted.sort((a, b) {
    final ia = kPoruthamCodeOrder.indexOf(a.code);
    final ib = kPoruthamCodeOrder.indexOf(b.code);
    return (ia == -1 ? kPoruthamCodeOrder.length : ia)
        .compareTo(ib == -1 ? kPoruthamCodeOrder.length : ib);
  });
  return sorted;
}

/// Sorts by [kKootaCodeOrder]; unrecognized codes appended at the end.
List<KootaResult> orderedKootas(List<KootaResult> kootas) {
  final sorted = [...kootas];
  sorted.sort((a, b) {
    final ia = kKootaCodeOrder.indexOf(a.code);
    final ib = kKootaCodeOrder.indexOf(b.code);
    return (ia == -1 ? kKootaCodeOrder.length : ia)
        .compareTo(ib == -1 ? kKootaCodeOrder.length : ib);
  });
  return sorted;
}

/// Matches `CompatibilityAggregate` (porutham/compatibility-aggregate.ts) —
/// the Karnataka 10-Porutham roll-up. `traditionalScoreMatched`/
/// `traditionalScoreTotal` is the "matched/10" display figure; PARTIAL is
/// deliberately excluded from the numerator (never half-credited here).
class KarnatakaPoruthamResult {
  const KarnatakaPoruthamResult({
    required this.ruleVersion,
    required this.totalPoruthams,
    required this.matchedCount,
    required this.partialCount,
    required this.notMatchedCount,
    required this.reviewRequiredCount,
    required this.notCalculableCount,
    required this.traditionalScoreMatched,
    required this.traditionalScoreTotal,
    required this.normalizedScore,
    required this.state,
    required this.isComplete,
    required this.requiresReview,
    required this.rajjuStatus,
    required this.rajjuCritical,
    required this.vedhaStatus,
    required this.vedhaCritical,
    required this.results,
  });

  final String? ruleVersion;
  final int totalPoruthams;
  final int matchedCount;
  final int partialCount;
  final int notMatchedCount;
  final int reviewRequiredCount;
  final int notCalculableCount;
  final int traditionalScoreMatched;
  final int traditionalScoreTotal;

  /// 0–1 internal figure (MATCHED=1, PARTIAL=0.5, NOT_MATCHED=0). A display
  /// transform only — never re-derived here. Null when nothing was
  /// calculable at all.
  final double? normalizedScore;

  final AstrologyModuleStatus state;
  final bool isComplete;
  final bool requiresReview;

  /// Rajju's own status/critical flag — an independent gate that must never
  /// be folded into [matchedCount]/[traditionalScoreMatched]. Matches
  /// `CompatibilityAggregate.rajjuStatus: PoruthamStatus | null` — the same
  /// 5-value vocabulary every individual Porutham uses, NOT
  /// [AstrologyModuleStatus]. Null only when no RAJJU entry is present in
  /// [results] at all.
  final PoruthamStatus? rajjuStatus;
  final bool rajjuCritical;

  /// Same as [rajjuStatus]/[rajjuCritical], for Vedha.
  final PoruthamStatus? vedhaStatus;
  final bool vedhaCritical;

  /// All 10 results — kept in whatever order the API sent (the backend's
  /// own fixed Dina→Vedha order); use [orderedPoruthams] before rendering to
  /// guarantee that order regardless.
  final List<PoruthamResult> results;

  /// The individual Rajju [PoruthamResult], if present — for its
  /// explanation text alongside the aggregate-level [rajjuStatus]/
  /// [rajjuCritical] gate.
  PoruthamResult? get rajjuResult => _findByCode('RAJJU');

  /// The individual Vedha [PoruthamResult], if present.
  PoruthamResult? get vedhaResult => _findByCode('VEDHA');

  PoruthamResult? _findByCode(String code) {
    for (final p in results) {
      if (p.code == code) return p;
    }
    return null;
  }

  factory KarnatakaPoruthamResult.fromJson(Map<String, dynamic> json) {
    final score = json['traditionalScore'];
    final scoreMap = score is Map ? Map<String, dynamic>.from(score) : const <String, dynamic>{};
    return KarnatakaPoruthamResult(
      ruleVersion: (json['ruleVersion'] as String?),
      totalPoruthams: (json['totalPoruthams'] as num?)?.toInt() ?? 0,
      matchedCount: (json['matchedCount'] as num?)?.toInt() ?? 0,
      partialCount: (json['partialCount'] as num?)?.toInt() ?? 0,
      notMatchedCount: (json['notMatchedCount'] as num?)?.toInt() ?? 0,
      reviewRequiredCount: (json['reviewRequiredCount'] as num?)?.toInt() ?? 0,
      notCalculableCount: (json['notCalculableCount'] as num?)?.toInt() ?? 0,
      traditionalScoreMatched: (scoreMap['matched'] as num?)?.toInt() ?? 0,
      traditionalScoreTotal: (scoreMap['total'] as num?)?.toInt() ?? 0,
      normalizedScore: (json['normalizedScore'] as num?)?.toDouble(),
      state: AstrologyModuleStatus.fromWire((json['state'] ?? '').toString()),
      isComplete: json['isComplete'] == true,
      requiresReview: json['requiresReview'] == true,
      rajjuStatus:
          json['rajjuStatus'] is String ? PoruthamStatus.fromWire(json['rajjuStatus'] as String) : null,
      rajjuCritical: json['rajjuCritical'] == true,
      vedhaStatus:
          json['vedhaStatus'] is String ? PoruthamStatus.fromWire(json['vedhaStatus'] as String) : null,
      vedhaCritical: json['vedhaCritical'] == true,
      results: (json['results'] is List ? json['results'] as List : const [])
          .whereType<Map>()
          .map((e) => PoruthamResult.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

/// Matches `KootaResult` (ashtakoota/ashtakoota.types.ts). `earned` is null
/// only for REVIEW_REQUIRED/NOT_CALCULABLE — "no verdict was reached" is
/// never shown as a fabricated 0.
class KootaResult {
  const KootaResult({
    required this.code,
    required this.status,
    required this.earned,
    required this.maximum,
    required this.ruleId,
    required this.inputs,
    required this.explanation,
    required this.reasonCode,
    required this.reviewRequired,
  });

  final String code;
  final PoruthamStatus status;
  final int? earned;
  final int maximum;
  final String ruleId;
  final Map<String, dynamic> inputs;
  final String explanation;
  final String reasonCode;
  final bool reviewRequired;

  factory KootaResult.fromJson(Map<String, dynamic> json) => KootaResult(
        code: (json['code'] ?? '').toString(),
        status: PoruthamStatus.fromWire((json['status'] ?? '').toString()),
        earned: (json['earned'] as num?)?.toInt(),
        maximum: (json['maximum'] as num?)?.toInt() ?? 0,
        ruleId: (json['ruleId'] ?? '').toString(),
        inputs: json['inputs'] is Map ? Map<String, dynamic>.from(json['inputs'] as Map) : const {},
        explanation: (json['explanation'] ?? '').toString(),
        reasonCode: (json['reasonCode'] ?? '').toString(),
        reviewRequired: json['reviewRequired'] == true,
      );
}

/// Matches `CompatibilityReportAshtakoota` (compatibility-report.types.ts) —
/// the 36-Guna Milan result, kept explicitly separate from
/// [KarnatakaPoruthamResult]. [earned] is null whenever any Koota is
/// REVIEW_REQUIRED/NOT_CALCULABLE — never a partial sum shown next to
/// `maximum: 36`, and never displayed as "0/36".
class AshtakootaResult {
  const AshtakootaResult({
    required this.ruleVersion,
    required this.brideProfileId,
    required this.groomProfileId,
    required this.earned,
    required this.maximum,
    required this.isComplete,
    required this.requiresReview,
    required this.kootas,
    required this.brideBoundaryRisk,
    required this.groomBoundaryRisk,
    required this.nakshatraBoundaryRiskOverride,
  });

  final String ruleVersion;
  final String brideProfileId;
  final String groomProfileId;
  final int? earned;
  final int maximum;
  final bool isComplete;
  final bool requiresReview;
  final List<KootaResult> kootas;
  final BoundaryRisk? brideBoundaryRisk;
  final BoundaryRisk? groomBoundaryRisk;
  final bool nakshatraBoundaryRiskOverride;

  /// True whenever [earned] is null — the UI must show "unavailable" text,
  /// never a fabricated "0 / 36" or "0%".
  bool get isUnavailable => earned == null;

  factory AshtakootaResult.fromJson(Map<String, dynamic> json) => AshtakootaResult(
        ruleVersion: (json['ruleVersion'] ?? '').toString(),
        brideProfileId: (json['brideProfileId'] ?? '').toString(),
        groomProfileId: (json['groomProfileId'] ?? '').toString(),
        earned: (json['earned'] as num?)?.toInt(),
        maximum: (json['maximum'] as num?)?.toInt() ?? 36,
        isComplete: json['isComplete'] == true,
        requiresReview: json['requiresReview'] == true,
        kootas: (json['kootas'] is List ? json['kootas'] as List : const [])
            .whereType<Map>()
            .map((e) => KootaResult.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        brideBoundaryRisk: json['brideBoundaryRisk'] is Map
            ? BoundaryRisk.fromJson(Map<String, dynamic>.from(json['brideBoundaryRisk'] as Map))
            : null,
        groomBoundaryRisk: json['groomBoundaryRisk'] is Map
            ? BoundaryRisk.fromJson(Map<String, dynamic>.from(json['groomBoundaryRisk'] as Map))
            : null,
        nakshatraBoundaryRiskOverride: json['nakshatraBoundaryRiskOverride'] == true,
      );
}

/// Matches `SouthIndianJatakaView` — the exact
/// `GET /reports/:reportId/south-indian-jataka` response. [overallAstrologyScore]
/// is always null on the backend today (no approved formula combines the
/// 10-Porutham and 36-Guna systems); this type still models it as a nullable
/// field so a future approved formula needs no Flutter contract change, and
/// the UI must never compute a stand-in value itself.
class SouthIndianJatakaResult {
  const SouthIndianJatakaResult({
    required this.reportId,
    required this.status,
    required this.ruleVersion,
    required this.karnatakaPorutham,
    required this.ashtakoota,
    required this.overallAstrologyScore,
  });

  final String reportId;
  final AstrologyModuleStatus status;
  final String? ruleVersion;
  final KarnatakaPoruthamResult? karnatakaPorutham;
  final AshtakootaResult? ashtakoota;
  final num? overallAstrologyScore;

  factory SouthIndianJatakaResult.fromJson(Map<String, dynamic> json) => SouthIndianJatakaResult(
        reportId: (json['reportId'] ?? '').toString(),
        status: AstrologyModuleStatus.fromWire((json['status'] ?? '').toString()),
        ruleVersion: (json['ruleVersion'] as String?),
        karnatakaPorutham: json['karnatakaPorutham'] is Map
            ? KarnatakaPoruthamResult.fromJson(Map<String, dynamic>.from(json['karnatakaPorutham'] as Map))
            : null,
        ashtakoota: json['ashtakoota'] is Map
            ? AshtakootaResult.fromJson(Map<String, dynamic>.from(json['ashtakoota'] as Map))
            : null,
        overallAstrologyScore: json['overallAstrologyScore'] as num?,
      );
}
