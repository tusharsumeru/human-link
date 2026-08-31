/// STEP 77–78 — turns generated PDF bytes into a saved file and hands it to
/// the platform's native share sheet via the project's existing `share_plus`
/// dependency (already used for post/reel sharing — see share_sheet.dart).
/// No new sharing mechanism is introduced.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// "Priya Sharma" -> "Priya_Sharma"; strips anything that isn't safe in a
/// filename on Android/Windows/iOS. Falls back to "Member" for an empty/
/// entirely-unsafe name so the file never ends up with a blank segment.
String sanitizeFileNamePart(String name) {
  final cleaned = name
      .trim()
      .replaceAll(RegExp(r'\s+'), '_')
      .replaceAll(RegExp(r'[^A-Za-z0-9_\-]'), '');
  return cleaned.isEmpty ? 'Member' : cleaned;
}

String compatibilityPdfFileName(String person1Name, String person2Name) =>
    'Marriage_Compatibility_${sanitizeFileNamePart(person1Name)}_${sanitizeFileNamePart(person2Name)}.pdf';

/// Overridable in tests so they never have to swap the global
/// `PathProviderPlatform.instance` — doing that also redirects the app
/// theme's `google_fonts` package (it uses path_provider too, for its own
/// font cache) into a directory that suddenly has no cached fonts, which
/// then fails a real network fetch inside the sandboxed test runner. Scoping
/// the override to just this function avoids that entirely.
Future<Directory> Function() documentsDirectoryProvider = getApplicationDocumentsDirectory;

typedef SavePdfFn = Future<File> Function({
  required Uint8List bytes,
  required String person1Name,
  required String person2Name,
});

/// Overridable in tests. Widget tests (`testWidgets`) that exercise this
/// through a button tap swap it for a fake that does no real disk I/O at
/// all: the real implementation is independently covered by a plain (non-
/// widget) `test()` in compatibility_pdf_test.dart, where real `dart:io`
/// File/Directory calls are reliable; from inside a `testWidgets` pump
/// cycle, the very first real file write in this sandboxed test runner has
/// been observed to stall for several minutes regardless of sync vs async
/// I/O — an environment quirk, not a correctness issue, and not worth
/// coupling every dashboard button test to.
SavePdfFn saveCompatibilityPdfImpl = _saveCompatibilityPdfToDisk;

/// Saves the PDF into the app's own private documents directory under a
/// `compatibility_reports/` subfolder — an internal cache the "Share Report"
/// button reads from (share_plus reads the file directly, so the OS share
/// sheet is all that ever needs to see it) and that "Download PDF" also reads
/// from before handing the bytes to [downloadCompatibilityPdfToDevice] below.
/// This directory is sandboxed to the app, invisible in the device's own file
/// manager/Downloads — never what "Download PDF" itself writes to; see that
/// function's own doc comment. Writing under a deterministic, sanitized
/// filename means regenerating the same pair's report overwrites its own
/// previous copy rather than accumulating duplicates. Uses the synchronous
/// `dart:io` File/Directory APIs — no reason to pay for the async variants'
/// extra round trip for a write this small.
Future<File> _saveCompatibilityPdfToDisk({
  required Uint8List bytes,
  required String person1Name,
  required String person2Name,
}) async {
  final docsDir = await documentsDirectoryProvider();
  final reportsDir = Directory('${docsDir.path}/compatibility_reports');
  if (!reportsDir.existsSync()) {
    reportsDir.createSync(recursive: true);
  }
  final fileName = compatibilityPdfFileName(person1Name, person2Name);
  final file = File('${reportsDir.path}/$fileName');
  file.writeAsBytesSync(bytes);
  return file;
}

Future<File> saveCompatibilityPdf({
  required Uint8List bytes,
  required String person1Name,
  required String person2Name,
}) =>
    saveCompatibilityPdfImpl(bytes: bytes, person1Name: person1Name, person2Name: person2Name);

/// Opens the native Android/iOS share sheet with the saved PDF as the
/// shared artifact — never a raw backend URL or the underlying report JSON.
Future<void> shareCompatibilityPdf(File file, {String? subject}) async {
  await Share.shareXFiles([XFile(file.path)], subject: subject);
}

typedef DownloadPdfFn = Future<bool> Function({
  required Uint8List bytes,
  required String fileName,
});

/// Overridable in tests, same reason and pattern as [saveCompatibilityPdfImpl]
/// — the real implementation opens a native platform picker, which has no
/// answer inside a `testWidgets` sandbox.
DownloadPdfFn downloadCompatibilityPdfImpl = _downloadCompatibilityPdfToDevice;

/// What "Download PDF" actually calls. [saveCompatibilityPdf] above writes
/// into the app's own sandboxed storage — real, but invisible to the member
/// in their device's file manager or Downloads app, which is what "the PDF
/// isn't downloading" reports on a real device turned out to mean: the write
/// was silently succeeding somewhere the member could never find it. This
/// instead opens the OS's own save picker (Android's Storage Access
/// Framework / iOS's document picker) via `file_picker` — already a project
/// dependency — with the bytes handed directly to it, since on mobile a
/// picker-returned path isn't a normal filesystem path this app can write to
/// itself; passing [bytes] is what makes the plugin do that write for us.
/// Returns false, not an error, when the member cancels the picker.
Future<bool> _downloadCompatibilityPdfToDevice({
  required Uint8List bytes,
  required String fileName,
}) async {
  final savedPath = await FilePicker.platform.saveFile(
    dialogTitle: 'Save Compatibility Report',
    fileName: fileName,
    bytes: bytes,
  );
  return savedPath != null;
}

/// Lets the member choose where the PDF actually lands on their device.
/// Returns true once saved, false if they cancelled the picker.
Future<bool> downloadCompatibilityPdfToDevice({
  required Uint8List bytes,
  required String fileName,
}) =>
    downloadCompatibilityPdfImpl(bytes: bytes, fileName: fileName);
