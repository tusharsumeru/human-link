/// Base URL of the Next.js web app's API.
///
/// The Android emulator reaches the host machine at 10.0.2.2; other platforms
/// use localhost. Override with `--dart-define=API_BASE_URL=http://192.168.x.x:3000`
/// when running on a physical device or a deployed backend.
class ApiConfig {
  ApiConfig._();

  /// Backend base URL. Default targets the local NestJS server from the Android
  /// emulator: 10.0.2.2 is the emulator's alias for the host machine, and using
  /// the IP (not a hostname) also avoids the emulator's flaky DNS.
  // NOTE: no trailing `/api` — every request path already begins with `/api`
  // (e.g. `/api/user/login`), so keeping it here would double it.
  // For a physical device or a tunnel, override with
  // --dart-define=API_BASE_URL=https://<host> (see below).
  static const String _deployed = "https://0895-2409-4091-9008-ae00-d574-3e10-35f6-fa4d.ngrok-free.app";
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

  /// How long to wait for the API before failing / falling back to demo data.
  /// Generous on purpose: an emulator's first HTTPS call through a dev tunnel
  /// (DNS + TLS handshake) can easily take several seconds.
  static const Duration timeout = Duration(seconds: 20);
}
