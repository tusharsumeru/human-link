import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// Base URL of the NestJS backend API.
///
/// The Android emulator reaches the host machine at 10.0.2.2; other platforms
/// use localhost. Override with `--dart-define=API_BASE_URL=http://192.168.x.x:4000`
/// when running on a physical device or a deployed backend.
class ApiConfig {
  ApiConfig._();

  // NOTE: no trailing `/api` — every request path already begins with `/api`
  // (e.g. `/api/user/login`), so keeping it here would double it.
  // For a physical device or a tunnel, override with
  // --dart-define=API_BASE_URL=https://<host> (see below).
  static const String _localDevPort = '4000';

  static const String _override = '';

  static String get _localDev {
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:$_localDevPort';
    }
    return 'http://localhost:$_localDevPort';
  }

  static String get baseUrl {
    // Trailing slashes are stripped: request paths already start with `/`, and
    // a base ending in `/` produces `//api/user/login`, which Express does not
    // normalise — it 404s, which the login screen then reports as "number not
    // registered".
    if (_override.isNotEmpty) return _override.replaceAll(RegExp(r'/+$'), '');
    // Default to the local server so the app works against the dev backend out
    // of the box. A tunnel or deployment is a build-time override:
    //   --dart-define=API_BASE_URL=https://<host>
    return _localDev;
  }

  /// How long to wait for the API before failing / falling back to demo data.
  /// Generous on purpose: an emulator's first HTTPS call through a dev tunnel
  /// (DNS + TLS handshake) can easily take several seconds.
  static const Duration timeout = Duration(seconds: 20);
}
