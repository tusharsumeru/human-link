import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daivajna_census/data/api_client.dart';
import 'package:daivajna_census/data/repository.dart';
import 'package:daivajna_census/screens/south_indian_jataka_screen.dart';

/// Stands in for the real HTTP client so [Repository.southIndianJataka] can
/// be exercised against canned JSON without a network call. Overriding
/// [getJson] is possible because [ApiClient]'s methods are ordinary instance
/// methods, not `final`.
class _FakeApiClient extends ApiClient {
  _FakeApiClient(this.handler);
  final dynamic Function(String path) handler;
  int callCount = 0;

  @override
  Future<dynamic> getJson(String path) async {
    callCount++;
    return handler(path);
  }
}

Map<String, dynamic> _poruthamJson(String code, {String status = 'MATCHED', bool critical = false}) => {
      'code': code,
      'status': status,
      'score': status == 'MATCHED' ? 1 : (status == 'PARTIAL' ? 0.5 : 0),
      'ruleId': 'RULE_1',
      'details': <String, dynamic>{},
      'critical': critical,
      'explanation': '$code resolved to $status.',
      'reasonCode': '${code}_$status',
      'reviewRequired': status == 'REVIEW_REQUIRED',
    };

const _kPoruthamOrder = [
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
];

Map<String, dynamic> _karnatakaJson({
  String state = 'CALCULATED',
  String rajjuStatus = 'MATCHED',
  String vedhaStatus = 'MATCHED',
}) =>
    {
      'ruleVersion': 'KARNATAKA_SOUTH_INDIAN_V1',
      'totalPoruthams': 10,
      'matchedCount': 8,
      'partialCount': 1,
      'notMatchedCount': 1,
      'reviewRequiredCount': 0,
      'notCalculableCount': 0,
      'traditionalScore': {'matched': 8, 'total': 10},
      'normalizedScore': 0.85,
      'state': state,
      'isComplete': true,
      'requiresReview': state == 'REVIEW_REQUIRED',
      'rajjuStatus': rajjuStatus,
      'rajjuCritical': true,
      'vedhaStatus': vedhaStatus,
      'vedhaCritical': true,
      'results': [
        for (final code in _kPoruthamOrder)
          _poruthamJson(code, critical: code == 'RAJJU' || code == 'VEDHA'),
      ],
    };

Map<String, dynamic> _ashtakootaJson({int? earned = 29}) => {
      'ruleVersion': 'ASHTAKOOTA_V1',
      'brideProfileId': 'b1',
      'groomProfileId': 'g1',
      'earned': earned,
      'maximum': 36,
      'isComplete': earned != null,
      'requiresReview': false,
      'kootas': [
        {
          'code': 'VARNA',
          'status': 'MATCHED',
          'earned': earned == null ? null : 1,
          'maximum': 1,
          'ruleId': 'R1',
          'inputs': <String, dynamic>{},
          'explanation': 'Varna matched.',
          'reasonCode': 'VARNA_MATCHED',
          'reviewRequired': false,
        },
      ],
      'nakshatraBoundaryRiskOverride': false,
    };

Widget _app(String reportId) => MaterialApp(
      home: SouthIndianJatakaScreen(reportId: reportId, otherName: 'Asha'),
    );

/// A tall surface so the whole result (Karnataka card, critical checks,
/// 10-Porutham list, Ashtakoota) is actually built by the lazy ListView
/// instead of staying off-screen and un-findable. Must run inside the test
/// body (not setUp) — `setSurfaceSize` asserts it's called within a test.
Future<void> _useTallSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(400, 2400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

void main() {
  late Repository originalRepository;

  setUp(() {
    originalRepository = Repository.instance;
  });

  tearDown(() {
    Repository.instance = originalRepository;
  });

  testWidgets('shows a loading state before the result arrives', (tester) async {
    final fake = _FakeApiClient((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      return {
        'reportId': 'r1',
        'status': 'CALCULATED',
        'ruleVersion': 'KARNATAKA_SOUTH_INDIAN_V1',
        'karnatakaPorutham': _karnatakaJson(),
        'ashtakoota': _ashtakootaJson(),
        'overallAstrologyScore': null,
      };
    });
    Repository.instance = Repository(api: fake);

    await _useTallSurface(tester);
    await tester.pumpWidget(_app('r1'));
    await tester.pump(); // one frame — request still in flight

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('CALCULATED renders Karnataka score, Rajju/Vedha and Ashtakoota', (tester) async {
    final fake = _FakeApiClient((path) async {
      expect(path, '/api/v1/compatibility/reports/r1/south-indian-jataka');
      return {
        'reportId': 'r1',
        'status': 'CALCULATED',
        'ruleVersion': 'KARNATAKA_SOUTH_INDIAN_V1',
        'karnatakaPorutham': _karnatakaJson(),
        'ashtakoota': _ashtakootaJson(earned: 29),
        'overallAstrologyScore': null,
      };
    });
    Repository.instance = Repository(api: fake);

    await _useTallSurface(tester);
    await tester.pumpWidget(_app('r1'));
    await tester.pumpAndSettle();

    expect(find.text('Karnataka 10 Porutham'), findsOneWidget);
    expect(find.text('8/10 matched'), findsOneWidget);
    // Rajju/Vedha appear twice by design: once in the dedicated "Critical
    // checks" card (driven by the aggregate's own rajjuStatus/vedhaStatus),
    // and once more as items 9/10 of the ordered 10-Porutham list.
    expect(find.text('Rajju'), findsNWidgets(2));
    expect(find.text('Vedha'), findsNWidgets(2));
    expect(find.text('ASHTAKOOTA / 36 GUNA'), findsOneWidget);
    expect(find.text('29 / 36'), findsOneWidget);
    // No fabricated overall percentage — overallAstrologyScore was null.
    expect(find.text('Overall astrology score'), findsNothing);
  });

  testWidgets('the 10 Poruthams render in fixed Dina→Vedha order, not alphabetical', (tester) async {
    final fake = _FakeApiClient((_) async => {
          'reportId': 'r1',
          'status': 'CALCULATED',
          'ruleVersion': 'KARNATAKA_SOUTH_INDIAN_V1',
          'karnatakaPorutham': _karnatakaJson(),
          'ashtakoota': _ashtakootaJson(),
          'overallAstrologyScore': null,
        });
    Repository.instance = Repository(api: fake);

    await _useTallSurface(tester);
    await tester.pumpWidget(_app('r1'));
    await tester.pumpAndSettle();

    final expectedLabels = ['Dina', 'Gana', 'Mahendra', 'Stree Deergha', 'Yoni', 'Rashi', 'Rashi Adhipathi', 'Vashya'];
    final positions = expectedLabels.map((l) => tester.getTopLeft(find.text(l)).dy).toList();
    for (var i = 1; i < positions.length; i++) {
      expect(positions[i], greaterThan(positions[i - 1]), reason: 'expected $expectedLabels in order');
    }
  });

  testWidgets('Ashtakoota NOT_CALCULABLE shows an unavailable message, never 0/36 or 0%', (tester) async {
    final fake = _FakeApiClient((_) async => {
          'reportId': 'r1',
          'status': 'CALCULATED',
          'ruleVersion': 'KARNATAKA_SOUTH_INDIAN_V1',
          'karnatakaPorutham': _karnatakaJson(),
          'ashtakoota': _ashtakootaJson(earned: null),
          'overallAstrologyScore': null,
        });
    Repository.instance = Repository(api: fake);

    await _useTallSurface(tester);
    await tester.pumpWidget(_app('r1'));
    await tester.pumpAndSettle();

    expect(find.text('Ashtakoota calculation is currently unavailable.'), findsOneWidget);
    expect(find.text('0 / 36'), findsNothing);
    expect(find.textContaining('0%'), findsNothing);
  });

  testWidgets('REVIEW_REQUIRED renders a review notice, never success or failure', (tester) async {
    final fake = _FakeApiClient((_) async => {
          'reportId': 'r1',
          'status': 'REVIEW_REQUIRED',
          'ruleVersion': 'KARNATAKA_SOUTH_INDIAN_V1',
          'karnatakaPorutham': _karnatakaJson(state: 'REVIEW_REQUIRED'),
          'ashtakoota': _ashtakootaJson(),
          'overallAstrologyScore': null,
        });
    Repository.instance = Repository(api: fake);

    await _useTallSurface(tester);
    await tester.pumpWidget(_app('r1'));
    await tester.pumpAndSettle();

    expect(
      find.text('Some calculations require review because of birth-time uncertainty.'),
      findsOneWidget,
    );
  });

  testWidgets('NOT_CALCULABLE renders the reason, never a fake score', (tester) async {
    final fake = _FakeApiClient((_) async => {
          'reportId': 'r1',
          'status': 'NOT_CALCULABLE',
          'ruleVersion': null,
          'karnatakaPorutham': null,
          'ashtakoota': null,
          'overallAstrologyScore': null,
        });
    Repository.instance = Repository(api: fake);

    await _useTallSurface(tester);
    await tester.pumpWidget(_app('r1'));
    await tester.pumpAndSettle();

    expect(find.text('Not calculable yet'), findsOneWidget);
    expect(find.textContaining('matched'), findsNothing);
  });

  testWidgets('API error shows a retry state, and Try again re-fetches', (tester) async {
    var attempt = 0;
    final fake = _FakeApiClient((_) async {
      attempt++;
      if (attempt == 1) {
        throw ApiException('Could not reach the server', statusCode: 500);
      }
      return {
        'reportId': 'r1',
        'status': 'CALCULATED',
        'ruleVersion': 'KARNATAKA_SOUTH_INDIAN_V1',
        'karnatakaPorutham': _karnatakaJson(),
        'ashtakoota': _ashtakootaJson(),
        'overallAstrologyScore': null,
      };
    });
    Repository.instance = Repository(api: fake);

    await _useTallSurface(tester);
    await tester.pumpWidget(_app('r1'));
    await tester.pumpAndSettle();

    expect(find.text('Could not reach the server'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(attempt, 2);
    expect(find.text('Karnataka 10 Porutham'), findsOneWidget);
  });

  testWidgets('never shows raw birth data (DOB, time, coordinates)', (tester) async {
    final fake = _FakeApiClient((_) async => {
          'reportId': 'r1',
          'status': 'CALCULATED',
          'ruleVersion': 'KARNATAKA_SOUTH_INDIAN_V1',
          'karnatakaPorutham': _karnatakaJson(),
          'ashtakoota': _ashtakootaJson(),
          'overallAstrologyScore': null,
        });
    Repository.instance = Repository(api: fake);

    await _useTallSurface(tester);
    await tester.pumpWidget(_app('r1'));
    await tester.pumpAndSettle();

    for (final needle in ['latitude', 'longitude', 'date of birth', 'time of birth']) {
      expect(find.textContaining(needle, findRichText: true), findsNothing);
    }
  });
}
