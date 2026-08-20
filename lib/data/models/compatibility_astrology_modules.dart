/// STEP 72 — models for the four "sibling astrology system" sections of
/// `GET /api/v1/compatibility/reports/:reportId`: Advanced Jataka (STEP 51),
/// Kuja Dosha (STEP 52), Dasha Compatibility (STEP 53), and Vivaha Kala Bala
/// (STEP 55/56). Each is a deliberately independent traditional-astrology
/// system on the backend — never merged with Karnataka 10-Porutham,
/// Ashtakoota, or each other, and never collapsed into a percentage. Nothing
/// here recomputes a chart, a Dasha timeline, or a transit position — this
/// file only parses what the backend already calculated.
library;

import 'compatibility_models.dart' show BoundaryRisk;
import 'south_indian_jataka.dart' show AstrologyModuleStatus;

/// Matches `AdvancedJatakaStatus`/`VivahaKalaBalaStatus` — identical 5-value
/// wire vocabulary on the backend (two separate TypeScript types, one Dart
/// enum here since the values are the same). Reserved for the TOP-LEVEL
/// result of each of those two modules only; every individual finding inside
/// either module uses the plain 3-value [AstrologyModuleStatus] instead.
enum AstrologyFavorabilityStatus {
  supportive,
  neutral,
  caution,
  reviewRequired,
  notCalculable,
  unknown;

  static AstrologyFavorabilityStatus fromWire(String value) => switch (value) {
        'SUPPORTIVE' => AstrologyFavorabilityStatus.supportive,
        'NEUTRAL' => AstrologyFavorabilityStatus.neutral,
        'CAUTION' => AstrologyFavorabilityStatus.caution,
        'REVIEW_REQUIRED' => AstrologyFavorabilityStatus.reviewRequired,
        'NOT_CALCULABLE' => AstrologyFavorabilityStatus.notCalculable,
        _ => AstrologyFavorabilityStatus.unknown,
      };
}

// ── Advanced Jataka (STEP 51) ───────────────────────────────────────────────

/// Matches `AdvancedJatakaFinding`. `data` is a free-form map (derived chart
/// attributes only — never a raw birth time/coordinate, per the backend's own
/// "no sensitive birth information" rule) — kept as a raw map for the same
/// reason [PoruthamResult.details] is: no single typed shape covers every
/// finding code.
class AdvancedJatakaFinding {
  const AdvancedJatakaFinding({
    required this.code,
    required this.status,
    required this.reasonCode,
    required this.explanation,
    required this.reviewRequired,
    required this.data,
  });

  final String code;
  final AstrologyModuleStatus status;
  final String reasonCode;
  final String explanation;
  final bool reviewRequired;
  final Map<String, dynamic>? data;

  factory AdvancedJatakaFinding.fromJson(Map<String, dynamic> json) => AdvancedJatakaFinding(
        code: (json['code'] ?? '').toString(),
        status: AstrologyModuleStatus.fromWire((json['status'] ?? '').toString()),
        reasonCode: (json['reasonCode'] ?? '').toString(),
        explanation: (json['explanation'] ?? '').toString(),
        reviewRequired: json['reviewRequired'] == true,
        data: json['data'] is Map ? Map<String, dynamic>.from(json['data'] as Map) : null,
      );
}

AdvancedJatakaFinding _findingOrEmpty(Map<String, dynamic> json, String key) {
  final value = json[key];
  return value is Map
      ? AdvancedJatakaFinding.fromJson(Map<String, dynamic>.from(value))
      : const AdvancedJatakaFinding(
          code: '',
          status: AstrologyModuleStatus.notCalculable,
          reasonCode: '',
          explanation: '',
          reviewRequired: false,
          data: null,
        );
}

/// Matches `PartnerAdvancedJataka` — one partner's natal + Navamsha (D9)
/// findings.
class PartnerAdvancedJataka {
  const PartnerAdvancedJataka({
    required this.lagna,
    required this.lagnaLord,
    required this.seventhHouse,
    required this.seventhLord,
    required this.seventhHouseOccupants,
    required this.seventhHouseAspects,
    required this.venus,
    required this.jupiter,
    required this.moon,
    required this.mars,
    required this.d9Lagna,
    required this.d9SeventhHouse,
    required this.d9SeventhLord,
    required this.d9Venus,
    required this.d9Jupiter,
  });

  final AdvancedJatakaFinding lagna;
  final AdvancedJatakaFinding lagnaLord;
  final AdvancedJatakaFinding seventhHouse;
  final AdvancedJatakaFinding seventhLord;
  final AdvancedJatakaFinding seventhHouseOccupants;
  final AdvancedJatakaFinding seventhHouseAspects;
  final AdvancedJatakaFinding venus;
  final AdvancedJatakaFinding jupiter;
  final AdvancedJatakaFinding moon;
  final AdvancedJatakaFinding mars;

  final AdvancedJatakaFinding d9Lagna;
  final AdvancedJatakaFinding d9SeventhHouse;
  final AdvancedJatakaFinding d9SeventhLord;
  final AdvancedJatakaFinding d9Venus;
  final AdvancedJatakaFinding d9Jupiter;

  /// All natal findings, in the backend's own field order — for a UI that
  /// wants to iterate rather than name each getter.
  List<AdvancedJatakaFinding> get natalFindings =>
      [lagna, lagnaLord, seventhHouse, seventhLord, seventhHouseOccupants, seventhHouseAspects, venus, jupiter, moon, mars];

  List<AdvancedJatakaFinding> get navamshaFindings => [d9Lagna, d9SeventhHouse, d9SeventhLord, d9Venus, d9Jupiter];

  factory PartnerAdvancedJataka.fromJson(Map<String, dynamic> json) {
    final natal = json['natal'] is Map ? Map<String, dynamic>.from(json['natal'] as Map) : const <String, dynamic>{};
    final navamsha =
        json['navamsha'] is Map ? Map<String, dynamic>.from(json['navamsha'] as Map) : const <String, dynamic>{};
    return PartnerAdvancedJataka(
      lagna: _findingOrEmpty(natal, 'lagna'),
      lagnaLord: _findingOrEmpty(natal, 'lagnaLord'),
      seventhHouse: _findingOrEmpty(natal, 'seventhHouse'),
      seventhLord: _findingOrEmpty(natal, 'seventhLord'),
      seventhHouseOccupants: _findingOrEmpty(natal, 'seventhHouseOccupants'),
      seventhHouseAspects: _findingOrEmpty(natal, 'seventhHouseAspects'),
      venus: _findingOrEmpty(natal, 'venus'),
      jupiter: _findingOrEmpty(natal, 'jupiter'),
      moon: _findingOrEmpty(natal, 'moon'),
      mars: _findingOrEmpty(natal, 'mars'),
      d9Lagna: _findingOrEmpty(navamsha, 'd9Lagna'),
      d9SeventhHouse: _findingOrEmpty(navamsha, 'd9SeventhHouse'),
      d9SeventhLord: _findingOrEmpty(navamsha, 'd9SeventhLord'),
      d9Venus: _findingOrEmpty(navamsha, 'd9Venus'),
      d9Jupiter: _findingOrEmpty(navamsha, 'd9Jupiter'),
    );
  }
}

/// Matches `CompatibilityReportAdvancedJataka` — the report's `advancedJataka`
/// section. `status` is honestly NOT_CALCULABLE/REVIEW_REQUIRED today (no
/// approved formula turns the findings into SUPPORTIVE/NEUTRAL/CAUTION yet;
/// see the backend's own doc comment) — Flutter must never infer a
/// favorability verdict from the individual findings itself.
class AdvancedJataka {
  const AdvancedJataka({
    required this.ruleVersion,
    required this.brideProfileId,
    required this.groomProfileId,
    required this.status,
    required this.reviewRequired,
    required this.reasonCode,
    required this.explanation,
    required this.bride,
    required this.groom,
    required this.brideBoundaryRisk,
    required this.groomBoundaryRisk,
  });

  final String ruleVersion;
  final String brideProfileId;
  final String groomProfileId;
  final AstrologyFavorabilityStatus status;
  final bool reviewRequired;
  final String reasonCode;
  final String explanation;
  final PartnerAdvancedJataka bride;
  final PartnerAdvancedJataka groom;
  final BoundaryRisk? brideBoundaryRisk;
  final BoundaryRisk? groomBoundaryRisk;

  factory AdvancedJataka.fromJson(Map<String, dynamic> json) => AdvancedJataka(
        ruleVersion: (json['ruleVersion'] ?? '').toString(),
        brideProfileId: (json['brideProfileId'] ?? '').toString(),
        groomProfileId: (json['groomProfileId'] ?? '').toString(),
        status: AstrologyFavorabilityStatus.fromWire((json['status'] ?? '').toString()),
        reviewRequired: json['reviewRequired'] == true,
        reasonCode: (json['reasonCode'] ?? '').toString(),
        explanation: (json['explanation'] ?? '').toString(),
        bride: PartnerAdvancedJataka.fromJson(
            json['bride'] is Map ? Map<String, dynamic>.from(json['bride'] as Map) : const {}),
        groom: PartnerAdvancedJataka.fromJson(
            json['groom'] is Map ? Map<String, dynamic>.from(json['groom'] as Map) : const {}),
        brideBoundaryRisk: json['brideBoundaryRisk'] is Map
            ? BoundaryRisk.fromJson(Map<String, dynamic>.from(json['brideBoundaryRisk'] as Map))
            : null,
        groomBoundaryRisk: json['groomBoundaryRisk'] is Map
            ? BoundaryRisk.fromJson(Map<String, dynamic>.from(json['groomBoundaryRisk'] as Map))
            : null,
      );
}

// ── Kuja Dosha / Manglik (STEP 52) ──────────────────────────────────────────

/// Matches `KujaDoshaStatus` — a dedicated 8-value vocabulary, distinct from
/// [AstrologyModuleStatus] and [AstrologyFavorabilityStatus].
enum KujaDoshaStatus {
  notPresent,
  mild,
  moderate,
  strong,
  cancelled,
  balancedWithPartner,
  reviewRequired,
  notCalculable,
  unknown;

  static KujaDoshaStatus fromWire(String value) => switch (value) {
        'NOT_PRESENT' => KujaDoshaStatus.notPresent,
        'MILD' => KujaDoshaStatus.mild,
        'MODERATE' => KujaDoshaStatus.moderate,
        'STRONG' => KujaDoshaStatus.strong,
        'CANCELLED' => KujaDoshaStatus.cancelled,
        'BALANCED_WITH_PARTNER' => KujaDoshaStatus.balancedWithPartner,
        'REVIEW_REQUIRED' => KujaDoshaStatus.reviewRequired,
        'NOT_CALCULABLE' => KujaDoshaStatus.notCalculable,
        _ => KujaDoshaStatus.unknown,
      };

  /// Matches the backend's own `isActiveKujaDosha` predicate — true only for
  /// an active, uncancelled dosha. Reused as-is, never re-derived from a
  /// different rule client-side.
  bool get isActive => this == KujaDoshaStatus.mild || this == KujaDoshaStatus.moderate || this == KujaDoshaStatus.strong;
}

/// Matches `KujaReferenceFinding`.
class KujaReferenceFinding {
  const KujaReferenceFinding({
    required this.reference,
    required this.status,
    required this.marsHouse,
    required this.affected,
    required this.reasonCode,
    required this.explanation,
  });

  final String reference;
  final AstrologyModuleStatus status;
  final int? marsHouse;
  final bool? affected;
  final String reasonCode;
  final String explanation;

  factory KujaReferenceFinding.fromJson(Map<String, dynamic> json) => KujaReferenceFinding(
        reference: (json['reference'] ?? '').toString(),
        status: AstrologyModuleStatus.fromWire((json['status'] ?? '').toString()),
        marsHouse: (json['marsHouse'] as num?)?.toInt(),
        affected: json['affected'] as bool?,
        reasonCode: (json['reasonCode'] ?? '').toString(),
        explanation: (json['explanation'] ?? '').toString(),
      );
}

/// Matches `KujaCancellationFinding`.
class KujaCancellationFinding {
  const KujaCancellationFinding({required this.ruleId, required this.explanation});

  final String ruleId;
  final String explanation;

  factory KujaCancellationFinding.fromJson(Map<String, dynamic> json) => KujaCancellationFinding(
        ruleId: (json['ruleId'] ?? '').toString(),
        explanation: (json['explanation'] ?? '').toString(),
      );
}

/// Matches `PartnerKujaResult`. `relevantMarsPlacements` exposes only Mars'
/// derived rashi — never a raw sidereal longitude or birth time.
class PartnerKujaResult {
  const PartnerKujaResult({
    required this.status,
    required this.reviewRequired,
    required this.reasonCode,
    required this.explanation,
    required this.fromLagna,
    required this.fromMoon,
    required this.fromVenus,
    required this.marsRashiId,
    required this.marsRashiName,
    required this.cancellationFindings,
  });

  final KujaDoshaStatus status;
  final bool reviewRequired;
  final String reasonCode;
  final String explanation;

  /// Null when this reference point isn't part of the approved rule set at
  /// all (a tradition choice) — distinct from a [KujaReferenceFinding] whose
  /// own `status` is NOT_CALCULABLE (missing chart data).
  final KujaReferenceFinding? fromLagna;
  final KujaReferenceFinding? fromMoon;
  final KujaReferenceFinding? fromVenus;

  final int? marsRashiId;
  final String? marsRashiName;

  final List<KujaCancellationFinding> cancellationFindings;

  factory PartnerKujaResult.fromJson(Map<String, dynamic> json) {
    final placements = json['relevantMarsPlacements'];
    final placementsMap = placements is Map ? Map<String, dynamic>.from(placements) : null;
    return PartnerKujaResult(
      status: KujaDoshaStatus.fromWire((json['status'] ?? '').toString()),
      reviewRequired: json['reviewRequired'] == true,
      reasonCode: (json['reasonCode'] ?? '').toString(),
      explanation: (json['explanation'] ?? '').toString(),
      fromLagna: json['fromLagna'] is Map
          ? KujaReferenceFinding.fromJson(Map<String, dynamic>.from(json['fromLagna'] as Map))
          : null,
      fromMoon: json['fromMoon'] is Map
          ? KujaReferenceFinding.fromJson(Map<String, dynamic>.from(json['fromMoon'] as Map))
          : null,
      fromVenus: json['fromVenus'] is Map
          ? KujaReferenceFinding.fromJson(Map<String, dynamic>.from(json['fromVenus'] as Map))
          : null,
      marsRashiId: (placementsMap?['rashiId'] as num?)?.toInt(),
      marsRashiName: placementsMap?['rashiName'] as String?,
      cancellationFindings: (json['cancellationFindings'] is List ? json['cancellationFindings'] as List : const [])
          .whereType<Map>()
          .map((e) => KujaCancellationFinding.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

/// Matches `KujaDoshaComparison` — the pair-level verdict.
class KujaDoshaComparison {
  const KujaDoshaComparison({required this.status, required this.reasonCode, required this.explanation});

  final KujaDoshaStatus status;
  final String reasonCode;
  final String explanation;

  factory KujaDoshaComparison.fromJson(Map<String, dynamic> json) => KujaDoshaComparison(
        status: KujaDoshaStatus.fromWire((json['status'] ?? '').toString()),
        reasonCode: (json['reasonCode'] ?? '').toString(),
        explanation: (json['explanation'] ?? '').toString(),
      );
}

/// Matches `CompatibilityReportKujaDosha` — the report's `kujaDosha` section.
/// `status`/`reviewRequired`/`reasonCode`/`explanation` mirror [comparison]
/// directly (the pair-level verdict IS the headline); `bride`/`groom` stay
/// fully detailed underneath even when [status] is REVIEW_REQUIRED/
/// NOT_CALCULABLE.
class KujaDosha {
  const KujaDosha({
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
    required this.brideBoundaryRisk,
    required this.groomBoundaryRisk,
  });

  final String ruleVersion;
  final String brideProfileId;
  final String groomProfileId;
  final KujaDoshaStatus status;
  final bool reviewRequired;
  final String reasonCode;
  final String explanation;
  final PartnerKujaResult bride;
  final PartnerKujaResult groom;
  final KujaDoshaComparison comparison;
  final BoundaryRisk? brideBoundaryRisk;
  final BoundaryRisk? groomBoundaryRisk;

  factory KujaDosha.fromJson(Map<String, dynamic> json) => KujaDosha(
        ruleVersion: (json['ruleVersion'] ?? '').toString(),
        brideProfileId: (json['brideProfileId'] ?? '').toString(),
        groomProfileId: (json['groomProfileId'] ?? '').toString(),
        status: KujaDoshaStatus.fromWire((json['status'] ?? '').toString()),
        reviewRequired: json['reviewRequired'] == true,
        reasonCode: (json['reasonCode'] ?? '').toString(),
        explanation: (json['explanation'] ?? '').toString(),
        bride: PartnerKujaResult.fromJson(
            json['bride'] is Map ? Map<String, dynamic>.from(json['bride'] as Map) : const {}),
        groom: PartnerKujaResult.fromJson(
            json['groom'] is Map ? Map<String, dynamic>.from(json['groom'] as Map) : const {}),
        comparison: KujaDoshaComparison.fromJson(
            json['comparison'] is Map ? Map<String, dynamic>.from(json['comparison'] as Map) : const {}),
        brideBoundaryRisk: json['brideBoundaryRisk'] is Map
            ? BoundaryRisk.fromJson(Map<String, dynamic>.from(json['brideBoundaryRisk'] as Map))
            : null,
        groomBoundaryRisk: json['groomBoundaryRisk'] is Map
            ? BoundaryRisk.fromJson(Map<String, dynamic>.from(json['groomBoundaryRisk'] as Map))
            : null,
      );
}

// ── Dasha Compatibility (STEP 53) ───────────────────────────────────────────

/// Matches `DashaComparisonStatus` — a dedicated 5-value vocabulary.
enum DashaComparisonStatus {
  supportive,
  neutral,
  sensitiveTransition,
  reviewRequired,
  notCalculable,
  unknown;

  static DashaComparisonStatus fromWire(String value) => switch (value) {
        'SUPPORTIVE' => DashaComparisonStatus.supportive,
        'NEUTRAL' => DashaComparisonStatus.neutral,
        'SENSITIVE_TRANSITION' => DashaComparisonStatus.sensitiveTransition,
        'REVIEW_REQUIRED' => DashaComparisonStatus.reviewRequired,
        'NOT_CALCULABLE' => DashaComparisonStatus.notCalculable,
        _ => DashaComparisonStatus.unknown,
      };
}

/// Matches `DashaMahadashaEntry`. `lord` is kept as the raw wire string
/// (KETU/VENUS/SUN/MOON/MARS/RAHU/JUPITER/SATURN/MERCURY) — a 9-value fixed
/// vocabulary, but treated as plain text here (same convention as
/// [PoruthamResult.code]) since nothing in this app currently branches on it.
class DashaMahadashaEntry {
  const DashaMahadashaEntry({
    required this.lord,
    required this.startDate,
    required this.endDate,
    required this.durationYears,
    required this.sequenceIndex,
  });

  final String lord;
  final DateTime? startDate;
  final DateTime? endDate;
  final double durationYears;
  final int sequenceIndex;

  factory DashaMahadashaEntry.fromJson(Map<String, dynamic> json) => DashaMahadashaEntry(
        lord: (json['lord'] ?? '').toString(),
        startDate: DateTime.tryParse((json['startDate'] ?? '').toString()),
        endDate: DateTime.tryParse((json['endDate'] ?? '').toString()),
        durationYears: (json['durationYears'] as num?)?.toDouble() ?? 0,
        sequenceIndex: (json['sequenceIndex'] as num?)?.toInt() ?? 0,
      );
}

/// Matches `DashaAntardashaEntry`.
class DashaAntardashaEntry {
  const DashaAntardashaEntry({
    required this.lord,
    required this.startDate,
    required this.endDate,
    required this.parentMahadashaLord,
    required this.durationYears,
    required this.sequenceIndex,
  });

  final String lord;
  final DateTime? startDate;
  final DateTime? endDate;
  final String parentMahadashaLord;
  final double durationYears;
  final int sequenceIndex;

  factory DashaAntardashaEntry.fromJson(Map<String, dynamic> json) => DashaAntardashaEntry(
        lord: (json['lord'] ?? '').toString(),
        startDate: DateTime.tryParse((json['startDate'] ?? '').toString()),
        endDate: DateTime.tryParse((json['endDate'] ?? '').toString()),
        parentMahadashaLord: (json['parentMahadashaLord'] ?? '').toString(),
        durationYears: (json['durationYears'] as num?)?.toDouble() ?? 0,
        sequenceIndex: (json['sequenceIndex'] as num?)?.toInt() ?? 0,
      );
}

/// Matches `DashaSandhiFinding`. `withinWindow` stays null exactly when
/// [status] is NOT_CALCULABLE (no approved Sandhi-window rule) — never
/// guessed.
class DashaSandhiFinding {
  const DashaSandhiFinding({
    required this.previousMahadashaLord,
    required this.nextMahadashaLord,
    required this.transitionDate,
    required this.withinWindow,
    required this.status,
    required this.reasonCode,
    required this.explanation,
  });

  final String previousMahadashaLord;
  final String nextMahadashaLord;
  final DateTime? transitionDate;
  final bool? withinWindow;
  final AstrologyModuleStatus status;
  final String reasonCode;
  final String explanation;

  factory DashaSandhiFinding.fromJson(Map<String, dynamic> json) => DashaSandhiFinding(
        previousMahadashaLord: (json['previousMahadashaLord'] ?? '').toString(),
        nextMahadashaLord: (json['nextMahadashaLord'] ?? '').toString(),
        transitionDate: DateTime.tryParse((json['transitionDate'] ?? '').toString()),
        withinWindow: json['withinWindow'] as bool?,
        status: AstrologyModuleStatus.fromWire((json['status'] ?? '').toString()),
        reasonCode: (json['reasonCode'] ?? '').toString(),
        explanation: (json['explanation'] ?? '').toString(),
      );
}

/// Matches `MarriageSignificatorDashaFinding`. `matchedMahadashaSignificators`/
/// `matchedAntardashaSignificators` list which of SEVENTH_LORD/VENUS/JUPITER
/// matched — empty (not null) once [status] is CALCULATED, even when nothing
/// matched.
class MarriageSignificatorDashaFinding {
  const MarriageSignificatorDashaFinding({
    required this.status,
    required this.reviewRequired,
    required this.reasonCode,
    required this.explanation,
    required this.seventhLord,
    required this.mahadashaLordIsSignificator,
    required this.antardashaLordIsSignificator,
    required this.matchedMahadashaSignificators,
    required this.matchedAntardashaSignificators,
  });

  final AstrologyModuleStatus status;
  final bool reviewRequired;
  final String reasonCode;
  final String explanation;
  final String? seventhLord;
  final bool? mahadashaLordIsSignificator;
  final bool? antardashaLordIsSignificator;
  final List<String> matchedMahadashaSignificators;
  final List<String> matchedAntardashaSignificators;

  factory MarriageSignificatorDashaFinding.fromJson(Map<String, dynamic> json) =>
      MarriageSignificatorDashaFinding(
        status: AstrologyModuleStatus.fromWire((json['status'] ?? '').toString()),
        reviewRequired: json['reviewRequired'] == true,
        reasonCode: (json['reasonCode'] ?? '').toString(),
        explanation: (json['explanation'] ?? '').toString(),
        seventhLord: json['seventhLord'] as String?,
        mahadashaLordIsSignificator: json['mahadashaLordIsSignificator'] as bool?,
        antardashaLordIsSignificator: json['antardashaLordIsSignificator'] as bool?,
        matchedMahadashaSignificators: _stringList(json['matchedMahadashaSignificators']),
        matchedAntardashaSignificators: _stringList(json['matchedAntardashaSignificators']),
      );
}

List<String> _stringList(dynamic value) =>
    (value is List ? value : const []).map((e) => e.toString()).toList();

/// Matches `PartnerDashaResult` — one partner's Vimshottari Mahadasha/
/// Antardasha timeline plus Sandhi/marriage-significator findings.
class PartnerDashaResult {
  const PartnerDashaResult({
    required this.status,
    required this.reviewRequired,
    required this.reasonCode,
    required this.explanation,
    required this.birthNakshatraId,
    required this.birthNakshatraName,
    required this.birthNakshatraLord,
    required this.startingMahadasha,
    required this.startingMahadashaBalanceYears,
    required this.mahadashas,
    required this.currentMahadasha,
    required this.currentAntardasha,
    required this.nextMahadasha,
    required this.nextAntardasha,
    required this.antardashas,
    required this.sandhiFindings,
    required this.marriageSignificatorDasha,
  });

  final AstrologyModuleStatus status;
  final bool reviewRequired;
  final String reasonCode;
  final String explanation;
  final int? birthNakshatraId;
  final String? birthNakshatraName;
  final String? birthNakshatraLord;
  final DashaMahadashaEntry? startingMahadasha;
  final double? startingMahadashaBalanceYears;
  final List<DashaMahadashaEntry> mahadashas;
  final DashaMahadashaEntry? currentMahadasha;
  final DashaAntardashaEntry? currentAntardasha;
  final DashaMahadashaEntry? nextMahadasha;
  final DashaAntardashaEntry? nextAntardasha;
  final List<DashaAntardashaEntry> antardashas;
  final List<DashaSandhiFinding> sandhiFindings;

  /// Null only when [status] itself is not CALCULATED.
  final MarriageSignificatorDashaFinding? marriageSignificatorDasha;

  factory PartnerDashaResult.fromJson(Map<String, dynamic> json) => PartnerDashaResult(
        status: AstrologyModuleStatus.fromWire((json['status'] ?? '').toString()),
        reviewRequired: json['reviewRequired'] == true,
        reasonCode: (json['reasonCode'] ?? '').toString(),
        explanation: (json['explanation'] ?? '').toString(),
        birthNakshatraId: (json['birthNakshatraId'] as num?)?.toInt(),
        birthNakshatraName: json['birthNakshatraName'] as String?,
        birthNakshatraLord: json['birthNakshatraLord'] as String?,
        startingMahadasha: json['startingMahadasha'] is Map
            ? DashaMahadashaEntry.fromJson(Map<String, dynamic>.from(json['startingMahadasha'] as Map))
            : null,
        startingMahadashaBalanceYears: (json['startingMahadashaBalanceYears'] as num?)?.toDouble(),
        mahadashas: (json['mahadashas'] is List ? json['mahadashas'] as List : const [])
            .whereType<Map>()
            .map((e) => DashaMahadashaEntry.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        currentMahadasha: json['currentMahadasha'] is Map
            ? DashaMahadashaEntry.fromJson(Map<String, dynamic>.from(json['currentMahadasha'] as Map))
            : null,
        currentAntardasha: json['currentAntardasha'] is Map
            ? DashaAntardashaEntry.fromJson(Map<String, dynamic>.from(json['currentAntardasha'] as Map))
            : null,
        nextMahadasha: json['nextMahadasha'] is Map
            ? DashaMahadashaEntry.fromJson(Map<String, dynamic>.from(json['nextMahadasha'] as Map))
            : null,
        nextAntardasha: json['nextAntardasha'] is Map
            ? DashaAntardashaEntry.fromJson(Map<String, dynamic>.from(json['nextAntardasha'] as Map))
            : null,
        antardashas: (json['antardashas'] is List ? json['antardashas'] as List : const [])
            .whereType<Map>()
            .map((e) => DashaAntardashaEntry.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        sandhiFindings: (json['sandhiFindings'] is List ? json['sandhiFindings'] as List : const [])
            .whereType<Map>()
            .map((e) => DashaSandhiFinding.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        marriageSignificatorDasha: json['marriageSignificatorDasha'] is Map
            ? MarriageSignificatorDashaFinding.fromJson(
                Map<String, dynamic>.from(json['marriageSignificatorDasha'] as Map))
            : null,
      );
}

/// Matches `DashaComparison` — the pair-level verdict.
class DashaComparison {
  const DashaComparison({required this.status, required this.reasonCode, required this.explanation});

  final DashaComparisonStatus status;
  final String reasonCode;
  final String explanation;

  factory DashaComparison.fromJson(Map<String, dynamic> json) => DashaComparison(
        status: DashaComparisonStatus.fromWire((json['status'] ?? '').toString()),
        reasonCode: (json['reasonCode'] ?? '').toString(),
        explanation: (json['explanation'] ?? '').toString(),
      );
}

/// Matches `CompatibilityReportDasha` — the report's `dasha` section.
/// `assessmentDate` is persisted verbatim by the backend (a saved report
/// never silently changes when read later) — Flutter must display it as-is,
/// never substitute "now."
class DashaCompatibility {
  const DashaCompatibility({
    required this.ruleVersion,
    required this.assessmentDate,
    required this.brideProfileId,
    required this.groomProfileId,
    required this.status,
    required this.reviewRequired,
    required this.reasonCode,
    required this.explanation,
    required this.bride,
    required this.groom,
    required this.comparison,
    required this.brideBoundaryRisk,
    required this.groomBoundaryRisk,
  });

  final String ruleVersion;
  final DateTime? assessmentDate;
  final String brideProfileId;
  final String groomProfileId;
  final DashaComparisonStatus status;
  final bool reviewRequired;
  final String reasonCode;
  final String explanation;
  final PartnerDashaResult bride;
  final PartnerDashaResult groom;
  final DashaComparison comparison;
  final BoundaryRisk? brideBoundaryRisk;
  final BoundaryRisk? groomBoundaryRisk;

  factory DashaCompatibility.fromJson(Map<String, dynamic> json) => DashaCompatibility(
        ruleVersion: (json['ruleVersion'] ?? '').toString(),
        assessmentDate: DateTime.tryParse((json['assessmentDate'] ?? '').toString()),
        brideProfileId: (json['brideProfileId'] ?? '').toString(),
        groomProfileId: (json['groomProfileId'] ?? '').toString(),
        status: DashaComparisonStatus.fromWire((json['status'] ?? '').toString()),
        reviewRequired: json['reviewRequired'] == true,
        reasonCode: (json['reasonCode'] ?? '').toString(),
        explanation: (json['explanation'] ?? '').toString(),
        bride: PartnerDashaResult.fromJson(
            json['bride'] is Map ? Map<String, dynamic>.from(json['bride'] as Map) : const {}),
        groom: PartnerDashaResult.fromJson(
            json['groom'] is Map ? Map<String, dynamic>.from(json['groom'] as Map) : const {}),
        comparison: DashaComparison.fromJson(
            json['comparison'] is Map ? Map<String, dynamic>.from(json['comparison'] as Map) : const {}),
        brideBoundaryRisk: json['brideBoundaryRisk'] is Map
            ? BoundaryRisk.fromJson(Map<String, dynamic>.from(json['brideBoundaryRisk'] as Map))
            : null,
        groomBoundaryRisk: json['groomBoundaryRisk'] is Map
            ? BoundaryRisk.fromJson(Map<String, dynamic>.from(json['groomBoundaryRisk'] as Map))
            : null,
      );
}

// ── Vivaha Kala Bala / marriage timing (STEP 55/56) ─────────────────────────

/// Matches `TransitPositionSummary` — a planet's position at the assessment
/// date, stripped to derived attributes only (never a raw sidereal
/// longitude).
class TransitPositionSummary {
  const TransitPositionSummary({
    required this.rashiId,
    required this.nakshatraId,
    required this.nakshatraPada,
    required this.isRetrograde,
  });

  final int rashiId;
  final int nakshatraId;
  final int nakshatraPada;
  final bool isRetrograde;

  factory TransitPositionSummary.fromJson(Map<String, dynamic> json) => TransitPositionSummary(
        rashiId: (json['rashiId'] as num?)?.toInt() ?? 0,
        nakshatraId: (json['nakshatraId'] as num?)?.toInt() ?? 0,
        nakshatraPada: (json['nakshatraPada'] as num?)?.toInt() ?? 0,
        isRetrograde: json['isRetrograde'] == true,
      );
}

TransitPositionSummary? _transitPositionOrNull(dynamic value) =>
    value is Map ? TransitPositionSummary.fromJson(Map<String, dynamic>.from(value)) : null;

/// Matches `PartnerVivahaTimingResult` — the couple-level rollup shown per
/// partner.
class PartnerVivahaTimingResult {
  const PartnerVivahaTimingResult({
    required this.status,
    required this.reviewRequired,
    required this.reasonCode,
    required this.explanation,
  });

  final AstrologyModuleStatus status;
  final bool reviewRequired;
  final String reasonCode;
  final String explanation;

  factory PartnerVivahaTimingResult.fromJson(Map<String, dynamic> json) => PartnerVivahaTimingResult(
        status: AstrologyModuleStatus.fromWire((json['status'] ?? '').toString()),
        reviewRequired: json['reviewRequired'] == true,
        reasonCode: (json['reasonCode'] ?? '').toString(),
        explanation: (json['explanation'] ?? '').toString(),
      );
}

/// Matches `PartnerBalaFinding`. `classification` ('SUPPORTIVE'/'NEUTRAL') is
/// kept as a raw nullable string — a small, module-local 2-value union not
/// worth a dedicated enum — null whenever [status] is not CALCULATED.
class PartnerBalaFinding {
  const PartnerBalaFinding({
    required this.status,
    required this.reviewRequired,
    required this.reasonCode,
    required this.explanation,
    required this.classification,
  });

  final AstrologyModuleStatus status;
  final bool reviewRequired;
  final String reasonCode;
  final String explanation;
  final String? classification;

  factory PartnerBalaFinding.fromJson(Map<String, dynamic> json) => PartnerBalaFinding(
        status: AstrologyModuleStatus.fromWire((json['status'] ?? '').toString()),
        reviewRequired: json['reviewRequired'] == true,
        reasonCode: (json['reasonCode'] ?? '').toString(),
        explanation: (json['explanation'] ?? '').toString(),
        classification: json['classification'] as String?,
      );
}

/// Matches `BalaFinding` — the shared shape for Guru Bala / Shukra Bala /
/// Chandra Bala. `status` is REVIEW_REQUIRED (not NOT_CALCULABLE) whenever
/// the assessment date is valid — the transit position itself is known; only
/// an approved interpretation rule is missing. NOT_CALCULABLE means no
/// transit position at all (invalid assessment date).
class BalaFinding {
  const BalaFinding({
    required this.status,
    required this.reviewRequired,
    required this.reasonCode,
    required this.explanation,
    required this.transitPosition,
    required this.bride,
    required this.groom,
  });

  final AstrologyModuleStatus status;
  final bool reviewRequired;
  final String reasonCode;
  final String explanation;
  final TransitPositionSummary? transitPosition;
  final PartnerBalaFinding bride;
  final PartnerBalaFinding groom;

  factory BalaFinding.fromJson(Map<String, dynamic> json) => BalaFinding(
        status: AstrologyModuleStatus.fromWire((json['status'] ?? '').toString()),
        reviewRequired: json['reviewRequired'] == true,
        reasonCode: (json['reasonCode'] ?? '').toString(),
        explanation: (json['explanation'] ?? '').toString(),
        transitPosition: _transitPositionOrNull(json['transitPosition']),
        bride: PartnerBalaFinding.fromJson(
            json['bride'] is Map ? Map<String, dynamic>.from(json['bride'] as Map) : const {}),
        groom: PartnerBalaFinding.fromJson(
            json['groom'] is Map ? Map<String, dynamic>.from(json['groom'] as Map) : const {}),
      );
}

/// Matches `PartnerTaraBalaFinding`. `taraPosition` (1-9) is an objective
/// classification, never itself labelled auspicious/inauspicious without an
/// approved rule — see [classification].
class PartnerTaraBalaFinding {
  const PartnerTaraBalaFinding({
    required this.status,
    required this.reviewRequired,
    required this.reasonCode,
    required this.explanation,
    required this.taraPosition,
    required this.classification,
  });

  final AstrologyModuleStatus status;
  final bool reviewRequired;
  final String reasonCode;
  final String explanation;
  final int? taraPosition;
  final String? classification;

  factory PartnerTaraBalaFinding.fromJson(Map<String, dynamic> json) => PartnerTaraBalaFinding(
        status: AstrologyModuleStatus.fromWire((json['status'] ?? '').toString()),
        reviewRequired: json['reviewRequired'] == true,
        reasonCode: (json['reasonCode'] ?? '').toString(),
        explanation: (json['explanation'] ?? '').toString(),
        taraPosition: (json['taraPosition'] as num?)?.toInt(),
        classification: json['classification'] as String?,
      );
}

/// Matches `TaraBalaFinding`. Unlike [BalaFinding], `taraPosition` is
/// genuinely per-partner (each has their own birth Nakshatra); only the
/// transiting Moon's position is shared.
class TaraBalaFinding {
  const TaraBalaFinding({
    required this.status,
    required this.reviewRequired,
    required this.reasonCode,
    required this.explanation,
    required this.transitMoonPosition,
    required this.bride,
    required this.groom,
  });

  final AstrologyModuleStatus status;
  final bool reviewRequired;
  final String reasonCode;
  final String explanation;
  final TransitPositionSummary? transitMoonPosition;
  final PartnerTaraBalaFinding bride;
  final PartnerTaraBalaFinding groom;

  factory TaraBalaFinding.fromJson(Map<String, dynamic> json) => TaraBalaFinding(
        status: AstrologyModuleStatus.fromWire((json['status'] ?? '').toString()),
        reviewRequired: json['reviewRequired'] == true,
        reasonCode: (json['reasonCode'] ?? '').toString(),
        explanation: (json['explanation'] ?? '').toString(),
        transitMoonPosition: _transitPositionOrNull(json['transitMoonPosition']),
        bride: PartnerTaraBalaFinding.fromJson(
            json['bride'] is Map ? Map<String, dynamic>.from(json['bride'] as Map) : const {}),
        groom: PartnerTaraBalaFinding.fromJson(
            json['groom'] is Map ? Map<String, dynamic>.from(json['groom'] as Map) : const {}),
      );
}

/// Matches `GocharFinding` — the transiting 9-graha picture, shared between
/// bride and groom (the same sky, the same day). `transitPositions` is a map
/// keyed by graha name (SUN/MOON/MARS/…) — kept as a raw map since the key
/// set mirrors [DashaMahadashaEntry.lord]'s free-text convention.
class GocharFinding {
  const GocharFinding({
    required this.status,
    required this.reviewRequired,
    required this.reasonCode,
    required this.explanation,
    required this.transitPositions,
  });

  final AstrologyModuleStatus status;
  final bool reviewRequired;
  final String reasonCode;
  final String explanation;
  final Map<String, TransitPositionSummary>? transitPositions;

  factory GocharFinding.fromJson(Map<String, dynamic> json) {
    final raw = json['transitPositions'];
    Map<String, TransitPositionSummary>? positions;
    if (raw is Map) {
      positions = {
        for (final entry in raw.entries)
          if (entry.value is Map) entry.key.toString(): TransitPositionSummary.fromJson(Map<String, dynamic>.from(entry.value as Map)),
      };
    }
    return GocharFinding(
      status: AstrologyModuleStatus.fromWire((json['status'] ?? '').toString()),
      reviewRequired: json['reviewRequired'] == true,
      reasonCode: (json['reasonCode'] ?? '').toString(),
      explanation: (json['explanation'] ?? '').toString(),
      transitPositions: positions,
    );
  }
}

/// Matches `PartnerDashaTimingFinding`. `timingClassification`
/// ('SUPPORTIVE'/'NEUTRAL'/'CAUTION') is kept as a raw nullable string — null
/// whenever no approved DashaTimingConfig rule matches, even when
/// `currentMahadashaLord`/`currentAntardashaLord` are themselves known.
class PartnerDashaTimingFinding {
  const PartnerDashaTimingFinding({
    required this.status,
    required this.reviewRequired,
    required this.reasonCode,
    required this.explanation,
    required this.currentMahadashaLord,
    required this.currentAntardashaLord,
    required this.timingClassification,
  });

  final AstrologyModuleStatus status;
  final bool reviewRequired;
  final String reasonCode;
  final String explanation;
  final String? currentMahadashaLord;
  final String? currentAntardashaLord;
  final String? timingClassification;

  factory PartnerDashaTimingFinding.fromJson(Map<String, dynamic> json) => PartnerDashaTimingFinding(
        status: AstrologyModuleStatus.fromWire((json['status'] ?? '').toString()),
        reviewRequired: json['reviewRequired'] == true,
        reasonCode: (json['reasonCode'] ?? '').toString(),
        explanation: (json['explanation'] ?? '').toString(),
        currentMahadashaLord: json['currentMahadashaLord'] as String?,
        currentAntardashaLord: json['currentAntardashaLord'] as String?,
        timingClassification: json['timingClassification'] as String?,
      );
}

/// Matches `DashaTimingFinding`.
class DashaTimingFinding {
  const DashaTimingFinding({
    required this.status,
    required this.reviewRequired,
    required this.reasonCode,
    required this.explanation,
    required this.bride,
    required this.groom,
  });

  final AstrologyModuleStatus status;
  final bool reviewRequired;
  final String reasonCode;
  final String explanation;
  final PartnerDashaTimingFinding bride;
  final PartnerDashaTimingFinding groom;

  factory DashaTimingFinding.fromJson(Map<String, dynamic> json) => DashaTimingFinding(
        status: AstrologyModuleStatus.fromWire((json['status'] ?? '').toString()),
        reviewRequired: json['reviewRequired'] == true,
        reasonCode: (json['reasonCode'] ?? '').toString(),
        explanation: (json['explanation'] ?? '').toString(),
        bride: PartnerDashaTimingFinding.fromJson(
            json['bride'] is Map ? Map<String, dynamic>.from(json['bride'] as Map) : const {}),
        groom: PartnerDashaTimingFinding.fromJson(
            json['groom'] is Map ? Map<String, dynamic>.from(json['groom'] as Map) : const {}),
      );
}

/// Matches `CompatibilityReportVivahaKalaBala` — the report's `vivahaKalaBala`
/// section. `status` is always NOT_CALCULABLE today except for a
/// boundary-risk escalation to REVIEW_REQUIRED (no approved formula combines
/// Guru/Shukra/Chandra Bala + Tara Bala + Gochar + Dasha timing into one
/// verdict) — Flutter must never infer SUPPORTIVE/NEUTRAL/CAUTION itself.
/// `assessmentDate` is persisted verbatim, same as [DashaCompatibility].
class VivahaKalaBala {
  const VivahaKalaBala({
    required this.ruleVersion,
    required this.assessmentDate,
    required this.brideProfileId,
    required this.groomProfileId,
    required this.status,
    required this.reviewRequired,
    required this.reasonCode,
    required this.explanation,
    required this.bride,
    required this.groom,
    required this.guruBala,
    required this.shukraBala,
    required this.chandraBala,
    required this.taraBala,
    required this.gochar,
    required this.dashaTiming,
    required this.brideBoundaryRisk,
    required this.groomBoundaryRisk,
  });

  final String ruleVersion;
  final DateTime? assessmentDate;
  final String brideProfileId;
  final String groomProfileId;
  final AstrologyFavorabilityStatus status;
  final bool reviewRequired;
  final String reasonCode;
  final String explanation;
  final PartnerVivahaTimingResult bride;
  final PartnerVivahaTimingResult groom;
  final BalaFinding guruBala;
  final BalaFinding shukraBala;
  final BalaFinding chandraBala;
  final TaraBalaFinding taraBala;
  final GocharFinding gochar;
  final DashaTimingFinding dashaTiming;
  final BoundaryRisk? brideBoundaryRisk;
  final BoundaryRisk? groomBoundaryRisk;

  factory VivahaKalaBala.fromJson(Map<String, dynamic> json) => VivahaKalaBala(
        ruleVersion: (json['ruleVersion'] ?? '').toString(),
        assessmentDate: DateTime.tryParse((json['assessmentDate'] ?? '').toString()),
        brideProfileId: (json['brideProfileId'] ?? '').toString(),
        groomProfileId: (json['groomProfileId'] ?? '').toString(),
        status: AstrologyFavorabilityStatus.fromWire((json['status'] ?? '').toString()),
        reviewRequired: json['reviewRequired'] == true,
        reasonCode: (json['reasonCode'] ?? '').toString(),
        explanation: (json['explanation'] ?? '').toString(),
        bride: PartnerVivahaTimingResult.fromJson(
            json['bride'] is Map ? Map<String, dynamic>.from(json['bride'] as Map) : const {}),
        groom: PartnerVivahaTimingResult.fromJson(
            json['groom'] is Map ? Map<String, dynamic>.from(json['groom'] as Map) : const {}),
        guruBala: BalaFinding.fromJson(
            json['guruBala'] is Map ? Map<String, dynamic>.from(json['guruBala'] as Map) : const {}),
        shukraBala: BalaFinding.fromJson(
            json['shukraBala'] is Map ? Map<String, dynamic>.from(json['shukraBala'] as Map) : const {}),
        chandraBala: BalaFinding.fromJson(
            json['chandraBala'] is Map ? Map<String, dynamic>.from(json['chandraBala'] as Map) : const {}),
        taraBala: TaraBalaFinding.fromJson(
            json['taraBala'] is Map ? Map<String, dynamic>.from(json['taraBala'] as Map) : const {}),
        gochar: GocharFinding.fromJson(
            json['gochar'] is Map ? Map<String, dynamic>.from(json['gochar'] as Map) : const {}),
        dashaTiming: DashaTimingFinding.fromJson(
            json['dashaTiming'] is Map ? Map<String, dynamic>.from(json['dashaTiming'] as Map) : const {}),
        brideBoundaryRisk: json['brideBoundaryRisk'] is Map
            ? BoundaryRisk.fromJson(Map<String, dynamic>.from(json['brideBoundaryRisk'] as Map))
            : null,
        groomBoundaryRisk: json['groomBoundaryRisk'] is Map
            ? BoundaryRisk.fromJson(Map<String, dynamic>.from(json['groomBoundaryRisk'] as Map))
            : null,
      );
}
