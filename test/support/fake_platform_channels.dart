/// Test double for the `share_plus` platform-interface plugin the STEP 77-78
/// share flow depends on — flutter_test has no real platform to answer its
/// method channel, so it must be swapped for a fake via `PlatformInterface`'s
/// `MockPlatformInterfaceMixin` escape hatch (the standard pattern for
/// testing plugin-backed code). path_provider does NOT need the same
/// treatment: compatibility_pdf_export.dart exposes its own
/// `documentsDirectoryProvider` override point instead of needing
/// `PathProviderPlatform.instance` swapped globally (which would also break
/// the app theme's `google_fonts` font cache lookup — see that file).
library;

import 'dart:ui';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:share_plus_platform_interface/share_plus_platform_interface.dart';

class FakeSharePlatform extends SharePlatform with MockPlatformInterfaceMixin {
  final List<List<XFile>> sharedFileCalls = [];
  final List<String?> subjects = [];
  Object? throwOnShare;

  @override
  Future<ShareResult> shareXFiles(
    List<XFile> files, {
    String? subject,
    String? text,
    Rect? sharePositionOrigin,
    List<String>? fileNameOverrides,
  }) async {
    if (throwOnShare != null) throw throwOnShare!;
    sharedFileCalls.add(files);
    subjects.add(subject);
    return const ShareResult('ok', ShareResultStatus.success);
  }
}
