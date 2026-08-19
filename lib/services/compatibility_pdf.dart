/// STEP 77–78 — builds the Marriage Compatibility PDF report from an
/// already-fetched [CompatibilityReport]. Purely a rendering layer over
/// `compatibility_pdf_content.dart`'s content builders — nothing here
/// recalculates a percentage, a score, or a discussion point; the backend
/// remains the single source of truth. No network calls happen in this file.
library;

import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../data/models/compatibility_models.dart';
import 'compatibility_pdf_content.dart';

class _Styles {
  _Styles()
      : title = pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.green900),
        subtitle = pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
        section = pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.green800),
        subheading = pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900),
        body = pw.TextStyle(fontSize: 10, color: PdfColors.grey900),
        muted = pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
        tableHeader = pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
        tableCell = pw.TextStyle(fontSize: 9, color: PdfColors.grey900);

  final pw.TextStyle title;
  final pw.TextStyle subtitle;
  final pw.TextStyle section;
  final pw.TextStyle subheading;
  final pw.TextStyle body;
  final pw.TextStyle muted;
  final pw.TextStyle tableHeader;
  final pw.TextStyle tableCell;
}

/// Builds the complete PDF and returns its bytes. [person1Name]/[person2Name]
/// are the display names already known to the UI (report.profileAId /
/// profileBId carry no name) — passed in rather than re-derived here.
Future<Uint8List> buildCompatibilityPdfBytes({
  required CompatibilityReport report,
  required String person1Name,
  required String person2Name,
}) async {
  final s = _Styles();
  final doc = pw.Document();
  final generatedAt = DateTime.now();

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(32, 28, 32, 32),
      header: (context) => _pageHeader(context, s),
      footer: (context) => _pageFooter(context, generatedAt, s),
      build: (context) => [
        _titleBlock(person1Name, person2Name, report, s),
        pw.SizedBox(height: 14),
        _section('Overall Compatibility', s),
        _kvTable(overallSummaryRows(report), s),
        pw.SizedBox(height: 12),
        _section('Profile Compatibility', s),
        _bullets(profileCompatibilityLines(report.profileCompatibility), s),
        pw.SizedBox(height: 12),
        _section('Karnataka 10 Porutham', s),
        _bullets(karnatakaSummaryLines(report.jataka), s),
        _findingTable(const ['Porutham', 'Result', 'Explanation'], karnatakaPoruthamRows(report.jataka), s,
            columnWidths: const {0: pw.FlexColumnWidth(2), 1: pw.FlexColumnWidth(1.4), 2: pw.FlexColumnWidth(4)}),
        pw.SizedBox(height: 12),
        _section('Ashtakoota 36 Guna', s),
        _bullets(ashtakootaSummaryLines(report.ashtakoota, report.astrologyCompatibility?.ashtakoota), s),
        _findingTable(const ['Koota', 'Score', 'Result', 'Explanation'], ashtakootaKootaRows(report.ashtakoota), s,
            columnWidths: const {0: pw.FlexColumnWidth(1.6), 1: pw.FlexColumnWidth(1), 2: pw.FlexColumnWidth(1.4), 3: pw.FlexColumnWidth(4)}),
        pw.SizedBox(height: 12),
        _section('Advanced Jataka', s),
        _bullets(advancedJatakaSummaryLines(report.advancedJataka), s),
        if (report.advancedJataka != null) ...[
          _subHeading('Bride', s),
          _findingTable(const ['Finding', 'Status', 'Details'], advancedJatakaFindingRows(report.advancedJataka!.bride), s,
              columnWidths: const {0: pw.FlexColumnWidth(2), 1: pw.FlexColumnWidth(1.4), 2: pw.FlexColumnWidth(4)}),
          _subHeading('Groom', s),
          _findingTable(const ['Finding', 'Status', 'Details'], advancedJatakaFindingRows(report.advancedJataka!.groom), s,
              columnWidths: const {0: pw.FlexColumnWidth(2), 1: pw.FlexColumnWidth(1.4), 2: pw.FlexColumnWidth(4)}),
        ],
        pw.SizedBox(height: 12),
        _section('Kuja Dosha', s),
        _bullets(kujaDoshaSummaryLines(report.kujaDosha), s),
        if (report.kujaDosha != null) ...[
          _subHeading('Bride', s),
          _bullets(kujaDoshaPartnerLines(report.kujaDosha!.bride), s),
          _subHeading('Groom', s),
          _bullets(kujaDoshaPartnerLines(report.kujaDosha!.groom), s),
        ],
        pw.SizedBox(height: 12),
        _section('Dasha Compatibility', s),
        _bullets(dashaSummaryLines(report.dasha), s),
        if (report.dasha != null) ...[
          _subHeading('Bride', s),
          _bullets(dashaPartnerLines(report.dasha!.bride), s),
          _findingTable(const ['Mahadasha', 'Start', 'End'], dashaMahadashaTimelineRows(report.dasha!.bride), s,
              columnWidths: const {0: pw.FlexColumnWidth(2), 1: pw.FlexColumnWidth(2), 2: pw.FlexColumnWidth(2)}),
          _subHeading('Groom', s),
          _bullets(dashaPartnerLines(report.dasha!.groom), s),
          _findingTable(const ['Mahadasha', 'Start', 'End'], dashaMahadashaTimelineRows(report.dasha!.groom), s,
              columnWidths: const {0: pw.FlexColumnWidth(2), 1: pw.FlexColumnWidth(2), 2: pw.FlexColumnWidth(2)}),
        ],
        pw.SizedBox(height: 12),
        _section('Vivaha Kala Bala', s),
        _bullets(vivahaKalaBalaSummaryLines(report.vivahaKalaBala), s),
        if (report.vivahaKalaBala != null) _bullets(vivahaKalaBalaDetailLines(report.vivahaKalaBala!), s),
        pw.SizedBox(height: 12),
        _section('Daivagna Parampara', s),
        _bullets(paramparaSummaryLines(report.daivagnaParampara), s),
        if (report.daivagnaParampara != null) ...[
          _subHeading('Bride', s),
          _kvTable(paramparaPartnerRows(report.daivagnaParampara!.bride), s),
          _subHeading('Groom', s),
          _kvTable(paramparaPartnerRows(report.daivagnaParampara!.groom), s),
        ],
        pw.SizedBox(height: 12),
        _section('Kundli Chart (D1 / D9 Planetary Positions)', s),
        _bullets(kundliChartSummaryLines(report.kundliChart), s),
        if (report.kundliChart != null) ...[
          _subHeading('Bride - D1 (Natal)', s),
          _findingTable(
              const ['Point', 'Rashi', 'Nakshatra', 'Pada', 'Retrograde'], kundliPlanetRows(report.kundliChart!.bride), s,
              columnWidths: const {
                0: pw.FlexColumnWidth(1.6),
                1: pw.FlexColumnWidth(1.6),
                2: pw.FlexColumnWidth(1.8),
                3: pw.FlexColumnWidth(0.9),
                4: pw.FlexColumnWidth(1.2),
              }),
          if (report.kundliChart!.bride?.hasNavamsha ?? false) ...[
            _subHeading('Bride - D9 (Navamsha)', s),
            _findingTable(const ['Point', 'Rashi'], kundliNavamshaRows(report.kundliChart!.bride), s,
                columnWidths: const {0: pw.FlexColumnWidth(2), 1: pw.FlexColumnWidth(2)}),
          ],
          _subHeading('Groom - D1 (Natal)', s),
          _findingTable(
              const ['Point', 'Rashi', 'Nakshatra', 'Pada', 'Retrograde'], kundliPlanetRows(report.kundliChart!.groom), s,
              columnWidths: const {
                0: pw.FlexColumnWidth(1.6),
                1: pw.FlexColumnWidth(1.6),
                2: pw.FlexColumnWidth(1.8),
                3: pw.FlexColumnWidth(0.9),
                4: pw.FlexColumnWidth(1.2),
              }),
          if (report.kundliChart!.groom?.hasNavamsha ?? false) ...[
            _subHeading('Groom - D9 (Navamsha)', s),
            _findingTable(const ['Point', 'Rashi'], kundliNavamshaRows(report.kundliChart!.groom), s,
                columnWidths: const {0: pw.FlexColumnWidth(2), 1: pw.FlexColumnWidth(2)}),
          ],
        ],
        if (report.discussionPoints.isNotEmpty) ...[
          pw.SizedBox(height: 12),
          _section('Discussion Points', s),
          _bullets(discussionPointLines(report.discussionPoints), s),
        ],
        pw.SizedBox(height: 14),
        _section('Disclaimer', s),
        pw.Text(
          report.disclaimer.isNotEmpty ? report.disclaimer : kNotAvailable,
          style: s.muted.copyWith(fontStyle: pw.FontStyle.italic),
        ),
      ],
    ),
  );

  return doc.save();
}

pw.Widget _pageHeader(pw.Context context, _Styles s) {
  if (context.pageNumber == 1) return pw.SizedBox();
  return pw.Container(
    alignment: pw.Alignment.centerLeft,
    margin: const pw.EdgeInsets.only(bottom: 8),
    padding: const pw.EdgeInsets.only(bottom: 4),
    decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300))),
    child: pw.Text('Marriage Compatibility Report', style: s.muted),
  );
}

pw.Widget _pageFooter(pw.Context context, DateTime generatedAt, _Styles s) {
  return pw.Container(
    alignment: pw.Alignment.centerRight,
    margin: const pw.EdgeInsets.only(top: 8),
    padding: const pw.EdgeInsets.only(top: 4),
    decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300))),
    child: pw.Text(
      'Generated ${_formatDateTime(generatedAt)}   |   Page ${context.pageNumber} of ${context.pagesCount}',
      style: s.muted,
    ),
  );
}

pw.Widget _titleBlock(String person1, String person2, CompatibilityReport report, _Styles s) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text('MARRIAGE COMPATIBILITY REPORT', style: s.title),
      pw.SizedBox(height: 8),
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Person 1', style: s.muted),
                pw.Text(person1.isNotEmpty ? person1 : kNotAvailable, style: s.subheading),
              ],
            ),
          ),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Person 2', style: s.muted),
                pw.Text(person2.isNotEmpty ? person2 : kNotAvailable, style: s.subheading),
              ],
            ),
          ),
        ],
      ),
      pw.SizedBox(height: 6),
      pw.Text(
        'Report generated: ${report.createdAt != null ? _formatDateTime(report.createdAt!) : kNotAvailable}',
        style: s.subtitle,
      ),
    ],
  );
}

pw.Widget _section(String title, _Styles s) => pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Text(title, style: s.section),
    );

pw.Widget _subHeading(String title, _Styles s) => pw.Padding(
      padding: const pw.EdgeInsets.only(top: 6, bottom: 4),
      child: pw.Text(title, style: s.subheading),
    );

pw.Widget _bullets(List<String> lines, _Styles s) {
  if (lines.isEmpty) return pw.SizedBox();
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      for (final line in lines)
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 2),
          child: pw.Text('-  $line', style: s.body),
        ),
    ],
  );
}

pw.Widget _kvTable(List<List<String>> rows, _Styles s) {
  if (rows.isEmpty) return pw.SizedBox();
  return pw.TableHelper.fromTextArray(
    data: rows,
    cellStyle: s.tableCell,
    cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
    border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
    columnWidths: const {0: pw.FlexColumnWidth(2), 1: pw.FlexColumnWidth(2)},
    cellAlignments: const {0: pw.Alignment.centerLeft, 1: pw.Alignment.centerLeft},
    oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
  );
}

/// A findings table with a colored header row — used for the larger,
/// list-shaped sections (Poruthams, Kootas, Advanced Jataka findings, a
/// Mahadasha timeline) so long content wraps and continues cleanly onto the
/// next page instead of being crammed into one dense block.
pw.Widget _findingTable(
  List<String> headers,
  List<List<String>> rows,
  _Styles s, {
  required Map<int, pw.TableColumnWidth> columnWidths,
}) {
  if (rows.isEmpty) return pw.SizedBox();
  return pw.Padding(
    padding: const pw.EdgeInsets.only(top: 4, bottom: 4),
    child: pw.TableHelper.fromTextArray(
      headers: headers,
      data: rows,
      headerStyle: s.tableHeader,
      headerDecoration: const pw.BoxDecoration(color: PdfColors.green800),
      cellStyle: s.tableCell,
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: columnWidths,
      oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
    ),
  );
}

String _formatDateTime(DateTime d) {
  final local = d.toLocal();
  final y = local.year.toString().padLeft(4, '0');
  final m = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final h = local.hour.toString().padLeft(2, '0');
  final min = local.minute.toString().padLeft(2, '0');
  return '$y-$m-$day $h:$min';
}
