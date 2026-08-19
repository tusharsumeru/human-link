import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:daivajna_census/data/api_client.dart';
import 'package:daivajna_census/data/repository.dart';
import 'package:daivajna_census/screens/compatibility_check_screen.dart';
import 'package:daivajna_census/screens/south_indian_jataka_screen.dart';
import 'package:daivajna_census/services/auth_service.dart';

/// Handles both GET (prerequisites, then the South Indian Jataka fetch after
/// navigation) and POST (calculate) so the full tap → calculate → navigate →
/// fetch chain can be exercised without a real network call.
class _FakeApiClient extends ApiClient {
  _FakeApiClient({this.getJsonHandler, this.postJsonHandler});
  final dynamic Function(String path)? getJsonHandler;
  final dynamic Function(String path, Map<String, dynamic> body)? postJsonHandler;
  final List<String> getJsonCalls = [];
  final List<String> postJsonCalls = [];

  @override
  Future<dynamic> getJson(String path) async {
    getJsonCalls.add(path);
    if (getJsonHandler == null) throw ApiException('unexpected getJson call: $path');
    return getJsonHandler!(path);
  }

  @override
  Future<dynamic> postJson(String path, Map<String, dynamic> body) async {
    postJsonCalls.add(path);
    if (postJsonHandler == null) throw ApiException('unexpected postJson call: $path');
    return postJsonHandler!(path, body);
  }
}

Map<String, dynamic> _moduleJson(String status, {String? reason, int? coverage}) {
  final json = <String, dynamic>{'status': status, 'reason': reason};
  if (coverage != null) json['coverage'] = coverage;
  return json;
}

Map<String, dynamic> _prereqsJson({
  required String jatakaStatus,
  String? jatakaReason,
}) =>
    {
      'candidateProfileId': 'candidate-1',
      'overallStatus': jatakaStatus == 'READY' ? 'READY' : 'ACTION_REQUIRED',
      'jataka': _moduleJson(jatakaStatus, reason: jatakaReason),
      'profileCompatibility': _moduleJson('ACTION_REQUIRED', reason: 'INSUFFICIENT_PROFILE_DATA', coverage: 10),
      'familyCompatibility': _moduleJson('ACTION_REQUIRED', reason: 'YOUR_FAMILY_TREE_INCOMPLETE', coverage: 10),
      'personalityCompatibility':
          _moduleJson('UNAVAILABLE', reason: 'PERSONALITY_QUESTIONNAIRE_NOT_AVAILABLE', coverage: 0),
      'familyRelationship': _moduleJson('ACTION_REQUIRED', reason: 'YOUR_FAMILY_TREE_INCOMPLETE'),
      'verification': _moduleJson('UNAVAILABLE', reason: 'MATCH_VERIFICATION_UNAVAILABLE'),
    };

Map<String, dynamic> _southIndianJatakaJson(String reportId) => {
      'reportId': reportId,
      'status': 'CALCULATED',
      'ruleVersion': 'KARNATAKA_SOUTH_INDIAN_V1',
      'karnatakaPorutham': null,
      'ashtakoota': null,
      'overallAstrologyScore': null,
    };

Widget _app({AuthService? authService}) => MaterialApp(
      home: authService == null
          ? const CompatibilityCheckScreen(
              myProfileId: 'me-1',
              candidateProfileId: 'candidate-1',
              candidateName: 'Asha',
              candidateGender: 'F',
            )
          : ChangeNotifierProvider<AuthService>.value(
              value: authService,
              child: const CompatibilityCheckScreen(
                myProfileId: 'me-1',
                candidateProfileId: 'candidate-1',
                candidateName: 'Asha',
                candidateGender: 'F',
              ),
            ),
    );

/// Tall enough that both module cards are actually built by the lazy
/// ListView instead of staying off-screen and un-findable. Must run inside
/// the test body (not setUp) — `setSurfaceSize` asserts it's called within a
/// test.
Future<void> _useTallSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(400, 1600));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

void main() {
  late Repository originalRepository;

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  setUp(() {
    originalRepository = Repository.instance;
  });

  tearDown(() {
    Repository.instance = originalRepository;
  });

  testWidgets('only the implemented module cards render — Family/Personality/Verification are gone', (tester) async {
    final fake = _FakeApiClient(getJsonHandler: (_) async => _prereqsJson(jatakaStatus: 'READY'));
    Repository.instance = Repository(api: fake);

    await _useTallSurface(tester);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    for (final title in ['South Indian Jataka', 'Profile Compatibility']) {
      expect(find.text(title), findsOneWidget, reason: 'module card "$title" should still render');
    }
    // Family/Personality Compatibility have no backend engine yet, and
    // Family Relationship Check / Verification aren't compatibility modules
    // — none of the four should be offered as calculable options here.
    for (final title in [
      'Family Compatibility',
      'Personality Compatibility',
      'Family Relationship Check',
      'Verification',
    ]) {
      expect(find.text(title), findsNothing, reason: 'module card "$title" should no longer render');
    }
  });

  testWidgets('Jataka ready shows its own scoped Check Compatibility action', (tester) async {
    final fake = _FakeApiClient(getJsonHandler: (_) async => _prereqsJson(jatakaStatus: 'READY'));
    Repository.instance = Repository(api: fake);

    await _useTallSurface(tester);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    // One "Check Compatibility" button on the Jataka card, plus the bulk
    // Continue bar's own button of the same label — both must coexist
    // without the new action replacing or breaking the existing bar.
    expect(find.widgetWithText(OutlinedButton, 'Check Compatibility'), findsOneWidget);
    expect(find.text('Checking Compatibility...'), findsNothing);
  });

  testWidgets('Jataka consent-required reuses the existing Manage Consent action, no ready action', (tester) async {
    final fake = _FakeApiClient(
      getJsonHandler: (_) async =>
          _prereqsJson(jatakaStatus: 'ACTION_REQUIRED', jatakaReason: 'YOUR_CONSENT_REQUIRED'),
    );
    Repository.instance = Repository(api: fake);

    await _useTallSurface(tester);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('Compatibility permission required.'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Manage Consent'), findsWidgets);
    expect(find.widgetWithText(OutlinedButton, 'Check Compatibility'), findsNothing);
  });

  testWidgets(
    'tapping Check Compatibility uses the calculate response\'s reportId end-to-end — '
    'not an empty id, not the candidate id',
    (tester) async {
      final fake = _FakeApiClient(
        getJsonHandler: (path) async {
          if (path.contains('/prerequisites/')) return _prereqsJson(jatakaStatus: 'READY');
          if (path.endsWith('/south-indian-jataka')) return _southIndianJatakaJson('saved-report-42');
          throw ApiException('unexpected GET: $path');
        },
        postJsonHandler: (path, body) async {
          expect(path, '/api/v1/compatibility/calculate');
          // The real backend shape: {reportId, ...moduleStatuses} — no `id`,
          // no `jataka` object.
          return {'reportId': 'saved-report-42', 'jataka': 'CALCULATED'};
        },
      );
      Repository.instance = Repository(api: fake);

      final authService = AuthService(repo: Repository.instance);
      await authService.loginWithUser(
        const AppUser(name: 'Me', phone: '999', role: 'member', gotra: '', native: '', avatar: '', gender: 'F'),
      );

      await _useTallSurface(tester);
      await tester.pumpWidget(_app(authService: authService));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(OutlinedButton, 'Check Compatibility'));
      await tester.pumpAndSettle();

      // Navigated to the richer South Indian Jataka screen...
      expect(find.byType(SouthIndianJatakaScreen), findsOneWidget);
      final pushed = tester.widget<SouthIndianJatakaScreen>(find.byType(SouthIndianJatakaScreen));
      // ...carrying the id calculate() actually returned, not the candidate
      // profile id and not an empty string.
      expect(pushed.reportId, 'saved-report-42');
      expect(pushed.otherName, 'Asha');

      // ...and its own fetch used that same real id in the URL.
      expect(
        fake.getJsonCalls,
        contains('/api/v1/compatibility/reports/saved-report-42/south-indian-jataka'),
      );
      expect(fake.getJsonCalls.any((p) => p == '/api/v1/compatibility/reports//south-indian-jataka'), isFalse);
    },
  );

  testWidgets(
    'a calculate response with a missing reportId shows an error and never navigates or hits '
    '/reports/ with an empty id',
    (tester) async {
      final fake = _FakeApiClient(
        getJsonHandler: (path) async {
          if (path.contains('/prerequisites/')) return _prereqsJson(jatakaStatus: 'READY');
          throw ApiException('unexpected GET: $path');
        },
        postJsonHandler: (path, body) async {
          // The backend, in this scenario, hands back a response with no
          // usable reportId at all.
          return {'jataka': 'CALCULATED'};
        },
      );
      Repository.instance = Repository(api: fake);

      final authService = AuthService(repo: Repository.instance);
      await authService.loginWithUser(
        const AppUser(name: 'Me', phone: '999', role: 'member', gotra: '', native: '', avatar: '', gender: 'F'),
      );

      await _useTallSurface(tester);
      await tester.pumpWidget(_app(authService: authService));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(OutlinedButton, 'Check Compatibility'));
      await tester.pumpAndSettle();

      expect(find.byType(SouthIndianJatakaScreen), findsNothing);
      expect(find.text('Could not calculate compatibility right now.'), findsOneWidget);
      // No GET was ever attempted with a missing/blank report id segment.
      expect(fake.getJsonCalls.any((p) => p.contains('/reports/') && !p.contains('/prerequisites/')), isFalse);
    },
  );
}
