/// Base URL of the NestJS backend API.
///
/// The Android emulator reaches the host machine at 10.0.2.2; other platforms
/// use localhost. Override with `--dart-define=API_BASE_URL=http://192.168.x.x:4000`
/// when running on a physical device or a deployed backend.
class ApiConfig {
  ApiConfig._();

  /// Backend base URL. Default targets the local NestJS server (port 4000) from
  /// the Android emulator: 10.0.2.2 is the emulator's alias for the host
  /// machine — inside the emulator `localhost` is the emulator itself, so a
  /// local server is unreachable under that name. Using the IP (not a hostname)
  /// also avoids the emulator's flaky DNS.
  // NOTE: no trailing `/api` — every request path already begins with `/api`
  // (e.g. `/api/user/login`), so keeping it here would double it.
  // For a physical device or a tunnel, override with
  // --dart-define=API_BASE_URL=https://<host> (see below).
  static const String _localDev = "http://10.0.2.2:4000";
  static const String _override = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static String get baseUrl {
    // Trailing slashes are stripped: request paths already start with `/`, and
    // a base ending in `/` produces `//api/user/login`, which Express does not
    // normalise — it 404s, which the login screen then reports as "number not
    // registered".
    if (_override.isNotEmpty) return _override.replaceAll(RegExp(r'/+$'), '');
    // Default to the local server so the app works against the dev backend out
    // of the box. A tunnel or deployment is a build-time override:
    //   --dart-define=API_BASE_URL=https://<host>
    // (A hardcoded ngrok URL used to live here. Free tunnels get a new address
    // on every restart, so once it expired every call failed — and the screens
    // swallowed the error, showing an empty feed and "Network error" on login.)
    return _localDev;
  }

  /// How long to wait for the API before failing / falling back to demo data.
  /// Generous on purpose: an emulator's first HTTPS call through a dev tunnel
  /// (DNS + TLS handshake) can easily take several seconds.
  static const Duration timeout = Duration(seconds: 20);
}
