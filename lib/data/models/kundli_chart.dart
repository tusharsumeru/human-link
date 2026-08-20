/// STEP 80 — models for `GET /api/v1/compatibility/reports/:reportId/kundli-chart`
/// (the Kundli / Janma Kundali birth-chart section of the detailed
/// compatibility report). Matches the backend's `CompatibilityReportKundliChart`
/// / `PartnerKundliChart` / `KundliPlanetPosition` / `KundliNavamshaPosition`
/// types exactly. A purely presentational D1 (natal) + D9 (Navamsha) snapshot
/// — NOT an eighth traditional-astrology system: it carries no status/
/// verdict/score of its own, and is never combined with any of the seven
/// systems above or with Profile/Overall Compatibility. Pure display
/// transform over an already-computed, already-persisted report — nothing
/// here recomputes a Graha position, Rashi, Nakshatra, or Lagna.
library;

/// The fixed Su→Ke display order — matches the backend's `NATAL_GRAHA_ORDER`.
/// Never alphabetical; never re-derived from the response itself, since a
/// response could (in principle) arrive in any order.
const List<String> kGrahaDisplayOrder = [
  'SUN',
  'MOON',
  'MARS',
  'MERCURY',
  'JUPITER',
  'VENUS',
  'SATURN',
  'RAHU',
  'KETU',
];

/// Standard 2-letter Graha abbreviations — presentation-only labels, not
/// found anywhere else in this app yet (no calculation of any kind). Falls
/// back to the first two letters of the raw code for anything unrecognized,
/// so an unexpected graha code never renders blank.
const Map<String, String> kGrahaShortLabels = {
  'SUN': 'Su',
  'MOON': 'Mo',
  'MARS': 'Ma',
  'MERCURY': 'Me',
  'JUPITER': 'Ju',
  'VENUS': 'Ve',
  'SATURN': 'Sa',
  'RAHU': 'Ra',
  'KETU': 'Ke',
};

String grahaShortLabel(String graha) =>
    kGrahaShortLabels[graha] ?? (graha.isEmpty ? '?' : graha.substring(0, graha.length >= 2 ? 2 : 1));

/// Full Graha display names — presentation-only, same scope as
/// [kGrahaShortLabels]. Shared by both the Kundli chart section widget and
/// the PDF export's tabular planetary-position rows, so the two never drift.
const Map<String, String> kGrahaFullNames = {
  'SUN': 'Sun',
  'MOON': 'Moon',
  'MARS': 'Mars',
  'MERCURY': 'Mercury',
  'JUPITER': 'Jupiter',
  'VENUS': 'Venus',
  'SATURN': 'Saturn',
  'RAHU': 'Rahu',
  'KETU': 'Ketu',
};

String grahaFullName(String graha) => kGrahaFullNames[graha] ?? graha;

/// Sorts by [kGrahaDisplayOrder]; anything with an unrecognized graha code is
/// appended at the end, in its original relative order, rather than dropped.
List<KundliPlanetPosition> orderedKundliPlanets(List<KundliPlanetPosition> planets) {
  final sorted = [...planets];
  sorted.sort((a, b) {
    final ia = kGrahaDisplayOrder.indexOf(a.graha);
    final ib = kGrahaDisplayOrder.indexOf(b.graha);
    return (ia == -1 ? kGrahaDisplayOrder.length : ia)
        .compareTo(ib == -1 ? kGrahaDisplayOrder.length : ib);
  });
  return sorted;
}

/// Matches `KundliPlanetPosition` — one Graha's D1 (natal) placement.
/// Deliberately no `siderealLongitude`/degree field — the backend never
/// sends one (see the backend's own "never expose raw sidereal longitude"
/// policy), so there is nothing here to omit-if-null; degree is simply not
/// part of this contract.
class KundliPlanetPosition {
  const KundliPlanetPosition({
    required this.graha,
    required this.rashiId,
    required this.rashiName,
    required this.nakshatraId,
    required this.nakshatraName,
    required this.nakshatraPada,
    required this.isRetrograde,
  });

  final String graha;
  final int rashiId;
  final String rashiName;
  final int nakshatraId;
  final String nakshatraName;
  final int nakshatraPada;
  final bool isRetrograde;

  factory KundliPlanetPosition.fromJson(Map<String, dynamic> json) => KundliPlanetPosition(
        graha: (json['graha'] ?? '').toString(),
        rashiId: (json['rashiId'] as num?)?.toInt() ?? 0,
        rashiName: (json['rashiName'] ?? '').toString(),
        nakshatraId: (json['nakshatraId'] as num?)?.toInt() ?? 0,
        nakshatraName: (json['nakshatraName'] ?? '').toString(),
        nakshatraPada: (json['nakshatraPada'] as num?)?.toInt() ?? 0,
        isRetrograde: json['isRetrograde'] == true,
      );
}

/// Matches `KundliNavamshaPosition` — one point's (a Graha, or the Lagna
/// itself, when [point] is `"LAGNA"`) D9 (Navamsha) placement.
class KundliNavamshaPosition {
  const KundliNavamshaPosition({
    required this.point,
    required this.rashiId,
    required this.rashiName,
  });

  final String point;
  final int rashiId;
  final String rashiName;

  bool get isLagna => point == 'LAGNA';

  factory KundliNavamshaPosition.fromJson(Map<String, dynamic> json) => KundliNavamshaPosition(
        point: (json['point'] ?? '').toString(),
        rashiId: (json['rashiId'] as num?)?.toInt() ?? 0,
        rashiName: (json['rashiName'] ?? '').toString(),
      );
}

/// Matches `PartnerKundliChart` — one side's (bride's or groom's) full D1 +
/// D9 chart: the Lagna plus all 9 Grahas' natal placements, and the Lagna +
/// all 9 Grahas' Navamsha placements.
class PartnerKundliChart {
  const PartnerKundliChart({
    required this.lagnaId,
    required this.lagnaRashiName,
    required this.planets,
    required this.navamsha,
  });

  final int lagnaId;
  final String lagnaRashiName;
  final List<KundliPlanetPosition> planets;

  /// The Navamsha (D9) Lagna + all 9 Grahas' D9 placements — empty only for
  /// a report saved before this data was captured (never fabricated).
  final List<KundliNavamshaPosition> navamsha;

  /// True when this side actually has Navamsha (D9) data — the UI must show
  /// "Navamsha chart is not available for this report." rather than an
  /// empty grid when this is false, never a silently blank D9 chart.
  bool get hasNavamsha => navamsha.isNotEmpty;

  KundliNavamshaPosition? get navamshaLagna {
    for (final n in navamsha) {
      if (n.isLagna) return n;
    }
    return null;
  }

  factory PartnerKundliChart.fromJson(Map<String, dynamic> json) => PartnerKundliChart(
        lagnaId: (json['lagnaId'] as num?)?.toInt() ?? 0,
        lagnaRashiName: (json['lagnaRashiName'] ?? '').toString(),
        planets: (json['planets'] is List ? json['planets'] as List : const [])
            .whereType<Map>()
            .map((e) => KundliPlanetPosition.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        navamsha: (json['navamsha'] is List ? json['navamsha'] as List : const [])
            .whereType<Map>()
            .map((e) => KundliNavamshaPosition.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}

/// Matches the exact `GET /reports/:reportId/kundli-chart` response —
/// [bride]/[groom] are null together only, for a report saved before STEP 80
/// (or one whose JATAKA module never ran at all — same null-propagation
/// convention every other module on this report already follows).
class KundliChart {
  const KundliChart({
    required this.reportId,
    required this.brideProfileId,
    required this.groomProfileId,
    required this.bride,
    required this.groom,
  });

  final String reportId;
  final String? brideProfileId;
  final String? groomProfileId;
  final PartnerKundliChart? bride;
  final PartnerKundliChart? groom;

  factory KundliChart.fromJson(Map<String, dynamic> json) => KundliChart(
        reportId: (json['reportId'] ?? '').toString(),
        brideProfileId: json['brideProfileId'] as String?,
        groomProfileId: json['groomProfileId'] as String?,
        bride: json['bride'] is Map ? PartnerKundliChart.fromJson(Map<String, dynamic>.from(json['bride'] as Map)) : null,
        groom: json['groom'] is Map ? PartnerKundliChart.fromJson(Map<String, dynamic>.from(json['groom'] as Map)) : null,
      );
}
