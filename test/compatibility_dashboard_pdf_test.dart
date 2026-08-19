import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:share_plus_platform_interface/share_plus_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:daivajna_census/data/api_client.dart';
import 'package:daivajna_census/data/repository.dart';
import 'package:daivajna_census/screens/compatibility_dashboard_screen.dart';
import 'package:daivajna_census/services/auth_service.dart';
import 'package:daivajna_census/services/compatibility_pdf_export.dart' as pdf_export;

import 'support/fake_platform_channels.dart';

/// STEP 77-78 — widget tests for the dashboard's "Download PDF" / "Share
/// Report" actions.
///
/// `saveCompatibilityPdfImpl` is faked out entirely (no real `dart:io` File/
/// Directory calls) — from inside a `testWidgets` pump cycle, the very first
/// real file write in this sandboxed test runner has been observed to stall
/// for minutes at a time regardless of sync/async I/O, an environment quirk
/// unrelated to correctness. The real disk-writing implementation is
/// reliably covered by plain (non-widget) tests in compatibility_pdf_test.dart
/// instead. share_plus needs its own platform channel faked the same way
/// (see support/fake_platform_channels.dart) since flutter_test has no real
/// platform to answer either.
class _FakeApiClient extends ApiClient {
  _FakeApiClient(this.handler);
  final dynamic Function(String path) handler;

  @override
  Future<dynamic> getJson(String path) async => handler(path);
}

class _FakeSavedPdf {
  final List<({Uint8List bytes, String person1Name, String person2Name})> calls = [];
  Object? throwOnSave;
  Duration delay = Duration.zero;

  Future<File> save({
    required Uint8List bytes,
    required String person1Name,
    required String person2Name,
  }) async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (throwOnSave != null) throw throwOnSave!;
    calls.add((bytes: bytes, person1Name: person1Name, person2Name: person2Name));
    final fileName = pdf_export.compatibilityPdfFileName(person1Name, person2Name);
    return File('/fake/compatibility_reports/$fileName');
  }
}

Map<String, dynamic> _reportJson() => {
      'id': 'report-1',
      'profileAId': 'profile-a',
      'profileBId': 'profile-b',
      'ruleVersion': 'KARNATAKA_SOUTH_INDIAN_V1',
      'requestedInclude': <String>[],
      'notImplementedInclude': <String>[],
      'overallCompatibility': {
        'percentage': 81,
        'status': 'CALCULATED',
        'reasonCode': 'OK',
        'explanation': 'Weighted 50/50.',
        'profilePercentage': 84,
        'astrologyPercentage': 78,
        'profileWeight': 50,
        'astrologyWeight': 50,
      },
      'discussionPoints': <dynamic>[],
      'overallStatus': 'CALCULATED',
      'disclaimer': 'This compatibility result is an initial matchmaking assessment.',
      'coverage': 85,
      'confidence': 'HIGH',
      'createdAt': '2026-01-01T00:00:00.000Z',
    };

Widget _app(AuthService authService) => ChangeNotifierProvider<AuthService>.value(
      value: authService,
      child: const MaterialApp(
        home: CompatibilityDashboardScreen(reportId: 'report-1', otherName: 'Asha'),
      ),
    );

Future<void> _useTallSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(400, 2400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

/// The right alternative to `pumpAndSettle()` for use right after a PDF/
/// Share action. Two things make plain `pumpAndSettle()` wrong here: (1)
/// "Share Report" shows an indeterminate `CircularProgressIndicator` while
/// busy, which repeats forever and never lets `pumpAndSettle()` converge;
/// (2) the success `SnackBar` has a 3-second display duration, so a long
/// enough pump run sails straight through its entrance AND its
/// auto-dismissal. Polling — stopping as soon as `condition` is true — is
/// robust to both.
Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() condition, {
  int maxIterations = 50,
  Duration step = const Duration(milliseconds: 100),
}) async {
  for (var i = 0; i < maxIterations; i++) {
    if (condition()) return;
    await tester.pump(step);
  }
  // Let the final assertion report a clear failure rather than looping forever.
}

void main() {
  late Repository originalRepository;
  late SharePlatform originalSharePlatform;
  late pdf_export.SavePdfFn originalSaveImpl;
  late AuthService authService;
  late _FakeSavedPdf fakeSave;

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  setUp(() async {
    originalRepository = Repository.instance;
    originalSharePlatform = SharePlatform.instance;
    originalSaveImpl = pdf_export.saveCompatibilityPdfImpl;
    fakeSave = _FakeSavedPdf();
    pdf_export.saveCompatibilityPdfImpl = fakeSave.save;

    final fake = _FakeApiClient((_) async => _reportJson());
    Repository.instance = Repository(api: fake);
    authService = AuthService(repo: Repository.instance);
    await authService.loginWithUser(
      const AppUser(name: 'Priya', phone: '999', role: 'member', gotra: '', native: '', avatar: '', gender: 'F'),
    );
  });

  tearDown(() {
    Repository.instance = originalRepository;
    SharePlatform.instance = originalSharePlatform;
    pdf_export.saveCompatibilityPdfImpl = originalSaveImpl;
  });

  testWidgets('dashboard still renders correctly alongside the new PDF/Share actions', (tester) async {
    await _useTallSurface(tester);
    await tester.pumpWidget(_app(authService));
    await tester.pumpAndSettle();

    expect(find.text('OVERALL COMPATIBILITY'), findsOneWidget);
    expect(find.text('81%'), findsOneWidget);
    expect(find.text('View Detailed Report'), findsOneWidget);
    expect(find.text('Download PDF'), findsOneWidget);
    expect(find.text('Share Report'), findsOneWidget);
  });

  testWidgets('tapping Download PDF generates the PDF and shows a success snackbar', (tester) async {
    await _useTallSurface(tester);
    await tester.pumpWidget(_app(authService));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Download PDF'));
    await _pumpUntil(tester, () => find.textContaining('PDF saved:').evaluate().isNotEmpty);

    expect(find.textContaining('PDF saved:'), findsOneWidget);
    expect(fakeSave.calls, hasLength(1));
    expect(fakeSave.calls.single.person1Name, 'Priya');
    expect(fakeSave.calls.single.person2Name, 'Asha');
    expect(fakeSave.calls.single.bytes, isNotEmpty);
  });

  testWidgets('tapping Share Report invokes the native share sheet with the generated PDF', (tester) async {
    final fakeShare = FakeSharePlatform();
    SharePlatform.instance = fakeShare;

    await _useTallSurface(tester);
    await tester.pumpWidget(_app(authService));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Share Report'));
    await _pumpUntil(tester, () => fakeShare.sharedFileCalls.isNotEmpty);

    expect(fakeShare.sharedFileCalls, hasLength(1));
    expect(fakeShare.sharedFileCalls.single.single.path, endsWith('Marriage_Compatibility_Priya_Asha.pdf'));
    expect(fakeShare.subjects.single, contains('Priya'));
  });

  testWidgets('sharing right after downloading reuses the same generated PDF instead of regenerating it',
      (tester) async {
    final fakeShare = FakeSharePlatform();
    SharePlatform.instance = fakeShare;

    await _useTallSurface(tester);
    await tester.pumpWidget(_app(authService));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Download PDF'));
    await _pumpUntil(tester, () => find.textContaining('PDF saved:').evaluate().isNotEmpty);
    await tester.tap(find.text('Share Report'));
    await _pumpUntil(tester, () => fakeShare.sharedFileCalls.isNotEmpty);

    // Both actions produced a result, but the underlying PDF was only
    // generated once — the second action reused the cached file.
    expect(fakeSave.calls, hasLength(1));
    expect(fakeShare.sharedFileCalls, hasLength(1));
  });

  testWidgets('a repeat tap while a PDF is already generating does not start a second generation', (tester) async {
    fakeSave.delay = const Duration(milliseconds: 300);

    await _useTallSurface(tester);
    await tester.pumpWidget(_app(authService));
    await tester.pumpAndSettle();

    // Two taps fired back-to-back, before the first has any chance to
    // complete (it's awaiting the artificially slow save) — the second must
    // be rejected by the in-flight guard, not queue a second PDF generation.
    await tester.tap(find.text('Download PDF'));
    await tester.tap(find.text('Download PDF'));
    await _pumpUntil(tester, () => find.textContaining('PDF saved:').evaluate().isNotEmpty);

    expect(fakeSave.calls, hasLength(1));
  });

  testWidgets('a PDF generation failure shows a clear error with a working Retry action', (tester) async {
    fakeSave.throwOnSave = Exception('disk unavailable');

    await _useTallSurface(tester);
    await tester.pumpWidget(_app(authService));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Download PDF'));
    await _pumpUntil(tester, () => find.text('Could not generate the PDF. Please try again.').evaluate().isNotEmpty);

    expect(find.text('Could not generate the PDF. Please try again.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    // Let the SnackBar's entrance animation finish before tapping its
    // action — tapping mid-slide-in hits the wrong offset.
    await tester.pump(const Duration(milliseconds: 300));

    // Fix the underlying failure, then retry from the snackbar action.
    fakeSave.throwOnSave = null;
    await tester.tap(find.text('Retry'));
    await _pumpUntil(tester, () => find.textContaining('PDF saved:').evaluate().isNotEmpty);

    expect(find.textContaining('PDF saved:'), findsOneWidget);
  });

  testWidgets('buttons are disabled while a PDF is generating', (tester) async {
    fakeSave.delay = const Duration(milliseconds: 300);

    await _useTallSurface(tester);
    await tester.pumpWidget(_app(authService));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Download PDF'));
    await tester.pump(); // let the busy state apply, don't wait for it to finish

    expect(find.text('Generating…'), findsOneWidget);
    final downloadButton = tester.widget<OutlinedButton>(find.ancestor(
      of: find.text('Generating…'),
      matching: find.byType(OutlinedButton),
    ));
    expect(downloadButton.onPressed, isNull);

    await _pumpUntil(tester, () => find.textContaining('PDF saved:').evaluate().isNotEmpty);
  });
}
