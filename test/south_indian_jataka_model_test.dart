import 'package:flutter_test/flutter_test.dart';

import 'package:daivajna_census/data/models/compatibility_models.dart';
import 'package:daivajna_census/data/models/south_indian_jataka.dart';

Map<String, dynamic> _poruthamJson(
  String code, {
  String status = 'MATCHED',
  bool critical = false,
  String explanation = 'Some explanation',
  String reasonCode = 'CODE_MATCHED',
  bool reviewRequired = false,
}) =>
    {
      'code': code,
      'status': status,
      'score': status == 'MATCHED' ? 1 : null,
      'ruleId': 'RULE_1',
      'details': <String, dynamic>{},
      'critical': critical,
      'explanation': explanation,
      'reasonCode': reasonCode,
      'reviewRequired': reviewRequired,
    };

void main() {
  group('PoruthamResult.fromJson — new fields', () {
    test('parses explanation/reasonCode/reviewRequired/critical from the backend', () {
      final p = PoruthamResult.fromJson(_poruthamJson(
        'RAJJU',
        status: 'NOT_MATCHED',
        critical: true,
        explanation: 'Same Rajju on both sides.',
        reasonCode: 'RAJJU_NOT_MATCHED',
        reviewRequired: false,
      ));

      expect(p.explanation, 'Same Rajju on both sides.');
      expect(p.reasonCode, 'RAJJU_NOT_MATCHED');
      expect(p.critical, isTrue);
      expect(p.reviewRequired, isFalse);
      expect(p.status, PoruthamStatus.notMatched);
    });

    test('defaults new fields safely when the backend omits them', () {
      final p = PoruthamResult.fromJson({'code': 'DINA', 'status': 'MATCHED'});
      expect(p.explanation, '');
      expect(p.reasonCode, '');
      expect(p.critical, isFalse);
      expect(p.reviewRequired, isFalse);
    });
  });

  group('AstrologyModuleStatus.fromWire', () {
    test('maps all backend statuses, never inferring from a score', () {
      expect(AstrologyModuleStatus.fromWire('CALCULATED'), AstrologyModuleStatus.calculated);
      expect(AstrologyModuleStatus.fromWire('REVIEW_REQUIRED'), AstrologyModuleStatus.reviewRequired);
      expect(AstrologyModuleStatus.fromWire('NOT_CALCULABLE'), AstrologyModuleStatus.notCalculable);
      expect(AstrologyModuleStatus.fromWire('anything-else'), AstrologyModuleStatus.unknown);
    });
  });

  group('orderedPoruthams', () {
    test('always renders Dina→Vedha in the fixed order, never alphabetical', () {
      // Deliberately shuffled + reverse-alphabetical-ish input.
      final shuffled = [
        _poruthamJson('VEDHA'),
        _poruthamJson('DINA'),
        _poruthamJson('RAJJU'),
        _poruthamJson('VASHYA'),
        _poruthamJson('YONI'),
        _poruthamJson('GANA'),
        _poruthamJson('RASHI_ADHIPATHI'),
        _poruthamJson('MAHENDRA'),
        _poruthamJson('RASHI'),
        _poruthamJson('STREE_DEERGHA'),
      ].map(PoruthamResult.fromJson).toList();

      final ordered = orderedPoruthams(shuffled).map((p) => p.code).toList();

      expect(ordered, [
        'DINA',
        'GANA',
        'MAHENDRA',
        'STREE_DEERGHA',
        'YONI',
        'RASHI',
        'RASHI_ADHIPATHI',
        'VASHYA',
        'RAJJU',
        'VEDHA',
      ]);
    });
  });

  group('orderedKootas', () {
    test('renders Varna→Nadi in the fixed order', () {
      Map<String, dynamic> koota(String code) => {
            'code': code,
            'status': 'MATCHED',
            'earned': 1,
            'maximum': 1,
            'ruleId': 'R',
            'inputs': <String, dynamic>{},
            'explanation': '',
            'reasonCode': '',
            'reviewRequired': false,
          };
      final shuffled = [
        koota('NADI'),
        koota('VARNA'),
        koota('BHAKOOT'),
        koota('TARA'),
        koota('GANA'),
        koota('YONI'),
        koota('GRAHA_MAITRI'),
        koota('VASHYA'),
      ].map(KootaResult.fromJson).toList();

      final ordered = orderedKootas(shuffled).map((k) => k.code).toList();
      expect(ordered, ['VARNA', 'VASHYA', 'TARA', 'YONI', 'GRAHA_MAITRI', 'GANA', 'BHAKOOT', 'NADI']);
    });
  });

  group('KarnatakaPoruthamResult.fromJson', () {
    test('parses counts/state and exposes rajju/vedha as an independent gate', () {
      final json = {
        'ruleVersion': 'KARNATAKA_SOUTH_INDIAN_V1',
        'totalPoruthams': 10,
        'matchedCount': 7,
        'partialCount': 1,
        'notMatchedCount': 1,
        'reviewRequiredCount': 0,
        'notCalculableCount': 1,
        'traditionalScore': {'matched': 7, 'total': 10},
        'normalizedScore': 0.75,
        'state': 'CALCULATED',
        'isComplete': false,
        'requiresReview': false,
        'rajjuStatus': 'MATCHED',
        'rajjuCritical': true,
        'vedhaStatus': 'NOT_MATCHED',
        'vedhaCritical': true,
        'results': [
          _poruthamJson('RAJJU', status: 'MATCHED', critical: true, explanation: 'Different Rajju.'),
          _poruthamJson('VEDHA', status: 'NOT_MATCHED', critical: true, explanation: 'Vedha present.'),
        ],
      };

      final k = KarnatakaPoruthamResult.fromJson(json);

      expect(k.traditionalScoreMatched, 7);
      expect(k.traditionalScoreTotal, 10);
      expect(k.state, AstrologyModuleStatus.calculated);
      // rajjuStatus/vedhaStatus reuse the 5-value PoruthamStatus vocabulary
      // (matches backend `CompatibilityAggregate.rajjuStatus: PoruthamStatus`),
      // not the 3-value AstrologyModuleStatus used for the top-level status.
      expect(k.rajjuStatus, PoruthamStatus.matched);
      expect(k.vedhaStatus, PoruthamStatus.notMatched);
      expect(k.rajjuCritical, isTrue);
      expect(k.vedhaCritical, isTrue);
      expect(k.rajjuResult?.code, 'RAJJU');
      expect(k.vedhaResult?.code, 'VEDHA');
    });
  });

  group('AshtakootaResult — NOT_CALCULABLE handling', () {
    test('earned=null is exposed as unavailable, never a fabricated 0', () {
      final a = AshtakootaResult.fromJson({
        'system': 'ASHTAKOOTA_36_GUNA',
        'ruleVersion': '',
        'brideProfileId': 'b1',
        'groomProfileId': 'g1',
        'earned': null,
        'maximum': 36,
        'isComplete': false,
        'requiresReview': false,
        'kootas': [],
        'nakshatraBoundaryRiskOverride': false,
      });

      expect(a.earned, isNull);
      expect(a.isUnavailable, isTrue);
      expect(a.maximum, 36);
    });

    test('a real earned score is not treated as unavailable', () {
      final a = AshtakootaResult.fromJson({
        'ruleVersion': 'ASHTAKOOTA_V1',
        'brideProfileId': 'b1',
        'groomProfileId': 'g1',
        'earned': 29,
        'maximum': 36,
        'isComplete': true,
        'requiresReview': false,
        'kootas': [],
        'nakshatraBoundaryRiskOverride': false,
      });

      expect(a.earned, 29);
      expect(a.isUnavailable, isFalse);
    });
  });

  group('SouthIndianJatakaResult.fromJson', () {
    test('CALCULATED with both systems present', () {
      final r = SouthIndianJatakaResult.fromJson({
        'reportId': 'r1',
        'status': 'CALCULATED',
        'ruleVersion': 'KARNATAKA_SOUTH_INDIAN_V1',
        'karnatakaPorutham': {
          'ruleVersion': 'KARNATAKA_SOUTH_INDIAN_V1',
          'totalPoruthams': 10,
          'matchedCount': 8,
          'partialCount': 1,
          'notMatchedCount': 1,
          'reviewRequiredCount': 0,
          'notCalculableCount': 0,
          'traditionalScore': {'matched': 8, 'total': 10},
          'normalizedScore': 0.85,
          'state': 'CALCULATED',
          'isComplete': true,
          'requiresReview': false,
          'rajjuStatus': 'MATCHED',
          'rajjuCritical': true,
          'vedhaStatus': 'MATCHED',
          'vedhaCritical': true,
          'results': [],
        },
        'ashtakoota': null,
        'overallAstrologyScore': null,
      });

      expect(r.status, AstrologyModuleStatus.calculated);
      expect(r.karnatakaPorutham, isNotNull);
      expect(r.ashtakoota, isNull);
      expect(r.overallAstrologyScore, isNull);
    });

    test('REVIEW_REQUIRED is never silently converted to success or failure', () {
      final r = SouthIndianJatakaResult.fromJson({
        'reportId': 'r2',
        'status': 'REVIEW_REQUIRED',
        'ruleVersion': 'KARNATAKA_SOUTH_INDIAN_V1',
        'karnatakaPorutham': null,
        'ashtakoota': null,
        'overallAstrologyScore': null,
      });

      expect(r.status, AstrologyModuleStatus.reviewRequired);
    });

    test('NOT_CALCULABLE with nothing computed never fabricates a score', () {
      final r = SouthIndianJatakaResult.fromJson({
        'reportId': 'r3',
        'status': 'NOT_CALCULABLE',
        'ruleVersion': null,
        'karnatakaPorutham': null,
        'ashtakoota': null,
        'overallAstrologyScore': null,
      });

      expect(r.status, AstrologyModuleStatus.notCalculable);
      expect(r.karnatakaPorutham, isNull);
      expect(r.overallAstrologyScore, isNull);
    });

    test('overallAstrologyScore stays null even if the key is entirely absent', () {
      final r = SouthIndianJatakaResult.fromJson({
        'reportId': 'r4',
        'status': 'CALCULATED',
        'karnatakaPorutham': null,
        'ashtakoota': null,
      });
      expect(r.overallAstrologyScore, isNull);
    });
  });
}
