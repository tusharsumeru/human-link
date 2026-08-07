/// STEP 25A/25B — Check Compatibility prerequisites: a read-only readiness
/// check for whether compatibility CAN be calculated between the signed-in
/// member and a candidate, and why not where it can't. Matches
/// `CompatibilityPrerequisites` in the backend's prerequisites.types.ts.
///
/// Nothing here is a compatibility score — that stays the report screen's
/// job. This only decides what to show/enable on the preparation screen.
library;

/// Matches `ReadinessStatus`.
enum ReadinessStatus {
  ready,
  actionRequired,
  unavailable,
  unknown;

  static ReadinessStatus fromWire(String value) => switch (value) {
        'READY' => ReadinessStatus.ready,
        'ACTION_REQUIRED' => ReadinessStatus.actionRequired,
        'UNAVAILABLE' => ReadinessStatus.unavailable,
        _ => ReadinessStatus.unknown,
      };
}

/// Matches `OverallReadinessStatus`. See prerequisites.types.ts for the exact
/// rollup rule (READY = every module ready; READY_WITH_LIMITATIONS = at
/// least one is; ACTION_REQUIRED = none ready but the caller can fix one;
/// UNAVAILABLE = nothing ready and nothing fixable by the caller).
enum OverallReadinessStatus {
  ready,
  readyWithLimitations,
  actionRequired,
  unavailable,
  unknown;

  static OverallReadinessStatus fromWire(String value) => switch (value) {
        'READY' => OverallReadinessStatus.ready,
        'READY_WITH_LIMITATIONS' => OverallReadinessStatus.readyWithLimitations,
        'ACTION_REQUIRED' => OverallReadinessStatus.actionRequired,
        'UNAVAILABLE' => OverallReadinessStatus.unavailable,
        _ => OverallReadinessStatus.unknown,
      };

  /// Whether at least one module is usable — the same condition the backend
  /// uses to decide READY vs READY_WITH_LIMITATIONS, re-exposed here so the
  /// screen's Continue button enables/disables off the backend's own rollup
  /// rather than re-deriving it from the individual modules.
  bool get hasAnyReadyModule =>
      this == OverallReadinessStatus.ready || this == OverallReadinessStatus.readyWithLimitations;
}

/// Matches `PrerequisiteReason`. `YOUR_*` values are fixable by the signed-in
/// member (missing their own data/consent) — the screen offers an action for
/// those. `MATCH_*` values are on the candidate's side and are deliberately
/// never explained further in the UI, so nothing about the candidate's
/// private data or consent decisions leaks out.
enum PrerequisiteReason {
  yourBirthDetailsMissing,
  yourConsentRequired,
  matchBirthDetailsUnavailable,
  matchConsentUnavailable,
  insufficientProfileData,
  yourFamilyTreeIncomplete,
  matchFamilyTreeUnavailable,
  personalityQuestionnaireNotAvailable,
  yourVerificationIncomplete,
  matchVerificationUnavailable,
  unknown;

  static PrerequisiteReason fromWire(String? value) => switch (value) {
        'YOUR_BIRTH_DETAILS_MISSING' => PrerequisiteReason.yourBirthDetailsMissing,
        'YOUR_CONSENT_REQUIRED' => PrerequisiteReason.yourConsentRequired,
        'MATCH_BIRTH_DETAILS_UNAVAILABLE' => PrerequisiteReason.matchBirthDetailsUnavailable,
        'MATCH_CONSENT_UNAVAILABLE' => PrerequisiteReason.matchConsentUnavailable,
        'INSUFFICIENT_PROFILE_DATA' => PrerequisiteReason.insufficientProfileData,
        'YOUR_FAMILY_TREE_INCOMPLETE' => PrerequisiteReason.yourFamilyTreeIncomplete,
        'MATCH_FAMILY_TREE_UNAVAILABLE' => PrerequisiteReason.matchFamilyTreeUnavailable,
        'PERSONALITY_QUESTIONNAIRE_NOT_AVAILABLE' =>
          PrerequisiteReason.personalityQuestionnaireNotAvailable,
        'YOUR_VERIFICATION_INCOMPLETE' => PrerequisiteReason.yourVerificationIncomplete,
        'MATCH_VERIFICATION_UNAVAILABLE' => PrerequisiteReason.matchVerificationUnavailable,
        _ => PrerequisiteReason.unknown,
      };

  /// True for a `YOUR_*` reason — something the signed-in member can act on
  /// themselves. False for everything else (candidate-side gaps, or no
  /// reason at all), which the screen only ever explains generically.
  bool get isActionableByViewer => switch (this) {
        PrerequisiteReason.yourBirthDetailsMissing ||
        PrerequisiteReason.yourConsentRequired ||
        PrerequisiteReason.yourFamilyTreeIncomplete ||
        PrerequisiteReason.yourVerificationIncomplete =>
          true,
        _ => false,
      };
}

class ModuleReadiness {
  const ModuleReadiness({required this.status, required this.reason});

  final ReadinessStatus status;
  final PrerequisiteReason reason;

  bool get isReady => status == ReadinessStatus.ready;
  bool get isActionRequired => status == ReadinessStatus.actionRequired;

  factory ModuleReadiness.fromJson(Map<String, dynamic> json) => ModuleReadiness(
        status: ReadinessStatus.fromWire((json['status'] ?? '').toString()),
        reason: PrerequisiteReason.fromWire(json['reason'] as String?),
      );
}

/// Adds [coverage] — matches `ModuleReadinessWithCoverage`. Purely a display
/// figure ("how much structured data exists on both sides"), never a
/// compatibility score.
class ModuleReadinessWithCoverage extends ModuleReadiness {
  const ModuleReadinessWithCoverage({
    required super.status,
    required super.reason,
    required this.coverage,
  });

  final int coverage;

  factory ModuleReadinessWithCoverage.fromJson(Map<String, dynamic> json) =>
      ModuleReadinessWithCoverage(
        status: ReadinessStatus.fromWire((json['status'] ?? '').toString()),
        reason: PrerequisiteReason.fromWire(json['reason'] as String?),
        coverage: (json['coverage'] as num?)?.toInt() ?? 0,
      );
}

/// Matches `CompatibilityPrerequisites` from
/// `GET /api/v1/compatibility/prerequisites/:candidateProfileId`.
class CompatibilityPrerequisites {
  const CompatibilityPrerequisites({
    required this.candidateProfileId,
    required this.overallStatus,
    required this.jataka,
    required this.profileCompatibility,
    required this.familyCompatibility,
    required this.personalityCompatibility,
    required this.familyRelationship,
    required this.verification,
  });

  final String candidateProfileId;
  final OverallReadinessStatus overallStatus;
  final ModuleReadiness jataka;
  final ModuleReadinessWithCoverage profileCompatibility;
  final ModuleReadinessWithCoverage familyCompatibility;
  final ModuleReadinessWithCoverage personalityCompatibility;
  final ModuleReadiness familyRelationship;
  // Deliberately excluded from overallStatus by the backend (verification is
  // a separate concern from compatibility) — read for display only, never
  // used to gate the Continue button.
  final ModuleReadiness verification;

  factory CompatibilityPrerequisites.fromJson(Map<String, dynamic> json) =>
      CompatibilityPrerequisites(
        candidateProfileId: (json['candidateProfileId'] ?? '').toString(),
        overallStatus:
            OverallReadinessStatus.fromWire((json['overallStatus'] ?? '').toString()),
        jataka: ModuleReadiness.fromJson(
            Map<String, dynamic>.from(json['jataka'] as Map? ?? const {})),
        profileCompatibility: ModuleReadinessWithCoverage.fromJson(
            Map<String, dynamic>.from(json['profileCompatibility'] as Map? ?? const {})),
        familyCompatibility: ModuleReadinessWithCoverage.fromJson(
            Map<String, dynamic>.from(json['familyCompatibility'] as Map? ?? const {})),
        personalityCompatibility: ModuleReadinessWithCoverage.fromJson(
            Map<String, dynamic>.from(json['personalityCompatibility'] as Map? ?? const {})),
        familyRelationship: ModuleReadiness.fromJson(
            Map<String, dynamic>.from(json['familyRelationship'] as Map? ?? const {})),
        verification: ModuleReadiness.fromJson(
            Map<String, dynamic>.from(json['verification'] as Map? ?? const {})),
      );
}
