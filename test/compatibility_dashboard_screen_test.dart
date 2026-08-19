import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:daivajna_census/data/api_client.dart';
import 'package:daivajna_census/data/repository.dart';
import 'package:daivajna_census/screens/compatibility_dashboard_screen.dart';
import 'package:daivajna_census/screens/compatibility_report_screen.dart';
import 'package:daivajna_census/services/auth_service.dart';

/// Serves whatever JSON the test hands it for any `GET /api/v1/compatibility/
/// reports/...` call — both the dashboard's own fetch and, when "View
/// Detailed Report" is tapped, [CompatibilityReportScreen]'s follow-up fetch
/// of the same report.
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

/// A minimal `CompatibilityReportView` fixture — only the fields
/// [CompatibilityDashboardScreen] actually reads (see STEP 72's own full-shape
/// fixture in compatibility_report_full_test.dart for the complete contract).
Map<String, dynamic> _reportJson({
  String id = 'report-1',
  int? overallPercentage,
  String overallStatus = 'CALCULATED',
  String overallExplanation = 'Calculated from both Profile and Astrology Compatibility, weighted 50%/50%.',
  int? profilePercentage,
  String? profileStatus = 'CALCULATED',
  int? astrologyPercentage,
  String? astrologyStatus = 'CALCULATED',
  int karnatakaMatched = 7,
  int karnatakaTotal = 10,
  int? karnatakaPercentage,
  int? ashtakootaEarned = 28,
  int ashtakootaMaximum = 36,
  double? ashtakootaPercentage,
  List<Map<String, dynamic>> discussionPoints = const [],
  String disclaimer =
      'This compatibility result is an initial matchmaking assessment based on the configured Karnataka/South-Indian astrological rules. It is not a definitive prediction and should not be treated as a guarantee of relationship or marriage outcome.',
}) =>
    {
      'id': id,
      'profileAId': 'profile-a',
      'profileBId': 'profile-b',
      'ruleVersion': 'KARNATAKA_SOUTH_INDIAN_V1',
      'requestedInclude': <String>[],
      'notImplementedInclude': <String>[],
      'overallCompatibility': {
        'percentage': overallPercentage,
        'status': overallStatus,
        'reasonCode': 'OVERALL_COMPATIBILITY_CALCULATED',
        'explanation': overallExplanation,
        'profilePercentage': profilePercentage,
        'astrologyPercentage': astrologyPercentage,
        'profileWeight': 50,
        'astrologyWeight': 50,
      },
      if (profileStatus != null)
        'profileCompatibility': {
          'ruleVersion': 'PROFILE_COMPATIBILITY_V1',
          'profileAId': 'profile-a',
          'profileBId': 'profile-b',
          'status': profileStatus,
          'reasonCode': 'PROFILE_COMPATIBILITY_CALCULATED',
          'explanation': 'Calculated from the questionnaire answers.',
          'percentage': profilePercentage,
          'coverage': 90,
          'confidence': 'HIGH',
          'categories': <dynamic>[],
          'dealBreakers': <dynamic>[],
        },
      if (astrologyStatus != null)
        'astrologyCompatibility': {
          'status': astrologyStatus,
          'reasonCode': 'ASTROLOGY_COMPATIBILITY_CALCULATED',
          'explanation': 'Calculated from every Karnataka Porutham.',
          'primarySystem': 'KARNATAKA_SOUTH_INDIAN',
          'percentage': astrologyPercentage,
          'karnatakaPorutham': {
            'matched': karnatakaMatched,
            'partial': 1,
            'notMatched': 2,
            'calculable': karnatakaTotal,
            'total': karnatakaTotal,
            'percentage': karnatakaPercentage,
          },
          'ashtakoota': {
            'earned': ashtakootaEarned,
            'maximum': ashtakootaMaximum,
            'percentage': ashtakootaPercentage,
            'isComplete': ashtakootaEarned != null,
          },
        },
      'discussionPoints': discussionPoints,
      'overallStatus': overallStatus,
      'disclaimer': disclaimer,
      'coverage': 85,
      'confidence': 'HIGH',
      'createdAt': '2026-01-01T00:00:00.000Z',
    };

/// Provider wraps MaterialApp (matching the real app.dart, where AuthService
/// is injected once above the whole app) — not the other way around. Any
/// screen reached via Navigator.push, not just `home`, needs to see it too;
/// pushing "View Detailed Report" is exactly that case.
Widget _app({
  required AuthService authService,
  String reportId = 'report-1',
  Map<String, dynamic>? discoveryMatch,
}) =>
    ChangeNotifierProvider<AuthService>.value(
      value: authService,
      child: MaterialApp(
        home: CompatibilityDashboardScreen(
          reportId: reportId,
          otherName: 'Asha',
          discoveryMatch: discoveryMatch,
        ),
      ),
    );

Future<void> _useTallSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(400, 2200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

void main() {
  late Repository originalRepository;
  late AuthService authService;

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  setUp(() async {
    originalRepository = Repository.instance;
    authService = AuthService(repo: Repository.instance);
    await authService.loginWithUser(
      const AppUser(name: 'Priya', phone: '999', role: 'member', gotra: '', native: '', avatar: '', gender: 'F'),
    );
  });

  tearDown(() {
    Repository.instance = originalRepository;
  });

  testWidgets('1. Overall percentage is displayed', (tester) async {
    final fake = _FakeApiClient((_) async => _reportJson(overallPercentage: 81));
    Repository.instance = Repository(api: fake);

    await _useTallSurface(tester);
    await tester.pumpWidget(_app(authService: authService));
    await tester.pumpAndSettle();

    expect(find.text('81%'), findsOneWidget);
    expect(find.text('OVERALL COMPATIBILITY'), findsOneWidget);
  });

  testWidgets('2. Profile percentage is displayed', (tester) async {
    final fake = _FakeApiClient((_) async => _reportJson(overallPercentage: 81, profilePercentage: 84));
    Repository.instance = Repository(api: fake);

    await _useTallSurface(tester);
    await tester.pumpWidget(_app(authService: authService));
    await tester.pumpAndSettle();

    expect(find.text('Profile Compatibility'), findsOneWidget);
    expect(find.text('84%'), findsOneWidget);
  });

  testWidgets('3. Astrology percentage is displayed', (tester) async {
    final fake = _FakeApiClient(
      (_) async => _reportJson(overallPercentage: 81, astrologyPercentage: 78, karnatakaPercentage: 78),
    );
    Repository.instance = Repository(api: fake);

    await _useTallSurface(tester);
    await tester.pumpWidget(_app(authService: authService));
    await tester.pumpAndSettle();

    expect(find.text('Astrology Compatibility'), findsOneWidget);
    expect(find.text('78%'), findsWidgets); // top card + karnataka sublabel both read 78%
  });

  testWidgets('4. Both Profile and Astrology percentages null — overall stays honest', (tester) async {
    final fake = _FakeApiClient((_) async => _reportJson(
          overallPercentage: null,
          overallStatus: 'NOT_CALCULABLE',
          overallExplanation: 'Neither Profile Compatibility nor Astrology Compatibility could be calculated.',
          profilePercentage: null,
          profileStatus: 'NOT_CALCULABLE',
          astrologyPercentage: null,
          astrologyStatus: 'NOT_CALCULABLE',
          karnatakaPercentage: null,
          ashtakootaEarned: null,
        ));
    Repository.instance = Repository(api: fake);

    await _useTallSurface(tester);
    await tester.pumpWidget(_app(authService: authService));
    await tester.pumpAndSettle();

    expect(find.text('-'), findsOneWidget); // the ring's own null-percentage glyph
    expect(find.text('Not enough profile information'), findsOneWidget);
    expect(find.text('Not enough astrology information'), findsOneWidget);
  });

  testWidgets('5. Profile null while Astrology and Overall are present', (tester) async {
    final fake = _FakeApiClient((_) async => _reportJson(
          overallPercentage: 78,
          overallStatus: 'REVIEW_REQUIRED',
          profilePercentage: null,
          profileStatus: 'NOT_CALCULABLE',
          astrologyPercentage: 78,
          astrologyStatus: 'CALCULATED',
          karnatakaPercentage: 78,
        ));
    Repository.instance = Repository(api: fake);

    await _useTallSurface(tester);
    await tester.pumpWidget(_app(authService: authService));
    await tester.pumpAndSettle();

    expect(find.text('Not enough profile information'), findsOneWidget);
    expect(find.text('78%'), findsWidgets); // overall ring + astrology card + karnataka sublabel
  });

  testWidgets('6. Astrology null while Profile and Overall are present', (tester) async {
    // astrologyStatus: null omits `astrologyCompatibility` entirely — the
    // real "Jataka never ran" case (distinct from "ran but NOT_CALCULABLE",
    // which would still render the summary card with an Unavailable/no-%
    // state).
    final fake = _FakeApiClient((_) async => _reportJson(
          overallPercentage: 84,
          overallStatus: 'REVIEW_REQUIRED',
          profilePercentage: 84,
          profileStatus: 'CALCULATED',
          astrologyPercentage: null,
          astrologyStatus: null,
        ));
    Repository.instance = Repository(api: fake);

    await _useTallSurface(tester);
    await tester.pumpWidget(_app(authService: authService));
    await tester.pumpAndSettle();

    expect(find.text('Not enough astrology information'), findsOneWidget);
    // Astrology summary card itself is skipped entirely when astrologyCompatibility is null.
    expect(find.text('ASTROLOGY SUMMARY'), findsNothing);
  });

  testWidgets('7. REVIEW_REQUIRED status is shown on the relevant card', (tester) async {
    final fake = _FakeApiClient((_) async => _reportJson(
          overallPercentage: 84,
          overallStatus: 'REVIEW_REQUIRED',
          profilePercentage: 84,
          profileStatus: 'REVIEW_REQUIRED',
          astrologyPercentage: 78,
          karnatakaPercentage: 78,
        ));
    Repository.instance = Repository(api: fake);

    await _useTallSurface(tester);
    await tester.pumpWidget(_app(authService: authService));
    await tester.pumpAndSettle();

    expect(find.text('Review required'), findsWidgets); // overall status row + profile card status
  });

  testWidgets('8. Discussion points are displayed', (tester) async {
    final fake = _FakeApiClient((_) async => _reportJson(
          overallPercentage: 81,
          profilePercentage: 84,
          astrologyPercentage: 78,
          karnatakaPercentage: 78,
          discussionPoints: const [
            {
              'code': 'ASHTAKOOTA_NADI_MISMATCH',
              'source': 'ASHTAKOOTA',
              'severity': 'REVIEW',
              'message': 'Nadi Koota did not match.',
            },
          ],
        ));
    Repository.instance = Repository(api: fake);

    await _useTallSurface(tester);
    await tester.pumpWidget(_app(authService: authService));
    await tester.pumpAndSettle();

    expect(find.text('Discussion Points'), findsOneWidget);
    expect(find.text('Nadi Koota did not match.'), findsOneWidget);
  });

  testWidgets('9. Empty discussion points — no empty card shown', (tester) async {
    final fake = _FakeApiClient((_) async => _reportJson(
          overallPercentage: 81,
          profilePercentage: 84,
          astrologyPercentage: 78,
          karnatakaPercentage: 78,
          discussionPoints: const [],
        ));
    Repository.instance = Repository(api: fake);

    await _useTallSurface(tester);
    await tester.pumpWidget(_app(authService: authService));
    await tester.pumpAndSettle();

    expect(find.text('Discussion Points'), findsNothing);
  });

  testWidgets('10. Disclaimer is displayed verbatim', (tester) async {
    final fake = _FakeApiClient((_) async => _reportJson(overallPercentage: 81));
    Repository.instance = Repository(api: fake);

    await _useTallSurface(tester);
    await tester.pumpWidget(_app(authService: authService));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'This compatibility result is an initial matchmaking assessment based on the configured Karnataka/South-Indian astrological rules. It is not a definitive prediction and should not be treated as a guarantee of relationship or marriage outcome.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('11. Loading state shows a spinner, no fake percentage', (tester) async {
    final fake = _FakeApiClient((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      return _reportJson(overallPercentage: 81);
    });
    Repository.instance = Repository(api: fake);

    await _useTallSurface(tester);
    await tester.pumpWidget(_app(authService: authService));
    await tester.pump(); // one frame — request still in flight

    expect(find.byType(CircularProgressIndicator), findsWidgets);
    expect(find.textContaining('%'), findsNothing);

    await tester.pumpAndSettle();
  });

  testWidgets('12. Error state shows a message and a retry action', (tester) async {
    var attempt = 0;
    final fake = _FakeApiClient((_) async {
      attempt++;
      if (attempt == 1) throw ApiException('Could not reach the server', statusCode: 500);
      return _reportJson(overallPercentage: 81);
    });
    Repository.instance = Repository(api: fake);

    await _useTallSurface(tester);
    await tester.pumpWidget(_app(authService: authService));
    await tester.pumpAndSettle();

    expect(find.text('Could not reach the server'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(attempt, 2);
    expect(find.text('81%'), findsOneWidget);
  });

  testWidgets('13. A null percentage never renders as 0%', (tester) async {
    final fake = _FakeApiClient((_) async => _reportJson(
          overallPercentage: null,
          overallStatus: 'NOT_CALCULABLE',
          profilePercentage: null,
          profileStatus: 'NOT_CALCULABLE',
          astrologyPercentage: null,
          astrologyStatus: 'NOT_CALCULABLE',
          karnatakaPercentage: null,
          ashtakootaEarned: null,
        ));
    Repository.instance = Repository(api: fake);

    await _useTallSurface(tester);
    await tester.pumpWidget(_app(authService: authService));
    await tester.pumpAndSettle();

    expect(find.text('0%'), findsNothing);
    expect(find.text('-'), findsOneWidget); // the ring's own null-percentage glyph
  });

  testWidgets('14. "View Detailed Report" navigates to CompatibilityReportScreen', (tester) async {
    final fake = _FakeApiClient((path) async {
      // Both the dashboard's own fetch and the pushed detailed report
      // screen's follow-up fetch hit the same reportId.
      expect(path, '/api/v1/compatibility/reports/report-1');
      return _reportJson(overallPercentage: 81, profilePercentage: 84, astrologyPercentage: 78, karnatakaPercentage: 78);
    });
    Repository.instance = Repository(api: fake);

    await _useTallSurface(tester);
    await tester.pumpWidget(_app(authService: authService));
    await tester.pumpAndSettle();

    expect(find.byType(CompatibilityReportScreen), findsNothing);

    await tester.tap(find.text('View Detailed Report'));
    await tester.pumpAndSettle();

    expect(find.byType(CompatibilityReportScreen), findsOneWidget);
    expect(fake.calls.length, greaterThanOrEqualTo(2)); // dashboard fetch + detailed report's own fetch
  });

  group('Profile Compatibility falls back to Discovery Match', () {
    const discoveryMatch = {
      'matchPercentage': 69,
      'matchLevel': 'MODERATE',
      'factors': <dynamic>[],
    };

    testWidgets(
        '15. no ProfileCompatibility + a discoveryMatch — shows its percentage (Calculated), and Overall becomes the '
        'profile/astrology weighted blend rather than the backend\'s astrology-only figure',
        (tester) async {
      final fake = _FakeApiClient((_) async => _reportJson(
            // The backend's own overall — astrology-only, since it never saw a
            // profile figure at all. Must NOT be what ends up on screen once
            // Discovery Match substitutes a profile figure client-side.
            overallPercentage: 78,
            overallStatus: 'REVIEW_REQUIRED',
            profilePercentage: null,
            profileStatus: null, // omits profileCompatibility entirely — "never ran"
            astrologyPercentage: 78,
            astrologyStatus: 'CALCULATED',
            karnatakaPercentage: 78,
          ));
      Repository.instance = Repository(api: fake);

      await _useTallSurface(tester);
      await tester.pumpWidget(_app(authService: authService, discoveryMatch: discoveryMatch));
      await tester.pumpAndSettle();

      expect(find.text('Not enough profile information'), findsNothing);
      expect(find.text('69%'), findsOneWidget);
      expect(find.text('Calculated'), findsWidgets); // Profile card + Astrology card both read Calculated

      // (69 * 50 + 78 * 50) / 100 = 73.5 -> 74, using the report's own
      // profileWeight/astrologyWeight (50/50) — never a fabricated number.
      expect(find.text('74%'), findsOneWidget);
      expect(find.text('78%'), findsWidgets); // Astrology card + karnataka sublabel, unaffected

      // The two removed captions must not reappear.
      expect(find.textContaining('From your match preferences'), findsNothing);
      expect(find.textContaining('reflects Astrology Compatibility alone'), findsNothing);
    });

    testWidgets('16. a real ProfileCompatibility percentage is never overridden by discoveryMatch, and Overall stays the backend\'s own figure',
        (tester) async {
      final fake = _FakeApiClient((_) async => _reportJson(overallPercentage: 81, profilePercentage: 84));
      Repository.instance = Repository(api: fake);

      await _useTallSurface(tester);
      await tester.pumpWidget(_app(authService: authService, discoveryMatch: discoveryMatch));
      await tester.pumpAndSettle();

      expect(find.text('84%'), findsOneWidget);
      expect(find.text('69%'), findsNothing);
      expect(find.text('81%'), findsOneWidget); // backend's own overall, untouched
      expect(find.text('74%'), findsNothing); // never the discoveryMatch-blended figure
    });

    testWidgets('17. neither ProfileCompatibility nor discoveryMatch — still shows "Not enough profile information"',
        (tester) async {
      final fake = _FakeApiClient((_) async => _reportJson(
            overallPercentage: null,
            overallStatus: 'NOT_CALCULABLE',
            profilePercentage: null,
            profileStatus: 'NOT_CALCULABLE',
          ));
      Repository.instance = Repository(api: fake);

      await _useTallSurface(tester);
      await tester.pumpWidget(_app(authService: authService)); // no discoveryMatch
      await tester.pumpAndSettle();

      expect(find.text('Not enough profile information'), findsOneWidget);
      expect(find.textContaining('From your match preferences'), findsNothing);
    });
  });
}
