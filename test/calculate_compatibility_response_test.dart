import 'package:flutter_test/flutter_test.dart';

import 'package:daivajna_census/data/api_client.dart';
import 'package:daivajna_census/data/models/compatibility_models.dart';
import 'package:daivajna_census/data/repository.dart';

/// Records every path passed to [getJson] so a test can assert a call never
/// happened, without a real network call.
class _FakeApiClient extends ApiClient {
  _FakeApiClient({this.getJsonHandler, this.postJsonHandler});
  final dynamic Function(String path)? getJsonHandler;
  final dynamic Function(String path, Map<String, dynamic> body)? postJsonHandler;
  final List<String> getJsonCalls = [];

  @override
  Future<dynamic> getJson(String path) async {
    getJsonCalls.add(path);
    if (getJsonHandler == null) throw ApiException('unexpected getJson call: $path');
    return getJsonHandler!(path);
  }

  @override
  Future<dynamic> postJson(String path, Map<String, dynamic> body) async {
    if (postJsonHandler == null) throw ApiException('unexpected postJson call: $path');
    return postJsonHandler!(path, body);
  }
}

void main() {
  group('CalculateCompatibilityResponse.fromJson', () {
    test('reads the real POST /calculate shape — "reportId", never "id"', () {
      // The backend's actual CalculateCompatibilityResponse type:
      // `{ reportId: string } & Partial<Record<ModuleStatusKey, ModuleResultStatus>>`.
      final response = CalculateCompatibilityResponse.fromJson({
        'reportId': 'saved-report-42',
        'jataka': 'CALCULATED',
        'verification': 'NOT_CALCULABLE',
      });

      expect(response.reportId, 'saved-report-42');
      expect(response.moduleStatuses['jataka'], 'CALCULATED');
      expect(response.moduleStatuses['verification'], 'NOT_CALCULABLE');
      // 'reportId' itself must never leak into moduleStatuses.
      expect(response.moduleStatuses.containsKey('reportId'), isFalse);
    });

    test('a response with no "reportId" key parses to an empty id, never a guess', () {
      final response = CalculateCompatibilityResponse.fromJson({'jataka': 'CALCULATED'});
      expect(response.reportId, '');
    });
  });

  group('Repository.calculateCompatibility', () {
    test('parses "reportId", not the unrelated "id" field some other endpoint might send', () async {
      final fake = _FakeApiClient(
        postJsonHandler: (path, body) async {
          expect(path, '/api/v1/compatibility/calculate');
          return {'reportId': 'r-999', 'jataka': 'CALCULATED'};
        },
      );
      final repo = Repository(api: fake);

      final response = await repo.calculateCompatibility(
        profileAId: 'a1',
        profileBId: 'b1',
        roleA: TraditionalRole.bride,
        roleB: TraditionalRole.groom,
      );

      expect(response.reportId, 'r-999');
    });
  });

  group('Repository.southIndianJataka — request path construction', () {
    test('constructs /reports/{reportId}/south-indian-jataka with the real id', () async {
      final fake = _FakeApiClient(
        getJsonHandler: (_) async => {
          'reportId': 'r-999',
          'status': 'CALCULATED',
          'ruleVersion': null,
          'karnatakaPorutham': null,
          'ashtakoota': null,
          'overallAstrologyScore': null,
        },
      );
      final repo = Repository(api: fake);

      await repo.southIndianJataka('r-999');

      expect(fake.getJsonCalls, ['/api/v1/compatibility/reports/r-999/south-indian-jataka']);
    });

    test('a missing reportId never reaches the network — no "/reports//south-indian-jataka"', () async {
      final fake = _FakeApiClient();
      final repo = Repository(api: fake);

      await expectLater(
        () => repo.southIndianJataka(''),
        throwsA(isA<ApiException>()),
      );
      expect(fake.getJsonCalls, isEmpty);
    });

    test('a whitespace-only reportId is treated the same as empty', () async {
      final fake = _FakeApiClient();
      final repo = Repository(api: fake);

      await expectLater(() => repo.southIndianJataka('   '), throwsA(isA<ApiException>()));
      expect(fake.getJsonCalls, isEmpty);
    });
  });

  group('Repository.compatibilityReport — same guard', () {
    test('a missing reportId never reaches the network — no "GET /reports/"', () async {
      final fake = _FakeApiClient();
      final repo = Repository(api: fake);

      await expectLater(() => repo.compatibilityReport(''), throwsA(isA<ApiException>()));
      expect(fake.getJsonCalls, isEmpty);
    });

    test('a real reportId builds the correct path', () async {
      final fake = _FakeApiClient(
        getJsonHandler: (_) async => {
          'id': 'r-999',
          'profileAId': 'a1',
          'profileBId': 'b1',
          'traditionalRoleA': 'BRIDE',
          'traditionalRoleB': 'GROOM',
          'ruleVersion': 'KARNATAKA_SOUTH_INDIAN_V1',
          'requestedInclude': ['JATAKA'],
          'notImplementedInclude': [],
          'jataka': null,
          'createdAt': null,
        },
      );
      final repo = Repository(api: fake);

      await repo.compatibilityReport('r-999');

      expect(fake.getJsonCalls, ['/api/v1/compatibility/reports/r-999']);
    });
  });
}
