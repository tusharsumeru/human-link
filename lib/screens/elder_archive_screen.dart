import 'package:flutter/material.dart';

import '../data/avatars.dart';
import '../l10n/generated/app_localizations.dart';
import '../theme/app_theme.dart';
import '../widgets/app_shell.dart';
import '../widgets/pexels_image.dart';
import '../widgets/ui_kit.dart';

/// Elder · Heritage Memory Archive — ported & enriched from
/// `src/app/elder/archive/page.tsx`. A gallery of Samaj memory cards that open
/// a detail sheet, plus an "Upload a Memory" action.
class ElderArchiveScreen extends StatelessWidget {
  const ElderArchiveScreen({super.key});

  // Wire tag key (also the lookup key into _tagColors) → localized fields.
  // Built at call time (not `const`), so it always reflects the active
  // language.
  static List<Map<String, dynamic>> _memoriesOf(AppLocalizations t) => [
    {
      'title': t.elderMem1Title,
      'year': '1968',
      'tag': 'Cultural',
      'photo': 2601464,
      'caption': t.elderMem1Caption,
      'contributor': t.elderMem1Contributor,
    },
    {
      'title': t.elderMem2Title,
      'year': '1974',
      'tag': 'Heritage',
      'photo': 17815020,
      'caption': t.elderMem2Caption,
      'contributor': t.elderMem2Contributor,
    },
    {
      'title': t.elderMem3Title,
      'year': '1952',
      'tag': 'Lineage',
      'photo': 4053536,
      'caption': t.elderMem3Caption,
      'contributor': t.elderMem3Contributor,
    },
    {
      'title': t.elderMem4Title,
      'year': '1992',
      'tag': 'Cultural',
      'photo': 5746790,
      'caption': t.elderMem4Caption,
      'contributor': t.elderMem4Contributor,
    },
    {
      'title': t.elderMem5Title,
      'year': '2008',
      'tag': 'Heritage',
      'photo': 11138457,
      'caption': t.elderMem5Caption,
      'contributor': t.elderMem5Contributor,
    },
    {
      'title': t.elderMem6Title,
      'year': '1981',
      'tag': 'Devotional',
      'photo': 29201034,
      'caption': t.elderMem6Caption,
      'contributor': t.elderMem6Contributor,
    },
  ];

  static const Map<String, List<int>> _tagColors = {
    'Cultural': [0xFFDBEAFE, 0xFF1E40AF],
    'Heritage': [0xFFF3E8E8, 0xFF8B5E3C],
    'Lineage': [0xFFD1FAE5, 0xFF065F46],
    'Devotional': [0xFFFEF3C7, 0xFFD97706],
  };

  static String _tagLabel(String tag, AppLocalizations t) => switch (tag) {
        'Cultural' => t.elderTagCultural,
        'Heritage' => t.elderTagHeritage,
        'Lineage' => t.elderTagLineage,
        'Devotional' => t.elderTagDevotional,
        _ => tag,
      };

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.forest800,
        behavior: SnackBarBehavior.floating,
      ));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return AppShell(
      title: t.elderArchives,
      currentRoute: '/elder/archive',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SectionHeader(
                  eyebrow: t.elderHeritageMemoryArchive,
                  title: t.elderOurLivingHistory,
                  subtitle: t.elderLivingHistorySubtitle,
                  titleSize: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GoldButton(
            label: t.elderUploadMemory,
            icon: Icons.upload_rounded,
            onPressed: () => _toast(context, t.elderUploadMemoryToast),
          ),
          const SizedBox(height: 18),
          ..._memoriesOf(t).map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _memoryCard(context, m, t),
              )),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _memoryCard(BuildContext context, Map<String, dynamic> m, AppLocalizations t) {
    final col = _tagColors[m['tag']] ?? const [0xFFF3F4F6, 0xFF374151];
    return AppCard(
      padding: EdgeInsets.zero,
      onTap: () => _openDetail(context, m, t),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 150,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  PexelsImage(
                    url: px(m['photo'] as int),
                    name: m['title'] as String,
                    size: 150,
                    radius: BorderRadius.zero,
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Pill(_tagLabel(m['tag'] as String, t),
                        bg: Color(col[0]), fg: Color(col[1])),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(m['title'] as String,
                            style: display(17, color: AppColors.forest900)),
                      ),
                      Pill(m['year'] as String,
                          bg: AppColors.creamDark, fg: AppColors.gold700),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(m['caption'] as String,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: body(12.5, color: AppColors.textMuted, height: 1.5)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.person_outline_rounded,
                          size: 13, color: AppColors.hint),
                      const SizedBox(width: 5),
                      Text(t.elderContributedBy(m['contributor'] as String),
                          style: body(11, color: AppColors.hint)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openDetail(BuildContext context, Map<String, dynamic> m, AppLocalizations t) {
    final col = _tagColors[m['tag']] ?? const [0xFFF3F4F6, 0xFF374151];
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.92,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: EdgeInsets.zero,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              child: SizedBox(
                height: 220,
                width: double.infinity,
                child: PexelsImage(
                  url: px(m['photo'] as int),
                  name: m['title'] as String,
                  size: 220,
                  radius: BorderRadius.zero,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Pill(_tagLabel(m['tag'] as String, t),
                          bg: Color(col[0]), fg: Color(col[1])),
                      const SizedBox(width: 8),
                      Pill(m['year'] as String,
                          bg: AppColors.creamDark, fg: AppColors.gold700),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(m['title'] as String,
                      style: display(24, color: AppColors.forest900)),
                  const SizedBox(height: 10),
                  Text(m['caption'] as String,
                      style: body(14, color: AppColors.label, height: 1.6)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F0E8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.archive_outlined,
                            size: 16, color: AppColors.gold700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(t.elderContributedBy(m['contributor'] as String),
                              style: body(12.5,
                                  weight: FontWeight.w600,
                                  color: AppColors.forest900)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  ForestButton(
                    label: t.elderClose,
                    expand: true,
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
