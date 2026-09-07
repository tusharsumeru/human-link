/// STEP 76 — the detailed Daivagna Parampara section of the full
/// compatibility report. Purely a display transform over
/// [CompatibilityReport.daivagnaParampara] — every Gotra/Pravara/Kuladevata/
/// Kuladevi value shown is exactly what each member self-declared; nothing
/// here infers a Gotra from a surname, a Pravara from a Gotra, or a
/// Kuladevata from a community. MATCH/DIFFERENT are purely descriptive, never
/// an incompatibility verdict.
library;

import 'package:flutter/material.dart';

import '../data/models/parampara.dart'
    show
        DaivagnaParampara,
        ParamparaDeclaredValue,
        ParamparaValueStatus,
        PartnerParamparaResult;
import '../theme/app_theme.dart';
import 'compatibility_status_ui.dart' show CompatibilityUnavailableNotice;
import 'ui_kit.dart';

class DaivagnaParamparaSection extends StatelessWidget {
  const DaivagnaParamparaSection({super.key, required this.parampara});

  final DaivagnaParampara? parampara;

  @override
  Widget build(BuildContext context) {
    final p = parampara;
    if (p == null) {
      return const CompatibilityUnavailableNotice(
        title: 'Daivagna Parampara not available',
        message: 'This report does not include a Daivagna Parampara result.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _partnerCard(context, 'Bride', p.bride),
        const SizedBox(height: 10),
        _partnerCard(context, 'Groom', p.groom),
      ],
    );
  }

  Widget _partnerCard(
    BuildContext context,
    String who,
    PartnerParamparaResult p,
  ) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            who,
            style: body(
              14,
              weight: FontWeight.w700,
              color: context.onBrightness(
                light: AppColors.forest900,
                dark: AppColors.darkText,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _declaredValueRow(context, 'Gotra', p.gotra),
          _declaredValueRow(context, 'Kuladevata', p.kuladevata),
        ],
      ),
    );
  }

  Widget _declaredValueRow(
    BuildContext context,
    String label,
    ParamparaDeclaredValue v,
  ) {
    final (
      String valueText,
      Color colorLight,
      Color colorDark,
    ) = switch (v.status) {
      ParamparaValueStatus.provided => (
        (v.customValue?.trim().isNotEmpty ?? false)
            ? v.customValue!.trim()
            : 'Not provided',
        AppColors.ink,
        AppColors.darkText,
      ),
      ParamparaValueStatus.unknown => (
        'Unknown',
        AppColors.hint,
        AppColors.darkTextMuted,
      ),
      ParamparaValueStatus.notProvided => (
        'Not provided',
        AppColors.hint,
        AppColors.darkTextMuted,
      ),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: body(
                13,
                weight: FontWeight.w600,
                color: context.onBrightness(
                  light: AppColors.textMuted,
                  dark: AppColors.darkTextMuted,
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              valueText,
              style: body(
                13,
                weight: FontWeight.w600,
                color: context.onBrightness(light: colorLight, dark: colorDark),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
