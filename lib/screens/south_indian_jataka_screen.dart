import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/api_client.dart';
import '../data/models/compatibility_models.dart';
import '../data/models/south_indian_jataka.dart';
import '../data/repository.dart';
import '../l10n/generated/app_localizations.dart';
import '../theme/app_theme.dart';
import '../widgets/compatibility_status_ui.dart' show statusColorTone;
import '../widgets/ui_kit.dart';

/// STEP F1 — South Indian Jataka result screen, reached from the "Check
/// Compatibility" screen's Jataka module card. Fetches
/// `GET /api/v1/compatibility/reports/:reportId/south-indian-jataka` and
/// renders the Karnataka 10-Porutham and Ashtakoota 36-Guna results exactly
/// as the backend computed them — nothing here calculates a Nakshatra,
/// Rashi, Porutham, Koota, or any score, and no raw birth data (DOB, time,
/// coordinates) is ever displayed.
class SouthIndianJatakaScreen extends StatefulWidget {
  const SouthIndianJatakaScreen({
    super.key,
    required this.reportId,
    this.otherName = '',
  });

  final String reportId;
  final String otherName;

  @override
  State<SouthIndianJatakaScreen> createState() =>
      _SouthIndianJatakaScreenState();
}

class _SouthIndianJatakaScreenState extends State<SouthIndianJatakaScreen> {
  bool _loading = true;
  CompatibilityRequestError? _error;
  SouthIndianJatakaResult? _result;

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
      final r = await Repository.instance.southIndianJataka(widget.reportId);
      if (!mounted) return;
      setState(() {
        _result = r;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = CompatibilityRequestError.fromApiException(e);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = CompatibilityRequestError(
          reason: CompatibilityErrorReason.apiError,
          message: AppLocalizations.of(context).jatakaLoadError,
        );
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final otherName = widget.otherName.trim().isNotEmpty
        ? widget.otherName.trim()
        : t.compThisMember;

    return Scaffold(
      backgroundColor: context.onBrightness(
        light: AppColors.cream,
        dark: AppColors.darkBg,
      ),
      appBar: AppBar(
        backgroundColor: AppColors.forest800,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(t.jatakaTitle, style: display(18, color: Colors.white)),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? _errorState(_error!, t)
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                children: [
                  Text(
                    t.compYouAnd(otherName),
                    style: body(
                      13,
                      weight: FontWeight.w600,
                      color: context.onBrightness(
                        light: AppColors.textMuted,
                        dark: AppColors.darkTextMuted,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  ..._content(_result!, t),
                ],
              ),
      ),
    );
  }

  // ── Error state ────────────────────────────────────────────────────────

  Widget _errorState(CompatibilityRequestError error, AppLocalizations t) {
    final mine = error.profile == CompatibilityErrorProfile.a;
    final (String? actionLabel, VoidCallback? onAction) = !mine
        ? (null, null)
        : switch (error.reason) {
            CompatibilityErrorReason.missingConsent => (
              t.compManageConsent,
              () => context.push('/matrimonial/compatibility-consent'),
            ),
            CompatibilityErrorReason.missingBirthData => (
              t.compAddBirthDetailsBtn,
              () => context.push('/matrimonial/birth-details'),
            ),
            CompatibilityErrorReason.missingRole ||
            CompatibilityErrorReason.apiError => (null, null),
          };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 32,
              color: context.onBrightness(
                light: AppColors.hint,
                dark: AppColors.darkTextMuted,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              error.message,
              textAlign: TextAlign.center,
              style: body(
                14,
                color: context.onBrightness(
                  light: AppColors.textMuted,
                  dark: AppColors.darkTextMuted,
                ),
              ),
            ),
            const SizedBox(height: 14),
            if (actionLabel != null) ...[
              ForestButton(label: actionLabel, onPressed: onAction),
              const SizedBox(height: 10),
            ],
            OutlineButtonX(label: t.compTryAgain, onPressed: _load),
          ],
        ),
      ),
    );
  }

  // ── Success content ───────────────────────────────────────────────────

  List<Widget> _content(SouthIndianJatakaResult r, AppLocalizations t) {
    final widgets = <Widget>[];

    switch (r.status) {
      case AstrologyModuleStatus.reviewRequired:
        widgets
          ..add(
            _notice(
              icon: Icons.rate_review_outlined,
              title: t.jatakaReviewRequired,
              message: t.jatakaReviewRequiredBody,
              bg: const Color(0xFFFFF8E8),
              fg: AppColors.gold700,
            ),
          )
          ..add(const SizedBox(height: 14));
        break;
      case AstrologyModuleStatus.notCalculable:
        widgets.add(
          _notice(
            icon: Icons.info_outline_rounded,
            title: t.jatakaNotCalculableTitle,
            message: t.jatakaNotCalculableBody,
            bg: const Color(0xFFFFF8E8),
            fg: AppColors.gold700,
          ),
        );
        return widgets;
      case AstrologyModuleStatus.calculated:
      case AstrologyModuleStatus.unknown:
        break;
    }

    final karnataka = r.karnatakaPorutham;
    if (karnataka != null) {
      widgets
        ..add(_karnatakaScoreCard(karnataka, t))
        ..add(const SizedBox(height: 14))
        ..add(_criticalChecksCard(karnataka, t))
        ..add(const SizedBox(height: 14))
        ..add(_poruthamListCard(karnataka, t));
    } else {
      widgets.add(
        _notice(
          icon: Icons.info_outline_rounded,
          title: t.jatakaNoKarnatakaTitle,
          message: t.jatakaNoKarnatakaBody,
          bg: const Color(0xFFFFF8E8),
          fg: AppColors.gold700,
        ),
      );
    }

    widgets
      ..add(const SizedBox(height: 14))
      ..add(_ashtakootaCard(r.ashtakoota, t));

    // overallAstrologyScore is always null today (no approved formula
    // combines the two systems) — only rendered if the backend ever sends
    // one; Flutter never computes a stand-in itself.
    if (r.overallAstrologyScore != null) {
      widgets
        ..add(const SizedBox(height: 14))
        ..add(_overallScoreCard(r.overallAstrologyScore!, t));
    }

    return widgets;
  }

  Widget _notice({
    required IconData icon,
    required String title,
    required String message,
    required Color bg,
    required Color fg,
  }) {
    return AppCard(
      color: bg,
      border: false,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: fg),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: body(14, weight: FontWeight.w700, color: fg),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: body(13, color: AppColors.textMuted, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _karnatakaScoreCard(KarnatakaPoruthamResult k, AppLocalizations t) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.jatakaSectionLabel,
            style: body(
              11,
              weight: FontWeight.w700,
              color: context.onBrightness(
                light: AppColors.gold700,
                dark: AppColors.goldSoft,
              ),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            t.jatakaKarnataka10Porutham,
            style: display(
              18,
              color: context.onBrightness(
                light: AppColors.forest900,
                dark: AppColors.darkText,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            t.jatakaMatchedOf(
              '${k.traditionalScoreMatched}',
              '${k.traditionalScoreTotal}',
            ),
            style: display(
              24,
              color: context.onBrightness(
                light: AppColors.forest900,
                dark: AppColors.darkText,
              ),
            ),
          ),
          if (k.ruleVersion != null) ...[
            const SizedBox(height: 2),
            Text(
              t.jatakaRuleVersion('${k.ruleVersion}'),
              style: body(
                11,
                color: context.onBrightness(
                  light: AppColors.textMuted,
                  dark: AppColors.darkTextMuted,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _countChip(
                t.jatakaChipMatched,
                k.matchedCount,
                AppColors.forest700,
              ),
              _countChip(
                t.jatakaChipPartial,
                k.partialCount,
                AppColors.gold700,
              ),
              _countChip(
                t.jatakaChipNotMatched,
                k.notMatchedCount,
                Colors.red.shade700,
              ),
              if (k.reviewRequiredCount > 0)
                _countChip(
                  t.jatakaChipReview,
                  k.reviewRequiredCount,
                  AppColors.gold700,
                ),
              if (k.notCalculableCount > 0)
                _countChip(
                  t.jatakaChipUnavailable,
                  k.notCalculableCount,
                  AppColors.hint,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _countChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: context.onBrightness(
          light: Colors.white,
          dark: AppColors.darkSurface,
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: context.onBrightness(
            light: AppColors.border,
            dark: AppColors.darkBorder,
          ),
        ),
      ),
      child: Text(
        '$label: $count',
        style: body(
          12,
          weight: FontWeight.w700,
          color: statusColorTone(context, color),
        ),
      ),
    );
  }

  /// Rajju and Vedha, using the aggregate-level `rajjuStatus`/`rajjuCritical`/
  /// `vedhaStatus`/`vedhaCritical` fields directly — an independent gate that
  /// is never folded into the overall matched count, and never merged with
  /// each other into one generic failure.
  Widget _criticalChecksCard(KarnatakaPoruthamResult k, AppLocalizations t) {
    return AppCard(
      color: const Color(0xFFFEF7F7),
      border: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.priority_high_rounded,
                size: 18,
                color: Colors.red.shade700,
              ),
              const SizedBox(width: 6),
              Text(
                t.jatakaCriticalChecks,
                style: body(
                  13,
                  weight: FontWeight.w700,
                  color: Colors.red.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _criticalRow(
            t.jatakaRajju,
            k.rajjuStatus,
            k.rajjuCritical,
            k.rajjuResult,
            t,
          ),
          const Divider(height: 20),
          _criticalRow(
            t.jatakaVedha,
            k.vedhaStatus,
            k.vedhaCritical,
            k.vedhaResult,
            t,
          ),
        ],
      ),
    );
  }

  Widget _criticalRow(
    String label,
    PoruthamStatus? status,
    bool critical,
    PoruthamResult? result,
    AppLocalizations t,
  ) {
    final (IconData icon, Color color, String statusLabel) = switch (status) {
      PoruthamStatus.matched => (
        Icons.check_circle_rounded,
        AppColors.forest700,
        t.jatakaStatusMatched,
      ),
      PoruthamStatus.partial => (
        Icons.adjust_rounded,
        AppColors.gold700,
        t.jatakaStatusPartial,
      ),
      PoruthamStatus.notMatched => (
        Icons.cancel_rounded,
        Colors.red.shade700,
        t.jatakaStatusNotMatched,
      ),
      PoruthamStatus.reviewRequired => (
        Icons.rate_review_outlined,
        AppColors.gold700,
        t.jatakaStatusReviewRequired,
      ),
      PoruthamStatus.notCalculable => (
        Icons.remove_circle_outline_rounded,
        AppColors.hint,
        t.jatakaStatusUnavailable,
      ),
      PoruthamStatus.unknown || null => (
        Icons.help_outline_rounded,
        AppColors.hint,
        t.jatakaStatusUnknown,
      ),
    };
    final explanation = result?.explanation ?? '';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: body(
                        13,
                        weight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  if (critical) ...[
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 14,
                      color: Colors.red.shade700,
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    statusLabel,
                    style: body(12, weight: FontWeight.w700, color: color),
                  ),
                ],
              ),
              if (explanation.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  explanation,
                  style: body(11, color: AppColors.textMuted, height: 1.3),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _poruthamListCard(KarnatakaPoruthamResult k, AppLocalizations t) {
    final ordered = orderedPoruthams(k.results);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.jatakaThe10Poruthams,
            style: display(
              15,
              color: context.onBrightness(
                light: AppColors.forest900,
                dark: AppColors.darkText,
              ),
            ),
          ),
          const SizedBox(height: 10),
          for (final p in ordered) _poruthamRow(p, t),
        ],
      ),
    );
  }

  /// Status → indicator icon/color/label. Only ever maps what the API
  /// returned in `status` — never inferred from `score`.
  Widget _poruthamRow(PoruthamResult p, AppLocalizations t) {
    final (IconData icon, Color color, String label) = switch (p.status) {
      PoruthamStatus.matched => (
        Icons.check_circle_rounded,
        AppColors.forest700,
        t.jatakaStatusMatched,
      ),
      PoruthamStatus.partial => (
        Icons.adjust_rounded,
        AppColors.gold700,
        t.jatakaStatusPartial,
      ),
      PoruthamStatus.notMatched => (
        Icons.cancel_rounded,
        Colors.red.shade700,
        t.jatakaStatusNotMatched,
      ),
      PoruthamStatus.reviewRequired => (
        Icons.rate_review_outlined,
        AppColors.gold700,
        t.jatakaStatusReviewRequired,
      ),
      PoruthamStatus.notCalculable => (
        Icons.remove_circle_outline_rounded,
        AppColors.hint,
        t.jatakaStatusUnavailable,
      ),
      PoruthamStatus.unknown => (
        Icons.help_outline_rounded,
        AppColors.hint,
        t.jatakaStatusUnknown,
      ),
    };
    // A critical row is always wrapped by the caller below in its own fixed
    // pastel red card (never the theme-following default) — only the
    // non-critical path, which sits directly on that default, needs its
    // colors to follow the theme.
    final resolvedColor = p.critical ? color : statusColorTone(context, color);
    final resolvedLabelColor = p.critical
        ? Colors.red.shade800
        : context.onBrightness(light: AppColors.ink, dark: AppColors.darkText);
    final resolvedExplanationColor = p.critical
        ? AppColors.textMuted
        : context.onBrightness(
            light: AppColors.textMuted,
            dark: AppColors.darkTextMuted,
          );

    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: resolvedColor),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      poruthamLabel(p.code),
                      style: body(
                        13,
                        weight: FontWeight.w700,
                        color: resolvedLabelColor,
                      ),
                    ),
                  ),
                  if (p.critical) ...[
                    Icon(
                      Icons.priority_high_rounded,
                      size: 14,
                      color: Colors.red.shade700,
                    ),
                    const SizedBox(width: 2),
                  ],
                  Text(
                    label,
                    style: body(
                      12,
                      weight: FontWeight.w700,
                      color: resolvedColor,
                    ),
                  ),
                ],
              ),
              // The backend's own explanation — never re-derived here.
              if (p.explanation.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  p.explanation,
                  style: body(11, color: resolvedExplanationColor, height: 1.3),
                ),
              ],
            ],
          ),
        ),
      ],
    );

    if (!p.critical) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: content,
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: content,
    );
  }

  // ── Ashtakoota ─────────────────────────────────────────────────────────

  Widget _ashtakootaCard(AshtakootaResult? a, AppLocalizations t) {
    if (a == null || a.isUnavailable) {
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.jatakaAshtakootaLabel,
              style: body(
                11,
                weight: FontWeight.w700,
                color: context.onBrightness(
                  light: AppColors.gold700,
                  dark: AppColors.goldSoft,
                ),
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.hourglass_top_rounded,
                  size: 18,
                  color: context.onBrightness(
                    light: AppColors.hint,
                    dark: AppColors.darkTextMuted,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    t.jatakaAshtakootaUnavailable,
                    style: body(
                      13,
                      color: context.onBrightness(
                        light: AppColors.textMuted,
                        dark: AppColors.darkTextMuted,
                      ),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.jatakaAshtakootaLabel,
            style: body(
              11,
              weight: FontWeight.w700,
              color: context.onBrightness(
                light: AppColors.gold700,
                dark: AppColors.goldSoft,
              ),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${a.earned} / ${a.maximum}',
            style: display(
              24,
              color: context.onBrightness(
                light: AppColors.forest900,
                dark: AppColors.darkText,
              ),
            ),
          ),
          const SizedBox(height: 12),
          for (final koota in orderedKootas(a.kootas)) _kootaRow(koota, t),
        ],
      ),
    );
  }

  Widget _kootaRow(KootaResult k, AppLocalizations t) {
    final (IconData icon, Color color, String label) = switch (k.status) {
      PoruthamStatus.matched => (
        Icons.check_circle_rounded,
        AppColors.forest700,
        t.jatakaStatusMatched,
      ),
      PoruthamStatus.partial => (
        Icons.adjust_rounded,
        AppColors.gold700,
        t.jatakaStatusPartial,
      ),
      PoruthamStatus.notMatched => (
        Icons.cancel_rounded,
        Colors.red.shade700,
        t.jatakaStatusNotMatched,
      ),
      PoruthamStatus.reviewRequired => (
        Icons.rate_review_outlined,
        AppColors.gold700,
        t.jatakaStatusReviewRequired,
      ),
      PoruthamStatus.notCalculable => (
        Icons.remove_circle_outline_rounded,
        AppColors.hint,
        t.jatakaStatusUnavailable,
      ),
      PoruthamStatus.unknown => (
        Icons.help_outline_rounded,
        AppColors.hint,
        t.jatakaStatusUnknown,
      ),
    };
    final scoreLabel = k.earned != null ? '${k.earned}/${k.maximum}' : label;
    final resolvedColor = statusColorTone(context, color);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: resolvedColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        kootaLabel(k.code),
                        style: body(
                          13,
                          weight: FontWeight.w700,
                          color: context.onBrightness(
                            light: AppColors.ink,
                            dark: AppColors.darkText,
                          ),
                        ),
                      ),
                    ),
                    Text(
                      scoreLabel,
                      style: body(
                        12,
                        weight: FontWeight.w700,
                        color: resolvedColor,
                      ),
                    ),
                  ],
                ),
                if (k.explanation.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    k.explanation,
                    style: body(
                      11,
                      color: context.onBrightness(
                        light: AppColors.textMuted,
                        dark: AppColors.darkTextMuted,
                      ),
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _overallScoreCard(num score, AppLocalizations t) {
    return AppCard(
      color: const Color(0xFFF0FBF4),
      border: false,
      child: Row(
        children: [
          const Icon(Icons.stars_rounded, size: 24, color: AppColors.forest700),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.jatakaOverallScore,
                  style: body(
                    12,
                    weight: FontWeight.w700,
                    color: AppColors.forest700,
                  ),
                ),
                Text('$score', style: display(18, color: AppColors.forest900)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
