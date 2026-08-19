import 'package:flutter_test/flutter_test.dart';

import 'package:daivajna_census/data/models/compatibility_astrology_modules.dart';
import 'package:daivajna_census/data/models/compatibility_models.dart';
import 'package:daivajna_census/data/models/compatibility_summary.dart';
import 'package:daivajna_census/data/models/parampara.dart';
import 'package:daivajna_census/data/models/south_indian_jataka.dart';

/// STEP 72 — a realistic, full `GET /api/v1/compatibility/reports/:reportId`
/// response, matching the backend's `CompatibilityReportView` field-for-field.
/// Used as the base fixture for every test below; individual tests strip or
/// null out pieces of it rather than duplicating the whole shape each time.
Map<String, dynamic> _fullReportJson() => {
      'id': 'report-1',
      'profileAId': 'profile-a',
      'profileBId': 'profile-b',
      'traditionalRoleA': 'BRIDE',
      'traditionalRoleB': 'GROOM',
      'ruleVersion': 'KARNATAKA_SOUTH_INDIAN_V1',
      'requestedInclude': ['JATAKA'],
      'notImplementedInclude': <String>[],
      'jataka': {
        'ruleVersion': 'KARNATAKA_SOUTH_INDIAN_V1',
        'brideProfileId': 'profile-a',
        'groomProfileId': 'profile-b',
        'matched': 7,
        'partial': 1,
        'notMatched': 2,
        'reviewRequired': 0,
        'notCalculable': 0,
        'normalizedPercentage': 75,
        'verdict': 'GOOD',
        'verdictLabel': 'Good match',
        'criticalAlerts': <dynamic>[],
        'poruthams': <dynamic>[],
        'nakshatraBoundaryRiskOverride': false,
        'ruleVersionId': 'rv-1',
        'ruleVersionStatus': 'PUBLISHED',
        'ruleVersionChecksum': 'abc123',
      },
      'ashtakoota': {
        'ruleVersion': 'ASHTAKOOTA_V1',
        'brideProfileId': 'profile-a',
        'groomProfileId': 'profile-b',
        'earned': 29,
        'maximum': 36,
        'isComplete': true,
        'requiresReview': false,
        'kootas': <dynamic>[],
        'nakshatraBoundaryRiskOverride': false,
      },
      'advancedJataka': {
        'ruleVersion': 'ADVANCED_JATAKA_V1',
        'brideProfileId': 'profile-a',
        'groomProfileId': 'profile-b',
        'status': 'NOT_CALCULABLE',
        'reviewRequired': false,
        'reasonCode': 'NO_APPROVED_FORMULA',
        'explanation': 'No approved interpretation formula exists.',
        'bride': {
          'natal': {
            'lagna': {
              'code': 'LAGNA',
              'status': 'CALCULATED',
              'reasonCode': 'LAGNA_CALCULATED',
              'explanation': 'Lagna is Leo.',
              'reviewRequired': false,
              'data': {'rashiId': 5, 'rashiName': 'Leo'},
            },
          },
          'navamsha': <String, dynamic>{},
        },
        'groom': {'natal': <String, dynamic>{}, 'navamsha': <String, dynamic>{}},
      },
      'kujaDosha': {
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
          'fromMoon': null,
          'fromVenus': null,
          'relevantMarsPlacements': {'rashiId': 1, 'rashiName': 'Aries'},
          'cancellationFindings': <dynamic>[],
        },
        'groom': {
          'status': 'MODERATE',
          'reviewRequired': false,
          'reasonCode': 'MARS_IN_AFFECTED_HOUSE',
          'explanation': 'Mars is in an affected house from Lagna.',
          'fromLagna': null,
          'fromMoon': null,
          'fromVenus': null,
          'relevantMarsPlacements': null,
          'cancellationFindings': <dynamic>[],
        },
        'comparison': {
          'status': 'BALANCED_WITH_PARTNER',
          'reasonCode': 'BOTH_ACTIVE',
          'explanation': 'Both bride and groom have an active dosha.',
        },
      },
      'dasha': {
        'ruleVersion': 'DASHA_COMPATIBILITY_V1',
        'assessmentDate': '2026-01-01T00:00:00.000Z',
        'brideProfileId': 'profile-a',
        'groomProfileId': 'profile-b',
        'status': 'NEUTRAL',
        'reviewRequired': false,
        'reasonCode': 'NEUTRAL_PAIRING',
        'explanation': 'Current Mahadasha lords are a neutral pairing.',
        'bride': {
          'status': 'CALCULATED',
          'reviewRequired': false,
          'reasonCode': 'DASHA_CALCULATED',
          'explanation': 'Timeline calculated from birth Nakshatra.',
          'birthNakshatraId': 3,
          'birthNakshatraName': 'Krittika',
          'birthNakshatraLord': 'SUN',
          'startingMahadasha': null,
          'startingMahadashaBalanceYears': null,
          'mahadashas': <dynamic>[],
          'currentMahadasha': null,
          'currentAntardasha': null,
          'nextMahadasha': null,
          'nextAntardasha': null,
          'antardashas': <dynamic>[],
          'sandhiFindings': <dynamic>[],
          'marriageSignificatorDasha': null,
        },
        'groom': {
          'status': 'CALCULATED',
          'reviewRequired': false,
          'reasonCode': 'DASHA_CALCULATED',
          'explanation': 'Timeline calculated from birth Nakshatra.',
          'birthNakshatraId': 8,
          'birthNakshatraName': 'Pushya',
          'birthNakshatraLord': 'SATURN',
          'startingMahadasha': null,
          'startingMahadashaBalanceYears': null,
          'mahadashas': <dynamic>[],
          'currentMahadasha': null,
          'currentAntardasha': null,
          'nextMahadasha': null,
          'nextAntardasha': null,
          'antardashas': <dynamic>[],
          'sandhiFindings': <dynamic>[],
          'marriageSignificatorDasha': null,
        },
        'comparison': {
          'status': 'NEUTRAL',
          'reasonCode': 'NEUTRAL_PAIRING',
          'explanation': 'Current Mahadasha lords are a neutral pairing.',
        },
      },
      'daivagnaParampara': {
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
      },
      'vivahaKalaBala': {
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
          'bride': {'status': 'REVIEW_REQUIRED', 'reviewRequired': true, 'reasonCode': 'NO_RULE', 'explanation': 'No rule.', 'classification': null},
          'groom': {'status': 'REVIEW_REQUIRED', 'reviewRequired': true, 'reasonCode': 'NO_RULE', 'explanation': 'No rule.', 'classification': null},
        },
        'shukraBala': {
          'status': 'REVIEW_REQUIRED',
          'reviewRequired': true,
          'reasonCode': 'NO_APPROVED_RULE',
          'explanation': 'Transit position known, no approved rule.',
          'transitPosition': null,
          'bride': {'status': 'REVIEW_REQUIRED', 'reviewRequired': true, 'reasonCode': 'NO_RULE', 'explanation': 'No rule.', 'classification': null},
          'groom': {'status': 'REVIEW_REQUIRED', 'reviewRequired': true, 'reasonCode': 'NO_RULE', 'explanation': 'No rule.', 'classification': null},
        },
        'chandraBala': {
          'status': 'REVIEW_REQUIRED',
          'reviewRequired': true,
          'reasonCode': 'NO_APPROVED_RULE',
          'explanation': 'Transit position known, no approved rule.',
          'transitPosition': null,
          'bride': {'status': 'REVIEW_REQUIRED', 'reviewRequired': true, 'reasonCode': 'NO_RULE', 'explanation': 'No rule.', 'classification': null},
          'groom': {'status': 'REVIEW_REQUIRED', 'reviewRequired': true, 'reasonCode': 'NO_RULE', 'explanation': 'No rule.', 'classification': null},
        },
        'taraBala': {
          'status': 'REVIEW_REQUIRED',
          'reviewRequired': true,
          'reasonCode': 'NO_APPROVED_CONFIG',
          'explanation': 'Category known, no approved config.',
          'transitMoonPosition': {'rashiId': 4, 'nakshatraId': 10, 'nakshatraPada': 1, 'isRetrograde': false},
          'bride': {'status': 'REVIEW_REQUIRED', 'reviewRequired': true, 'reasonCode': 'NO_CONFIG', 'explanation': 'No config.', 'taraPosition': 5, 'classification': null},
          'groom': {'status': 'REVIEW_REQUIRED', 'reviewRequired': true, 'reasonCode': 'NO_CONFIG', 'explanation': 'No config.', 'taraPosition': 3, 'classification': null},
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
          'bride': {
            'status': 'CALCULATED',
            'reviewRequired': false,
            'reasonCode': 'OK',
            'explanation': 'OK',
            'currentMahadashaLord': 'VENUS',
            'currentAntardashaLord': 'MOON',
            'timingClassification': null,
          },
          'groom': {
            'status': 'CALCULATED',
            'reviewRequired': false,
            'reasonCode': 'OK',
            'explanation': 'OK',
            'currentMahadashaLord': 'SATURN',
            'currentAntardashaLord': 'MERCURY',
            'timingClassification': null,
          },
        },
      },
      'astrologyCompatibility': {
        'status': 'CALCULATED',
        'reasonCode': 'ASTROLOGY_COMPATIBILITY_CALCULATED',
        'explanation': 'Calculated from every Karnataka Porutham.',
        'primarySystem': 'KARNATAKA_SOUTH_INDIAN',
        'percentage': 78,
        'karnatakaPorutham': {
          'matched': 7,
          'partial': 1,
          'notMatched': 2,
          'calculable': 10,
          'total': 10,
          'percentage': 78,
        },
        'ashtakoota': {'earned': 29, 'maximum': 36, 'percentage': 80.56, 'isComplete': true},
      },
      'profileCompatibility': {
        'ruleVersion': 'PROFILE_COMPATIBILITY_V1',
        'profileAId': 'profile-a',
        'profileBId': 'profile-b',
        'status': 'CALCULATED',
        'reasonCode': 'PROFILE_COMPATIBILITY_CALCULATED',
        'explanation': 'Calculated from the questionnaire answers.',
        'percentage': 84,
        'coverage': 92,
        'confidence': 'HIGH',
        'categories': <dynamic>[
          {
            'category': 'CORE_VALUES',
            'weight': 20,
            'score': 90,
            'coverage': 100,
            'answeredQuestions': 5,
            'totalQuestions': 5,
            'status': 'CALCULATED',
            'questionResults': <dynamic>[],
            'dealBreakers': <dynamic>[],
          },
        ],
        'dealBreakers': <dynamic>[],
      },
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
      'discussionPoints': <dynamic>[
        {
          'code': 'ASHTAKOOTA_NADI_MISMATCH',
          'source': 'ASHTAKOOTA',
          'severity': 'REVIEW',
          'message': 'Nadi Koota did not match.',
        },
      ],
      'overallStatus': 'CALCULATED',
      'disclaimer':
          'This compatibility result is an initial matchmaking assessment based on the configured Karnataka/South-Indian astrological rules. It is not a definitive prediction and should not be treated as a guarantee of relationship or marriage outcome.',
      'coverage': 85,
      'confidence': 'HIGH',
      'createdAt': '2026-01-01T00:00:00.000Z',
    };

void main() {
  group('CompatibilityReport.fromJson — full response', () {
    test('parses every top-level section without throwing', () {
      final report = CompatibilityReport.fromJson(_fullReportJson());

      expect(report.id, 'report-1');
      expect(report.traditionalRoleA, TraditionalRole.bride);
      expect(report.traditionalRoleB, TraditionalRole.groom);
      expect(report.jataka, isNotNull);
      expect(report.ashtakoota, isNotNull);
      expect(report.advancedJataka, isNotNull);
      expect(report.kujaDosha, isNotNull);
      expect(report.dasha, isNotNull);
      expect(report.daivagnaParampara, isNotNull);
      expect(report.vivahaKalaBala, isNotNull);
      expect(report.astrologyCompatibility, isNotNull);
      expect(report.profileCompatibility, isNotNull);
      expect(report.overallStatus, AstrologyModuleStatus.calculated);
      expect(report.confidence, ConfidenceLevel.high);
      expect(report.coverage, 85);
      expect(report.disclaimer, contains('not a definitive prediction'));
    });

    test('extended CompatibilityJataka fields (ruleVersionId/Status/Checksum) parse', () {
      final report = CompatibilityReport.fromJson(_fullReportJson());
      expect(report.jataka!.ruleVersionId, 'rv-1');
      expect(report.jataka!.ruleVersionStatus, 'PUBLISHED');
      expect(report.jataka!.ruleVersionChecksum, 'abc123');
    });

    test('Ashtakoota (reused AshtakootaResult) parses via CompatibilityReport', () {
      final report = CompatibilityReport.fromJson(_fullReportJson());
      expect(report.ashtakoota!.earned, 29);
      expect(report.ashtakoota!.maximum, 36);
      expect(report.ashtakoota, isA<AshtakootaResult>());
    });
  });

  group('Overall Compatibility parsing (STEP 69)', () {
    test('CALCULATED — 50/50 weighted, matches backend example (84/78 -> 81)', () {
      final report = CompatibilityReport.fromJson(_fullReportJson());
      final overall = report.overallCompatibility;
      expect(overall.percentage, 81);
      expect(overall.status, AstrologyModuleStatus.calculated);
      expect(overall.profilePercentage, 84);
      expect(overall.astrologyPercentage, 78);
      expect(overall.profileWeight, 50);
      expect(overall.astrologyWeight, 50);
    });

    test('REVIEW_REQUIRED — profile-only input is never silently presented as the full result', () {
      final json = {
        'percentage': 84,
        'status': 'REVIEW_REQUIRED',
        'reasonCode': 'OVERALL_COMPATIBILITY_PROFILE_ONLY',
        'explanation': 'Astrology Compatibility could not be calculated.',
        'profilePercentage': 84,
        'astrologyPercentage': null,
        'profileWeight': 50,
        'astrologyWeight': 50,
      };
      final overall = OverallCompatibility.fromJson(json);
      expect(overall.status, AstrologyModuleStatus.reviewRequired);
      expect(overall.percentage, 84);
      expect(overall.astrologyPercentage, isNull);
    });

    test('NOT_CALCULABLE — neither input available, percentage stays null (never 0)', () {
      final json = {
        'percentage': null,
        'status': 'NOT_CALCULABLE',
        'reasonCode': 'OVERALL_COMPATIBILITY_NO_INPUTS',
        'explanation': 'Neither Profile Compatibility nor Astrology Compatibility could be calculated.',
        'profilePercentage': null,
        'astrologyPercentage': null,
        'profileWeight': 50,
        'astrologyWeight': 50,
      };
      final overall = OverallCompatibility.fromJson(json);
      expect(overall.status, AstrologyModuleStatus.notCalculable);
      expect(overall.percentage, isNull);
      expect(overall.profilePercentage, isNull);
      expect(overall.astrologyPercentage, isNull);
    });

    test('missing overallCompatibility object entirely still parses to a safe default', () {
      final json = _fullReportJson()..remove('overallCompatibility');
      final report = CompatibilityReport.fromJson(json);
      expect(report.overallCompatibility.percentage, isNull);
      // AstrologyModuleStatus.unknown here, not notCalculable — the real
      // backend always sends overallCompatibility (it's non-nullable on
      // CompatibilityReportView), so this defensive fallback deliberately
      // never guesses a specific status for a shape it wasn't given.
      expect(report.overallCompatibility.status, AstrologyModuleStatus.unknown);
    });
  });

  group('Astrology Compatibility parsing (STEP 64)', () {
    test('CALCULATED — Karnataka percentage duplicated at the top level', () {
      final astro = AstrologyCompatibility.fromJson(_fullReportJson()['astrologyCompatibility'] as Map<String, dynamic>);
      expect(astro.status, AstrologyModuleStatus.calculated);
      expect(astro.percentage, 78);
      expect(astro.percentage, astro.karnatakaPorutham.percentage);
      expect(astro.ashtakoota!.percentage, 80.56);
    });

    test('NOT_CALCULABLE — zero calculable Poruthams, percentage stays null', () {
      final json = {
        'status': 'NOT_CALCULABLE',
        'reasonCode': 'ASTROLOGY_COMPATIBILITY_NO_CALCULABLE_RESULTS',
        'explanation': 'No Karnataka Porutham produced a result.',
        'primarySystem': 'KARNATAKA_SOUTH_INDIAN',
        'percentage': null,
        'karnatakaPorutham': {'matched': 0, 'partial': 0, 'notMatched': 0, 'calculable': 0, 'total': 10, 'percentage': null},
        'ashtakoota': null,
      };
      final astro = AstrologyCompatibility.fromJson(json);
      expect(astro.status, AstrologyModuleStatus.notCalculable);
      expect(astro.percentage, isNull);
      expect(astro.karnatakaPorutham.percentage, isNull);
      expect(astro.ashtakoota, isNull);
    });

    test('REVIEW_REQUIRED — partial Poruthams still produce a real (non-null) percentage', () {
      final json = {
        'status': 'REVIEW_REQUIRED',
        'reasonCode': 'ASTROLOGY_COMPATIBILITY_PARTIAL_REVIEW_REQUIRED',
        'explanation': 'Reflects 8 of 10 Poruthams.',
        'primarySystem': 'KARNATAKA_SOUTH_INDIAN',
        'percentage': 70,
        'karnatakaPorutham': {'matched': 5, 'partial': 1, 'notMatched': 2, 'calculable': 8, 'total': 10, 'percentage': 70},
        'ashtakoota': null,
      };
      final astro = AstrologyCompatibility.fromJson(json);
      expect(astro.status, AstrologyModuleStatus.reviewRequired);
      expect(astro.percentage, 70);
    });

    test('astrologyCompatibility missing entirely (jataka never ran) parses to null on the report', () {
      final json = _fullReportJson()..remove('astrologyCompatibility');
      final report = CompatibilityReport.fromJson(json);
      expect(report.astrologyCompatibility, isNull);
    });
  });

  group('Profile Compatibility parsing (STEP 65/66)', () {
    test('CALCULATED — percentage, coverage, categories, deal breakers', () {
      final profile =
          ProfileCompatibility.fromJson(_fullReportJson()['profileCompatibility'] as Map<String, dynamic>);
      expect(profile.status, AstrologyModuleStatus.calculated);
      expect(profile.percentage, 84);
      expect(profile.coverage, 92);
      expect(profile.confidence, 'HIGH');
      expect(profile.categories, hasLength(1));
      expect(profile.categories.first.category, 'CORE_VALUES');
      expect(profile.categories.first.score, 90);
    });

    test('NOT_CALCULABLE — insufficient coverage, percentage stays null', () {
      final json = {
        'ruleVersion': 'PROFILE_COMPATIBILITY_V1',
        'profileAId': 'a',
        'profileBId': 'b',
        'status': 'NOT_CALCULABLE',
        'reasonCode': 'PROFILE_COMPATIBILITY_INSUFFICIENT_COVERAGE',
        'explanation': 'Only 10% answered (minimum 50% required).',
        'percentage': null,
        'coverage': 10,
        'confidence': 'LOW',
        'categories': <dynamic>[],
        'dealBreakers': <dynamic>[],
      };
      final profile = ProfileCompatibility.fromJson(json);
      expect(profile.status, AstrologyModuleStatus.notCalculable);
      expect(profile.percentage, isNull);
      expect(profile.coverage, 10); // present even when percentage is null
    });

    test('a category with zero usable answers has a null score, never a fabricated 0', () {
      final json = {
        'category': 'LIFESTYLE',
        'weight': 15,
        'score': null,
        'coverage': 0,
        'answeredQuestions': 0,
        'totalQuestions': 4,
        'status': 'NOT_CALCULABLE',
        'questionResults': <dynamic>[],
        'dealBreakers': <dynamic>[],
      };
      final category = ProfileCategoryResult.fromJson(json);
      expect(category.score, isNull);
      expect(category.status, AstrologyModuleStatus.notCalculable);
    });

    test('profileCompatibility missing entirely (no consent) parses to null on the report', () {
      final json = _fullReportJson()..remove('profileCompatibility');
      final report = CompatibilityReport.fromJson(json);
      expect(report.profileCompatibility, isNull);
    });
  });

  group('Advanced Jataka / Kuja Dosha / Dasha / Vivaha Kala Bala status handling', () {
    test('AdvancedJataka NOT_CALCULABLE — findings still parse underneath', () {
      final aj = AdvancedJataka.fromJson(_fullReportJson()['advancedJataka'] as Map<String, dynamic>);
      expect(aj.status, AstrologyFavorabilityStatus.notCalculable);
      expect(aj.bride.lagna.status, AstrologyModuleStatus.calculated);
      expect(aj.bride.lagna.data?['rashiName'], 'Leo');
    });

    test('KujaDosha BALANCED_WITH_PARTNER — pair verdict mirrors comparison', () {
      final kd = KujaDosha.fromJson(_fullReportJson()['kujaDosha'] as Map<String, dynamic>);
      expect(kd.status, KujaDoshaStatus.balancedWithPartner);
      expect(kd.bride.status, KujaDoshaStatus.moderate);
      expect(kd.bride.status.isActive, isTrue);
      expect(kd.groom.fromLagna, isNull);
    });

    test('DashaCompatibility NEUTRAL — assessmentDate persisted verbatim', () {
      final dasha = DashaCompatibility.fromJson(_fullReportJson()['dasha'] as Map<String, dynamic>);
      expect(dasha.status, DashaComparisonStatus.neutral);
      expect(dasha.assessmentDate, DateTime.parse('2026-01-01T00:00:00.000Z'));
      expect(dasha.bride.birthNakshatraName, 'Krittika');
    });

    test('VivahaKalaBala NOT_CALCULABLE overall — Gochar still CALCULATED underneath', () {
      final vkb = VivahaKalaBala.fromJson(_fullReportJson()['vivahaKalaBala'] as Map<String, dynamic>);
      expect(vkb.status, AstrologyFavorabilityStatus.notCalculable);
      expect(vkb.gochar.status, AstrologyModuleStatus.calculated);
      expect(vkb.gochar.transitPositions?['SUN']?.rashiId, 9);
      expect(vkb.guruBala.status, AstrologyModuleStatus.reviewRequired);
      expect(vkb.guruBala.bride.classification, isNull);
    });

    test('all four sibling modules missing entirely (JATAKA never ran) parse to null on the report', () {
      final json = _fullReportJson()
        ..remove('advancedJataka')
        ..remove('kujaDosha')
        ..remove('dasha')
        ..remove('vivahaKalaBala')
        ..remove('jataka');
      final report = CompatibilityReport.fromJson(json);
      expect(report.advancedJataka, isNull);
      expect(report.kujaDosha, isNull);
      expect(report.dasha, isNull);
      expect(report.vivahaKalaBala, isNull);
    });
  });

  group('Daivagna Parampara parsing (STEP 54/72)', () {
    test('INFORMATIONAL — declared values compared, never an incompatibility verdict', () {
      final dp = DaivagnaParampara.fromJson(_fullReportJson()['daivagnaParampara'] as Map<String, dynamic>);
      expect(dp.status, ParamparaComparisonStatus.informational);
      expect(dp.bride.gotra.customValue, 'Kashyapa');
      expect(dp.groom.gotra.customValue, 'Bharadwaj');
      expect(dp.comparison.fieldFindings, hasLength(1));
      expect(dp.comparison.fieldFindings.first.status, ParamparaFieldComparisonStatus.different);
    });

    test('a partner with no ParamparaProfile document is NOT_CALCULABLE, fields default to NOT_PROVIDED', () {
      final json = {
        'ruleVersion': 'DAIVAGNA_PARAMPARA_V1',
        'brideProfileId': 'a',
        'groomProfileId': 'b',
        'status': 'NOT_CALCULABLE',
        'reviewRequired': false,
        'reasonCode': 'PARTNER_PROFILE_MISSING',
        'explanation': 'One partner has no Parampara declarations at all.',
        'bride': {
          'status': 'NOT_CALCULABLE',
          'reviewRequired': false,
          'reasonCode': 'NO_PROFILE',
          'explanation': 'No ParamparaProfile document.',
          // gotra/pravara/kuladevata/kuladevi intentionally absent
        },
        'groom': {'status': 'CALCULATED', 'reviewRequired': false, 'reasonCode': 'OK', 'explanation': 'OK'},
        'comparison': {'status': 'NOT_CALCULABLE', 'reasonCode': 'PARTNER_PROFILE_MISSING', 'explanation': 'Missing.', 'fieldFindings': <dynamic>[]},
      };
      final dp = DaivagnaParampara.fromJson(json);
      expect(dp.status, ParamparaComparisonStatus.notCalculable);
      expect(dp.bride.status, AstrologyModuleStatus.notCalculable);
      expect(dp.bride.gotra.status, ParamparaValueStatus.notProvided);
      expect(dp.bride.gotra.customValue, isNull);
    });

    test('daivagnaParampara missing entirely parses to null on the report', () {
      final json = _fullReportJson()..remove('daivagnaParampara');
      final report = CompatibilityReport.fromJson(json);
      expect(report.daivagnaParampara, isNull);
    });
  });

  group('Discussion Points parsing (STEP 69 §11)', () {
    test('parses each point with its source/severity/message', () {
      final report = CompatibilityReport.fromJson(_fullReportJson());
      expect(report.discussionPoints, hasLength(1));
      expect(report.discussionPoints.first.source, 'ASHTAKOOTA');
      expect(report.discussionPoints.first.severity, 'REVIEW');
    });

    test('empty discussionPoints array parses to an empty list, not an error', () {
      final json = _fullReportJson()..['discussionPoints'] = <dynamic>[];
      final report = CompatibilityReport.fromJson(json);
      expect(report.discussionPoints, isEmpty);
    });

    test('missing discussionPoints key entirely parses to an empty list', () {
      final json = _fullReportJson()..remove('discussionPoints');
      final report = CompatibilityReport.fromJson(json);
      expect(report.discussionPoints, isEmpty);
    });
  });

  group('Old reports missing every STEP 51-69 field (pre-STEP-72 backend)', () {
    /// Exactly the shape `CompatibilityReport` supported before this step —
    /// only what the original south-indian-jataka-era backend ever sent.
    Map<String, dynamic> legacyReportJson() => {
          'id': 'old-report-1',
          'profileAId': 'profile-a',
          'profileBId': 'profile-b',
          'traditionalRoleA': 'BRIDE',
          'traditionalRoleB': 'GROOM',
          'ruleVersion': 'KARNATAKA_SOUTH_INDIAN_V1',
          'requestedInclude': ['JATAKA'],
          'notImplementedInclude': <String>[],
          'jataka': {
            'ruleVersion': 'KARNATAKA_SOUTH_INDIAN_V1',
            'brideProfileId': 'profile-a',
            'groomProfileId': 'profile-b',
            'matched': 6,
            'partial': 1,
            'notMatched': 3,
            'reviewRequired': 0,
            'notCalculable': 0,
            'normalizedPercentage': 65,
            'verdict': 'MODERATE',
            'verdictLabel': 'Moderate match',
            'criticalAlerts': <dynamic>[],
            'poruthams': <dynamic>[],
            'nakshatraBoundaryRiskOverride': false,
            // no ruleVersionId/ruleVersionStatus/ruleVersionChecksum
          },
          'createdAt': '2025-01-01T00:00:00.000Z',
          // no ashtakoota, advancedJataka, kujaDosha, dasha, daivagnaParampara,
          // vivahaKalaBala, astrologyCompatibility, profileCompatibility,
          // overallCompatibility, discussionPoints, overallStatus, disclaimer,
          // coverage, confidence at all.
        };

    test('parses without throwing', () {
      expect(() => CompatibilityReport.fromJson(legacyReportJson()), returnsNormally);
    });

    test('every STEP 51-69 field degrades to a safe default, never a crash or a fabricated value', () {
      final report = CompatibilityReport.fromJson(legacyReportJson());

      expect(report.ashtakoota, isNull);
      expect(report.advancedJataka, isNull);
      expect(report.kujaDosha, isNull);
      expect(report.dasha, isNull);
      expect(report.daivagnaParampara, isNull);
      expect(report.vivahaKalaBala, isNull);
      expect(report.astrologyCompatibility, isNull);
      expect(report.profileCompatibility, isNull);

      // overallCompatibility is never null on the type, but a legacy report
      // (no astrology/profile summary at all) correctly reports it as
      // NOT_CALCULABLE with a null percentage — never a fabricated 0%.
      expect(report.overallCompatibility.percentage, isNull);
      // AstrologyModuleStatus.unknown here, not notCalculable — the real
      // backend always sends overallCompatibility (it's non-nullable on
      // CompatibilityReportView), so this defensive fallback deliberately
      // never guesses a specific status for a shape it wasn't given.
      expect(report.overallCompatibility.status, AstrologyModuleStatus.unknown);

      expect(report.discussionPoints, isEmpty);
      expect(report.overallStatus, AstrologyModuleStatus.unknown);
      expect(report.disclaimer, isEmpty);
      expect(report.coverage, 0);
      expect(report.confidence, ConfidenceLevel.unknown);

      // The original, already-shipped Jataka section still parses correctly.
      expect(report.jataka!.matched, 6);
      expect(report.jataka!.ruleVersionId, isNull);
      expect(report.jataka!.ruleVersionStatus, '');
    });
  });
}
