/// Base URL of the Next.js web app's API.
///
/// The Android emulator reaches the host machine at 10.0.2.2; other platforms
/// use localhost. Override with `--dart-define=API_BASE_URL=http://192.168.x.x:3000`
/// when running on a physical device or a deployed backend.
class ApiConfig {
  ApiConfig._();

  /// Deployed Next.js backend (Vercel). Verified working: `/api/auth/login`,
  /// `/api/stats` return live data from MongoDB.
  static const String _deployed =
      'https://f68d-2409-4091-9008-ac01-3caa-aa0f-fd0a-339b.ngrok-free.app';

  static const String _override = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static String get baseUrl {
    if (_override.isNotEmpty) return _override;
    // Default to the live deployment so the app works on real devices and
    // emulators without a local server. Override for local dev with
    // --dart-define=API_BASE_URL=http://10.0.2.2:3000
    return _deployed;
  }

  /// How long to wait for the API before falling back to embedded demo data.
  static const Duration timeout = Duration(seconds: 4);
}
