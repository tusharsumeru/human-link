import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daivajna_census/app.dart';
import 'package:daivajna_census/data/api_client.dart';
import 'package:daivajna_census/data/repository.dart';

class _FakeApiClient extends ApiClient {
  Map<String, dynamic>? lastBody;

  @override
  Future<dynamic> postJson(String path, Map<String, dynamic> body) async {
    lastBody = body;
    return {'mode': 'accepted', 'member': {'name': 'Test'}, 'relationship': {}};
  }
}

void main() {
  testWidgets('App boots to a MaterialApp', (WidgetTester tester) async {
    await tester.pumpWidget(const DaivajnaApp());
    expect(find.byType(MaterialApp), findsWidgets);
  });

  test('addFamilyMember sends smartphone and phoneVerified booleans', () async {
    final api = _FakeApiClient();
    final repo = Repository(api: api);

    await repo.addFamilyMember(
      relation: 'father',
      name: 'Ramesh',
      gender: 'M',
      status: 'alive',
      phone: '9876543210',
      dob: '1962-04-11',
      smartphone: false,
      phoneVerified: true,
    );

    expect(api.lastBody, isNotNull);
    expect(api.lastBody!['smartphone'], isFalse);
    expect(api.lastBody!['phoneVerified'], isTrue);
  });
}
