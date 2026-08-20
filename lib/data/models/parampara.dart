/// Matches the backend's Parampara module — self-declared Gotra/Pravara/
/// Kuladevata/Kuladevi family-tradition data. Entirely separate from the
/// basic `User.gotra` field (used for sagotra matrimonial matching) — see
/// the backend's parampara.types.ts doc comment on why the two coexist.
///
/// Two distinct consumers share this file:
///  - `GET/PUT /api/parampara/me` (self-service save; this app only reads/
///    writes [ParamparaProfile.kuladevata] today).
///  - STEP 72 — the `daivagnaParampara` section of
///    `GET /api/v1/compatibility/reports/:reportId` (READ-ONLY; both
///    partners' full gotra/pravara/kuladevata/kuladevi plus a purely
///    informational comparison — see [DaivagnaParampara]).
library;

import 'south_indian_jataka.dart' show AstrologyModuleStatus;

/// Matches `ParamparaValueStatus`. `PROVIDED` is the only status
/// [ParamparaDeclaredValue.customValue] is meaningful for.
enum ParamparaValueStatus {
  notProvided,
  unknown,
  provided;

  static ParamparaValueStatus fromWire(String value) => switch (value) {
        'PROVIDED' => ParamparaValueStatus.provided,
        'UNKNOWN' => ParamparaValueStatus.unknown,
        _ => ParamparaValueStatus.notProvided,
      };
}

/// Matches `ParamparaValueSource` — HOW a PROVIDED value was captured, never
/// a truth claim. `masterData` is modeled for forward-compatibility only;
/// the backend's Kuladevata/Gotra/Pravara/Kuladevi master lists are
/// deliberately empty in production today, so this app never actually
/// receives it.
enum ParamparaValueSource {
  userDeclared,
  masterData,
  unknown;

  static ParamparaValueSource fromWire(String value) => switch (value) {
        'USER_DECLARED' => ParamparaValueSource.userDeclared,
        'MASTER_DATA' => ParamparaValueSource.masterData,
        _ => ParamparaValueSource.unknown,
      };
}

/// Matches `ParamparaVerificationStatus` — deliberately only two members; no
/// verification workflow exists yet for Gotra/Pravara/Kuladevata/Kuladevi.
enum ParamparaVerificationStatus {
  notAvailable,
  unverified,
  unknown;

  static ParamparaVerificationStatus fromWire(String value) => switch (value) {
        'NOT_AVAILABLE' => ParamparaVerificationStatus.notAvailable,
        'UNVERIFIED' => ParamparaVerificationStatus.unverified,
        _ => ParamparaVerificationStatus.unknown,
      };
}

/// Matches `ParamparaDeclaredValue`. The backend's Kuladevata master list
/// (`KULADEVATA_MASTER`) is deliberately empty in production — a family's
/// Kuladevata is never a shared, inferable constant — so `source` is always
/// USER_DECLARED in practice; this app never sends MASTER_DATA/masterId.
/// `source`/`masterId`/`verificationStatus` are additive to this app's own
/// self-service save flow (which only ever reads `status`/`customValue`) —
/// needed when reading ANOTHER member's declared Parampara data off a
/// compatibility report (see [PartnerParamparaResult]).
class ParamparaDeclaredValue {
  const ParamparaDeclaredValue({
    required this.status,
    required this.customValue,
    this.source,
    this.masterId,
    this.verificationStatus = ParamparaVerificationStatus.notAvailable,
  });

  final ParamparaValueStatus status;
  final String? customValue;
  final ParamparaValueSource? source;
  final int? masterId;
  final ParamparaVerificationStatus verificationStatus;

  factory ParamparaDeclaredValue.fromJson(Map<String, dynamic> json) => ParamparaDeclaredValue(
        status: ParamparaValueStatus.fromWire((json['status'] ?? '').toString()),
        customValue: json['customValue'] as String?,
        source: json['source'] is String ? ParamparaValueSource.fromWire(json['source'] as String) : null,
        masterId: (json['masterId'] as num?)?.toInt(),
        verificationStatus: ParamparaVerificationStatus.fromWire((json['verificationStatus'] ?? '').toString()),
      );
}

/// The fields this app actually reads from `GET /api/parampara/me`.
class ParamparaProfile {
  const ParamparaProfile({required this.kuladevata});

  final ParamparaDeclaredValue kuladevata;

  static const _notProvided = ParamparaDeclaredValue(status: ParamparaValueStatus.notProvided, customValue: null);

  factory ParamparaProfile.fromJson(Map<String, dynamic> json) => ParamparaProfile(
        kuladevata: json['kuladevata'] is Map
            ? ParamparaDeclaredValue.fromJson(Map<String, dynamic>.from(json['kuladevata'] as Map))
            : _notProvided,
      );
}

// ── Daivagna Parampara report section (STEP 54, wired into the report in
// STEP 72) ───────────────────────────────────────────────────────────────

/// Matches `ParamparaFieldComparisonStatus` — a purely descriptive equality
/// comparison of two declared values. MATCH does not mean "compatible";
/// DIFFERENT does not mean "incompatible" — neither is ever produced from a
/// fabricated tradition rule (e.g. "same Gotra = incompatible" is explicitly
/// forbidden on the backend).
enum ParamparaFieldComparisonStatus {
  match,
  different,
  notCalculable,
  unknown;

  static ParamparaFieldComparisonStatus fromWire(String value) => switch (value) {
        'MATCH' => ParamparaFieldComparisonStatus.match,
        'DIFFERENT' => ParamparaFieldComparisonStatus.different,
        'NOT_CALCULABLE' => ParamparaFieldComparisonStatus.notCalculable,
        _ => ParamparaFieldComparisonStatus.unknown,
      };
}

/// Matches `ParamparaFieldComparison` — one field's (gotra/pravara/
/// kuladevata/kuladevi) bride-vs-groom comparison.
class ParamparaFieldComparison {
  const ParamparaFieldComparison({
    required this.field,
    required this.status,
    required this.reasonCode,
    required this.explanation,
  });

  final String field;
  final ParamparaFieldComparisonStatus status;
  final String reasonCode;
  final String explanation;

  factory ParamparaFieldComparison.fromJson(Map<String, dynamic> json) => ParamparaFieldComparison(
        field: (json['field'] ?? '').toString(),
        status: ParamparaFieldComparisonStatus.fromWire((json['status'] ?? '').toString()),
        reasonCode: (json['reasonCode'] ?? '').toString(),
        explanation: (json['explanation'] ?? '').toString(),
      );
}

/// Matches `ParamparaComparisonStatus`. REVIEW_REQUIRED here means "a
/// declared value has a data-integrity problem" (e.g. a MASTER_DATA-sourced
/// masterId that no longer resolves) — NOT "these two people's traditions
/// conflict." This module never derives REVIEW_REQUIRED from comparing two
/// valid declarations against each other.
enum ParamparaComparisonStatus {
  match,
  informational,
  reviewRequired,
  notCalculable,
  unknown;

  static ParamparaComparisonStatus fromWire(String value) => switch (value) {
        'MATCH' => ParamparaComparisonStatus.match,
        'INFORMATIONAL' => ParamparaComparisonStatus.informational,
        'REVIEW_REQUIRED' => ParamparaComparisonStatus.reviewRequired,
        'NOT_CALCULABLE' => ParamparaComparisonStatus.notCalculable,
        _ => ParamparaComparisonStatus.unknown,
      };
}

/// Matches `ParamparaComparison` — the pair-level comparison.
class ParamparaComparison {
  const ParamparaComparison({
    required this.status,
    required this.reasonCode,
    required this.explanation,
    required this.fieldFindings,
  });

  final ParamparaComparisonStatus status;
  final String reasonCode;
  final String explanation;
  final List<ParamparaFieldComparison> fieldFindings;

  factory ParamparaComparison.fromJson(Map<String, dynamic> json) => ParamparaComparison(
        status: ParamparaComparisonStatus.fromWire((json['status'] ?? '').toString()),
        reasonCode: (json['reasonCode'] ?? '').toString(),
        explanation: (json['explanation'] ?? '').toString(),
        fieldFindings: (json['fieldFindings'] is List ? json['fieldFindings'] as List : const [])
            .whereType<Map>()
            .map((e) => ParamparaFieldComparison.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}

/// Matches `PartnerParamparaResult` — one partner's full declared tradition
/// data (all four fields, not just Kuladevata). `status` reuses
/// [AstrologyModuleStatus]: NOT_CALCULABLE only when the person has no
/// ParamparaProfile document at all; CALCULATED otherwise, regardless of how
/// many of the four fields are NOT_PROVIDED/UNKNOWN — "hasn't filled this
/// in" is itself a valid, calculated state, never a failure.
class PartnerParamparaResult {
  const PartnerParamparaResult({
    required this.status,
    required this.reviewRequired,
    required this.reasonCode,
    required this.explanation,
    required this.gotra,
    required this.pravara,
    required this.kuladevata,
    required this.kuladevi,
  });

  final AstrologyModuleStatus status;
  final bool reviewRequired;
  final String reasonCode;
  final String explanation;
  final ParamparaDeclaredValue gotra;
  final ParamparaDeclaredValue pravara;
  final ParamparaDeclaredValue kuladevata;
  final ParamparaDeclaredValue kuladevi;

  static const _notProvided = ParamparaDeclaredValue(status: ParamparaValueStatus.notProvided, customValue: null);

  factory PartnerParamparaResult.fromJson(Map<String, dynamic> json) => PartnerParamparaResult(
        status: AstrologyModuleStatus.fromWire((json['status'] ?? '').toString()),
        reviewRequired: json['reviewRequired'] == true,
        reasonCode: (json['reasonCode'] ?? '').toString(),
        explanation: (json['explanation'] ?? '').toString(),
        gotra: json['gotra'] is Map
            ? ParamparaDeclaredValue.fromJson(Map<String, dynamic>.from(json['gotra'] as Map))
            : _notProvided,
        pravara: json['pravara'] is Map
            ? ParamparaDeclaredValue.fromJson(Map<String, dynamic>.from(json['pravara'] as Map))
            : _notProvided,
        kuladevata: json['kuladevata'] is Map
            ? ParamparaDeclaredValue.fromJson(Map<String, dynamic>.from(json['kuladevata'] as Map))
            : _notProvided,
        kuladevi: json['kuladevi'] is Map
            ? ParamparaDeclaredValue.fromJson(Map<String, dynamic>.from(json['kuladevi'] as Map))
            : _notProvided,
      );
}

/// Matches `CompatibilityReportDaivagnaParampara` — the report's
/// `daivagnaParampara` section. Unlike every other astrology module, this
/// one has no BoundaryRisk fields — birth-time uncertainty has no bearing on
/// a DECLARED family-tradition value. Purely informational, never an
/// incompatibility verdict.
class DaivagnaParampara {
  const DaivagnaParampara({
    required this.ruleVersion,
    required this.brideProfileId,
    required this.groomProfileId,
    required this.status,
    required this.reviewRequired,
    required this.reasonCode,
    required this.explanation,
    required this.bride,
    required this.groom,
    required this.comparison,
  });

  final String ruleVersion;
  final String brideProfileId;
  final String groomProfileId;
  final ParamparaComparisonStatus status;
  final bool reviewRequired;
  final String reasonCode;
  final String explanation;
  final PartnerParamparaResult bride;
  final PartnerParamparaResult groom;
  final ParamparaComparison comparison;

  factory DaivagnaParampara.fromJson(Map<String, dynamic> json) => DaivagnaParampara(
        ruleVersion: (json['ruleVersion'] ?? '').toString(),
        brideProfileId: (json['brideProfileId'] ?? '').toString(),
        groomProfileId: (json['groomProfileId'] ?? '').toString(),
        status: ParamparaComparisonStatus.fromWire((json['status'] ?? '').toString()),
        reviewRequired: json['reviewRequired'] == true,
        reasonCode: (json['reasonCode'] ?? '').toString(),
        explanation: (json['explanation'] ?? '').toString(),
        bride: PartnerParamparaResult.fromJson(
            json['bride'] is Map ? Map<String, dynamic>.from(json['bride'] as Map) : const {}),
        groom: PartnerParamparaResult.fromJson(
            json['groom'] is Map ? Map<String, dynamic>.from(json['groom'] as Map) : const {}),
        comparison: ParamparaComparison.fromJson(
            json['comparison'] is Map ? Map<String, dynamic>.from(json['comparison'] as Map) : const {}),
      );
}
