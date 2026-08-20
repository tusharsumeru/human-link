import 'package:flutter_test/flutter_test.dart';

import 'package:daivajna_census/data/models/compatibility_astrology_modules.dart';
import 'package:daivajna_census/data/models/compatibility_models.dart';
import 'package:daivajna_census/data/models/south_indian_jataka.dart';
import 'package:daivajna_census/services/compatibility_pdf_content.dart';

/// STEP 77-78 — unit tests for the PDF's content-model builders (plain
/// strings/rows, no PDF rendering involved) — the fast, reliable way to
/// assert "X appears in the PDF" without parsing generated PDF bytes, since
/// the same lines/rows this test checks are exactly what compatibility_pdf.dart
/// feeds into the page widgets.
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
        'poruthams': [
          {'code': 'DINA', 'status': 'MATCHED', 'ruleId': 'R1', 'details': <String, dynamic>{}, 'explanation': 'Dina matched.'},
          {'code': 'RAJJU', 'status': 'NOT_MATCHED', 'ruleId': 'R2', 'details': <String, dynamic>{}, 'explanation': 'Rajju mismatch.'},
        ],
        'nakshatraBoundaryRiskOverride': false,
      },
      'ashtakoota': {
        'ruleVersion': 'ASHTAKOOTA_V1',
        'brideProfileId': 'profile-a',
        'groomProfileId': 'profile-b',
        'earned': 28,
        'maximum': 36,
        'isComplete': true,
        'requiresReview': false,
        'kootas': [
          {'code': 'NADI', 'status': 'NOT_MATCHED', 'earned': 0, 'maximum': 8, 'ruleId': 'K1', 'inputs': <String, dynamic>{}, 'explanation': 'Nadi did not match.'},
          {'code': 'VARNA', 'status': 'MATCHED', 'earned': 1, 'maximum': 1, 'ruleId': 'K2', 'inputs': <String, dynamic>{}, 'explanation': 'Varna matched.'},
        ],
        'nakshatraBoundaryRiskOverride': false,
      },
      'advancedJataka': {
        'ruleVersion': 'ADVANCED_JATAKA_V1',
        'brideProfileId': 'profile-a',
        'groomProfileId': 'profile-b',
        'status': 'SUPPORTIVE',
        'reviewRequired': false,
        'reasonCode': 'FINDINGS_COMPUTED',
        'explanation': 'Advanced Jataka findings computed.',
        'bride': {
          'natal': {
            'lagna': {'code': 'LAGNA', 'status': 'CALCULATED', 'reasonCode': 'OK', 'explanation': 'Lagna is Leo.', 'reviewRequired': false},
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
          'fromLagna': {'reference': 'LAGNA', 'status': 'CALCULATED', 'marsHouse': 7, 'affected': true, 'reasonCode': 'OK', 'explanation': 'House 7 is affected.'},
          'relevantMarsPlacements': {'rashiId': 1, 'rashiName': 'Aries'},
          'cancellationFindings': [
            {'ruleId': 'MARS_OWN_HOUSE', 'explanation': 'Mars is in its own house, cancelling the dosha.'},
          ],
        },
        'groom': {'status': 'NOT_PRESENT', 'reviewRequired': false, 'reasonCode': 'NO_DOSHA', 'explanation': 'No active dosha.', 'cancellationFindings': <dynamic>[]},
        'comparison': {'status': 'BALANCED_WITH_PARTNER', 'reasonCode': 'BOTH_ACTIVE', 'explanation': 'Both bride and groom have an active dosha.'},
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
          'reasonCode': 'OK',
          'explanation': 'Timeline calculated.',
          'birthNakshatraName': 'Krittika',
          'mahadashas': [
            {'lord': 'VENUS', 'startDate': '2020-01-01T00:00:00.000Z', 'endDate': '2040-01-01T00:00:00.000Z', 'durationYears': 20, 'sequenceIndex': 0},
          ],
          'currentMahadasha': {'lord': 'VENUS', 'startDate': '2020-01-01T00:00:00.000Z', 'endDate': '2040-01-01T00:00:00.000Z', 'durationYears': 20, 'sequenceIndex': 0},
          'antardashas': <dynamic>[],
          'sandhiFindings': <dynamic>[],
        },
        'groom': {'status': 'CALCULATED', 'reviewRequired': false, 'reasonCode': 'OK', 'explanation': 'Timeline calculated.', 'mahadashas': <dynamic>[], 'antardashas': <dynamic>[], 'sandhiFindings': <dynamic>[]},
        'comparison': {'status': 'NEUTRAL', 'reasonCode': 'NEUTRAL_PAIRING', 'explanation': 'Current Mahadasha lords are a neutral pairing.'},
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
          'reasonCode': 'OK',
          'explanation': 'Declarations read.',
          'gotra': {'status': 'PROVIDED', 'customValue': 'Kashyapa'},
          'pravara': {'status': 'NOT_PROVIDED'},
          'kuladevata': {'status': 'PROVIDED', 'customValue': 'Shree Mahalasa'},
          'kuladevi': {'status': 'NOT_PROVIDED'},
        },
        'groom': {
          'status': 'CALCULATED',
          'reviewRequired': false,
          'reasonCode': 'OK',
          'explanation': 'Declarations read.',
          'gotra': {'status': 'PROVIDED', 'customValue': 'Bharadwaj'},
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
      'kundliChart': {
        'brideProfileId': 'profile-a',
        'groomProfileId': 'profile-b',
        'bride': {
          'lagnaId': 1,
          'lagnaRashiName': 'Mesha',
          'planets': [
            {'graha': 'SUN', 'rashiId': 1, 'rashiName': 'Mesha', 'nakshatraId': 1, 'nakshatraName': 'Ashwini', 'nakshatraPada': 1, 'isRetrograde': false},
            {'graha': 'RAHU', 'rashiId': 7, 'rashiName': 'Tula', 'nakshatraId': 8, 'nakshatraName': 'Pushya', 'nakshatraPada': 4, 'isRetrograde': true},
          ],
          'navamsha': [
            {'point': 'LAGNA', 'rashiId': 1, 'rashiName': 'Mesha'},
            {'point': 'SUN', 'rashiId': 2, 'rashiName': 'Vrishabha'},
          ],
        },
        'groom': {
          'lagnaId': 5,
          'lagnaRashiName': 'Simha',
          'planets': [
            {'graha': 'MOON', 'rashiId': 3, 'rashiName': 'Mithuna', 'nakshatraId': 4, 'nakshatraName': 'Rohini', 'nakshatraPada': 2, 'isRetrograde': false},
          ],
          'navamsha': <dynamic>[],
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
          'status': 'REVIEW_REQUIRED', 'reviewRequired': true, 'reasonCode': 'NO_RULE', 'explanation': 'No approved rule.',
          'bride': {'status': 'REVIEW_REQUIRED', 'reviewRequired': true, 'reasonCode': 'NO_RULE', 'explanation': 'No rule.'},
          'groom': {'status': 'REVIEW_REQUIRED', 'reviewRequired': true, 'reasonCode': 'NO_RULE', 'explanation': 'No rule.'},
        },
        'shukraBala': {
          'status': 'REVIEW_REQUIRED', 'reviewRequired': true, 'reasonCode': 'NO_RULE', 'explanation': 'No approved rule.',
          'bride': {'status': 'REVIEW_REQUIRED', 'reviewRequired': true, 'reasonCode': 'NO_RULE', 'explanation': 'No rule.'},
          'groom': {'status': 'REVIEW_REQUIRED', 'reviewRequired': true, 'reasonCode': 'NO_RULE', 'explanation': 'No rule.'},
        },
        'chandraBala': {
          'status': 'REVIEW_REQUIRED', 'reviewRequired': true, 'reasonCode': 'NO_RULE', 'explanation': 'No approved rule.',
          'bride': {'status': 'REVIEW_REQUIRED', 'reviewRequired': true, 'reasonCode': 'NO_RULE', 'explanation': 'No rule.'},
          'groom': {'status': 'REVIEW_REQUIRED', 'reviewRequired': true, 'reasonCode': 'NO_RULE', 'explanation': 'No rule.'},
        },
        'taraBala': {
          'status': 'REVIEW_REQUIRED', 'reviewRequired': true, 'reasonCode': 'NO_CONFIG', 'explanation': 'No approved config.',
          'bride': {'status': 'REVIEW_REQUIRED', 'reviewRequired': true, 'reasonCode': 'NO_CONFIG', 'explanation': 'No config.', 'taraPosition': 5},
          'groom': {'status': 'REVIEW_REQUIRED', 'reviewRequired': true, 'reasonCode': 'NO_CONFIG', 'explanation': 'No config.', 'taraPosition': 3},
        },
        'gochar': {
          'status': 'CALCULATED', 'reviewRequired': false, 'reasonCode': 'OK', 'explanation': 'Transit chart calculated.',
          'transitPositions': {'SUN': {'rashiId': 9, 'nakshatraId': 24, 'nakshatraPada': 2, 'isRetrograde': false}},
        },
        'dashaTiming': {
          'status': 'CALCULATED', 'reviewRequired': false, 'reasonCode': 'OK', 'explanation': 'OK',
          'bride': {'status': 'CALCULATED', 'reviewRequired': false, 'reasonCode': 'OK', 'explanation': 'OK', 'currentMahadashaLord': 'VENUS', 'currentAntardashaLord': 'MOON'},
          'groom': {'status': 'CALCULATED', 'reviewRequired': false, 'reasonCode': 'OK', 'explanation': 'OK', 'currentMahadashaLord': 'SATURN', 'currentAntardashaLord': 'MERCURY'},
        },
      },
      'astrologyCompatibility': {
        'status': 'CALCULATED', 'reasonCode': 'OK', 'explanation': 'OK', 'primarySystem': 'KARNATAKA_SOUTH_INDIAN', 'percentage': 78,
        'karnatakaPorutham': {'matched': 7, 'partial': 1, 'notMatched': 2, 'calculable': 10, 'total': 10, 'percentage': 78},
        'ashtakoota': {'earned': 28, 'maximum': 36, 'percentage': 77.78, 'isComplete': true},
      },
      'profileCompatibility': {
        'ruleVersion': 'PROFILE_COMPATIBILITY_V1', 'profileAId': 'a', 'profileBId': 'b', 'status': 'CALCULATED',
        'reasonCode': 'OK', 'explanation': 'Calculated from the questionnaire answers.', 'percentage': 84, 'coverage': 92, 'confidence': 'HIGH',
        'categories': [
          {'category': 'CORE_VALUES', 'weight': 20, 'score': 90, 'coverage': 100, 'answeredQuestions': 5, 'totalQuestions': 5, 'status': 'CALCULATED', 'questionResults': <dynamic>[], 'dealBreakers': <dynamic>[]},
        ],
        'dealBreakers': <dynamic>[],
      },
      'overallCompatibility': {
        'percentage': 81, 'status': 'CALCULATED', 'reasonCode': 'OK', 'explanation': 'Weighted 50/50.',
        'profilePercentage': 84, 'astrologyPercentage': 78, 'profileWeight': 50, 'astrologyWeight': 50,
      },
      'discussionPoints': [
        {'code': 'ASHTAKOOTA_NADI_MISMATCH', 'source': 'ASHTAKOOTA', 'severity': 'REVIEW', 'message': 'Nadi Koota did not match.'},
      ],
      'overallStatus': 'CALCULATED',
      'disclaimer': 'This compatibility result is an initial matchmaking assessment. It is not a definitive prediction.',
      'coverage': 85,
      'confidence': 'HIGH',
      'createdAt': '2026-01-01T00:00:00.000Z',
    };

Map<String, dynamic> _legacyReportJson() => {
      'id': 'old-report-1',
      'profileAId': 'profile-a',
      'profileBId': 'profile-b',
      'ruleVersion': 'KARNATAKA_SOUTH_INDIAN_V1',
      'requestedInclude': ['JATAKA'],
      'notImplementedInclude': <String>[],
      'jataka': {
        'ruleVersion': 'KARNATAKA_SOUTH_INDIAN_V1', 'brideProfileId': 'profile-a', 'groomProfileId': 'profile-b',
        'matched': 6, 'partial': 1, 'notMatched': 3, 'reviewRequired': 0, 'notCalculable': 0,
        'normalizedPercentage': null, 'verdict': 'MODERATE', 'verdictLabel': 'Moderate match',
        'criticalAlerts': <dynamic>[], 'poruthams': <dynamic>[], 'nakshatraBoundaryRiskOverride': false,
      },
      'overallCompatibility': {
        'percentage': null, 'status': 'NOT_CALCULABLE', 'reasonCode': 'NO_INPUTS', 'explanation': '',
        'profilePercentage': null, 'astrologyPercentage': null, 'profileWeight': 50, 'astrologyWeight': 50,
      },
      'discussionPoints': <dynamic>[],
      'overallStatus': 'UNKNOWN',
      'disclaimer': '',
      'coverage': 0,
      'confidence': 'UNKNOWN',
    };

void main() {
  final report = CompatibilityReport.fromJson(_fullReportJson());
  final legacy = CompatibilityReport.fromJson(_legacyReportJson());

  group('Overall / Profile / Astrology summary', () {
    test('overall, profile and astrology percentages all appear', () {
      final rows = overallSummaryRows(report);
      expect(rows, contains(equals(['Overall Compatibility', '81%'])));
      expect(rows, contains(equals(['Profile Compatibility', '84%'])));
      expect(rows, contains(equals(['Astrology Compatibility', '78%'])));
      expect(rows, contains(equals(['Status', 'Calculated'])));
    });

    test('null percentages never become 0%', () {
      final rows = overallSummaryRows(legacy);
      expect(rows, contains(equals(['Overall Compatibility', kNotAvailable])));
      expect(rows.toString(), isNot(contains('0%')));
    });

    test('profile compatibility lines include percentage, coverage and category results', () {
      final lines = profileCompatibilityLines(report.profileCompatibility);
      expect(lines.any((l) => l.contains('84%')), isTrue);
      expect(lines.any((l) => l.contains('92%')), isTrue);
      expect(lines.any((l) => l.contains('Core Values')), isTrue);
    });

    test('missing profile compatibility never becomes 0%', () {
      final lines = profileCompatibilityLines(null);
      expect(lines.join(), isNot(contains('0%')));
      expect(lines.join(), contains('could not be calculated'));
    });
  });

  group('Karnataka 10 Porutham', () {
    test('summary and Porutham rows appear', () {
      final summary = karnatakaSummaryLines(report.jataka).join(' ');
      expect(summary, contains('7/10 matched'));
      expect(summary, contains('75%'));
      final rows = karnatakaPoruthamRows(report.jataka);
      expect(rows.any((r) => r[0] == 'Dina' && r[1] == 'Matched'), isTrue);
      expect(rows.any((r) => r[0] == 'Rajju' && r[1] == 'Not Matched'), isTrue);
    });

    test('missing normalizedPercentage is Not Available, never 0%', () {
      final summary = karnatakaSummaryLines(legacy.jataka).join(' ');
      expect(summary, contains(kNotAvailable));
      expect(summary, isNot(contains('0%')));
    });

    test('missing Jataka entirely does not crash', () {
      expect(karnatakaSummaryLines(null), isNotEmpty);
      expect(karnatakaPoruthamRows(null), isEmpty);
    });
  });

  group('Ashtakoota 36 Guna', () {
    test('score and Koota rows appear, including Nadi\'s real result', () {
      final summary = ashtakootaSummaryLines(report.ashtakoota, report.astrologyCompatibility?.ashtakoota).join(' ');
      expect(summary, contains('28 / 36'));
      final rows = ashtakootaKootaRows(report.ashtakoota);
      expect(rows.any((r) => r[0] == 'Nadi' && r[1] == '0/8' && r[2] == 'Not Matched'), isTrue);
      expect(rows.any((r) => r[0] == 'Varna' && r[1] == '1/1'), isTrue);
    });

    test('incomplete Ashtakoota never shows a fabricated 0/36', () {
      final unavailable = AshtakootaResult.fromJson({
        'ruleVersion': 'V1', 'brideProfileId': 'a', 'groomProfileId': 'b', 'earned': null, 'maximum': 36,
        'isComplete': false, 'requiresReview': true, 'kootas': <dynamic>[], 'nakshatraBoundaryRiskOverride': false,
      });
      final summary = ashtakootaSummaryLines(unavailable, null).join(' ');
      expect(summary, isNot(contains('0 / 36')));
      expect(summary, isNot(contains('0/36')));
    });

    test('missing Ashtakoota entirely does not crash', () {
      expect(ashtakootaSummaryLines(null, null), isNotEmpty);
      expect(ashtakootaKootaRows(null), isEmpty);
    });
  });

  group('Advanced Jataka', () {
    test('summary and findings appear', () {
      final summary = advancedJatakaSummaryLines(report.advancedJataka).join(' ');
      expect(summary, contains('Supportive'));
      final rows = advancedJatakaFindingRows(report.advancedJataka!.bride);
      expect(rows.any((r) => r[0] == 'Lagna' && r[2].contains('Leo')), isTrue);
      // Every one of the 15 natal+navamsha labels renders even when empty.
      expect(rows, hasLength(15));
    });

    test('missing Advanced Jataka does not crash', () {
      expect(advancedJatakaSummaryLines(null), isNotEmpty);
      expect(advancedJatakaFindingRows(null), isEmpty);
    });
  });

  group('Kuja Dosha', () {
    test('bride/groom severity and cancellation findings appear using backend terminology', () {
      final summary = kujaDoshaSummaryLines(report.kujaDosha).join(' ');
      expect(summary, contains('Balanced With Partner'));
      final brideLines = kujaDoshaPartnerLines(report.kujaDosha!.bride).join(' ');
      expect(brideLines, contains('Moderate'));
      expect(brideLines, contains('cancelling the dosha'));
      final groomLines = kujaDoshaPartnerLines(report.kujaDosha!.groom).join(' ');
      expect(groomLines, contains('Not Present'));
    });

    test('missing Kuja Dosha does not crash', () {
      expect(kujaDoshaSummaryLines(null), isNotEmpty);
      expect(kujaDoshaPartnerLines(null), [kNotAvailable]);
    });
  });

  group('Dasha Compatibility', () {
    test('assessment date, Mahadasha/Antardasha and timeline appear', () {
      final summary = dashaSummaryLines(report.dasha).join(' ');
      expect(summary, contains('1 Jan 2026'));
      final brideLines = dashaPartnerLines(report.dasha!.bride).join(' ');
      expect(brideLines, contains('Current Mahadasha: Venus'));
      final timeline = dashaMahadashaTimelineRows(report.dasha!.bride);
      expect(timeline.any((r) => r[0] == 'Venus'), isTrue);
    });

    test('REVIEW_REQUIRED comparison status renders', () {
      final reviewDasha = DashaCompatibility.fromJson({
        ...(_fullReportJson()['dasha'] as Map<String, dynamic>),
        'status': 'REVIEW_REQUIRED',
        'comparison': {'status': 'REVIEW_REQUIRED', 'reasonCode': 'X', 'explanation': 'Needs review.'},
      });
      expect(dashaSummaryLines(reviewDasha).join(' '), contains('Review Required'));
    });

    test('missing Dasha does not crash', () {
      expect(dashaSummaryLines(null), isNotEmpty);
      expect(dashaPartnerLines(null), [kNotAvailable]);
      expect(dashaMahadashaTimelineRows(null), isEmpty);
    });
  });

  group('Vivaha Kala Bala', () {
    test('assessment date and every Bala/Gochar/Dasha-timing sub-section appear', () {
      final summary = vivahaKalaBalaSummaryLines(report.vivahaKalaBala).join(' ');
      expect(summary, contains('1 Jan 2026'));
      final detail = vivahaKalaBalaDetailLines(report.vivahaKalaBala!).join(' ');
      expect(detail, contains('Guru Bala'));
      expect(detail, contains('Shukra Bala'));
      expect(detail, contains('Chandra Bala'));
      expect(detail, contains('Tara Bala'));
      expect(detail, contains('Gochar'));
      expect(detail, contains('Dasha Timing'));
    });

    test('missing Vivaha Kala Bala does not crash', () {
      expect(vivahaKalaBalaSummaryLines(null), isNotEmpty);
    });
  });

  group('Daivagna Parampara', () {
    test('Gotra/Pravara/Kuladevata/Kuladevi and comparison findings appear', () {
      final brideRows = paramparaPartnerRows(report.daivagnaParampara!.bride);
      expect(brideRows, contains(equals(['Gotra', 'Kashyapa'])));
      expect(brideRows, contains(equals(['Pravara', 'Not provided'])));
      expect(brideRows, contains(equals(['Kuladevata', 'Shree Mahalasa'])));
      final summary = paramparaSummaryLines(report.daivagnaParampara).join(' ');
      expect(summary, contains('Informational'));
      expect(summary, contains('Different'));
    });

    test('missing declarations show "Not provided", never inferred', () {
      final groomRows = paramparaPartnerRows(report.daivagnaParampara!.groom);
      expect(groomRows, contains(equals(['Kuladevata', 'Not provided'])));
    });

    test('missing Parampara does not crash', () {
      expect(paramparaSummaryLines(null), isNotEmpty);
      expect(paramparaPartnerRows(null), isEmpty);
    });
  });

  group('Kundli Chart', () {
    test('summary line and Lagna + planet rows appear for both partners', () {
      final summary = kundliChartSummaryLines(report.kundliChart).join(' ');
      expect(summary, contains('D1'));

      final brideRows = kundliPlanetRows(report.kundliChart!.bride);
      expect(brideRows, contains(equals(['Lagna', 'Mesha', '', '', ''])));
      expect(brideRows, contains(equals(['Sun', 'Mesha', 'Ashwini', '1', ''])));
      expect(brideRows, contains(equals(['Rahu', 'Tula', 'Pushya', '4', 'Retrograde'])));

      final groomRows = kundliPlanetRows(report.kundliChart!.groom);
      expect(groomRows, contains(equals(['Lagna', 'Simha', '', '', ''])));
      expect(groomRows, contains(equals(['Moon', 'Mithuna', 'Rohini', '2', ''])));
    });

    test('D9 (Navamsha) rows appear only when the report actually has them', () {
      final brideNavamsha = kundliNavamshaRows(report.kundliChart!.bride);
      expect(brideNavamsha, contains(equals(['Lagna', 'Mesha'])));
      expect(brideNavamsha, contains(equals(['Sun', 'Vrishabha'])));

      // Groom's fixture has an empty navamsha list (no D9 data for this
      // report) — must produce an empty table, never a fabricated D9 Lagna.
      expect(kundliNavamshaRows(report.kundliChart!.groom), isEmpty);
    });

    test('missing Kundli chart entirely does not crash, and produces no rows', () {
      expect(kundliChartSummaryLines(null), isNotEmpty);
      expect(kundliPlanetRows(null), isEmpty);
      expect(kundliNavamshaRows(null), isEmpty);
    });
  });

  group('Discussion Points', () {
    test('every point renders, review severity flagged', () {
      final lines = discussionPointLines(report.discussionPoints);
      expect(lines, hasLength(1));
      expect(lines.first, contains('Nadi Koota did not match'));
      expect(lines.first, startsWith('[Review]'));
    });

    test('empty discussion points produce an empty list, not an error', () {
      expect(discussionPointLines(const []), isEmpty);
    });
  });

  group('Legacy report — every builder degrades safely', () {
    test('none of the builders throw, and none fabricate a percentage/score/0-36', () {
      final all = <String>[
        ...overallSummaryRows(legacy).expand((r) => r),
        ...profileCompatibilityLines(legacy.profileCompatibility),
        ...karnatakaSummaryLines(legacy.jataka),
        ...ashtakootaSummaryLines(legacy.ashtakoota, legacy.astrologyCompatibility?.ashtakoota),
        ...advancedJatakaSummaryLines(legacy.advancedJataka),
        ...kujaDoshaSummaryLines(legacy.kujaDosha),
        ...dashaSummaryLines(legacy.dasha),
        ...vivahaKalaBalaSummaryLines(legacy.vivahaKalaBala),
        ...paramparaSummaryLines(legacy.daivagnaParampara),
        ...kundliChartSummaryLines(legacy.kundliChart),
        ...discussionPointLines(legacy.discussionPoints),
      ].join(' | ');

      expect(all, isNot(contains('0%')));
      expect(all, isNot(contains('0/36')));
      expect(all, isNot(contains('0 / 36')));
    });
  });
}
