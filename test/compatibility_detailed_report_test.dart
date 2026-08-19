import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:daivajna_census/data/api_client.dart';
import 'package:daivajna_census/data/models/compatibility_models.dart';
import 'package:daivajna_census/data/repository.dart';
import 'package:daivajna_census/screens/compatibility_report_screen.dart';
import 'package:daivajna_census/services/auth_service.dart';
import 'package:daivajna_census/widgets/compatibility_report_view.dart';
import 'package:daivajna_census/widgets/south_indian_kundli_chart.dart';

/// STEP 74–76 — widget tests for the detailed Astrology Compatibility
/// sections (Karnataka 10 Porutham, Ashtakoota, Advanced Jataka, Kuja Dosha,
/// Dasha Compatibility, Vivaha Kala Bala, Daivagna Parampara), rendered by
/// [CompatibilityReportView] inside [CompatibilityReportScreen]. Every
/// fixture below mirrors the backend's `CompatibilityReportView` shape
/// (compatibility_report_full_test.dart is the STEP 72 model-parsing
/// counterpart of this fixture) — nothing here recalculates a score.
Map<String, dynamic> _poruthamJson(String code, String status, {bool critical = false}) => {
      'code': code,
      'status': status,
      'score': status == 'MATCHED' ? 1.0 : (status == 'PARTIAL' ? 0.5 : 0.0),
      'ruleId': '${code}_RULE',
      'details': <String, dynamic>{},
      'severity': critical && status == 'NOT_MATCHED' ? 'CRITICAL' : null,
      'critical': critical,
      'explanation': '$code explanation text.',
      'reasonCode': '',
      'reviewRequired': status == 'REVIEW_REQUIRED',
    };

List<Map<String, dynamic>> _tenPoruthams() => [
      _poruthamJson('DINA', 'MATCHED'),
      _poruthamJson('GANA', 'MATCHED'),
      _poruthamJson('MAHENDRA', 'MATCHED'),
      _poruthamJson('STREE_DEERGHA', 'MATCHED'),
      _poruthamJson('YONI', 'PARTIAL'),
      _poruthamJson('RASHI', 'MATCHED'),
      _poruthamJson('RASHI_ADHIPATHI', 'NOT_MATCHED'),
      _poruthamJson('VASHYA', 'MATCHED'),
      _poruthamJson('RAJJU', 'MATCHED', critical: true),
      _poruthamJson('VEDHA', 'NOT_MATCHED', critical: true),
    ];

Map<String, dynamic> _kootaJson(String code, String status, int? earned, int maximum) => {
      'code': code,
      'status': status,
      'earned': earned,
      'maximum': maximum,
      'ruleId': '${code}_RULE',
      'inputs': <String, dynamic>{},
      'explanation': '$code explanation text.',
      'reasonCode': '',
      'reviewRequired': status == 'REVIEW_REQUIRED',
    };

List<Map<String, dynamic>> _eightKootas() => [
      _kootaJson('VARNA', 'MATCHED', 1, 1),
      _kootaJson('VASHYA', 'MATCHED', 2, 2),
      _kootaJson('TARA', 'MATCHED', 3, 3),
      _kootaJson('YONI', 'MATCHED', 4, 4),
      _kootaJson('GRAHA_MAITRI', 'MATCHED', 5, 5),
      _kootaJson('GANA', 'MATCHED', 6, 6),
      _kootaJson('BHAKOOT', 'MATCHED', 7, 7),
      _kootaJson('NADI', 'NOT_MATCHED', 0, 8),
    ];

Map<String, dynamic> _jatakaJson({List<Map<String, dynamic>>? poruthams, int? normalizedPercentage = 75}) => {
      'ruleVersion': 'KARNATAKA_SOUTH_INDIAN_V1',
      'brideProfileId': 'profile-a',
      'groomProfileId': 'profile-b',
      'matched': 7,
      'partial': 1,
      'notMatched': 2,
      'reviewRequired': 0,
      'notCalculable': 0,
      'normalizedPercentage': normalizedPercentage,
      'verdict': 'GOOD',
      'verdictLabel': 'Good match',
      'criticalAlerts': <dynamic>[],
      'poruthams': poruthams ?? _tenPoruthams(),
      'nakshatraBoundaryRiskOverride': false,
    };

Map<String, dynamic> _ashtakootaJson({List<Map<String, dynamic>>? kootas, int? earned = 28, bool requiresReview = false}) => {
      'ruleVersion': 'ASHTAKOOTA_V1',
      'brideProfileId': 'profile-a',
      'groomProfileId': 'profile-b',
      'earned': earned,
      'maximum': 36,
      'isComplete': earned != null,
      'requiresReview': requiresReview,
      'kootas': kootas ?? _eightKootas(),
      'nakshatraBoundaryRiskOverride': false,
    };

Map<String, dynamic> _advancedJatakaJson({String status = 'SUPPORTIVE'}) => {
      'ruleVersion': 'ADVANCED_JATAKA_V1',
      'brideProfileId': 'profile-a',
      'groomProfileId': 'profile-b',
      'status': status,
      'reviewRequired': false,
      'reasonCode': 'FINDINGS_COMPUTED',
      'explanation': 'Advanced Jataka explanation.',
      'bride': {
        'natal': {
          'lagna': {
            'code': 'LAGNA',
            'status': 'CALCULATED',
            'reasonCode': 'LAGNA_CALCULATED',
            'explanation': 'Lagna is Leo.',
            'reviewRequired': false,
            'data': {'rashiName': 'Leo'},
          },
        },
        'navamsha': <String, dynamic>{},
      },
      'groom': {'natal': <String, dynamic>{}, 'navamsha': <String, dynamic>{}},
    };

Map<String, dynamic> _kujaDoshaJson() => {
      'ruleVersion': 'KUJA_DOSHA_V1',
      'brideProfileId': 'profile-a',
      'groomProfileId': 'profile-b',
      'status': 'BALANCED_WITH_PARTNER',
      'reviewRequired': false,
      'reasonCode': 'BALANCED',
      'explanation': 'Both partners have an active dosha; balanced.',
      'bride': {
        'status': 'MODERATE',
        'reviewRequired': false,
        'reasonCode': 'MARS_IN_AFFECTED_HOUSE',
        'explanation': 'Mars is in an affected house from Lagna.',
        'fromLagna': {
          'reference': 'LAGNA',
          'status': 'CALCULATED',
          'marsHouse': 7,
          'affected': true,
          'reasonCode': 'HOUSE_7_AFFECTED',
          'explanation': 'House 7 is a configured affected house.',
        },
        'relevantMarsPlacements': {'rashiId': 1, 'rashiName': 'Aries'},
        'cancellationFindings': [
          {'ruleId': 'MARS_OWN_HOUSE_CANCELLATION', 'explanation': 'Mars is in its own house, cancelling the dosha.'},
        ],
      },
      'groom': {
        'status': 'NOT_PRESENT',
        'reviewRequired': false,
        'reasonCode': 'NO_DOSHA',
        'explanation': 'No active dosha found.',
        'cancellationFindings': <dynamic>[],
      },
      'comparison': {
        'status': 'BALANCED_WITH_PARTNER',
        'reasonCode': 'BOTH_ACTIVE',
        'explanation': 'Both bride and groom have an active dosha.',
      },
    };

Map<String, dynamic> _dashaJson({String comparisonStatus = 'NEUTRAL'}) => {
      'ruleVersion': 'DASHA_COMPATIBILITY_V1',
      'assessmentDate': '2026-01-01T00:00:00.000Z',
      'brideProfileId': 'profile-a',
      'groomProfileId': 'profile-b',
      'status': comparisonStatus,
      'reviewRequired': comparisonStatus == 'REVIEW_REQUIRED',
      'reasonCode': 'PAIRING',
      'explanation': 'Dasha pairing explanation.',
      'bride': {
        'status': 'CALCULATED',
        'reviewRequired': false,
        'reasonCode': 'DASHA_CALCULATED',
        'explanation': 'Timeline calculated.',
        'birthNakshatraId': 3,
        'birthNakshatraName': 'Krittika',
        'birthNakshatraLord': 'SUN',
        'mahadashas': [
          {'lord': 'VENUS', 'startDate': '2020-01-01T00:00:00.000Z', 'endDate': '2040-01-01T00:00:00.000Z', 'durationYears': 20, 'sequenceIndex': 0},
          {'lord': 'SUN', 'startDate': '2040-01-01T00:00:00.000Z', 'endDate': '2046-01-01T00:00:00.000Z', 'durationYears': 6, 'sequenceIndex': 1},
        ],
        'currentMahadasha': {'lord': 'VENUS', 'startDate': '2020-01-01T00:00:00.000Z', 'endDate': '2040-01-01T00:00:00.000Z', 'durationYears': 20, 'sequenceIndex': 0},
        'currentAntardasha': {'lord': 'MOON', 'startDate': '2025-01-01T00:00:00.000Z', 'endDate': '2026-06-01T00:00:00.000Z', 'parentMahadashaLord': 'VENUS', 'durationYears': 1.4, 'sequenceIndex': 0},
        'antardashas': <dynamic>[],
        'sandhiFindings': <dynamic>[],
        'marriageSignificatorDasha': null,
      },
      'groom': {
        'status': 'CALCULATED',
        'reviewRequired': false,
        'reasonCode': 'DASHA_CALCULATED',
        'explanation': 'Timeline calculated.',
        'birthNakshatraId': 8,
        'birthNakshatraName': 'Pushya',
        'birthNakshatraLord': 'SATURN',
        'mahadashas': <dynamic>[],
        'antardashas': <dynamic>[],
        'sandhiFindings': <dynamic>[],
        'marriageSignificatorDasha': null,
      },
      'comparison': {'status': comparisonStatus, 'reasonCode': 'PAIRING', 'explanation': 'Dasha pairing explanation.'},
    };

Map<String, dynamic> _vivahaKalaBalaJson() => {
      'ruleVersion': 'VIVAHA_KALA_BALA_V1',
      'assessmentDate': '2026-01-01T00:00:00.000Z',
      'brideProfileId': 'profile-a',
      'groomProfileId': 'profile-b',
      'status': 'NOT_CALCULABLE',
      'reviewRequired': false,
      'reasonCode': 'NO_APPROVED_COMBINATION_FORMULA',
      'explanation': 'No approved formula combines these components.',
      'bride': {'status': 'CALCULATED', 'reviewRequired': false, 'reasonCode': 'OK', 'explanation': 'OK'},
      'groom': {'status': 'CALCULATED', 'reviewRequired': false, 'reasonCode': 'OK', 'explanation': 'OK'},
      'guruBala': {
        'status': 'REVIEW_REQUIRED',
        'reviewRequired': true,
        'reasonCode': 'NO_APPROVED_RULE',
        'explanation': 'Transit position known, no approved rule.',
        'transitPosition': {'rashiId': 9, 'nakshatraId': 24, 'nakshatraPada': 2, 'isRetrograde': false},
        'bride': {'status': 'REVIEW_REQUIRED', 'reviewRequired': true, 'reasonCode': 'NO_RULE', 'explanation': 'No rule.'},
        'groom': {'status': 'REVIEW_REQUIRED', 'reviewRequired': true, 'reasonCode': 'NO_RULE', 'explanation': 'No rule.'},
      },
      'shukraBala': {
        'status': 'REVIEW_REQUIRED',
        'reviewRequired': true,
        'reasonCode': 'NO_APPROVED_RULE',
        'explanation': 'Transit position known, no approved rule.',
        'bride': {'status': 'REVIEW_REQUIRED', 'reviewRequired': true, 'reasonCode': 'NO_RULE', 'explanation': 'No rule.'},
        'groom': {'status': 'REVIEW_REQUIRED', 'reviewRequired': true, 'reasonCode': 'NO_RULE', 'explanation': 'No rule.'},
      },
      'chandraBala': {
        'status': 'REVIEW_REQUIRED',
        'reviewRequired': true,
        'reasonCode': 'NO_APPROVED_RULE',
        'explanation': 'Transit position known, no approved rule.',
        'bride': {'status': 'REVIEW_REQUIRED', 'reviewRequired': true, 'reasonCode': 'NO_RULE', 'explanation': 'No rule.'},
        'groom': {'status': 'REVIEW_REQUIRED', 'reviewRequired': true, 'reasonCode': 'NO_RULE', 'explanation': 'No rule.'},
      },
      'taraBala': {
        'status': 'REVIEW_REQUIRED',
        'reviewRequired': true,
        'reasonCode': 'NO_APPROVED_CONFIG',
        'explanation': 'Category known, no approved config.',
        'bride': {'status': 'REVIEW_REQUIRED', 'reviewRequired': true, 'reasonCode': 'NO_CONFIG', 'explanation': 'No config.', 'taraPosition': 5},
        'groom': {'status': 'REVIEW_REQUIRED', 'reviewRequired': true, 'reasonCode': 'NO_CONFIG', 'explanation': 'No config.', 'taraPosition': 3},
      },
      'gochar': {
        'status': 'CALCULATED',
        'reviewRequired': false,
        'reasonCode': 'GOCHAR_CALCULATED',
        'explanation': 'Transit chart calculated.',
        'transitPositions': {
          'SUN': {'rashiId': 9, 'nakshatraId': 24, 'nakshatraPada': 2, 'isRetrograde': false},
        },
      },
      'dashaTiming': {
        'status': 'CALCULATED',
        'reviewRequired': false,
        'reasonCode': 'DASHA_TIMING_CALCULATED',
        'explanation': 'Dasha timing calculated.',
        'bride': {'status': 'CALCULATED', 'reviewRequired': false, 'reasonCode': 'OK', 'explanation': 'OK', 'currentMahadashaLord': 'VENUS', 'currentAntardashaLord': 'MOON'},
        'groom': {'status': 'CALCULATED', 'reviewRequired': false, 'reasonCode': 'OK', 'explanation': 'OK', 'currentMahadashaLord': 'SATURN', 'currentAntardashaLord': 'MERCURY'},
      },
    };

Map<String, dynamic> _paramparaJson() => {
      'ruleVersion': 'DAIVAGNA_PARAMPARA_V1',
      'brideProfileId': 'profile-a',
      'groomProfileId': 'profile-b',
      'status': 'INFORMATIONAL',
      'reviewRequired': false,
      'reasonCode': 'DECLARED_VALUES_COMPARED',
      'explanation': 'Declared values compared for information only.',
      'bride': {
        'status': 'CALCULATED',
        'reviewRequired': false,
        'reasonCode': 'PARAMPARA_CALCULATED',
        'explanation': 'Declarations read.',
        'gotra': {'status': 'PROVIDED', 'source': 'USER_DECLARED', 'customValue': 'Kashyapa'},
        'pravara': {'status': 'NOT_PROVIDED'},
        'kuladevata': {'status': 'PROVIDED', 'source': 'USER_DECLARED', 'customValue': 'Shree Mahalasa'},
        'kuladevi': {'status': 'NOT_PROVIDED'},
      },
      'groom': {
        'status': 'CALCULATED',
        'reviewRequired': false,
        'reasonCode': 'PARAMPARA_CALCULATED',
        'explanation': 'Declarations read.',
        'gotra': {'status': 'PROVIDED', 'source': 'USER_DECLARED', 'customValue': 'Bharadwaj'},
        'pravara': {'status': 'NOT_PROVIDED'},
        'kuladevata': {'status': 'NOT_PROVIDED'},
        'kuladevi': {'status': 'NOT_PROVIDED'},
      },
      'comparison': {
        'status': 'INFORMATIONAL',
        'reasonCode': 'GOTRA_DIFFERENT',
        'explanation': 'Declared Gotras differ.',
        'fieldFindings': [
          {'field': 'gotra', 'status': 'DIFFERENT', 'reasonCode': 'GOTRA_DIFFERENT', 'explanation': 'Kashyapa vs Bharadwaj.'},
        ],
      },
    };

Map<String, dynamic> _kundliPlanetJson(
  String graha,
  int rashiId,
  String rashiName,
  int nakshatraId,
  String nakshatraName,
  int pada, {
  bool retrograde = false,
}) =>
    {
      'graha': graha,
      'rashiId': rashiId,
      'rashiName': rashiName,
      'nakshatraId': nakshatraId,
      'nakshatraName': nakshatraName,
      'nakshatraPada': pada,
      'isRetrograde': retrograde,
    };

/// All 9 Grahas, deliberately clustering SUN/MOON/MERCURY together in Mesha
/// (rashiId 1) so tests can assert "multiple planets in one Rashi cell"
/// without a separate fixture.
List<Map<String, dynamic>> _ninePlanetsJson() => [
      _kundliPlanetJson('SUN', 1, 'Mesha', 1, 'Ashwini', 1),
      _kundliPlanetJson('MOON', 1, 'Mesha', 2, 'Bharani', 2),
      _kundliPlanetJson('MERCURY', 1, 'Mesha', 3, 'Krittika', 3),
      _kundliPlanetJson('MARS', 2, 'Vrishabha', 4, 'Rohini', 4),
      _kundliPlanetJson('JUPITER', 4, 'Karka', 5, 'Mrigashira', 1),
      _kundliPlanetJson('VENUS', 5, 'Simha', 6, 'Ardra', 2),
      _kundliPlanetJson('SATURN', 6, 'Kanya', 7, 'Punarvasu', 3),
      _kundliPlanetJson('RAHU', 7, 'Tula', 8, 'Pushya', 4, retrograde: true),
      _kundliPlanetJson('KETU', 8, 'Vrishchika', 9, 'Ashlesha', 1, retrograde: true),
    ];

List<Map<String, dynamic>> _tenNavamshaJson() => [
      {'point': 'LAGNA', 'rashiId': 1, 'rashiName': 'Mesha'},
      {'point': 'SUN', 'rashiId': 2, 'rashiName': 'Vrishabha'},
      {'point': 'MOON', 'rashiId': 3, 'rashiName': 'Mithuna'},
      {'point': 'MARS', 'rashiId': 4, 'rashiName': 'Karka'},
      {'point': 'MERCURY', 'rashiId': 5, 'rashiName': 'Simha'},
      {'point': 'JUPITER', 'rashiId': 6, 'rashiName': 'Kanya'},
      {'point': 'VENUS', 'rashiId': 7, 'rashiName': 'Tula'},
      {'point': 'SATURN', 'rashiId': 8, 'rashiName': 'Vrishchika'},
      {'point': 'RAHU', 'rashiId': 9, 'rashiName': 'Dhanu'},
      {'point': 'KETU', 'rashiId': 10, 'rashiName': 'Makara'},
    ];

Map<String, dynamic> _partnerKundliJson({
  int lagnaId = 1,
  String lagnaRashiName = 'Mesha',
  List<Map<String, dynamic>>? planets,
  bool includeNavamsha = true,
}) =>
    {
      'lagnaId': lagnaId,
      'lagnaRashiName': lagnaRashiName,
      'planets': planets ?? _ninePlanetsJson(),
      'navamsha': includeNavamsha ? _tenNavamshaJson() : <dynamic>[],
    };

Map<String, dynamic> _kundliChartJson({
  bool includeNavamsha = true,
  List<Map<String, dynamic>>? bridePlanets,
  List<Map<String, dynamic>>? groomPlanets,
}) =>
    {
      'brideProfileId': 'profile-a',
      'groomProfileId': 'profile-b',
      'bride': _partnerKundliJson(
          lagnaId: 1, lagnaRashiName: 'Mesha', planets: bridePlanets, includeNavamsha: includeNavamsha),
      'groom': _partnerKundliJson(
          lagnaId: 5, lagnaRashiName: 'Simha', planets: groomPlanets, includeNavamsha: includeNavamsha),
    };

Map<String, dynamic> _fullReportJson({
  Map<String, dynamic>? jataka,
  Map<String, dynamic>? ashtakoota,
  Map<String, dynamic>? advancedJataka,
  Map<String, dynamic>? kujaDosha,
  Map<String, dynamic>? dasha,
  Map<String, dynamic>? vivahaKalaBala,
  Map<String, dynamic>? daivagnaParampara,
  Map<String, dynamic>? kundliChart,
  List<Map<String, dynamic>> discussionPoints = const [],
}) =>
    {
      'id': 'report-1',
      'profileAId': 'profile-a',
      'profileBId': 'profile-b',
      'traditionalRoleA': 'BRIDE',
      'traditionalRoleB': 'GROOM',
      'ruleVersion': 'KARNATAKA_SOUTH_INDIAN_V1',
      'requestedInclude': ['JATAKA'],
      'notImplementedInclude': <String>[],
      'jataka': ?jataka,
      'ashtakoota': ?ashtakoota,
      'advancedJataka': ?advancedJataka,
      'kujaDosha': ?kujaDosha,
      'dasha': ?dasha,
      'vivahaKalaBala': ?vivahaKalaBala,
      'daivagnaParampara': ?daivagnaParampara,
      'kundliChart': ?kundliChart,
      'overallCompatibility': {
        'percentage': 81,
        'status': 'CALCULATED',
        'reasonCode': 'OVERALL_COMPATIBILITY_CALCULATED',
        'explanation': 'Calculated from both Profile and Astrology Compatibility, weighted 50%/50%.',
        'profilePercentage': 84,
        'astrologyPercentage': 78,
        'profileWeight': 50,
        'astrologyWeight': 50,
      },
      'discussionPoints': discussionPoints,
      'overallStatus': 'CALCULATED',
      'disclaimer':
          'This compatibility result is an initial matchmaking assessment. It is not a definitive prediction.',
      'coverage': 85,
      'confidence': 'HIGH',
      'createdAt': '2026-01-01T00:00:00.000Z',
    };

/// The "full" fixture used by most tests below: every one of the 6 new
/// modules present, plus a real 10-Porutham / 8-Koota Karnataka+Ashtakoota
/// result — mirrors a real, fully-calculated report.
Map<String, dynamic> _fullFixture({String? advancedJatakaStatus, String? dashaComparisonStatus}) => _fullReportJson(
      jataka: _jatakaJson(),
      ashtakoota: _ashtakootaJson(),
      advancedJataka: _advancedJatakaJson(status: advancedJatakaStatus ?? 'SUPPORTIVE'),
      kujaDosha: _kujaDoshaJson(),
      dasha: _dashaJson(comparisonStatus: dashaComparisonStatus ?? 'NEUTRAL'),
      vivahaKalaBala: _vivahaKalaBalaJson(),
      daivagnaParampara: _paramparaJson(),
      kundliChart: _kundliChartJson(),
      discussionPoints: const [
        {'code': 'ASHTAKOOTA_NADI_MISMATCH', 'source': 'ASHTAKOOTA', 'severity': 'REVIEW', 'message': 'Nadi Koota did not match.'},
      ],
    );

/// Pumps [CompatibilityReportView] inside a scrollable host (mirroring
/// [CompatibilityReportScreen]'s own `ListView` ancestor) without needing
/// Repository/Provider — this widget takes an already-parsed
/// [CompatibilityReport], not a reportId.
Future<void> _pumpView(WidgetTester tester, Map<String, dynamic> json, {Size surface = const Size(420, 3600)}) async {
  await tester.binding.setSurfaceSize(surface);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final report = CompatibilityReport.fromJson(json);
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: CompatibilityReportView(report: report),
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  group('Karnataka 10 Porutham', () {
    testWidgets('all 10 Poruthams render', (tester) async {
      await _pumpView(tester, _fullReportJson(jataka: _jatakaJson()));
      for (final code in const [
        'Dina', 'Gana', 'Mahendra', 'Stree Deergha', 'Yoni', //
        'Rashi', 'Rashi Adhipathi', 'Vashya', 'Rajju', 'Vedha',
      ]) {
        expect(find.text(code), findsOneWidget, reason: '$code should render');
      }
    });

    testWidgets('matched/partial/notMatched statuses render distinctly', (tester) async {
      await _pumpView(tester, _fullReportJson(jataka: _jatakaJson()));
      expect(find.text('Matched'), findsWidgets);
      expect(find.text('Partial'), findsOneWidget);
      expect(find.text('Not matched'), findsWidgets);
    });

    testWidgets('normalizedPercentage is shown verbatim, never recalculated', (tester) async {
      await _pumpView(tester, _fullReportJson(jataka: _jatakaJson(normalizedPercentage: 75)));
      expect(find.text('Normalized score: 75%'), findsOneWidget);
    });

    testWidgets('missing normalizedPercentage never becomes 0%', (tester) async {
      await _pumpView(tester, _fullReportJson(jataka: _jatakaJson(normalizedPercentage: null)));
      expect(find.textContaining('Normalized score'), findsNothing);
      expect(find.text('Normalized score: 0%'), findsNothing);
    });
  });

  group('Ashtakoota 36 Guna', () {
    testWidgets('all 8 Kootas render, including Nadi with its real result', (tester) async {
      await _pumpView(tester, _fullReportJson(ashtakoota: _ashtakootaJson()));
      for (final label in const [
        'Varna', 'Vashya', 'Tara', 'Yoni', 'Graha Maitri', 'Gana', 'Bhakoot', 'Nadi', //
      ]) {
        expect(find.text(label), findsOneWidget, reason: '$label should render');
      }
      // Nadi's own NOT_MATCHED result must show, not a fabricated match.
      expect(find.text('0/8'), findsOneWidget);
    });

    testWidgets('28/36 score renders', (tester) async {
      await _pumpView(tester, _fullReportJson(ashtakoota: _ashtakootaJson(earned: 28)));
      expect(find.text('28 / 36'), findsOneWidget);
    });

    testWidgets('incomplete Ashtakoota never shows a fabricated 0/36 or 0%', (tester) async {
      await _pumpView(tester, _fullReportJson(ashtakoota: _ashtakootaJson(earned: null)));
      expect(find.text('0 / 36'), findsNothing);
      expect(find.textContaining('unavailable'), findsWidgets);
    });

    testWidgets('percentage is displayed as the backend sent it, not recomputed from earned/maximum', (tester) async {
      final json = _fullReportJson(ashtakoota: _ashtakootaJson(earned: 28));
      json['astrologyCompatibility'] = {
        'status': 'CALCULATED',
        'reasonCode': 'OK',
        'explanation': 'OK',
        'primarySystem': 'KARNATAKA_SOUTH_INDIAN',
        'percentage': 78,
        'karnatakaPorutham': {'matched': 7, 'partial': 1, 'notMatched': 2, 'calculable': 10, 'total': 10, 'percentage': 78},
        // Deliberately NOT 28/36*100 (77.78) — proves the UI shows this
        // verbatim figure rather than recomputing one from earned/maximum.
        'ashtakoota': {'earned': 28, 'maximum': 36, 'percentage': 85.0, 'isComplete': true},
      };
      await _pumpView(tester, json);
      expect(find.text('85.0%'), findsOneWidget);
      expect(find.text('77.8%'), findsNothing);
    });
  });

  group('Advanced Jataka', () {
    testWidgets('findings render with their explanation', (tester) async {
      await _pumpView(tester, _fullReportJson(advancedJataka: _advancedJatakaJson()));
      // Findings live inside a collapsed-by-default expandable section — tap
      // to open it, matching how a real user would drill into detail.
      await tester.tap(find.text('Bride'));
      await tester.pumpAndSettle();
      expect(find.text('Lagna'), findsOneWidget);
      expect(find.textContaining('Lagna is Leo.'), findsOneWidget);
    });

    testWidgets('SUPPORTIVE status renders', (tester) async {
      await _pumpView(tester, _fullReportJson(advancedJataka: _advancedJatakaJson(status: 'SUPPORTIVE')));
      expect(find.text('Supportive'), findsOneWidget);
    });

    testWidgets('NEUTRAL status renders', (tester) async {
      await _pumpView(tester, _fullReportJson(advancedJataka: _advancedJatakaJson(status: 'NEUTRAL')));
      expect(find.text('Neutral'), findsOneWidget);
    });

    testWidgets('CAUTION status renders', (tester) async {
      await _pumpView(tester, _fullReportJson(advancedJataka: _advancedJatakaJson(status: 'CAUTION')));
      expect(find.text('Caution'), findsOneWidget);
    });

    testWidgets('missing Advanced Jataka data shows an unavailable notice, not a crash', (tester) async {
      await _pumpView(tester, _fullReportJson());
      expect(find.text('Advanced Jataka not available'), findsOneWidget);
    });
  });

  group('Kuja Dosha', () {
    testWidgets('bride and groom results render', (tester) async {
      await _pumpView(tester, _fullReportJson(kujaDosha: _kujaDoshaJson()));
      expect(find.text('Bride'), findsWidgets);
      expect(find.text('Groom'), findsWidgets);
    });

    testWidgets('severity (MODERATE / NOT_PRESENT) renders using backend terminology', (tester) async {
      await _pumpView(tester, _fullReportJson(kujaDosha: _kujaDoshaJson()));
      expect(find.text('Moderate'), findsOneWidget);
      expect(find.text('Not present'), findsOneWidget);
      expect(find.text('Balanced with partner'), findsOneWidget);
    });

    testWidgets('cancellation findings render', (tester) async {
      await _pumpView(tester, _fullReportJson(kujaDosha: _kujaDoshaJson()));
      expect(find.textContaining('cancelling the dosha'), findsOneWidget);
    });

    testWidgets('missing Kuja Dosha data shows an unavailable notice, not a crash', (tester) async {
      await _pumpView(tester, _fullReportJson());
      expect(find.text('Kuja Dosha not available'), findsOneWidget);
    });
  });

  group('Dasha Compatibility', () {
    testWidgets('Mahadasha/Antardasha render', (tester) async {
      await _pumpView(tester, _fullReportJson(dasha: _dashaJson()));
      // Current/Next Mahadasha-Antardasha live inside a collapsed-by-default
      // expandable section — tap to open it before asserting on its content.
      await tester.tap(find.text('Bride'));
      await tester.pumpAndSettle();
      expect(find.text('Current Mahadasha'), findsOneWidget);
      expect(find.text('Current Antardasha'), findsOneWidget);
      expect(find.text('Venus'), findsWidgets);
      expect(find.text('Moon'), findsOneWidget);
    });

    testWidgets('REVIEW_REQUIRED status renders', (tester) async {
      await _pumpView(tester, _fullReportJson(dasha: _dashaJson(comparisonStatus: 'REVIEW_REQUIRED')));
      expect(find.text('Review required'), findsOneWidget);
    });

    testWidgets('missing Dasha data shows an unavailable notice, not a crash', (tester) async {
      await _pumpView(tester, _fullReportJson());
      expect(find.text('Dasha Compatibility not available'), findsOneWidget);
    });
  });

  group('Vivaha Kala Bala', () {
    testWidgets('Guru, Shukra, Chandra, Tara, Gochar and Dasha Timing all render', (tester) async {
      await _pumpView(tester, _fullReportJson(vivahaKalaBala: _vivahaKalaBalaJson()));
      expect(find.text('Guru Bala'), findsOneWidget);
      expect(find.text('Shukra Bala'), findsOneWidget);
      expect(find.text('Chandra Bala'), findsOneWidget);
      expect(find.text('Tara Bala'), findsOneWidget);
      expect(find.text('Gochar (Transits)'), findsOneWidget);
      expect(find.text('Dasha Timing'), findsOneWidget);
    });

    testWidgets('missing Vivaha Kala Bala data shows an unavailable notice, not a crash', (tester) async {
      await _pumpView(tester, _fullReportJson());
      expect(find.text('Vivaha Kala Bala not available'), findsOneWidget);
    });
  });

  group('Daivagna Parampara', () {
    testWidgets('Gotra and Kuladevata render for both partners — Pravara/Kuladevi are deliberately not shown',
        (tester) async {
      await _pumpView(tester, _fullReportJson(daivagnaParampara: _paramparaJson()));
      expect(find.text('Gotra'), findsWidgets);
      expect(find.text('Kuladevata'), findsWidgets);
      expect(find.text('Pravara'), findsNothing);
      expect(find.text('Kuladevi'), findsNothing);
      expect(find.text('Kashyapa'), findsOneWidget);
      expect(find.text('Bharadwaj'), findsOneWidget);
    });

    testWidgets('missing declarations show "Not provided", never inferred', (tester) async {
      await _pumpView(tester, _fullReportJson(daivagnaParampara: _paramparaJson()));
      expect(find.text('Not provided'), findsWidgets);
    });

    testWidgets('missing Parampara data shows an unavailable notice, not a crash', (tester) async {
      await _pumpView(tester, _fullReportJson());
      expect(find.text('Daivagna Parampara not available'), findsOneWidget);
    });
  });

  group('Kundli Chart', () {
    testWidgets('D1 chart renders for both Bride and Groom under the birth-chart section header', (tester) async {
      await _pumpView(tester, _fullReportJson(kundliChart: _kundliChartJson()));
      expect(find.text('Birth Chart (South Indian Style)'), findsOneWidget);
      // "Lagna: Mesha" appears both as the bride's D1 headline and (since the
      // D9 fixture's own Navamsha Lagna also happens to be Mesha) in a D9
      // subtitle too — assert presence, not an exact count.
      expect(find.text('Lagna: Mesha'), findsWidgets);
      expect(find.text('Lagna: Simha'), findsOneWidget);
      // D1 charts for both partners render immediately; the D9 charts sit
      // inside a collapsed CompatibilityExpandableSection and only mount
      // once expanded (see the D9-specific test below).
      expect(find.byType(SouthIndianKundliChart), findsNWidgets(2));
    });

    testWidgets('all 9 Grahas render in the Planet Details list once expanded', (tester) async {
      await _pumpView(tester, _fullReportJson(kundliChart: _kundliChartJson()));
      await tester.tap(find.text('View Planet Details').first);
      await tester.pumpAndSettle();
      for (final name in ['Sun', 'Moon', 'Mercury', 'Mars', 'Jupiter', 'Venus', 'Saturn', 'Rahu', 'Ketu']) {
        expect(find.text(name), findsWidgets);
      }
    });

    testWidgets('retrograde planets are marked with (R)', (tester) async {
      await _pumpView(tester, _fullReportJson(kundliChart: _kundliChartJson()));
      expect(find.text('Ra(R)'), findsWidgets);
      expect(find.text('Ke(R)'), findsWidgets);
    });

    testWidgets('multiple planets sharing one Rashi cell all render without overflow', (tester) async {
      await _pumpView(tester, _fullReportJson(kundliChart: _kundliChartJson()));
      expect(tester.takeException(), isNull);
      // Su/Mo/Me are deliberately placed together in Mesha by _ninePlanetsJson.
      expect(find.text('Su'), findsWidgets);
      expect(find.text('Mo'), findsWidgets);
      expect(find.text('Me'), findsWidgets);
    });

    testWidgets('D9 (Navamsha) chart renders when the report has it, once expanded', (tester) async {
      await _pumpView(tester, _fullReportJson(kundliChart: _kundliChartJson()));
      expect(find.text('Navamsha (D9) Chart'), findsWidgets);
      await tester.tap(find.text('Navamsha (D9) Chart').first);
      await tester.pumpAndSettle();
      // The D1 charts were already mounted (2); expanding one D9 tile mounts
      // a 3rd SouthIndianKundliChart.
      expect(find.byType(SouthIndianKundliChart), findsNWidgets(3));
    });

    testWidgets('missing D9 shows "not available" text instead of an empty chart', (tester) async {
      await _pumpView(tester, _fullReportJson(kundliChart: _kundliChartJson(includeNavamsha: false)));
      expect(find.text('Navamsha chart is not available for this report.'), findsWidgets);
      expect(find.text('Navamsha (D9) Chart'), findsNothing);
    });

    testWidgets('a planet missing its Rashi/Nakshatra name does not crash or show a fabricated value', (tester) async {
      final incompletePlanet = [
        {
          'graha': 'SUN',
          'rashiId': 1,
          'rashiName': '',
          'nakshatraId': 0,
          'nakshatraName': '',
          'nakshatraPada': 0,
          'isRetrograde': false,
        },
      ];
      await _pumpView(tester, _fullReportJson(kundliChart: _kundliChartJson(bridePlanets: incompletePlanet)));
      expect(tester.takeException(), isNull);
      expect(find.textContaining('null'), findsNothing);
    });

    testWidgets('missing Kundli chart data shows an unavailable notice, not a crash', (tester) async {
      await _pumpView(tester, _fullReportJson());
      expect(find.text('Kundli chart not available'), findsOneWidget);
    });

    testWidgets('renders on a small-screen surface without overflow errors', (tester) async {
      await _pumpView(
        tester,
        _fullReportJson(kundliChart: _kundliChartJson()),
        surface: const Size(320, 4200),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('SouthIndianKundliChart widget', () {
    testWidgets('marks the Lagna cell', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: SouthIndianKundliChart(lagnaRashiId: 1, planetLabelsByRashi: {}),
        ),
      ));
      expect(find.text('As'), findsOneWidget);
    });

    testWidgets('renders every one of the 9 Grahas stacked in a single Rashi cell without overflow', (tester) async {
      const labels = ['Su', 'Mo', 'Ma', 'Me', 'Ju', 'Ve', 'Sa', 'Ra(R)', 'Ke(R)'];
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: SouthIndianKundliChart(
            lagnaRashiId: 1,
            planetLabelsByRashi: {1: labels},
            size: 160,
          ),
        ),
      ));
      await tester.pump();
      expect(tester.takeException(), isNull);
      for (final label in labels) {
        expect(find.text(label), findsOneWidget);
      }
    });

    testWidgets('renders at a very small size without overflow', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: SouthIndianKundliChart(lagnaRashiId: 1, planetLabelsByRashi: {1: ['Su']}, size: 80),
        ),
      ));
      expect(tester.takeException(), isNull);
    });

    test('the fixed grid has exactly 12 Rashi cells (Mesha..Meena) and 4 merged centre cells', () {
      final flat = kSouthIndianGridLayout.expand((row) => row).toList();
      expect(flat, hasLength(16));
      expect(flat.where((id) => id == null), hasLength(4));
      expect(flat.whereType<int>().toSet(), {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12});
    });
  });

  group('General', () {
    testWidgets('the full report — every module present — renders without error', (tester) async {
      await _pumpView(tester, _fullFixture());
      expect(tester.takeException(), isNull);
      // Section eyebrows render upper-cased (CompatibilitySectionHeader).
      expect(find.text('ASHTAKOOTA / 36 GUNA'), findsOneWidget);
      expect(find.text('ADVANCED JATAKA'), findsOneWidget);
      expect(find.text('KUJA DOSHA / MANGLIK'), findsOneWidget);
      expect(find.text('DASHA COMPATIBILITY'), findsOneWidget);
      expect(find.text('VIVAHA KALA BALA'), findsOneWidget);
      // Daivagna Parampara's "Family Tradition" comparison card and the
      // Discussion Points card were both deliberately removed from the
      // detailed report — only the Bride/Groom declared-value cards remain.
      expect(find.text('Bride'), findsWidgets);
      expect(find.text('Groom'), findsWidgets);
      expect(find.text('Birth Chart (South Indian Style)'), findsOneWidget);
    });

    testWidgets('null fields across every module do not crash', (tester) async {
      await _pumpView(tester, _fullReportJson());
      expect(tester.takeException(), isNull);
      expect(find.text('No Jataka result'), findsOneWidget);
    });

    testWidgets('an old report missing every STEP 51-69 field renders without a crash', (tester) async {
      final legacy = {
        'id': 'old-report-1',
        'profileAId': 'profile-a',
        'profileBId': 'profile-b',
        'ruleVersion': 'KARNATAKA_SOUTH_INDIAN_V1',
        'requestedInclude': ['JATAKA'],
        'notImplementedInclude': <String>[],
        'jataka': _jatakaJson(normalizedPercentage: null, poruthams: const []),
        'overallCompatibility': {
          'percentage': null,
          'status': 'NOT_CALCULABLE',
          'reasonCode': 'NO_INPUTS',
          'explanation': '',
          'profilePercentage': null,
          'astrologyPercentage': null,
          'profileWeight': 50,
          'astrologyWeight': 50,
        },
        'discussionPoints': <dynamic>[],
        'overallStatus': 'UNKNOWN',
        'disclaimer': '',
        'coverage': 0,
        'confidence': 'UNKNOWN',
      };
      await _pumpView(tester, legacy);
      expect(tester.takeException(), isNull);
      expect(find.text('Ashtakoota not available'), findsOneWidget);
      // A report saved before STEP 80 has no kundliChart field at all —
      // must degrade to the unavailable notice, never a crash or a
      // recalculated/invented chart.
      expect(find.text('Kundli chart not available'), findsOneWidget);
    });

    testWidgets('no fabricated 0% or 0/36 values appear anywhere on an incomplete report', (tester) async {
      await _pumpView(tester, _fullReportJson(
        jataka: _jatakaJson(normalizedPercentage: null),
        ashtakoota: _ashtakootaJson(earned: null, requiresReview: true),
      ));
      expect(find.text('0%'), findsNothing);
      expect(find.text('0 / 36'), findsNothing);
    });

    testWidgets('scrolling through the full report does not throw', (tester) async {
      await _pumpView(tester, _fullFixture());
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -3000));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.textContaining('initial matchmaking assessment'), findsOneWidget);
    });

    testWidgets('navigation: CompatibilityReportScreen fetches and renders the full detailed report', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final originalRepository = Repository.instance;
      addTearDown(() => Repository.instance = originalRepository);

      final fake = _FakeApiClient((_) async => _fullFixture());
      Repository.instance = Repository(api: fake);
      final authService = AuthService(repo: Repository.instance);
      await authService.loginWithUser(
        const AppUser(name: 'Priya', phone: '999', role: 'member', gotra: '', native: '', avatar: '', gender: 'F'),
      );

      await tester.binding.setSurfaceSize(const Size(420, 3600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ChangeNotifierProvider<AuthService>.value(
          value: authService,
          child: const MaterialApp(
            home: CompatibilityReportScreen(reportId: 'report-1', otherName: 'Asha'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // AppBar title + header card title both read "Compatibility Report".
      expect(find.text('Compatibility Report'), findsWidgets);
      expect(find.text('ASHTAKOOTA / 36 GUNA'), findsOneWidget);
      expect(fake.calls, ['/api/v1/compatibility/reports/report-1']);
    });
  });
}

class _FakeApiClient extends ApiClient {
  _FakeApiClient(this.handler);
  final dynamic Function(String path) handler;
  final List<String> calls = [];

  @override
  Future<dynamic> getJson(String path) async {
    calls.add(path);
    return handler(path);
  }
}
