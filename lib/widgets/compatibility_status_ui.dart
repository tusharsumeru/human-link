/// STEP 74–76 — shared presentation building blocks for the detailed
/// Astrology Compatibility sections (Karnataka 10 Porutham, Ashtakoota,
/// Advanced Jataka, Kuja Dosha, Dasha Compatibility, Vivaha Kala Bala,
/// Daivagna Parampara). Every status→(icon, color, label) mapping here only
/// describes how to DISPLAY a status the backend already computed — nothing
/// in this file infers, recomputes, or invents a verdict. Status is always
/// shown with both an icon and text, never color alone (accessibility).
library;

import 'package:flutter/material.dart';

import '../data/models/compatibility_astrology_modules.dart'
    show AstrologyFavorabilityStatus, DashaComparisonStatus, KujaDoshaStatus;
import '../data/models/compatibility_models.dart' show PoruthamStatus;
import '../data/models/parampara.dart' show ParamparaComparisonStatus, ParamparaFieldComparisonStatus;
import '../data/models/south_indian_jataka.dart' show AstrologyModuleStatus;
import '../theme/app_theme.dart';
import 'ui_kit.dart';

/// An icon + color + label for one status value — the app never
/// communicates status by color alone.
class StatusVisual {
  const StatusVisual(this.icon, this.color, this.label);
  final IconData icon;
  final Color color;
  final String label;
}

StatusVisual poruthamStatusVisual(PoruthamStatus status) => switch (status) {
      PoruthamStatus.matched => const StatusVisual(Icons.check_circle_rounded, AppColors.forest700, 'Matched'),
      PoruthamStatus.partial => const StatusVisual(Icons.adjust_rounded, AppColors.gold700, 'Partial'),
      PoruthamStatus.notMatched =>
        StatusVisual(Icons.cancel_rounded, Colors.red.shade700, 'Not matched'),
      PoruthamStatus.reviewRequired =>
        const StatusVisual(Icons.rate_review_outlined, AppColors.gold700, 'Review required'),
      PoruthamStatus.notCalculable =>
        const StatusVisual(Icons.remove_circle_outline_rounded, AppColors.hint, 'Unavailable'),
      PoruthamStatus.unknown => const StatusVisual(Icons.help_outline_rounded, AppColors.hint, 'Unknown'),
    };

StatusVisual moduleStatusVisual(AstrologyModuleStatus status) => switch (status) {
      AstrologyModuleStatus.calculated =>
        const StatusVisual(Icons.check_circle_rounded, AppColors.forest700, 'Calculated'),
      AstrologyModuleStatus.reviewRequired =>
        const StatusVisual(Icons.rate_review_outlined, AppColors.gold700, 'Review required'),
      AstrologyModuleStatus.notCalculable =>
        const StatusVisual(Icons.remove_circle_outline_rounded, AppColors.hint, 'Not calculable'),
      AstrologyModuleStatus.unknown =>
        const StatusVisual(Icons.help_outline_rounded, AppColors.hint, 'Unknown'),
    };

StatusVisual favorabilityStatusVisual(AstrologyFavorabilityStatus status) => switch (status) {
      AstrologyFavorabilityStatus.supportive =>
        const StatusVisual(Icons.thumb_up_alt_rounded, AppColors.forest700, 'Supportive'),
      AstrologyFavorabilityStatus.neutral =>
        const StatusVisual(Icons.trending_flat_rounded, AppColors.textMuted, 'Neutral'),
      AstrologyFavorabilityStatus.caution =>
        const StatusVisual(Icons.warning_amber_rounded, AppColors.gold700, 'Caution'),
      AstrologyFavorabilityStatus.reviewRequired =>
        const StatusVisual(Icons.rate_review_outlined, AppColors.gold700, 'Review required'),
      AstrologyFavorabilityStatus.notCalculable =>
        const StatusVisual(Icons.remove_circle_outline_rounded, AppColors.hint, 'Not calculable'),
      AstrologyFavorabilityStatus.unknown =>
        const StatusVisual(Icons.help_outline_rounded, AppColors.hint, 'Unknown'),
    };

StatusVisual kujaDoshaStatusVisual(KujaDoshaStatus status) => switch (status) {
      KujaDoshaStatus.notPresent =>
        const StatusVisual(Icons.check_circle_rounded, AppColors.forest700, 'Not present'),
      KujaDoshaStatus.mild => const StatusVisual(Icons.info_outline_rounded, AppColors.gold700, 'Mild'),
      KujaDoshaStatus.moderate =>
        const StatusVisual(Icons.warning_amber_rounded, AppColors.gold700, 'Moderate'),
      KujaDoshaStatus.strong =>
        StatusVisual(Icons.priority_high_rounded, Colors.red.shade700, 'Strong'),
      KujaDoshaStatus.cancelled =>
        const StatusVisual(Icons.verified_rounded, AppColors.forest700, 'Cancelled'),
      KujaDoshaStatus.balancedWithPartner =>
        const StatusVisual(Icons.balance_rounded, AppColors.forest700, 'Balanced with partner'),
      KujaDoshaStatus.reviewRequired =>
        const StatusVisual(Icons.rate_review_outlined, AppColors.gold700, 'Review required'),
      KujaDoshaStatus.notCalculable =>
        const StatusVisual(Icons.remove_circle_outline_rounded, AppColors.hint, 'Not calculable'),
      KujaDoshaStatus.unknown => const StatusVisual(Icons.help_outline_rounded, AppColors.hint, 'Unknown'),
    };

StatusVisual dashaComparisonStatusVisual(DashaComparisonStatus status) => switch (status) {
      DashaComparisonStatus.supportive =>
        const StatusVisual(Icons.thumb_up_alt_rounded, AppColors.forest700, 'Supportive'),
      DashaComparisonStatus.neutral =>
        const StatusVisual(Icons.trending_flat_rounded, AppColors.textMuted, 'Neutral'),
      DashaComparisonStatus.sensitiveTransition =>
        const StatusVisual(Icons.swap_horiz_rounded, AppColors.gold700, 'Sensitive transition'),
      DashaComparisonStatus.reviewRequired =>
        const StatusVisual(Icons.rate_review_outlined, AppColors.gold700, 'Review required'),
      DashaComparisonStatus.notCalculable =>
        const StatusVisual(Icons.remove_circle_outline_rounded, AppColors.hint, 'Not calculable'),
      DashaComparisonStatus.unknown =>
        const StatusVisual(Icons.help_outline_rounded, AppColors.hint, 'Unknown'),
    };

StatusVisual paramparaComparisonStatusVisual(ParamparaComparisonStatus status) => switch (status) {
      ParamparaComparisonStatus.match =>
        const StatusVisual(Icons.check_circle_rounded, AppColors.forest700, 'Match'),
      ParamparaComparisonStatus.informational =>
        const StatusVisual(Icons.info_outline_rounded, AppColors.textMuted, 'Informational'),
      ParamparaComparisonStatus.reviewRequired =>
        const StatusVisual(Icons.rate_review_outlined, AppColors.gold700, 'Review required'),
      ParamparaComparisonStatus.notCalculable =>
        const StatusVisual(Icons.remove_circle_outline_rounded, AppColors.hint, 'Not calculable'),
      ParamparaComparisonStatus.unknown =>
        const StatusVisual(Icons.help_outline_rounded, AppColors.hint, 'Unknown'),
    };

/// Purely descriptive — DIFFERENT is never shown as a failure/incompatible
/// color, matching the backend's own "MATCH does not mean compatible;
/// DIFFERENT does not mean incompatible" rule.
StatusVisual paramparaFieldStatusVisual(ParamparaFieldComparisonStatus status) => switch (status) {
      ParamparaFieldComparisonStatus.match =>
        const StatusVisual(Icons.check_circle_rounded, AppColors.forest700, 'Match'),
      ParamparaFieldComparisonStatus.different =>
        const StatusVisual(Icons.compare_arrows_rounded, AppColors.textMuted, 'Different'),
      ParamparaFieldComparisonStatus.notCalculable =>
        const StatusVisual(Icons.remove_circle_outline_rounded, AppColors.hint, 'Not calculable'),
      ParamparaFieldComparisonStatus.unknown =>
        const StatusVisual(Icons.help_outline_rounded, AppColors.hint, 'Unknown'),
    };

/// A module's eyebrow + title, matching the existing
/// "ASHTAKOOTA / 36 GUNA" / "Karnataka 10 Porutham" header pattern already
/// used by [CompatibilityReportView]/`SouthIndianJatakaScreen`.
class CompatibilitySectionHeader extends StatelessWidget {
  const CompatibilitySectionHeader({super.key, required this.eyebrow, required this.title, this.trailing});
  final String eyebrow;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(eyebrow.toUpperCase(),
                  style: body(11, weight: FontWeight.w700, color: AppColors.gold700, letterSpacing: 1)),
              const SizedBox(height: 6),
              Text(title, style: display(17, color: AppColors.forest900)),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

/// A single labeled finding: icon + status color, title, optional trailing
/// value, optional explanation below — the shared shape behind Koota rows,
/// Porutham rows, Advanced Jataka findings, Kuja reference findings, etc.
class FindingRow extends StatelessWidget {
  const FindingRow({
    super.key,
    required this.title,
    required this.visual,
    this.valueLabel,
    this.explanation,
    this.emphasized = false,
  });

  final String title;
  final StatusVisual visual;
  final String? valueLabel;
  final String? explanation;

  /// True for a finding the UI should call out (border + tint), mirroring
  /// the existing Rajju/Vedha "critical" card treatment.
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(visual.icon, size: 20, color: visual.color),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: body(13, weight: FontWeight.w700, color: AppColors.ink)),
                  ),
                  if (valueLabel != null && valueLabel!.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(valueLabel!,
                          textAlign: TextAlign.right,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: body(12, weight: FontWeight.w600, color: AppColors.textMuted)),
                    ),
                  ],
                  const SizedBox(width: 8),
                  Text(visual.label, style: body(12, weight: FontWeight.w700, color: visual.color)),
                ],
              ),
              if (explanation != null && explanation!.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(explanation!, style: body(11, color: AppColors.textMuted, height: 1.3)),
              ],
            ],
          ),
        ),
      ],
    );

    if (!emphasized) {
      return Padding(padding: const EdgeInsets.symmetric(vertical: 7), child: content);
    }
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: visual.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: visual.color.withValues(alpha: 0.35)),
      ),
      child: content,
    );
  }
}

/// A collapsible card for a large sub-section (e.g. one partner's 15
/// Advanced Jataka findings, or a full Dasha timeline) — the module's
/// headline stays visible; detail is opt-in via expansion, per spec §13/§14.
class CompatibilityExpandableSection extends StatelessWidget {
  const CompatibilityExpandableSection({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.initiallyExpanded = false,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      // The Container above paints its own white background, so the
      // ExpansionTile's ListTile needs its own transparent Material ancestor
      // — otherwise Flutter can't paint its tap ink/splash.
      child: Material(
        color: Colors.transparent,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: initiallyExpanded,
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            title: Text(title, style: body(14, weight: FontWeight.w700, color: AppColors.forest900)),
            subtitle: subtitle != null
                ? Text(subtitle!, style: body(12, color: AppColors.textMuted))
                : null,
            children: children,
          ),
        ),
      ),
    );
  }
}

/// The "this module has nothing to show" state — a module that's entirely
/// null on the report (not requested, missing consent, missing birth data),
/// distinct from an individual finding's own NOT_CALCULABLE.
class CompatibilityUnavailableNotice extends StatelessWidget {
  const CompatibilityUnavailableNotice({super.key, required this.title, required this.message});
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: const Color(0xFFFFF8E8),
      border: false,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.hourglass_top_rounded, size: 18, color: AppColors.gold700),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: body(14, weight: FontWeight.w700, color: AppColors.gold700)),
                const SizedBox(height: 4),
                Text(message, style: body(13, color: AppColors.textMuted, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// `startDate`/`endDate` verbatim, e.g. "14 Aug 2026" — never re-derived,
/// never substituted with "now."
String formatCompatDate(DateTime? d) {
  if (d == null) return 'Unknown';
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec', //
  ];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}

/// "GRAHA_DRISHTI" -> "Graha Drishti". Used for reason/rule codes across the
/// detailed sections — a display transform only.
String humanizeCode(String code) {
  return code
      .split('_')
      .where((w) => w.isNotEmpty)
      .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
      .join(' ');
}

/// "rashiName" -> "Rashi Name". Used for the free-form `data`/`details` maps
/// several findings carry — a display transform only, same convention as
/// [CompatibilityReportView]'s own key humanizer.
String humanizeKey(String key) {
  final spaced = key.replaceAllMapped(RegExp(r'([a-z0-9])([A-Z])'), (m) => '${m[1]} ${m[2]}');
  if (spaced.isEmpty) return spaced;
  return spaced[0].toUpperCase() + spaced.substring(1).toLowerCase();
}
