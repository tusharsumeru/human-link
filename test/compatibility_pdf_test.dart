import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider/path_provider.dart';

import 'package:daivajna_census/data/models/compatibility_models.dart';
import 'package:daivajna_census/services/compatibility_pdf.dart';
import 'package:daivajna_census/services/compatibility_pdf_export.dart';

/// STEP 77-78 — smoke tests for the actual `pw.Document` generation: this
/// only needs to confirm the PDF layer builds successfully (non-empty bytes,
/// no exception) for a full report, a report with every optional module
/// null, and a pre-STEP-72 legacy report. Exact text content is covered far
/// more cheaply by compatibility_pdf_content_test.dart's pure builder tests.
Map<String, dynamic> _minimalReportJson({bool includeModules = true}) => {
      'id': 'report-1',
      'profileAId': 'profile-a',
      'profileBId': 'profile-b',
      'ruleVersion': 'KARNATAKA_SOUTH_INDIAN_V1',
      'requestedInclude': ['JATAKA'],
      'notImplementedInclude': <String>[],
      if (includeModules)
        'jataka': {
          'ruleVersion': 'KARNATAKA_SOUTH_INDIAN_V1', 'brideProfileId': 'a', 'groomProfileId': 'b',
          'matched': 7, 'partial': 1, 'notMatched': 2, 'reviewRequired': 0, 'notCalculable': 0,
          'normalizedPercentage': 75, 'verdict': 'GOOD', 'verdictLabel': 'Good match',
          'criticalAlerts': <dynamic>[],
          'poruthams': [
            {'code': 'DINA', 'status': 'MATCHED', 'ruleId': 'R1', 'details': <String, dynamic>{}, 'explanation': 'Matched.'},
          ],
          'nakshatraBoundaryRiskOverride': false,
        },
      if (includeModules)
        'ashtakoota': {
          'ruleVersion': 'V1', 'brideProfileId': 'a', 'groomProfileId': 'b', 'earned': 28, 'maximum': 36,
          'isComplete': true, 'requiresReview': false,
          'kootas': [
            {'code': 'NADI', 'status': 'NOT_MATCHED', 'earned': 0, 'maximum': 8, 'ruleId': 'K1', 'inputs': <String, dynamic>{}, 'explanation': 'No match.'},
          ],
          'nakshatraBoundaryRiskOverride': false,
        },
      if (includeModules)
        'advancedJataka': {
          'ruleVersion': 'V1', 'brideProfileId': 'a', 'groomProfileId': 'b', 'status': 'SUPPORTIVE',
          'reviewRequired': false, 'reasonCode': 'OK', 'explanation': 'OK',
          'bride': {'natal': <String, dynamic>{}, 'navamsha': <String, dynamic>{}},
          'groom': {'natal': <String, dynamic>{}, 'navamsha': <String, dynamic>{}},
        },
      if (includeModules)
        'kujaDosha': {
          'ruleVersion': 'V1', 'brideProfileId': 'a', 'groomProfileId': 'b', 'status': 'NOT_PRESENT',
          'reviewRequired': false, 'reasonCode': 'OK', 'explanation': 'OK',
          'bride': {'status': 'NOT_PRESENT', 'reviewRequired': false, 'reasonCode': 'OK', 'explanation': 'OK', 'cancellationFindings': <dynamic>[]},
          'groom': {'status': 'NOT_PRESENT', 'reviewRequired': false, 'reasonCode': 'OK', 'explanation': 'OK', 'cancellationFindings': <dynamic>[]},
          'comparison': {'status': 'NOT_PRESENT', 'reasonCode': 'OK', 'explanation': 'OK'},
        },
      if (includeModules)
        'dasha': {
          'ruleVersion': 'V1', 'assessmentDate': '2026-01-01T00:00:00.000Z', 'brideProfileId': 'a', 'groomProfileId': 'b',
          'status': 'NEUTRAL', 'reviewRequired': false, 'reasonCode': 'OK', 'explanation': 'OK',
          'bride': {'status': 'CALCULATED', 'reviewRequired': false, 'reasonCode': 'OK', 'explanation': 'OK', 'mahadashas': <dynamic>[], 'antardashas': <dynamic>[], 'sandhiFindings': <dynamic>[]},
          'groom': {'status': 'CALCULATED', 'reviewRequired': false, 'reasonCode': 'OK', 'explanation': 'OK', 'mahadashas': <dynamic>[], 'antardashas': <dynamic>[], 'sandhiFindings': <dynamic>[]},
          'comparison': {'status': 'NEUTRAL', 'reasonCode': 'OK', 'explanation': 'OK'},
        },
      if (includeModules)
        'vivahaKalaBala': {
          'ruleVersion': 'V1', 'assessmentDate': '2026-01-01T00:00:00.000Z', 'brideProfileId': 'a', 'groomProfileId': 'b',
          'status': 'NOT_CALCULABLE', 'reviewRequired': false, 'reasonCode': 'OK', 'explanation': 'OK',
          'bride': {'status': 'CALCULATED', 'reviewRequired': false, 'reasonCode': 'OK', 'explanation': 'OK'},
          'groom': {'status': 'CALCULATED', 'reviewRequired': false, 'reasonCode': 'OK', 'explanation': 'OK'},
          'guruBala': {'status': 'REVIEW_REQUIRED', 'reviewRequired': true, 'reasonCode': 'OK', 'explanation': 'OK', 'bride': {'status': 'REVIEW_REQUIRED', 'reviewRequired': true, 'reasonCode': 'OK', 'explanation': 'OK'}, 'groom': {'status': 'REVIEW_REQUIRED', 'reviewRequired': true, 'reasonCode': 'OK', 'explanation': 'OK'}},
          'shukraBala': {'status': 'REVIEW_REQUIRED', 'reviewRequired': true, 'reasonCode': 'OK', 'explanation': 'OK', 'bride': {'status': 'REVIEW_REQUIRED', 'reviewRequired': true, 'reasonCode': 'OK', 'explanation': 'OK'}, 'groom': {'status': 'REVIEW_REQUIRED', 'reviewRequired': true, 'reasonCode': 'OK', 'explanation': 'OK'}},
          'chandraBala': {'status': 'REVIEW_REQUIRED', 'reviewRequired': true, 'reasonCode': 'OK', 'explanation': 'OK', 'bride': {'status': 'REVIEW_REQUIRED', 'reviewRequired': true, 'reasonCode': 'OK', 'explanation': 'OK'}, 'groom': {'status': 'REVIEW_REQUIRED', 'reviewRequired': true, 'reasonCode': 'OK', 'explanation': 'OK'}},
          'taraBala': {'status': 'REVIEW_REQUIRED', 'reviewRequired': true, 'reasonCode': 'OK', 'explanation': 'OK', 'bride': {'status': 'REVIEW_REQUIRED', 'reviewRequired': true, 'reasonCode': 'OK', 'explanation': 'OK'}, 'groom': {'status': 'REVIEW_REQUIRED', 'reviewRequired': true, 'reasonCode': 'OK', 'explanation': 'OK'}},
          'gochar': {'status': 'CALCULATED', 'reviewRequired': false, 'reasonCode': 'OK', 'explanation': 'OK'},
          'dashaTiming': {'status': 'CALCULATED', 'reviewRequired': false, 'reasonCode': 'OK', 'explanation': 'OK', 'bride': {'status': 'CALCULATED', 'reviewRequired': false, 'reasonCode': 'OK', 'explanation': 'OK'}, 'groom': {'status': 'CALCULATED', 'reviewRequired': false, 'reasonCode': 'OK', 'explanation': 'OK'}},
        },
      if (includeModules)
        'daivagnaParampara': {
          'ruleVersion': 'V1', 'brideProfileId': 'a', 'groomProfileId': 'b', 'status': 'INFORMATIONAL',
          'reviewRequired': false, 'reasonCode': 'OK', 'explanation': 'OK',
          'bride': {'status': 'CALCULATED', 'reviewRequired': false, 'reasonCode': 'OK', 'explanation': 'OK', 'gotra': {'status': 'PROVIDED', 'customValue': 'Kashyapa'}},
          'groom': {'status': 'CALCULATED', 'reviewRequired': false, 'reasonCode': 'OK', 'explanation': 'OK', 'gotra': {'status': 'PROVIDED', 'customValue': 'Bharadwaj'}},
          'comparison': {'status': 'INFORMATIONAL', 'reasonCode': 'OK', 'explanation': 'OK', 'fieldFindings': <dynamic>[]},
        },
      if (includeModules)
        'kundliChart': {
          'brideProfileId': 'a',
          'groomProfileId': 'b',
          'bride': {
            'lagnaId': 1,
            'lagnaRashiName': 'Mesha',
            'planets': [
              {'graha': 'SUN', 'rashiId': 1, 'rashiName': 'Mesha', 'nakshatraId': 1, 'nakshatraName': 'Ashwini', 'nakshatraPada': 1, 'isRetrograde': false},
            ],
            'navamsha': [
              {'point': 'LAGNA', 'rashiId': 1, 'rashiName': 'Mesha'},
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
      'overallCompatibility': {
        'percentage': includeModules ? 81 : null,
        'status': includeModules ? 'CALCULATED' : 'NOT_CALCULABLE',
        'reasonCode': 'OK',
        'explanation': 'OK',
        'profilePercentage': includeModules ? 84 : null,
        'astrologyPercentage': includeModules ? 78 : null,
        'profileWeight': 50,
        'astrologyWeight': 50,
      },
      'discussionPoints': includeModules
          ? [
              {'code': 'X', 'source': 'ASHTAKOOTA', 'severity': 'REVIEW', 'message': 'Nadi Koota did not match.'},
            ]
          : <dynamic>[],
      'overallStatus': includeModules ? 'CALCULATED' : 'UNKNOWN',
      'disclaimer': 'This compatibility result is an initial matchmaking assessment.',
      'coverage': includeModules ? 85 : 0,
      'confidence': includeModules ? 'HIGH' : 'UNKNOWN',
      'createdAt': '2026-01-01T00:00:00.000Z',
    };

void main() {
  test('a full report with every module present generates a non-empty PDF', () async {
    final report = CompatibilityReport.fromJson(_minimalReportJson());
    final bytes = await buildCompatibilityPdfBytes(report: report, person1Name: 'Priya', person2Name: 'Asha');
    expect(bytes, isNotEmpty);
    // %PDF is the standard PDF file signature.
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });

  test('a report with every optional module null does not crash PDF generation', () async {
    final report = CompatibilityReport.fromJson(_minimalReportJson(includeModules: false));
    final bytes = await buildCompatibilityPdfBytes(report: report, person1Name: 'Priya', person2Name: 'Asha');
    expect(bytes, isNotEmpty);
  });

  test('a legacy pre-STEP-72 report (only Jataka, nothing else) does not crash PDF generation', () async {
    final legacyJson = {
      'id': 'old-report-1',
      'profileAId': 'profile-a',
      'profileBId': 'profile-b',
      'ruleVersion': 'KARNATAKA_SOUTH_INDIAN_V1',
      'requestedInclude': ['JATAKA'],
      'notImplementedInclude': <String>[],
      'jataka': {
        'ruleVersion': 'KARNATAKA_SOUTH_INDIAN_V1', 'brideProfileId': 'a', 'groomProfileId': 'b',
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
    final report = CompatibilityReport.fromJson(legacyJson);
    final bytes = await buildCompatibilityPdfBytes(report: report, person1Name: 'Priya', person2Name: '');
    expect(bytes, isNotEmpty);
  });

  test('empty person names never crash PDF generation', () async {
    final report = CompatibilityReport.fromJson(_minimalReportJson());
    final bytes = await buildCompatibilityPdfBytes(report: report, person1Name: '', person2Name: '');
    expect(bytes, isNotEmpty);
  });

  group('filename sanitization', () {
    test('spaces become underscores and unsafe characters are stripped', () {
      expect(sanitizeFileNamePart('Priya Sharma!'), 'Priya_Sharma');
      expect(sanitizeFileNamePart('  Asha/Rao?  '), 'AshaRao');
    });

    test('an empty/entirely-unsafe name falls back to "Member", never a blank segment', () {
      expect(sanitizeFileNamePart(''), 'Member');
      expect(sanitizeFileNamePart('###'), 'Member');
    });

    test('the full filename follows the Marriage_Compatibility_<P1>_<P2>.pdf pattern', () {
      expect(compatibilityPdfFileName('Priya Sharma', 'Asha Rao'), 'Marriage_Compatibility_Priya_Sharma_Asha_Rao.pdf');
    });
  });

  group('saveCompatibilityPdf — real dart:io File/Directory calls', () {
    // Plain (non-widget) tests: real dart:io async File/Directory calls are
    // reliable here, unlike from inside a testWidgets pump cycle (see
    // compatibility_pdf_export.dart's own doc comment) — this is the
    // suite that actually exercises the default disk-writing implementation;
    // the dashboard's widget tests fake this function out entirely.
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('compat_pdf_export_test');
      documentsDirectoryProvider = () async => tempDir;
    });

    tearDown(() async {
      documentsDirectoryProvider = getApplicationDocumentsDirectory;
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    });

    test('writes the PDF under compatibility_reports/ with the sanitized filename', () async {
      final bytes = Uint8List.fromList([1, 2, 3, 4]);
      final file = await saveCompatibilityPdf(bytes: bytes, person1Name: 'Priya Sharma', person2Name: 'Asha Rao');

      expect(file.path, endsWith('compatibility_reports/Marriage_Compatibility_Priya_Sharma_Asha_Rao.pdf'));
      expect(await file.exists(), isTrue);
      expect(await file.readAsBytes(), bytes);
    });

    test('re-saving for the same pair overwrites rather than accumulating files', () async {
      await saveCompatibilityPdf(bytes: Uint8List.fromList([1]), person1Name: 'Priya', person2Name: 'Asha');
      final second = await saveCompatibilityPdf(bytes: Uint8List.fromList([1, 2, 3]), person1Name: 'Priya', person2Name: 'Asha');

      final reportsDir = Directory('${tempDir.path}/compatibility_reports');
      expect(reportsDir.listSync(), hasLength(1));
      expect(await second.readAsBytes(), [1, 2, 3]);
    });
  });
}
