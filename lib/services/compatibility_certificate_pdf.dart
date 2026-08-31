/// A compact, single-page "marriage compatibility certificate" — the
/// decorative PDF used only for the Download/Share actions on
/// [CompatibilityDashboardScreen]. Distinct from the full, multi-page,
/// section-by-section report built by `compatibility_pdf.dart` (used by
/// "View Detailed Report"), which this file never touches or replaces.
///
/// The client's reference design has an ornate hand-drawn temple-arch /
/// elephant border. That artwork hasn't been supplied yet, so this draws a
/// plain gold double-line border as a placeholder and looks for the real
/// artwork at [kCertificateBorderAssetPath] first — drop a full-bleed A4
/// PNG/JPG there (and add it under `flutter: assets:` in pubspec.yaml) and
/// it's used automatically, no code change needed.
///
/// English-only for now, matching every other label already in this app —
/// Kannada/Hindi come later from the backend, same as the rest of the UI.
library;

import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../data/models/compatibility_models.dart';
import '../data/models/compatibility_summary.dart' show OverallCompatibility;
import '../data/models/kundli_chart.dart' show PartnerKundliChart, KundliPlanetPosition;
import '../data/models/parampara.dart' show PartnerParamparaResult;
import '../data/models/south_indian_jataka.dart';
import 'compatibility_pdf_content.dart'
    show kNotAvailable, kundliPlanetRows, paramparaPartnerRows, poruthamStatusLabel;

/// Where to drop the client's ornate border/background artwork once
/// supplied (see the file doc comment above).
const String kCertificateBorderAssetPath = 'assets/images/certificate_border.png';

class _Palette {
  static const maroon = PdfColor.fromInt(0xFF7A1F1F);
  static const gold = PdfColor.fromInt(0xFFB8860B);
  static const cream = PdfColor.fromInt(0xFFFBF3E3);
  static const ink = PdfColors.grey900;
  static const muted = PdfColors.grey700;
  static const brideAccent = PdfColor.fromInt(0xFFC2185B);
  static const groomAccent = PdfColor.fromInt(0xFF1565C0);
  static const good = PdfColor.fromInt(0xFF2E7D32);
  static const review = PdfColor.fromInt(0xFFB8860B);
  static const unavailable = PdfColors.grey500;
}

/// Builds the certificate PDF and returns its bytes. [brideName]/[groomName]
/// are the already-known display names (the caller resolves which of the
/// report's two profiles holds each traditional role); [bridePhotoUrl]/
/// [groomPhotoUrl] are optional — a gender-appropriate placeholder icon is
/// drawn instead of a name that has no photo. A photo fetch failure never
/// fails the whole certificate — it just falls back to the icon.
Future<Uint8List> buildCompatibilityCertificateBytes({
  required CompatibilityReport report,
  required String brideName,
  required String groomName,
  String? bridePhotoUrl,
  String? groomPhotoUrl,
}) async {
  final borderImage = await _tryLoadAsset(kCertificateBorderAssetPath);
  final bridePhoto = await _tryLoadNetworkImage(bridePhotoUrl);
  final groomPhoto = await _tryLoadNetworkImage(groomPhotoUrl);

  final doc = pw.Document();
  doc.addPage(
    pw.MultiPage(
      // MultiPage (not a single fixed Page) because the full bride+groom
      // Kundli tables can push the content past one A4 page — MultiPage
      // flows the overflow onto a second page automatically instead of
      // silently clipping it. buildBackground repeats the border/artwork
      // on every page this generates, not just the first.
      pageTheme: pw.PageTheme(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(40, 46, 40, 46),
        buildBackground: (context) => pw.FullPage(
          ignoreMargins: true,
          child: pw.Stack(
            children: [
              pw.Positioned.fill(
                child: borderImage != null
                    ? pw.Image(borderImage, fit: pw.BoxFit.cover)
                    : pw.Container(color: _Palette.cream),
              ),
              if (borderImage == null) pw.Positioned.fill(child: _plainBorder()),
            ],
          ),
        ),
      ),
      build: (context) => _certificateBody(report, brideName, groomName, bridePhoto, groomPhoto),
    ),
  );
  return doc.save();
}

// ── Border placeholder ──────────────────────────────────────────────────────

pw.Widget _plainBorder() => pw.Container(
      margin: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _Palette.maroon, width: 2.4),
      ),
      child: pw.Container(
        margin: const pw.EdgeInsets.all(6),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: _Palette.gold, width: 1),
        ),
      ),
    );

// ── Body ─────────────────────────────────────────────────────────────────

List<pw.Widget> _certificateBody(
  CompatibilityReport report,
  String brideName,
  String groomName,
  pw.ImageProvider? bridePhoto,
  pw.ImageProvider? groomPhoto,
) {
  final overall = report.overallCompatibility;
  final verdict = _verdict(overall);

  return [
    pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text('DAIVAJNA SAMAJA', style: pw.TextStyle(fontSize: 11, color: _Palette.gold, letterSpacing: 2, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        pw.Text('MARRIAGE COMPATIBILITY CERTIFICATE',
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(fontSize: 19, color: _Palette.maroon, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 3),
        pw.Text('Vamsha Vruksha · Marriage Compatibility Assessment',
            style: pw.TextStyle(fontSize: 9, color: _Palette.muted, fontStyle: pw.FontStyle.italic)),
        pw.SizedBox(height: 10),
        _goldDivider(),
        pw.SizedBox(height: 14),
        _photoRow(brideName, groomName, bridePhoto, groomPhoto, overall, verdict),
      ],
    ),
    pw.SizedBox(height: 16),
    pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
            child: _birthDetailsCard(
                'BRIDE', report.kundliChart?.bride, report.daivagnaParampara?.bride, _Palette.brideAccent)),
        pw.SizedBox(width: 10),
        pw.Expanded(
            child: _birthDetailsCard(
                'GROOM', report.kundliChart?.groom, report.daivagnaParampara?.groom, _Palette.groomAccent)),
      ],
    ),
    pw.SizedBox(height: 16),
    _sectionTitle('Bride Kundli (Janma Kundali · D1)'),
    _kundliTable(kundliPlanetRows(report.kundliChart?.bride), _Palette.brideAccent),
    pw.SizedBox(height: 14),
    _sectionTitle('Groom Kundli (Janma Kundali · D1)'),
    _kundliTable(kundliPlanetRows(report.kundliChart?.groom), _Palette.groomAccent),
    pw.SizedBox(height: 18),
    _goldDivider(),
    pw.SizedBox(height: 10),
    pw.Center(
      child: pw.Text('KUNDLI MILAN - COMPATIBILITY MATCH',
          style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: _Palette.maroon, letterSpacing: 1)),
    ),
    pw.SizedBox(height: 12),
    _sectionTitle('Ashtakoota Milana (36 Guna)'),
    _compactTable(const ['Koota', 'Score', 'Result'], _ashtakootaRows(report.ashtakoota)),
    pw.SizedBox(height: 12),
    _sectionTitle('Karnataka 10 Porutham'),
    _compactTable(const ['Porutham', 'Result'], _karnatakaRows(report.jataka)),
    pw.SizedBox(height: 16),
    pw.Center(child: _verdictBanner(overall, verdict)),
    pw.SizedBox(height: 12),
    pw.Text(
      report.disclaimer.isNotEmpty
          ? report.disclaimer
          : 'This certificate summarizes the Karnataka Porutham, Ashtakoota, Kundli, and profile compatibility already calculated for this report. It is a matchmaking aid, not a guarantee.',
      textAlign: pw.TextAlign.center,
      style: pw.TextStyle(fontSize: 8, color: _Palette.muted, fontStyle: pw.FontStyle.italic),
    ),
    pw.SizedBox(height: 12),
    _footer(report),
  ];
}

/// Full D1 planetary-position table (Lagna + all 9 Grahas: Rashi, Nakshatra,
/// Pada, Retrograde) — the same figures the detailed report shows via
/// `kundliPlanetRows`, just styled to match this certificate.
pw.Widget _kundliTable(List<List<String>> rows, PdfColor accent) {
  if (rows.isEmpty) {
    return pw.Text(kNotAvailable, style: pw.TextStyle(fontSize: 9, color: _Palette.muted, fontStyle: pw.FontStyle.italic));
  }
  return pw.TableHelper.fromTextArray(
    headers: const ['Point', 'Rashi', 'Nakshatra', 'Pada', 'Retrograde'],
    data: rows,
    headerStyle: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
    headerDecoration: pw.BoxDecoration(color: accent),
    cellStyle: pw.TextStyle(fontSize: 8, color: _Palette.ink),
    cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
    border: pw.TableBorder.all(color: _Palette.gold, width: 0.4),
    columnWidths: const {
      0: pw.FlexColumnWidth(1.6),
      1: pw.FlexColumnWidth(1.6),
      2: pw.FlexColumnWidth(1.8),
      3: pw.FlexColumnWidth(0.9),
      4: pw.FlexColumnWidth(1.2),
    },
    oddRowDecoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFFFBF3E3)),
  );
}

pw.Widget _goldDivider() => pw.Container(height: 1.2, width: 220, color: _Palette.gold);

pw.Widget _sectionTitle(String text) => pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Text(text, style: pw.TextStyle(fontSize: 11.5, fontWeight: pw.FontWeight.bold, color: _Palette.maroon)),
    );

// ── Photo + names + overall badge ───────────────────────────────────────

pw.Widget _photoRow(
  String brideName,
  String groomName,
  pw.ImageProvider? bridePhoto,
  pw.ImageProvider? groomPhoto,
  OverallCompatibility overall,
  _Verdict verdict,
) {
  return pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.center,
    children: [
      pw.Expanded(child: _personColumn('BRIDE', brideName, bridePhoto, _Palette.brideAccent, isBride: true)),
      pw.Container(
        width: 96,
        alignment: pw.Alignment.center,
        child: pw.Column(
          children: [
            pw.Container(
              width: 64,
              height: 64,
              alignment: pw.Alignment.center,
              decoration: pw.BoxDecoration(shape: pw.BoxShape.circle, border: pw.Border.all(color: verdict.color, width: 2)),
              child: pw.Text(
                overall.percentage != null ? '${overall.percentage}%' : kNotAvailable,
                style: pw.TextStyle(fontSize: overall.percentage != null ? 15 : 8, fontWeight: pw.FontWeight.bold, color: verdict.color),
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text('OVERALL', style: pw.TextStyle(fontSize: 7.5, color: _Palette.muted, letterSpacing: 1)),
          ],
        ),
      ),
      pw.Expanded(child: _personColumn('GROOM', groomName, groomPhoto, _Palette.groomAccent, isBride: false)),
    ],
  );
}

pw.Widget _personColumn(String label, String name, pw.ImageProvider? photo, PdfColor accent, {required bool isBride}) {
  return pw.Column(
    children: [
      pw.Text(label, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: accent, letterSpacing: 1.5)),
      pw.SizedBox(height: 6),
      pw.Container(
        width: 78,
        height: 78,
        decoration: pw.BoxDecoration(shape: pw.BoxShape.circle, border: pw.Border.all(color: accent, width: 2)),
        child: pw.ClipOval(
          child: photo != null
              ? pw.Image(photo, fit: pw.BoxFit.cover, width: 78, height: 78)
              : pw.CustomPaint(size: const PdfPoint(78, 78), painter: (canvas, size) => _paintPersonIcon(canvas, size, accent)),
        ),
      ),
      pw.SizedBox(height: 6),
      pw.Text(
        name.isNotEmpty ? name : kNotAvailable,
        textAlign: pw.TextAlign.center,
        maxLines: 2,
        style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold, color: _Palette.ink),
      ),
    ],
  );
}

/// Fallback avatar for whichever side has no photo — a plain head-and-
/// shoulders silhouette (no external icon asset needed), tinted with that
/// side's accent color so bride/groom stay visually distinct even without
/// a photo.
void _paintPersonIcon(PdfGraphics canvas, PdfPoint size, PdfColor color) {
  final w = size.x, h = size.y;
  canvas
    ..setFillColor(PdfColor.fromInt(0xFFF3E9E9))
    ..drawRect(0, 0, w, h)
    ..fillPath();
  canvas
    ..setFillColor(color)
    ..drawEllipse(w / 2, h * 0.62, w * 0.16, w * 0.16)
    ..fillPath();
  canvas
    ..setFillColor(color)
    ..drawRRect(w * 0.22, -h * 0.05, w * 0.56, h * 0.42, w * 0.16, w * 0.16)
    ..fillPath();
}

// ── Birth details ────────────────────────────────────────────────────────

pw.Widget _birthDetailsCard(
  String label,
  PartnerKundliChart? chart,
  PartnerParamparaResult? parampara,
  PdfColor accent,
) {
  final moon = chart?.planets.where((p) => p.graha == 'MOON').cast<KundliPlanetPosition?>().firstWhere((_) => true, orElse: () => null);
  final rows = <List<String>>[
    ['Lagna', chart?.lagnaRashiName.isNotEmpty == true ? chart!.lagnaRashiName : kNotAvailable],
    ['Rashi (Moon Sign)', moon?.rashiName.isNotEmpty == true ? moon!.rashiName : kNotAvailable],
    ['Nakshatra', moon?.nakshatraName.isNotEmpty == true ? moon!.nakshatraName : kNotAvailable],
    ['Pada', moon != null && moon.nakshatraPada > 0 ? '${moon.nakshatraPada}' : kNotAvailable],
    // Gotra / Pravara / Kuladevata / Kuladevi — the self-declared Daivagna
    // Parampara fields, same rows the full detailed report already shows
    // (paramparaPartnerRows), just folded into this card rather than a
    // separate section.
    ...paramparaPartnerRows(parampara),
  ];
  return pw.Container(
    padding: const pw.EdgeInsets.all(8),
    decoration: pw.BoxDecoration(border: pw.Border.all(color: accent, width: 0.8), borderRadius: pw.BorderRadius.circular(4)),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('$label - BIRTH DETAILS', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: accent)),
        pw.SizedBox(height: 5),
        for (final r in rows)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 3),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(r[0], style: pw.TextStyle(fontSize: 8, color: _Palette.muted)),
                pw.Text(r[1], style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _Palette.ink)),
              ],
            ),
          ),
      ],
    ),
  );
}

// ── Ashtakoota / Karnataka tables ───────────────────────────────────────

List<List<String>> _ashtakootaRows(AshtakootaResult? a) {
  if (a == null || a.isUnavailable) return const [];
  return [
    for (final k in orderedKootas(a.kootas))
      [kootaLabel(k.code), k.earned != null ? '${k.earned}/${k.maximum}' : kNotAvailable, poruthamStatusLabel(k.status)],
  ];
}

List<List<String>> _karnatakaRows(CompatibilityJataka? jataka) {
  if (jataka == null) return const [];
  return [
    for (final p in orderedPoruthams(jataka.poruthams)) [poruthamLabel(p.code), poruthamStatusLabel(p.status)],
  ];
}

pw.Widget _compactTable(List<String> headers, List<List<String>> rows) {
  if (rows.isEmpty) {
    return pw.Text(kNotAvailable, style: pw.TextStyle(fontSize: 9, color: _Palette.muted, fontStyle: pw.FontStyle.italic));
  }
  return pw.TableHelper.fromTextArray(
    headers: headers,
    data: rows,
    headerStyle: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
    headerDecoration: const pw.BoxDecoration(color: _Palette.maroon),
    cellStyle: pw.TextStyle(fontSize: 8, color: _Palette.ink),
    cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
    border: pw.TableBorder.all(color: _Palette.gold, width: 0.4),
    oddRowDecoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFFFBF3E3)),
  );
}

// ── Verdict banner ───────────────────────────────────────────────────────

class _Verdict {
  const _Verdict(this.label, this.color);
  final String label;
  final PdfColor color;
}

/// Only ever labels what the backend already computed (`overall.status` +
/// `overall.percentage`) — never invents a new compatibility threshold.
_Verdict _verdict(OverallCompatibility overall) => switch (overall.status) {
      AstrologyModuleStatus.calculated => _Verdict(
          overall.percentage != null ? '${overall.percentage}% OVERALL COMPATIBILITY' : 'CALCULATED',
          _Palette.good,
        ),
      AstrologyModuleStatus.reviewRequired => const _Verdict('REVIEW REQUIRED', _Palette.review),
      AstrologyModuleStatus.notCalculable ||
      AstrologyModuleStatus.unknown =>
        const _Verdict('NOT AVAILABLE', _Palette.unavailable),
    };

pw.Widget _verdictBanner(OverallCompatibility overall, _Verdict verdict) {
  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: verdict.color, width: 1.2),
      borderRadius: pw.BorderRadius.circular(4),
      color: PdfColor.fromInt(0xFFFBF3E3),
    ),
    child: pw.Text(verdict.label, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: verdict.color, letterSpacing: 1)),
  );
}

// ── Footer ───────────────────────────────────────────────────────────────

pw.Widget _footer(CompatibilityReport report) {
  return pw.Column(
    children: [
      pw.SizedBox(height: 4),
      pw.Container(height: 0.8, width: double.infinity, color: _Palette.gold),
      pw.SizedBox(height: 6),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Daivajna Samaja', style: pw.TextStyle(fontSize: 8, color: _Palette.muted)),
          pw.Text(
            'Certificate generated ${_formatDate(DateTime.now())}',
            style: pw.TextStyle(fontSize: 8, color: _Palette.muted),
          ),
        ],
      ),
    ],
  );
}

String _formatDate(DateTime d) {
  final local = d.toLocal();
  final y = local.year.toString().padLeft(4, '0');
  final m = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

// ── Asset / network image loading (best-effort — never fails the PDF) ────

Future<pw.ImageProvider?> _tryLoadAsset(String path) async {
  try {
    final data = await rootBundle.load(path);
    return pw.MemoryImage(data.buffer.asUint8List());
  } catch (_) {
    return null; // not supplied yet — the plain drawn border is used instead
  }
}

Future<pw.ImageProvider?> _tryLoadNetworkImage(String? url) async {
  if (url == null || url.isEmpty) return null;
  try {
    final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 8));
    if (res.statusCode != 200 || res.bodyBytes.isEmpty) return null;
    return pw.MemoryImage(res.bodyBytes);
  } catch (_) {
    return null; // no photo — the fallback icon is used instead
  }
}
