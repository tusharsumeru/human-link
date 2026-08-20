import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/api_client.dart';
import '../data/models/compatibility_models.dart';
import '../data/models/compatibility_summary.dart';
import '../data/models/south_indian_jataka.dart' show AstrologyModuleStatus;
import '../data/repository.dart';
import '../services/auth_service.dart';
import '../services/compatibility_pdf.dart';
import '../services/compatibility_pdf_export.dart';
import '../theme/app_theme.dart';
import '../widgets/ui_kit.dart';
import 'compatibility_report_screen.dart';

/// STEP 73 — the main Marriage Compatibility dashboard: the landing screen
/// once a report exists (reached from [CompatibilityCheckScreen]'s bulk
/// "Check Compatibility" action, by `reportId`). Fetches the same
/// `GET /api/v1/compatibility/reports/:reportId` STEP 72 already wired up
/// and renders only backend-computed figures — Overall/Profile/Astrology
/// Compatibility, a compact Karnataka/Ashtakoota summary, discussion points,
/// and the disclaimer. Nothing here computes a percentage, a Porutham, a
/// Koota, or any astrology result; "View Detailed Report" hands off to the
/// existing [CompatibilityReportScreen] rather than a new engine screen —
/// STEP 74+'s job, not this one's.
class CompatibilityDashboardScreen extends StatefulWidget {
  const CompatibilityDashboardScreen({
    super.key,
    required this.reportId,
    this.otherName = '',
    this.discoveryMatch,
  });

  final String reportId;

  /// Convenience display name for the header — passed by the caller (who
  /// already has it loaded) so it renders immediately, without a second
  /// fetch just for a name. Same convention as [CompatibilityReportScreen].
  final String otherName;

  /// The candidate's `discoveryMatch` object (`{matchPercentage, matchLevel,
  /// factors}`) — a separate, already-computed backend figure (marriage
  /// intention/children/family/relocation/food/interests/location/age
  /// preference alignment, used for browsing matches). Shown in the Profile
  /// Compatibility card ONLY as a fallback when the questionnaire-based
  /// [ProfileCompatibility] hasn't been calculated yet — never blended with
  /// it, never presented as the same figure.
  final Map<String, dynamic>? discoveryMatch;

  @override
  State<CompatibilityDashboardScreen> createState() => _CompatibilityDashboardScreenState();
}

class _CompatibilityDashboardScreenState extends State<CompatibilityDashboardScreen> {
  bool _loading = true;
  String? _error;
  CompatibilityReport? _report;

  // STEP 77-78 — PDF download/share. `_pdfAction` tracks which of the two
  // buttons is currently generating (null when idle) so both can be disabled
  // together (never two PDF generations in flight at once) while only the
  // tapped button shows its own loading state. `_pdfFile` caches the last
  // generated file for this report so a second tap (e.g. Share right after
  // Download) reuses it instead of regenerating the same PDF.
  String? _pdfAction;
  File? _pdfFile;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final report = await Repository.instance.compatibilityReport(widget.reportId);
      if (!mounted) return;
      setState(() {
        _report = report;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        // Same "backend message, never a raw exception" convention every
        // sibling compatibility screen already uses — a 401/403/404/500 all
        // arrive as ApiException with the server's own message; a genuine
        // network failure falls back to a generic one, never a stack trace.
        _error = e is ApiException ? e.message : 'Could not load the compatibility dashboard';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final myName = context.watch<AuthService>().user?.name ?? 'You';
    final otherName = widget.otherName.trim().isNotEmpty ? widget.otherName.trim() : 'This member';

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.forest800,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('Marriage Compatibility', style: display(18, color: Colors.white)),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _errorState(_error!)
                : _content(_report!, myName, otherName),
      ),
    );
  }

  /// Generates the PDF only if it isn't already cached for this report —
  /// [_downloadPdf]/[_shareReport] both funnel through this so tapping
  /// "Share Report" right after "Download PDF" reuses the same file. Trusts
  /// the in-memory cache without re-checking the file still exists on disk —
  /// nothing else in this screen's lifetime deletes it.
  Future<File> _ensurePdf(CompatibilityReport report, String myName, String otherName) async {
    final cached = _pdfFile;
    if (cached != null) return cached;
    final bytes = await buildCompatibilityPdfBytes(report: report, person1Name: myName, person2Name: otherName);
    final file = await saveCompatibilityPdf(bytes: bytes, person1Name: myName, person2Name: otherName);
    _pdfFile = file;
    return file;
  }

  Future<void> _downloadPdf(CompatibilityReport report, String myName, String otherName) async {
    if (_pdfAction != null) return; // guards against a double tap firing twice
    setState(() => _pdfAction = 'download');
    try {
      final file = await _ensurePdf(report, myName, otherName);
      if (!mounted) return;
      _showSnack('PDF saved: ${file.uri.pathSegments.last}');
    } catch (_) {
      if (!mounted) return;
      _showSnack(
        'Could not generate the PDF. Please try again.',
        isError: true,
        onRetry: () => _downloadPdf(report, myName, otherName),
      );
    } finally {
      if (mounted) setState(() => _pdfAction = null);
    }
  }

  Future<void> _shareReport(CompatibilityReport report, String myName, String otherName) async {
    if (_pdfAction != null) return; // guards against a double tap firing twice
    setState(() => _pdfAction = 'share');
    try {
      final file = await _ensurePdf(report, myName, otherName);
      if (!mounted) return;
      await shareCompatibilityPdf(file, subject: 'Marriage Compatibility Report - $myName × $otherName');
    } catch (_) {
      if (!mounted) return;
      _showSnack(
        'Could not share the PDF. Please try again.',
        isError: true,
        onRetry: () => _shareReport(report, myName, otherName),
      );
    } finally {
      if (mounted) setState(() => _pdfAction = null);
    }
  }

  void _showSnack(String message, {bool isError = false, VoidCallback? onRetry}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message, style: body(13, color: Colors.white)),
        backgroundColor: isError ? Colors.red.shade700 : AppColors.forest800,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        action: onRetry != null ? SnackBarAction(label: 'Retry', textColor: Colors.white, onPressed: onRetry) : null,
      ));
  }

  Widget _errorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 32, color: AppColors.hint),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: body(14, color: AppColors.textMuted)),
            const SizedBox(height: 14),
            OutlineButtonX(label: 'Try again', onPressed: _load),
          ],
        ),
      ),
    );
  }

  Widget _content(CompatibilityReport report, String myName, String otherName) {
    final astro = report.astrologyCompatibility;

    // Profile Compatibility is the questionnaire-based figure
    // (ProfileCompatibility, consent-gated) and is always shown when the
    // backend has calculated it. Only when it hasn't do we fall back to the
    // Discovery Match percentage already loaded for this candidate — a
    // separate, already-computed backend figure (marriage intention/
    // children/family/relocation/food/interests/location/age alignment) —
    // rather than leaving the card empty.
    final profilePercentage = report.profileCompatibility?.percentage;
    final discoveryPercentage = (widget.discoveryMatch?['matchPercentage'] is num)
        ? (widget.discoveryMatch!['matchPercentage'] as num).round()
        : null;
    final usingDiscoveryFallback = profilePercentage == null && discoveryPercentage != null;
    final effectiveProfilePercentage = profilePercentage ?? discoveryPercentage;

    // Overall Compatibility: the backend's own figure is used as-is UNLESS
    // we're substituting Discovery Match for Profile Compatibility above —
    // in that one case the backend never saw a profile figure at all, so its
    // own overall is astrology-only. Recompute the same 50/50 (profileWeight/
    // astrologyWeight) blend the backend itself uses, now that a profile
    // figure (Discovery Match) is actually available client-side.
    final overall = report.overallCompatibility;
    int? overallPercentage = overall.percentage;
    AstrologyModuleStatus overallStatus = overall.status;
    if (usingDiscoveryFallback) {
      final astrologyPercentage = astro?.percentage;
      if (astrologyPercentage != null) {
        final pWeight = overall.profileWeight;
        final aWeight = overall.astrologyWeight;
        final totalWeight = pWeight + aWeight;
        overallPercentage = totalWeight > 0
            ? ((discoveryPercentage * pWeight + astrologyPercentage * aWeight) / totalWeight).round()
            : discoveryPercentage;
        overallStatus = AstrologyModuleStatus.calculated;
      } else {
        overallPercentage = discoveryPercentage;
        overallStatus = AstrologyModuleStatus.reviewRequired;
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        _header(myName, otherName),
        const SizedBox(height: 20),
        _overallCard(percentage: overallPercentage, status: overallStatus),
        const SizedBox(height: 14),
        // Two summary cards side by side — both narrow enough on a phone
        // screen that Row+Expanded never overflows; each card wraps its own
        // text rather than forcing a fixed width. Deliberately NOT
        // CrossAxisAlignment.stretch: this Row is a direct ListView child,
        // which hands it an unbounded height, and stretch would then try to
        // give both cards infinite height ("BoxConstraints forces an
        // infinite height") — the cards just size to their own content,
        // which reads fine even when one is one line taller than the other.
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _percentageSummaryCard(
              title: 'Profile Compatibility',
              percentage: effectiveProfilePercentage,
              status: usingDiscoveryFallback
                  ? AstrologyModuleStatus.calculated
                  : (report.profileCompatibility?.status ?? AstrologyModuleStatus.notCalculable),
              unavailableText: 'Not enough profile information',
            )),
            const SizedBox(width: 12),
            Expanded(child: _percentageSummaryCard(
              title: 'Astrology Compatibility',
              percentage: astro?.percentage,
              status: astro?.status ?? AstrologyModuleStatus.notCalculable,
              unavailableText: 'Not enough astrology information',
            )),
          ],
        ),
        if (astro != null) ...[
          const SizedBox(height: 14),
          _astrologySummaryCard(astro),
        ],
        if (report.discussionPoints.isNotEmpty) ...[
          const SizedBox(height: 14),
          _discussionPointsCard(report.discussionPoints),
        ],
        const SizedBox(height: 14),
        _detailedReportButton(otherName),
        const SizedBox(height: 10),
        _pdfActionsRow(report, myName, otherName),
        const SizedBox(height: 14),
        _disclaimerCard(report.disclaimer),
      ],
    );
  }

  Widget _header(String myName, String otherName) {
    return AppCard(
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(color: Color(0xFFFCEBDD), shape: BoxShape.circle),
            child: const Icon(Icons.favorite_rounded, size: 26, color: AppColors.gold700),
          ),
          const SizedBox(height: 14),
          Text('Marriage Compatibility', style: display(20, color: AppColors.forest900), textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text('$myName × $otherName',
              style: body(14, weight: FontWeight.w600, color: AppColors.textMuted), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  /// The primary visual element. [percentage]/[status] are normally the
  /// backend's own [OverallCompatibility] fields verbatim; the one exception
  /// is the Discovery Match fallback scenario in [_content], where they're a
  /// client-side 50/50 blend of the substituted Profile figure and Astrology
  /// Compatibility — the same weights the backend's own blend uses.
  Widget _overallCard({required int? percentage, required AstrologyModuleStatus status}) {
    final visual = _statusVisual(status);
    return AppCard(
      child: Column(
        children: [
          Text('OVERALL COMPATIBILITY',
              style: body(11, weight: FontWeight.w700, color: AppColors.gold700, letterSpacing: 1.4)),
          const SizedBox(height: 14),
          PercentageRing(percentage: percentage, color: visual.color),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(visual.icon, size: 16, color: visual.color),
              const SizedBox(width: 6),
              Text(visual.label, style: body(13, weight: FontWeight.w700, color: visual.color)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _percentageSummaryCard({
    required String title,
    required int? percentage,
    required AstrologyModuleStatus status,
    required String unavailableText,
  }) {
    final visual = _statusVisual(status);
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: body(12, weight: FontWeight.w700, color: AppColors.forest900, height: 1.3)),
          const SizedBox(height: 10),
          if (percentage != null)
            Text('$percentage%', style: display(26, color: AppColors.forest900))
          else
            Text(unavailableText, style: body(12, color: AppColors.textMuted, height: 1.35)),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(visual.icon, size: 13, color: visual.color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(visual.label,
                    style: body(11, weight: FontWeight.w700, color: visual.color),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ],
),
    );
  }

  /// Karnataka 10 Porutham + Ashtakoota 36 Guna — a compact summary only.
  /// Every number here is read straight from [AstrologyCompatibility]
  /// (STEP 64, already computed server-side); nothing is recalculated.
  Widget _astrologySummaryCard(AstrologyCompatibility astro) {
    final karnataka = astro.karnatakaPorutham;
    final ashtakoota = astro.ashtakoota;
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ASTROLOGY SUMMARY',
              style: body(11, weight: FontWeight.w700, color: AppColors.gold700, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _astrologyStat(
                  label: 'Karnataka 10 Porutham',
                  value: '${karnataka.matched}/${karnataka.total}',
                  sublabel: karnataka.percentage != null ? '${karnataka.percentage}%' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: (ashtakoota == null || ashtakoota.earned == null)
                    ? _astrologyStat(
                        label: 'Ashtakoota 36 Guna',
                        value: 'Unavailable',
                        sublabel: null,
                      )
                    : _astrologyStat(
                        label: 'Ashtakoota 36 Guna',
                        value: '${ashtakoota.earned} / ${ashtakoota.maximum}',
                        sublabel: ashtakoota.percentage != null ? '${ashtakoota.percentage}%' : null,
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _astrologyStat({required String label, required String value, required String? sublabel}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: body(11, color: AppColors.textMuted, height: 1.3)),
        const SizedBox(height: 4),
        Text(value, style: display(16, color: AppColors.forest900)),
        if (sublabel != null) ...[
          const SizedBox(height: 2),
          Text(sublabel, style: body(11, weight: FontWeight.w700, color: AppColors.forest700)),
        ],
      ],
    );
  }

  /// Read-only, deterministic points the backend already derived (STEP 69
  /// §11) — this app never generates or reorders them.
  Widget _discussionPointsCard(List<DiscussionPoint> points) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Discussion Points', style: display(15, color: AppColors.forest900)),
          const SizedBox(height: 10),
          for (var i = 0; i < points.length; i++) ...[
            if (i > 0) const Divider(height: 18),
            _discussionPointRow(points[i]),
          ],
        ],
      ),
    );
  }

  Widget _discussionPointRow(DiscussionPoint point) {
    final review = point.severity == 'REVIEW';
    final color = review ? AppColors.gold700 : AppColors.forest700;
    final icon = review ? Icons.rate_review_outlined : Icons.info_outline_rounded;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Expanded(child: Text(point.message, style: body(13, color: AppColors.ink, height: 1.4))),
      ],
    );
  }

  Widget _detailedReportButton(String otherName) {
    return SizedBox(
      height: 48,
      child: OutlineButtonX(
        label: 'View Detailed Report',
        expand: true,
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => CompatibilityReportScreen(reportId: widget.reportId, otherName: otherName),
        )),
      ),
    );
  }

  /// "Download PDF" (saves locally) + "Share Report" (native share sheet) —
  /// both generate the same PDF from the already-fetched [report], never a
  /// new API call. Busy while either is generating so a repeat tap can't
  /// kick off a second PDF build.
  Widget _pdfActionsRow(CompatibilityReport report, String myName, String otherName) {
    final busy = _pdfAction != null;
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 48,
            child: OutlineButtonX(
              label: _pdfAction == 'download' ? 'Generating…' : 'Download PDF',
              expand: true,
              onPressed: busy ? null : () => _downloadPdf(report, myName, otherName),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SizedBox(
            height: 48,
            child: ForestButton(
              label: 'Share Report',
              icon: Icons.ios_share_rounded,
              expand: true,
              loading: _pdfAction == 'share',
              onPressed: busy ? null : () => _shareReport(report, myName, otherName),
            ),
          ),
        ),
      ],
    );
  }

  /// Visually distinct (muted card, small icon) but deliberately low-key —
  /// never a modal/blocking banner. The exact backend string, verbatim,
  /// never paraphrased.
  Widget _disclaimerCard(String disclaimer) {
    if (disclaimer.trim().isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.creamDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.hint),
          const SizedBox(width: 8),
          Expanded(child: Text(disclaimer, style: body(11, color: AppColors.textMuted, height: 1.45))),
        ],
      ),
    );
  }

  ({IconData icon, Color color, String label}) _statusVisual(AstrologyModuleStatus status) {
    switch (status) {
      case AstrologyModuleStatus.calculated:
        return (icon: Icons.check_circle_rounded, color: AppColors.forest700, label: 'Calculated');
      case AstrologyModuleStatus.reviewRequired:
        return (icon: Icons.rate_review_outlined, color: AppColors.gold700, label: 'Review required');
      case AstrologyModuleStatus.notCalculable:
      case AstrologyModuleStatus.unknown:
        return (icon: Icons.remove_circle_outline_rounded, color: AppColors.hint, label: 'Not available');
    }
  }
}
