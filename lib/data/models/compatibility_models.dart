import '../api_client.dart';
import 'compatibility_astrology_modules.dart';
import 'compatibility_summary.dart';
import 'kundli_chart.dart' show KundliChart;
import 'parampara.dart' show DaivagnaParampara;
import 'south_indian_jataka.dart' show AshtakootaResult, AstrologyModuleStatus;

/// GROOM/BRIDE — matches `TRADITIONAL_ROLES` in the backend's
/// compatibility-report.types.ts. Derived from the existing `gender` field
/// ('M'/'F') everywhere in this app; never asked for separately.
enum TraditionalRole {
  groom('GROOM'),
  bride('BRIDE');

  const TraditionalRole(this.wireValue);
  final String wireValue;

  static TraditionalRole? forGender(String gender) => switch (gender) {
        'M' => TraditionalRole.groom,
        'F' => TraditionalRole.bride,
        _ => null,
      };

  static TraditionalRole? forWire(String value) => switch (value) {
        'GROOM' => TraditionalRole.groom,
        'BRIDE' => TraditionalRole.bride,
        _ => null,
      };
}

/// Matches `PoruthamStatus` in porutham.types.ts. `unknown` is a
/// forward-compat fallback only — the backend never actually sends it today.
enum PoruthamStatus {
  matched,
  partial,
  notMatched,
  reviewRequired,
  notCalculable,
  unknown;

  static PoruthamStatus fromWire(String value) => switch (value) {
        'MATCHED' => PoruthamStatus.matched,
        'PARTIAL' => PoruthamStatus.partial,
        'NOT_MATCHED' => PoruthamStatus.notMatched,
        'REVIEW_REQUIRED' => PoruthamStatus.reviewRequired,
        'NOT_CALCULABLE' => PoruthamStatus.notCalculable,
        _ => PoruthamStatus.unknown,
      };
}

/// Matches `TraditionalVerdictCode` in traditional-score.ts.
enum TraditionalVerdictCode {
  criticalReview,
  expertReviewRequired,
  strong,
  good,
  moderate,
  low,
  unknown;

  static TraditionalVerdictCode fromWire(String value) => switch (value) {
        'CRITICAL_REVIEW' => TraditionalVerdictCode.criticalReview,
        'EXPERT_REVIEW_REQUIRED' => TraditionalVerdictCode.expertReviewRequired,
        'STRONG' => TraditionalVerdictCode.strong,
        'GOOD' => TraditionalVerdictCode.good,
        'MODERATE' => TraditionalVerdictCode.moderate,
        'LOW' => TraditionalVerdictCode.low,
        _ => TraditionalVerdictCode.unknown,
      };
}

/// One Porutham's result — matches `PoruthamResult` in porutham.types.ts.
/// `details` stays a raw map deliberately: the backend itself types it as
/// `Record<string, unknown>` (each of the 10 Poruthams puts different fields
/// in it — distance, taraPosition, brideGana/groomGana, …), so there is no
/// single typed shape to give it here.
class PoruthamResult {
  const PoruthamResult({
    required this.code,
    required this.status,
    required this.score,
    required this.ruleId,
    required this.details,
    this.isCritical = false,
    this.critical = false,
    this.explanation = '',
    this.reasonCode = '',
    this.reviewRequired = false,
  });

  final String code;
  final PoruthamStatus status;
  final double? score;
  final String ruleId;
  final Map<String, dynamic> details;

  /// True only when the backend flagged this specific result `severity:
  /// 'CRITICAL'` (a prominent failure, e.g. a Rajju mismatch) — what the
  /// existing report view highlights. See [critical] for the always-true-for-
  /// Rajju/Vedha flag instead.
  final bool isCritical;

  /// Matches `PoruthamResult.critical` — true for every RAJJU/VEDHA result
  /// regardless of its own status (an independent gate, distinct from
  /// [isCritical]/`severity`, which only flags one specific failure).
  final bool critical;

  /// The backend's own explanation for this result — use directly, never
  /// re-derive one from [details] client-side.
  final String explanation;

  /// Machine-readable reason code for why this status was reached (matches
  /// `PoruthamResult.reasonCode`).
  final String reasonCode;

  /// Matches `PoruthamResult.reviewRequired` — derived purely from `status`
  /// on the backend (`status === 'REVIEW_REQUIRED'`), re-exposed here as a
  /// plain boolean convenience.
  final bool reviewRequired;

  factory PoruthamResult.fromJson(Map<String, dynamic> json) => PoruthamResult(
        code: (json['code'] ?? '').toString(),
        status: PoruthamStatus.fromWire((json['status'] ?? '').toString()),
        score: (json['score'] as num?)?.toDouble(),
        ruleId: (json['ruleId'] ?? '').toString(),
        details: json['details'] is Map
            ? Map<String, dynamic>.from(json['details'] as Map)
            : const {},
        isCritical: json['severity'] == 'CRITICAL',
        critical: json['critical'] == true,
        explanation: (json['explanation'] ?? '').toString(),
        reasonCode: (json['reasonCode'] ?? '').toString(),
        reviewRequired: json['reviewRequired'] == true,
      );
}

/// Matches `BirthTimeAccuracy` on birth-profile.schema.ts — how a member
/// described their confidence in the recorded time of birth.
enum BirthTimeAccuracy {
  exactDocumentVerified,
  exactFamilyConfirmed,
  approximate15Minutes,
  approximate30Minutes,
  approximate60Minutes,
  unknown;

  static BirthTimeAccuracy fromWire(String value) => switch (value) {
        'EXACT_DOCUMENT_VERIFIED' => BirthTimeAccuracy.exactDocumentVerified,
        'EXACT_FAMILY_CONFIRMED' => BirthTimeAccuracy.exactFamilyConfirmed,
        'APPROXIMATE_15_MINUTES' => BirthTimeAccuracy.approximate15Minutes,
        'APPROXIMATE_30_MINUTES' => BirthTimeAccuracy.approximate30Minutes,
        'APPROXIMATE_60_MINUTES' => BirthTimeAccuracy.approximate60Minutes,
        _ => BirthTimeAccuracy.unknown,
      };
}

const birthTimeAccuracyLabels = <BirthTimeAccuracy, String>{
  BirthTimeAccuracy.exactDocumentVerified: 'Exact (document verified)',
  BirthTimeAccuracy.exactFamilyConfirmed: 'Exact (family confirmed)',
  BirthTimeAccuracy.approximate15Minutes: 'Approximate (±15 min)',
  BirthTimeAccuracy.approximate30Minutes: 'Approximate (±30 min)',
  BirthTimeAccuracy.approximate60Minutes: 'Approximate (±60 min)',
  BirthTimeAccuracy.unknown: 'Unknown',
};

/// Matches `BoundaryRisk` from the backend's astronomy/boundary-risk.ts —
/// whether the recorded birth-time uncertainty is wide enough that a
/// derived chart point (Nakshatra/Pada/Rashi/Lagna/Navamsha) could plausibly
/// differ from the single-instant calculation. Rendered as-is; Flutter never
/// recomputes or re-derives these flags itself (spec §10 — "never convert
/// uncertainty into a definite result").
class BoundaryRisk {
  const BoundaryRisk({
    required this.birthTimeAccuracy,
    required this.confidence,
    required this.windowMinutes,
    required this.nakshatraMayChange,
    required this.padaMayChange,
    required this.rashiMayChange,
    required this.lagnaMayChange,
    required this.navamshaMayChange,
  });

  final BirthTimeAccuracy birthTimeAccuracy;
  /// 0–1, per BIRTH_TIME_ACCURACY_CONFIDENCE — a display figure, not
  /// something Flutter derives its own meaning from beyond showing it.
  final double confidence;
  final int windowMinutes;
  final bool nakshatraMayChange;
  final bool padaMayChange;
  final bool rashiMayChange;
  final bool lagnaMayChange;
  final bool navamshaMayChange;

  bool get hasAnyRisk =>
      nakshatraMayChange || padaMayChange || rashiMayChange || lagnaMayChange || navamshaMayChange;

  factory BoundaryRisk.fromJson(Map<String, dynamic> json) => BoundaryRisk(
        birthTimeAccuracy:
            BirthTimeAccuracy.fromWire((json['birthTimeAccuracy'] ?? '').toString()),
        confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
        windowMinutes: (json['windowMinutes'] as num?)?.toInt() ?? 0,
        nakshatraMayChange: json['nakshatraMayChange'] == true,
        padaMayChange: json['padaMayChange'] == true,
        rashiMayChange: json['rashiMayChange'] == true,
        lagnaMayChange: json['lagnaMayChange'] == true,
        navamshaMayChange: json['navamshaMayChange'] == true,
      );
}

/// The Jataka/Porutham section of a report — matches
/// `CompatibilityReportJataka`. Right now every Porutham comes back
/// NOT_CALCULABLE (no Karnataka rule table is approved yet) — that's the
/// backend's honest, correct output, not a bug, so the UI renders it as
/// "pending astrologer approval" rather than an error.
class CompatibilityJataka {
  const CompatibilityJataka({
    required this.ruleVersion,
    required this.brideProfileId,
    required this.groomProfileId,
    required this.matched,
    required this.partial,
    required this.notMatched,
    required this.reviewRequired,
    required this.notCalculable,
    required this.normalizedPercentage,
    required this.verdict,
    required this.verdictLabel,
    required this.criticalAlerts,
    required this.poruthams,
    required this.brideBoundaryRisk,
    required this.groomBoundaryRisk,
    required this.nakshatraBoundaryRiskOverride,
    this.ruleVersionId,
    this.ruleVersionStatus = '',
    this.ruleVersionChecksum,
  });

  final String ruleVersion;
  final String brideProfileId;
  final String groomProfileId;
  final int matched;
  final int partial;
  final int notMatched;
  final int reviewRequired;
  final int notCalculable;
  /// Internal normalized score (compatibility spec §25) — the UI leads with
  /// `matched`/10, not this; null when nothing was calculable at all.
  final int? normalizedPercentage;
  final TraditionalVerdictCode verdict;
  final String verdictLabel;
  final List<PoruthamResult> criticalAlerts;
  final List<PoruthamResult> poruthams;

  /// §10 boundary risk for each side's recorded birth time.
  final BoundaryRisk? brideBoundaryRisk;
  final BoundaryRisk? groomBoundaryRisk;

  /// True when either side's Nakshatra could plausibly be different given
  /// their birth-time uncertainty — when true, the backend already forced
  /// every Porutham above to REVIEW_REQUIRED rather than trusting the
  /// single-instant calculation (see CompatibilityService). This flag is
  /// purely informational for the UI — it must never be recomputed here,
  /// only displayed.
  final bool nakshatraBoundaryRiskOverride;

  /// The AstrologyRuleVersion actually resolved and used for [poruthams] —
  /// null when the requested rule version had nothing PUBLISHED (or failed
  /// its checksum check) at calculation time, in which case every Porutham
  /// above is NOT_CALCULABLE for that reason.
  final String? ruleVersionId;

  /// DRAFT/UNDER_REVIEW/APPROVED/PUBLISHED/RETIRED, or 'UNRESOLVED' when
  /// [ruleVersionId] is null — kept as a raw wire string (a low-priority
  /// informational field, same convention as [PoruthamResult.code]).
  final String ruleVersionStatus;
  final String? ruleVersionChecksum;

  factory CompatibilityJataka.fromJson(Map<String, dynamic> json) => CompatibilityJataka(
        ruleVersion: (json['ruleVersion'] ?? '').toString(),
        brideProfileId: (json['brideProfileId'] ?? '').toString(),
        groomProfileId: (json['groomProfileId'] ?? '').toString(),
        matched: (json['matched'] as num?)?.toInt() ?? 0,
        partial: (json['partial'] as num?)?.toInt() ?? 0,
        notMatched: (json['notMatched'] as num?)?.toInt() ?? 0,
        reviewRequired: (json['reviewRequired'] as num?)?.toInt() ?? 0,
        notCalculable: (json['notCalculable'] as num?)?.toInt() ?? 0,
        normalizedPercentage: (json['normalizedPercentage'] as num?)?.toInt(),
        verdict: TraditionalVerdictCode.fromWire((json['verdict'] ?? '').toString()),
        verdictLabel: (json['verdictLabel'] ?? '').toString(),
        criticalAlerts: _poruthamList(json['criticalAlerts']),
        poruthams: _poruthamList(json['poruthams']),
        brideBoundaryRisk: json['brideBoundaryRisk'] is Map
            ? BoundaryRisk.fromJson(Map<String, dynamic>.from(json['brideBoundaryRisk'] as Map))
            : null,
        groomBoundaryRisk: json['groomBoundaryRisk'] is Map
            ? BoundaryRisk.fromJson(Map<String, dynamic>.from(json['groomBoundaryRisk'] as Map))
            : null,
        nakshatraBoundaryRiskOverride: json['nakshatraBoundaryRiskOverride'] == true,
        ruleVersionId: json['ruleVersionId'] as String?,
        ruleVersionStatus: (json['ruleVersionStatus'] ?? '').toString(),
        ruleVersionChecksum: json['ruleVersionChecksum'] as String?,
      );

  static List<PoruthamResult> _poruthamList(dynamic value) => (value is List ? value : const [])
      .whereType<Map>()
      .map((e) => PoruthamResult.fromJson(Map<String, dynamic>.from(e)))
      .toList();
}

/// What `POST /api/v1/compatibility/calculate` actually hands back — matches
/// the backend's `CalculateCompatibilityResponse` type EXACTLY:
/// `{ reportId: string } & Partial<Record<ModuleStatusKey, ModuleResultStatus>>`.
/// This is NOT the same shape as [CompatibilityReport]/`GET /reports/:id` —
/// there is no `id` field here (only `reportId`), and no `jataka` object
/// (only a top-level status string per requested module). A caller that
/// needs the full per-module detail (Poruthams, Ashtakoota, …) must follow
/// up with `Repository.compatibilityReport(reportId)` or
/// `Repository.southIndianJataka(reportId)` using [reportId] from here.
class CalculateCompatibilityResponse {
  const CalculateCompatibilityResponse({
    required this.reportId,
    required this.moduleStatuses,
  });

  /// The persisted report's id — the ONLY id `POST /calculate` returns.
  /// Everything downstream (`GET /reports/:id`, `.../south-indian-jataka`,
  /// …) keys on this, never on a candidate/profile id, and never a value
  /// invented client-side.
  final String reportId;

  /// One entry per requested module ('jataka', 'profile', 'family',
  /// 'personality', 'relationshipGraph', 'verification') → its wire status
  /// ('CALCULATED'/'REVIEW_REQUIRED'/'NOT_CALCULABLE'). Kept as raw wire
  /// strings — callers needing the enum use
  /// `AstrologyModuleStatus.fromWire` (south_indian_jataka.dart).
  final Map<String, String> moduleStatuses;

  factory CalculateCompatibilityResponse.fromJson(Map<String, dynamic> json) {
    final statuses = <String, String>{};
    for (final entry in json.entries) {
      if (entry.key == 'reportId') continue;
      if (entry.value is String) statuses[entry.key] = entry.value as String;
    }
    return CalculateCompatibilityResponse(
      reportId: (json['reportId'] ?? '').toString(),
      moduleStatuses: statuses,
    );
  }
}

/// Matches `ConfidenceLevel` — a coarse, deterministic signal derived purely
/// from which modules actually calculated vs. required review vs. couldn't
/// run at all. Never an AI score or a probability.
enum ConfidenceLevel {
  none,
  low,
  moderate,
  high,
  unknown;

  static ConfidenceLevel fromWire(String value) => switch (value) {
        'NONE' => ConfidenceLevel.none,
        'LOW' => ConfidenceLevel.low,
        'MODERATE' => ConfidenceLevel.moderate,
        'HIGH' => ConfidenceLevel.high,
        _ => ConfidenceLevel.unknown,
      };
}

/// What `GET /reports/:id` hands back — matches `CompatibilityReportView`.
///
/// STEP 72 note on model naming/reuse (per the existing architecture's own
/// "prefer composition over duplicated models" rule): the backend's
/// `CompatibilityReportJataka`/`CompatibilityReportAshtakoota` sections are
/// exposed here as [jataka] ([CompatibilityJataka], already existed) and
/// [ashtakoota] ([AshtakootaResult], already existed in
/// south_indian_jataka.dart for the dedicated south-indian-jataka endpoint —
/// reused as-is rather than duplicated, since the two backend types are
/// identical). `family`/`personality`/`relationshipGraph`/`familyCompatibility`
/// and the raw `moduleStatuses` map are deliberately NOT modeled — STEP 72
/// explicitly excludes Family/Personality Compatibility, and every other
/// field they'd carry is either always the same
/// `{status: NOT_CALCULABLE, reason: 'ENGINE_NOT_IMPLEMENTED'}` stub or
/// already covered by [notImplementedInclude].
class CompatibilityReport {
  const CompatibilityReport({
    required this.id,
    required this.profileAId,
    required this.profileBId,
    required this.traditionalRoleA,
    required this.traditionalRoleB,
    required this.ruleVersion,
    required this.requestedInclude,
    required this.notImplementedInclude,
    required this.jataka,
    required this.ashtakoota,
    required this.advancedJataka,
    required this.kujaDosha,
    required this.dasha,
    required this.daivagnaParampara,
    required this.vivahaKalaBala,
    required this.kundliChart,
    required this.astrologyCompatibility,
    required this.profileCompatibility,
    required this.overallCompatibility,
    required this.discussionPoints,
    required this.overallStatus,
    required this.disclaimer,
    required this.coverage,
    required this.confidence,
    required this.createdAt,
  });

  final String id;
  final String profileAId;
  final String profileBId;
  final TraditionalRole? traditionalRoleA;
  final TraditionalRole? traditionalRoleB;
  final String ruleVersion;
  final List<String> requestedInclude;
  final List<String> notImplementedInclude;

  /// The Karnataka 10-Porutham section — null under exactly the same
  /// conditions every sibling module below is null (JATAKA not requested,
  /// missing consent, or missing/invalid birth data).
  final CompatibilityJataka? jataka;

  /// The Ashtakoota 36-Guna section — computed alongside [jataka] (same
  /// charts, same consent gate; Ashtakoota is not a separately requestable
  /// `include` module), null under the same conditions.
  final AshtakootaResult? ashtakoota;

  final AdvancedJataka? advancedJataka;
  final KujaDosha? kujaDosha;
  final DashaCompatibility? dasha;
  final DaivagnaParampara? daivagnaParampara;
  final VivahaKalaBala? vivahaKalaBala;

  /// STEP 80 — the Kundli / Janma Kundali D1+D9 chart snapshot, computed
  /// alongside [jataka] (same charts, same consent gate; Kundli Chart is not
  /// a separately requestable `include` module), null under the same
  /// conditions. A purely presentational addition — not an eighth
  /// traditional-astrology system.
  final KundliChart? kundliChart;

  /// STEP 64 — Karnataka's own percentage as the PRIMARY astrology figure
  /// (Ashtakoota's reported separately alongside it, never blended in) —
  /// null under the same conditions [jataka] itself is null.
  final AstrologyCompatibility? astrologyCompatibility;

  /// STEP 65 — the questionnaire-based system, independent of every
  /// astrology module above. Gated on its own PROFILE_ANSWER_COMPARISON
  /// consent — null when either profile hasn't granted it, independently of
  /// whether the astrology modules ran at all.
  final ProfileCompatibility? profileCompatibility;

  /// STEP 69 — combines ONLY [profileCompatibility]/[astrologyCompatibility]
  /// (50/50). Always present (never null) — its own `status` carries
  /// NOT_CALCULABLE when neither input is available, rather than the field
  /// itself being absent.
  final OverallCompatibility overallCompatibility;

  /// STEP 69 §11 — deterministic discussion points derived from
  /// already-computed results above. Never alters, and must never be used by
  /// this app to alter, any percentage.
  final List<DiscussionPoint> discussionPoints;

  /// FINAL BACKEND COMPLETION §3 — a single neutral summary of the 7
  /// astrology modules (never a percentage or score; the different systems
  /// are never combined into one number).
  final AstrologyModuleStatus overallStatus;

  /// FINAL BACKEND COMPLETION §9 — the exact, verbatim disclaimer every
  /// report carries, regardless of [overallStatus]. Always present — display
  /// as-is, never paraphrased.
  final String disclaimer;

  /// 0-100: % of the requested compatibility modules that produced
  /// CALCULATED or REVIEW_REQUIRED rather than NOT_CALCULABLE.
  final int coverage;
  final ConfidenceLevel confidence;
  final DateTime? createdAt;

  factory CompatibilityReport.fromJson(Map<String, dynamic> json) => CompatibilityReport(
        id: (json['id'] ?? '').toString(),
        profileAId: (json['profileAId'] ?? '').toString(),
        profileBId: (json['profileBId'] ?? '').toString(),
        traditionalRoleA: TraditionalRole.forWire((json['traditionalRoleA'] ?? '').toString()),
        traditionalRoleB: TraditionalRole.forWire((json['traditionalRoleB'] ?? '').toString()),
        ruleVersion: (json['ruleVersion'] ?? '').toString(),
        requestedInclude: _stringList(json['requestedInclude']),
        notImplementedInclude: _stringList(json['notImplementedInclude']),
        jataka: json['jataka'] is Map
            ? CompatibilityJataka.fromJson(Map<String, dynamic>.from(json['jataka'] as Map))
            : null,
        ashtakoota: json['ashtakoota'] is Map
            ? AshtakootaResult.fromJson(Map<String, dynamic>.from(json['ashtakoota'] as Map))
            : null,
        advancedJataka: json['advancedJataka'] is Map
            ? AdvancedJataka.fromJson(Map<String, dynamic>.from(json['advancedJataka'] as Map))
            : null,
        kujaDosha: json['kujaDosha'] is Map
            ? KujaDosha.fromJson(Map<String, dynamic>.from(json['kujaDosha'] as Map))
            : null,
        dasha: json['dasha'] is Map
            ? DashaCompatibility.fromJson(Map<String, dynamic>.from(json['dasha'] as Map))
            : null,
        daivagnaParampara: json['daivagnaParampara'] is Map
            ? DaivagnaParampara.fromJson(Map<String, dynamic>.from(json['daivagnaParampara'] as Map))
            : null,
        vivahaKalaBala: json['vivahaKalaBala'] is Map
            ? VivahaKalaBala.fromJson(Map<String, dynamic>.from(json['vivahaKalaBala'] as Map))
            : null,
        kundliChart: json['kundliChart'] is Map
            ? KundliChart.fromJson(Map<String, dynamic>.from(json['kundliChart'] as Map))
            : null,
        astrologyCompatibility: json['astrologyCompatibility'] is Map
            ? AstrologyCompatibility.fromJson(Map<String, dynamic>.from(json['astrologyCompatibility'] as Map))
            : null,
        profileCompatibility: json['profileCompatibility'] is Map
            ? ProfileCompatibility.fromJson(Map<String, dynamic>.from(json['profileCompatibility'] as Map))
            : null,
        overallCompatibility: OverallCompatibility.fromJson(
            json['overallCompatibility'] is Map ? Map<String, dynamic>.from(json['overallCompatibility'] as Map) : const {}),
        discussionPoints: discussionPointsFromJson(json['discussionPoints']),
        overallStatus: AstrologyModuleStatus.fromWire((json['overallStatus'] ?? '').toString()),
        disclaimer: (json['disclaimer'] ?? '').toString(),
        coverage: (json['coverage'] as num?)?.toInt() ?? 0,
        confidence: ConfidenceLevel.fromWire((json['confidence'] ?? '').toString()),
        createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()),
      );

  static List<String> _stringList(dynamic value) =>
      (value is List ? value : const []).map((e) => e.toString()).toList();
}

/// The known compatibility consent purposes — matches `CONSENT_TYPES` in the
/// backend's consent.schema.ts. Only [birthDataMatching] is required by
/// anything implemented today (Jataka needs birth data); the rest exist so
/// the UI has somewhere to grow into as Profile/Family/Personality/Report-
/// sharing consent get wired up, without a contract change.
enum CompatibilityConsentType {
  birthDataMatching('BIRTH_DATA_MATCHING'),
  profileAnswerComparison('PROFILE_ANSWER_COMPARISON'),
  familyTreeRelationshipCheck('FAMILY_TREE_RELATIONSHIP_CHECK'),
  sensitiveFieldComparison('SENSITIVE_FIELD_COMPARISON'),
  reportSharing('REPORT_SHARING');

  const CompatibilityConsentType(this.wireValue);
  final String wireValue;

  static CompatibilityConsentType? forWire(String value) {
    for (final t in CompatibilityConsentType.values) {
      if (t.wireValue == value) return t;
    }
    return null;
  }
}

/// One consent purpose's current status for the signed-in caller — matches
/// `ConsentStatusView` from `GET /api/v1/compatibility/consent`. This
/// endpoint is self-only server-side (ConsentController), so this type is
/// never used to represent anyone but the signed-in member's own consent —
/// there is no way to fetch another profile's.
class ConsentStatus {
  const ConsentStatus({
    required this.consentType,
    required this.granted,
    required this.isCurrentPolicy,
    required this.purpose,
    required this.policyVersion,
    required this.currentPolicyVersion,
    required this.grantedAt,
    required this.revokedAt,
  });

  final CompatibilityConsentType consentType;
  final bool granted;

  /// True only when [granted] AND the grant was recorded under the policy
  /// version currently in effect. A grant made under a since-superseded
  /// policy reads as `granted: true` (the decision genuinely happened, so
  /// the UI can still show when) but `isCurrentPolicy: false` — the member
  /// needs to re-confirm before it satisfies a calculation again.
  final bool isCurrentPolicy;

  final String? purpose;
  final String? policyVersion;
  final String currentPolicyVersion;
  final DateTime? grantedAt;
  final DateTime? revokedAt;

  /// Whether this purpose actually gates anything a calculation checks right
  /// now — mirrors ConsentService.hasConsent's own condition, purely for
  /// display (never re-derives what the server decides).
  bool get satisfiesCalculation => granted && isCurrentPolicy;

  factory ConsentStatus.fromJson(Map<String, dynamic> json) => ConsentStatus(
        consentType: CompatibilityConsentType.forWire((json['consentType'] ?? '').toString()) ??
            CompatibilityConsentType.birthDataMatching,
        granted: json['status'] == 'GRANTED',
        isCurrentPolicy: json['isCurrentPolicy'] == true,
        purpose: (json['purpose'] as String?),
        policyVersion: (json['policyVersion'] as String?),
        currentPolicyVersion: (json['currentPolicyVersion'] ?? '').toString(),
        grantedAt: DateTime.tryParse((json['grantedAt'] ?? '').toString()),
        revokedAt: DateTime.tryParse((json['revokedAt'] ?? '').toString()),
      );
}

/// Why a compatibility request couldn't be calculated. `missingRole` is
/// purely client-side (a gender is missing so GROOM/BRIDE can't be derived —
/// the request is never even sent); the other three come from the backend.
enum CompatibilityErrorReason {
  missingRole,
  missingBirthData,
  missingConsent,
  apiError,
}

/// Which side of the request the problem belongs to — [a] is always the
/// signed-in caller in this app's usage (profileAId), [b] the other profile.
enum CompatibilityErrorProfile { a, b }

/// A structured read of the backend's plain-string error codes (see
/// CompatibilityService/AstronomyCalculationService/ConsentService), so the
/// UI can switch on `reason` instead of string-matching `message` at every
/// call site.
class CompatibilityRequestError {
  const CompatibilityRequestError({
    required this.reason,
    required this.message,
    this.profile,
    this.detail,
  });

  final CompatibilityErrorReason reason;
  final String message;
  final CompatibilityErrorProfile? profile;

  /// The specific missing-field code (e.g. `TIME_OF_BIRTH_REQUIRED`) or
  /// consent type (e.g. `BIRTH_DATA_MATCHING`) this error is about.
  final String? detail;

  // The colon+type suffix is optional: ConsentService.validateCompatibilityConsent
  // throws a plain "PROFILE_A_CONSENT_MISSING" (the specific consentType
  // travels as a separate `consentType` field on the response body, which
  // ApiException/ApiClient doesn't surface) — matched without a suffix here
  // still tolerates an older/future colon-suffixed form if either ever sends one.
  static final _consentPattern = RegExp(r'^PROFILE_([AB])_CONSENT_MISSING(?::(.+))?$');
  static final _birthDataPattern = RegExp(
    r'^PROFILE_([AB])_'
    r'(DATE_OF_BIRTH_REQUIRED|TIME_OF_BIRTH_REQUIRED|TIMEZONE_REQUIRED|BIRTH_PLACE_COORDINATES_REQUIRED)$',
  );

  factory CompatibilityRequestError.fromApiException(ApiException e) {
    final msg = e.message;

    final consent = _consentPattern.firstMatch(msg);
    if (consent != null) {
      return CompatibilityRequestError(
        reason: CompatibilityErrorReason.missingConsent,
        message: msg,
        profile: consent.group(1) == 'A' ? CompatibilityErrorProfile.a : CompatibilityErrorProfile.b,
        detail: consent.group(2),
      );
    }

    final birthData = _birthDataPattern.firstMatch(msg);
    if (birthData != null) {
      return CompatibilityRequestError(
        reason: CompatibilityErrorReason.missingBirthData,
        message: msg,
        profile: birthData.group(1) == 'A' ? CompatibilityErrorProfile.a : CompatibilityErrorProfile.b,
        detail: birthData.group(2),
      );
    }

    return CompatibilityRequestError(reason: CompatibilityErrorReason.apiError, message: msg);
  }
}

/// Display label for a Porutham code, e.g. "RASHI_ADHIPATHI" → "Rashi Adhipathi".
const poruthamLabels = <String, String>{
  'DINA': 'Dina',
  'GANA': 'Gana',
  'MAHENDRA': 'Mahendra',
  'STREE_DEERGHA': 'Stree Deergha',
  'YONI': 'Yoni',
  'RASHI': 'Rashi',
  'RASHI_ADHIPATHI': 'Rashi Adhipathi',
  'VASHYA': 'Vashya',
  'RAJJU': 'Rajju',
  'VEDHA': 'Vedha',
};

String poruthamLabel(String code) => poruthamLabels[code] ?? code;
