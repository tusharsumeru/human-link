/// Base URL of the Next.js web app's API.
///
/// The Android emulator reaches the host machine at 10.0.2.2; other platforms
/// use localhost. Override with `--dart-define=API_BASE_URL=http://192.168.x.x:3000`
/// when running on a physical device or a deployed backend.
class ApiConfig {
  ApiConfig._();

  /// Deployed Next.js backend (Vercel). Verified working: `/api/user/login`,
  /// `/api/stats` return live data from MongoDB.
  // NOTE: no trailing `/api` — every request path already begins with `/api`
  // (e.g. `/api/user/login`), so keeping it here would double it.
  static const String _deployed ="https://53d3-2409-4091-9008-ae00-79a7-65ca-8d56-307e.ngrok-free.app";
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
