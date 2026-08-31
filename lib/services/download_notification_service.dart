/// Shows a local (on-device, no server push involved) notification once a
/// file finishes downloading — tapping it opens that file directly, via
/// whatever viewer the phone already has installed (a PDF reader for the
/// compatibility certificate). Lazily initializes itself on first use so
/// nothing needs to change in `main.dart`'s startup sequence.
library;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:open_filex/open_filex.dart';

class DownloadNotificationService {
  DownloadNotificationService._();
  static final instance = DownloadNotificationService._();

  static const _channelId = 'downloads';
  static const _channelName = 'Downloads';
  static const _channelDescription = 'Notifies when a file finishes downloading';

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  int _nextId = 0;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    // iOS/macOS: request permission at the moment a download actually
    // happens is redundant with PermissionsIntroScreen already asking, but
    // costs nothing to request again — the OS just no-ops if already
    // granted/denied.
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: false,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (response) {
        final path = response.payload;
        if (path != null && path.isNotEmpty) OpenFilex.open(path);
      },
    );
    _initialized = true;
  }

  /// Shows a "download complete" notification for [filePath] — tapping it
  /// opens the file via the platform's own file-viewer chooser (a PDF app
  /// for a compatibility certificate). [title]/[body] come from the caller
  /// (already localized via AppLocalizations — this service has no
  /// BuildContext of its own to read them from). Never throws — a
  /// notification failing to show (e.g. permission denied) shouldn't fail
  /// the download itself, since the file is already safely saved by the
  /// time this is called.
  Future<void> notifyDownloaded({
    required String filePath,
    required String title,
    required String body,
  }) async {
    try {
      await _ensureInitialized();
      const androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      );
      const iosDetails = DarwinNotificationDetails();
      await _plugin.show(
        _nextId++,
        title,
        body,
        const NotificationDetails(android: androidDetails, iOS: iosDetails),
        payload: filePath,
      );
    } catch (_) {
      // Best-effort only — see doc comment above.
    }
  }
}
