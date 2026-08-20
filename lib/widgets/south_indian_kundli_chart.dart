/// STEP 80 — a South Indian style Kundli/birth-chart grid: a fixed 4x4
/// layout with the 12 Rashi cells around the perimeter (in their permanent,
/// never-changing positions — Mesha top-row-second-cell, Vrishabha top-row-
/// third-cell, and so on clockwise) and the 2x2 centre merged into one
/// unused block, exactly like a traditional printed South Indian chart. This
/// is NOT the North Indian diamond-style chart (where houses rotate around a
/// fixed Lagna) — here the RASHI positions are fixed and the Lagna is
/// marked wherever it falls.
///
/// Purely presentational: every planet/Lagna placement shown here is passed
/// in already-computed by the caller (ultimately the backend's Kundli chart
/// snapshot) — nothing in this widget infers, recomputes, or invents a
/// Graha/Rashi/Lagna position. The only "knowledge" baked in here is which
/// grid cell each Rashi number permanently occupies — a fixed structural
/// fact about how a South Indian chart is drawn, not an astrology
/// calculation (the same kind of static, non-computed fact this app already
/// hardcodes for Porutham/Koota display order).
library;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Row-major 4x4 layout: `null` marks the merged, unused centre. Rashi ids
/// 1-12 (Mesha..Meena) sit at their permanent positions.
const List<List<int?>> kSouthIndianGridLayout = [
  [12, 1, 2, 3],
  [11, null, null, 4],
  [10, null, null, 5],
  [9, 8, 7, 6],
];

class SouthIndianKundliChart extends StatelessWidget {
  const SouthIndianKundliChart({
    super.key,
    required this.lagnaRashiId,
    required this.planetLabelsByRashi,
    this.rashiNamesById = const {},
    this.chartLabel,
    this.size = 320,
  });

  /// Which Rashi (1-12) the Lagna/Ascendant falls in — marked with a
  /// highlighted cell + "As" badge, wherever that happens to be in the fixed
  /// grid.
  final int lagnaRashiId;

  /// Already-formatted short labels (e.g. "Su", "Ra(R)") per Rashi id —
  /// built by the caller from the actual chart data. A Rashi with no
  /// entry (or an empty list) simply renders with no planets, never a
  /// fabricated placeholder.
  final Map<int, List<String>> planetLabelsByRashi;

  /// Optional Rashi display name per id, straight from the backend's
  /// already-resolved `rashiName` fields — a Rashi this app never received a
  /// name for (no planet/Lagna occupied it in this particular chart) simply
  /// shows no corner label; the fixed grid position is still correct either
  /// way, so nothing is lost.
  final Map<int, String> rashiNamesById;

  /// Small centre caption (e.g. "D1" / "D9") — purely cosmetic.
  final String? chartLabel;

  final double size;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: SizedBox(
        width: size,
        height: size,
        child: Column(
          children: [
            Expanded(child: _gridRow(kSouthIndianGridLayout[0])),
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(child: _cell(kSouthIndianGridLayout[1][0])),
                        Expanded(child: _cell(kSouthIndianGridLayout[2][0])),
                      ],
                    ),
                  ),
                  Expanded(flex: 2, child: _centreBox()),
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(child: _cell(kSouthIndianGridLayout[1][3])),
                        Expanded(child: _cell(kSouthIndianGridLayout[2][3])),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: _gridRow(kSouthIndianGridLayout[3])),
          ],
        ),
      ),
    );
  }

  Widget _gridRow(List<int?> rowRashiIds) =>
      Row(children: [for (final id in rowRashiIds) Expanded(child: _cell(id))]);

  Widget _centreBox() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFAF6EE),
        border: Border.all(color: AppColors.border),
      ),
      alignment: Alignment.center,
      child: chartLabel == null
          ? null
          : Text(chartLabel!,
              style: body(12, weight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 1.2)),
    );
  }

  Widget _cell(int? rashiId) {
    if (rashiId == null) return const SizedBox.shrink();
    final isLagna = rashiId == lagnaRashiId;
    final labels = planetLabelsByRashi[rashiId] ?? const <String>[];
    final rashiName = rashiNamesById[rashiId];
    return Container(
      decoration: BoxDecoration(
        color: isLagna ? AppColors.gold700.withValues(alpha: 0.10) : Colors.white,
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(2),
      child: Stack(
        children: [
          if (rashiName != null)
            Positioned(
              top: 0,
              left: 1,
              child: Text(
                rashiName,
                style: body(7.5, weight: FontWeight.w600, color: AppColors.textMuted),
              ),
            ),
          if (isLagna)
            Positioned(
              top: 0,
              right: 1,
              child: Text('As',
                  style: body(8, weight: FontWeight.w800, color: AppColors.gold700)),
            ),
          Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 3,
                  runSpacing: 1,
                  children: [
                    for (final label in labels)
                      Text(label, style: body(11, weight: FontWeight.w700, color: AppColors.forest900)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
