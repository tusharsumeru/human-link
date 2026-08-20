/// STEP 72 — models for the summary/percentage sections of
/// `GET /api/v1/compatibility/reports/:reportId`: Astrology Compatibility
/// (STEP 64), Profile Compatibility (STEP 65/66), Overall Compatibility
/// (STEP 69), and Discussion Points (STEP 69 §11). Every percentage here is
/// read directly off the backend's own already-computed summary — nothing in
/// this file combines, averages, or re-derives a score itself.
library;

import 'south_indian_jataka.dart' show AstrologyModuleStatus;

// ── Astrology Compatibility (STEP 64) ───────────────────────────────────────

/// The Karnataka (10 Porutham) slice of [AstrologyCompatibility] — matches
/// `AstrologyCompatibilitySummary.karnatakaPorutham`. `percentage` is null
/// only when [calculable] is 0 — never a fabricated 0%.
class AstrologyKarnatakaSummary {
  const AstrologyKarnatakaSummary({
    required this.matched,
    required this.partial,
    required this.notMatched,
    required this.calculable,
    required this.total,
    required this.percentage,
  });

  final int matched;
  final int partial;
  final int notMatched;

  /// matched + partial + notMatched — the denominator [percentage] was
  /// computed over; excludes reviewRequired/notCalculable.
  final int calculable;
  final int total;
  final int? percentage;

  factory AstrologyKarnatakaSummary.fromJson(Map<String, dynamic> json) => AstrologyKarnatakaSummary(
        matched: (json['matched'] as num?)?.toInt() ?? 0,
        partial: (json['partial'] as num?)?.toInt() ?? 0,
        notMatched: (json['notMatched'] as num?)?.toInt() ?? 0,
        calculable: (json['calculable'] as num?)?.toInt() ?? 0,
        total: (json['total'] as num?)?.toInt() ?? 0,
        percentage: (json['percentage'] as num?)?.toInt(),
      );
}

/// The Ashtakoota (36 Guna) slice of [AstrologyCompatibility] — matches
/// `AstrologyCompatibilitySummary.ashtakoota`. `percentage` is rounded to 2
/// decimal places (e.g. 28/36 -> 77.78) — Ashtakoota's own independent
/// precision, never forced to match Karnataka's whole-number rounding.
class AstrologyAshtakootaSummary {
  const AstrologyAshtakootaSummary({
    required this.earned,
    required this.maximum,
    required this.percentage,
    required this.isComplete,
  });

  final int? earned;
  final int maximum;
  final double? percentage;
  final bool isComplete;

  factory AstrologyAshtakootaSummary.fromJson(Map<String, dynamic> json) => AstrologyAshtakootaSummary(
        earned: (json['earned'] as num?)?.toInt(),
        maximum: (json['maximum'] as num?)?.toInt() ?? 36,
        percentage: (json['percentage'] as num?)?.toDouble(),
        isComplete: json['isComplete'] == true,
      );
}

/// Matches `AstrologyCompatibilitySummary` — Karnataka 10-Porutham is the
/// PRIMARY astrology percentage ([percentage] === [karnatakaPorutham]'s own
/// percentage); Ashtakoota is reported separately alongside it, never
/// blended into one combined score (no approved formula for that combination
/// exists — see [CompatibilityReport.overallCompatibility]'s own doc comment
/// for the one place a 50/50 blend DOES happen, and it isn't with
/// Ashtakoota). Null [percentage] means [status] is NOT_CALCULABLE — never a
/// fabricated 0%.
class AstrologyCompatibility {
  const AstrologyCompatibility({
    required this.status,
    required this.reasonCode,
    required this.explanation,
    required this.primarySystem,
    required this.percentage,
    required this.karnatakaPorutham,
    required this.ashtakoota,
  });

  final AstrologyModuleStatus status;
  final String reasonCode;
  final String explanation;
  final String primarySystem;

  /// Always equal to [karnatakaPorutham.percentage] — duplicated at the top
  /// level for a caller that wants one number without reaching into
  /// karnatakaPorutham.
  final int? percentage;
  final AstrologyKarnatakaSummary karnatakaPorutham;

  /// Null only in the defensive case where the backend's own Ashtakoota
  /// section is null despite Jataka being present.
  final AstrologyAshtakootaSummary? ashtakoota;

  factory AstrologyCompatibility.fromJson(Map<String, dynamic> json) => AstrologyCompatibility(
        status: AstrologyModuleStatus.fromWire((json['status'] ?? '').toString()),
        reasonCode: (json['reasonCode'] ?? '').toString(),
        explanation: (json['explanation'] ?? '').toString(),
        primarySystem: (json['primarySystem'] ?? '').toString(),
        percentage: (json['percentage'] as num?)?.toInt(),
        karnatakaPorutham: AstrologyKarnatakaSummary.fromJson(
            json['karnatakaPorutham'] is Map ? Map<String, dynamic>.from(json['karnatakaPorutham'] as Map) : const {}),
        ashtakoota: json['ashtakoota'] is Map
            ? AstrologyAshtakootaSummary.fromJson(Map<String, dynamic>.from(json['ashtakoota'] as Map))
            : null,
      );
}

// ── Profile Compatibility (STEP 65/66) ──────────────────────────────────────

/// Matches `DealBreakerAlert` — a discussion-point alert only, NEVER a
/// rejection signal. There is no MATCH_REJECTED/INCOMPATIBLE verdict
/// anywhere in this system; Flutter must not invent one from this either.
class DealBreakerAlert {
  const DealBreakerAlert({required this.code, required this.severity, required this.questionId, required this.title});

  final String code;
  final String severity;
  final String questionId;
  final String title;

  factory DealBreakerAlert.fromJson(Map<String, dynamic> json) => DealBreakerAlert(
        code: (json['code'] ?? '').toString(),
        severity: (json['severity'] ?? '').toString(),
        questionId: (json['questionId'] ?? '').toString(),
        title: (json['title'] ?? '').toString(),
      );
}

/// Matches `QuestionResult`. Deliberately carries no answer value from
/// either side — the privacy guarantee is structural, not just a display
/// convention (see the backend's own doc comment on `QuestionResult`).
class ProfileQuestionResult {
  const ProfileQuestionResult({
    required this.questionId,
    required this.category,
    required this.status,
    required this.score,
    required this.weight,
    required this.effectiveWeight,
    required this.answeredByBoth,
    required this.importanceA,
    required this.importanceB,
    required this.reasonCode,
  });

  final String questionId;
  final String category;

  /// MATCHED/PARTIAL/NOT_MATCHED/NOT_CALCULABLE — a QUESTIONNAIRE-specific
  /// vocabulary, deliberately not [PoruthamStatus] (see the backend's own
  /// `QuestionnaireStatus` doc comment) — kept as a raw wire string here
  /// since nothing in this app branches on it yet.
  final String status;

  /// 0-1 — null exactly when [status] is NOT_CALCULABLE, never a fabricated
  /// 0.
  final double? score;
  final double weight;
  final double effectiveWeight;
  final bool answeredByBoth;
  final String importanceA;
  final String importanceB;
  final String reasonCode;

  factory ProfileQuestionResult.fromJson(Map<String, dynamic> json) => ProfileQuestionResult(
        questionId: (json['questionId'] ?? '').toString(),
        category: (json['category'] ?? '').toString(),
        status: (json['status'] ?? '').toString(),
        score: (json['score'] as num?)?.toDouble(),
        weight: (json['weight'] as num?)?.toDouble() ?? 0,
        effectiveWeight: (json['effectiveWeight'] as num?)?.toDouble() ?? 0,
        answeredByBoth: json['answeredByBoth'] == true,
        importanceA: (json['importanceA'] ?? '').toString(),
        importanceB: (json['importanceB'] ?? '').toString(),
        reasonCode: (json['reasonCode'] ?? '').toString(),
      );
}

/// Matches `CategoryResult`. `score` is null exactly when the category has
/// zero usable (scored) answers — "MISSING CATEGORY: unavailable, never an
/// automatic zero," per the backend's own doc comment.
class ProfileCategoryResult {
  const ProfileCategoryResult({
    required this.category,
    required this.weight,
    required this.score,
    required this.coverage,
    required this.answeredQuestions,
    required this.totalQuestions,
    required this.status,
    required this.questionResults,
    required this.dealBreakers,
  });

  final String category;
  final int weight;
  final int? score;
  final int coverage;
  final int answeredQuestions;
  final int totalQuestions;

  /// CALCULATED/NOT_CALCULABLE only (the backend's own 2-value
  /// `CategoryResultStatus`) — reuses [AstrologyModuleStatus] rather than a
  /// dedicated 2-value enum; REVIEW_REQUIRED simply never appears here.
  final AstrologyModuleStatus status;
  final List<ProfileQuestionResult> questionResults;
  final List<DealBreakerAlert> dealBreakers;

  factory ProfileCategoryResult.fromJson(Map<String, dynamic> json) => ProfileCategoryResult(
        category: (json['category'] ?? '').toString(),
        weight: (json['weight'] as num?)?.toInt() ?? 0,
        score: (json['score'] as num?)?.toInt(),
        coverage: (json['coverage'] as num?)?.toInt() ?? 0,
        answeredQuestions: (json['answeredQuestions'] as num?)?.toInt() ?? 0,
        totalQuestions: (json['totalQuestions'] as num?)?.toInt() ?? 0,
        status: AstrologyModuleStatus.fromWire((json['status'] ?? '').toString()),
        questionResults: (json['questionResults'] is List ? json['questionResults'] as List : const [])
            .whereType<Map>()
            .map((e) => ProfileQuestionResult.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        dealBreakers: (json['dealBreakers'] is List ? json['dealBreakers'] as List : const [])
            .whereType<Map>()
            .map((e) => DealBreakerAlert.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}

/// Matches `CompatibilityReportProfileCompatibility` — the report's
/// `profileCompatibility` section (the questionnaire-based system,
/// independent of every astrology module). `percentage` is null exactly when
/// [status] is NOT_CALCULABLE — never a fabricated 0%; `coverage` is always
/// present even then, so a caller can see why.
class ProfileCompatibility {
  const ProfileCompatibility({
    required this.ruleVersion,
    required this.profileAId,
    required this.profileBId,
    required this.status,
    required this.reasonCode,
    required this.explanation,
    required this.percentage,
    required this.coverage,
    required this.confidence,
    required this.categories,
    required this.dealBreakers,
  });

  final String ruleVersion;
  final String profileAId;
  final String profileBId;

  /// CALCULATED/NOT_CALCULABLE/REVIEW_REQUIRED — reuses
  /// [AstrologyModuleStatus] (the backend's `ProfileCompatibilityState` is
  /// the same 3-value set).
  final AstrologyModuleStatus status;
  final String reasonCode;
  final String explanation;
  final int? percentage;
  final int coverage;

  /// LOW/MEDIUM/HIGH/VERY_HIGH — kept as a raw wire string; a
  /// questionnaire-specific confidence vocabulary distinct from
  /// [CompatibilityReport.confidence]'s NONE/LOW/MODERATE/HIGH.
  final String confidence;
  final List<ProfileCategoryResult> categories;
  final List<DealBreakerAlert> dealBreakers;

  factory ProfileCompatibility.fromJson(Map<String, dynamic> json) => ProfileCompatibility(
        ruleVersion: (json['ruleVersion'] ?? '').toString(),
        profileAId: (json['profileAId'] ?? '').toString(),
        profileBId: (json['profileBId'] ?? '').toString(),
        status: AstrologyModuleStatus.fromWire((json['status'] ?? '').toString()),
        reasonCode: (json['reasonCode'] ?? '').toString(),
        explanation: (json['explanation'] ?? '').toString(),
        percentage: (json['percentage'] as num?)?.toInt(),
        coverage: (json['coverage'] as num?)?.toInt() ?? 0,
        confidence: (json['confidence'] ?? '').toString(),
        categories: (json['categories'] is List ? json['categories'] as List : const [])
            .whereType<Map>()
            .map((e) => ProfileCategoryResult.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        dealBreakers: (json['dealBreakers'] is List ? json['dealBreakers'] as List : const [])
            .whereType<Map>()
            .map((e) => DealBreakerAlert.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}

// ── Overall Compatibility (STEP 69) ─────────────────────────────────────────

/// Matches `OverallCompatibilitySummary`. Combines ONLY Profile Compatibility
/// and Astrology Compatibility, 50/50 — Family/Personality are never
/// included (the backend has no real percentage for either). [percentage] is
/// null only when NEITHER component is available — never a fabricated 0%.
/// Flutter must display this value as-is and never recompute it from
/// [profilePercentage]/[astrologyPercentage] itself.
class OverallCompatibility {
  const OverallCompatibility({
    required this.percentage,
    required this.status,
    required this.reasonCode,
    required this.explanation,
    required this.profilePercentage,
    required this.astrologyPercentage,
    required this.profileWeight,
    required this.astrologyWeight,
  });

  final int? percentage;
  final AstrologyModuleStatus status;
  final String reasonCode;
  final String explanation;

  /// The exact Profile Compatibility percentage this was computed from —
  /// null if unavailable. Both-available -> CALCULATED (weighted 50/50);
  /// exactly-one-available -> REVIEW_REQUIRED (that value alone, not the
  /// full weighted result); neither -> NOT_CALCULABLE.
  final int? profilePercentage;
  final int? astrologyPercentage;
  final int profileWeight;
  final int astrologyWeight;

  factory OverallCompatibility.fromJson(Map<String, dynamic> json) => OverallCompatibility(
        percentage: (json['percentage'] as num?)?.toInt(),
        status: AstrologyModuleStatus.fromWire((json['status'] ?? '').toString()),
        reasonCode: (json['reasonCode'] ?? '').toString(),
        explanation: (json['explanation'] ?? '').toString(),
        profilePercentage: (json['profilePercentage'] as num?)?.toInt(),
        astrologyPercentage: (json['astrologyPercentage'] as num?)?.toInt(),
        profileWeight: (json['profileWeight'] as num?)?.toInt() ?? 0,
        astrologyWeight: (json['astrologyWeight'] as num?)?.toInt() ?? 0,
      );
}

// ── Discussion Points (STEP 69 §11) ─────────────────────────────────────────

/// Matches `DiscussionPoint` — deterministic, read-only points derived from
/// already-computed engine results. Never alters, and is never used by
/// Flutter to alter, any percentage.
class DiscussionPoint {
  const DiscussionPoint({required this.code, required this.source, required this.severity, required this.message});

  final String code;

  /// KARNATAKA_POROTHAM/ASHTAKOOTA/KUJA_DOSHA/DASHA_COMPATIBILITY/
  /// ADVANCED_JATAKA/DAIVAGNA_PARAMPARA/PROFILE_COMPATIBILITY.
  final String source;

  /// INFO/REVIEW.
  final String severity;
  final String message;

  factory DiscussionPoint.fromJson(Map<String, dynamic> json) => DiscussionPoint(
        code: (json['code'] ?? '').toString(),
        source: (json['source'] ?? '').toString(),
        severity: (json['severity'] ?? '').toString(),
        message: (json['message'] ?? '').toString(),
      );
}

List<DiscussionPoint> discussionPointsFromJson(dynamic value) =>
    (value is List ? value : const []).whereType<Map>().map((e) => DiscussionPoint.fromJson(Map<String, dynamic>.from(e))).toList();
