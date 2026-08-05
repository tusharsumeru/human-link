import '../api_client.dart';

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
  });

  final String code;
  final PoruthamStatus status;
  final double? score;
  final String ruleId;
  final Map<String, dynamic> details;
  final bool isCritical;

  factory PoruthamResult.fromJson(Map<String, dynamic> json) => PoruthamResult(
        code: (json['code'] ?? '').toString(),
        status: PoruthamStatus.fromWire((json['status'] ?? '').toString()),
        score: (json['score'] as num?)?.toDouble(),
        ruleId: (json['ruleId'] ?? '').toString(),
        details: json['details'] is Map
            ? Map<String, dynamic>.from(json['details'] as Map)
            : const {},
        isCritical: json['severity'] == 'CRITICAL',
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
      );

  static List<PoruthamResult> _poruthamList(dynamic value) => (value is List ? value : const [])
      .whereType<Map>()
      .map((e) => PoruthamResult.fromJson(Map<String, dynamic>.from(e)))
      .toList();
}

/// What `POST /calculate` and `GET /reports/:id` both hand back — matches
/// `CompatibilityReportView`. Only the JATAKA module is implemented on the
/// backend today, so [jataka] is the only section with real content;
/// [notImplementedInclude] echoes back anything else requested (Profile,
/// Family, Personality, …) that the server accepted but couldn't compute yet.
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
  final CompatibilityJataka? jataka;
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
