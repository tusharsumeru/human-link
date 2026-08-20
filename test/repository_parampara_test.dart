import 'package:flutter_test/flutter_test.dart';

import 'package:daivajna_census/data/api_client.dart';
import 'package:daivajna_census/data/repository.dart';

/// Covers `Repository.saveParamparaGotra` — added so the Gotra dropdown in
/// Edit Profile also populates the Parampara resource the Daivagna Parampara
/// compatibility comparison actually reads (previously it only ever wrote
/// the basic `User.gotra` field via `saveProfile`, so that comparison always
/// showed "Not provided" even for a member who'd filled in their Gotra).
class _FakeApiClient extends ApiClient {
  _FakeApiClient();
  final List<(String path, Map<String, dynamic> body)> putCalls = [];

  @override
  Future<dynamic> putJson(String path, Map<String, dynamic> body) async {
    putCalls.add((path, body));
    return <String, dynamic>{};
  }
}

void main() {
  late _FakeApiClient fake;
  late Repository repo;

  setUp(() {
    fake = _FakeApiClient();
    repo = Repository(api: fake);
  });

  test('saveParamparaGotra sends a PROVIDED/USER_DECLARED gotra to PUT /api/parampara/me', () async {
    await repo.saveParamparaGotra('Kashyapa');

    expect(fake.putCalls, hasLength(1));
    final (path, body) = fake.putCalls.single;
    expect(path, '/api/parampara/me');
    expect(body, {
      'gotra': {'status': 'PROVIDED', 'source': 'USER_DECLARED', 'customValue': 'Kashyapa'},
    });
  });

  test('saveParamparaGotra never touches kuladevata/pravara/kuladevi — only gotra is sent', () async {
    await repo.saveParamparaGotra('Bharadwaj');

    final (_, body) = fake.putCalls.single;
    expect(body.containsKey('kuladevata'), isFalse);
    expect(body.containsKey('pravara'), isFalse);
    expect(body.containsKey('kuladevi'), isFalse);
  });

  test('a null/blank value clears the declaration to NOT_PROVIDED, never sends an empty customValue', () async {
    await repo.saveParamparaGotra(null);
    await repo.saveParamparaGotra('   ');

    expect(fake.putCalls, hasLength(2));
    for (final (_, body) in fake.putCalls) {
      expect(body['gotra'], {'status': 'NOT_PROVIDED'});
    }
  });

  test('saveKuladevata still works unchanged (regression check)', () async {
    await repo.saveKuladevata('Shree Mahalasa');

    final (path, body) = fake.putCalls.single;
    expect(path, '/api/parampara/me');
    expect(body, {
      'kuladevata': {'status': 'PROVIDED', 'source': 'USER_DECLARED', 'customValue': 'Shree Mahalasa'},
    });
  });
}
