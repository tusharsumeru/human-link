import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/repository.dart';
import '../theme/app_theme.dart';
import '../widgets/pexels_image.dart';
import '../widgets/ui_kit.dart';

/// Elder · Lineage Conflict Resolution — ported from
/// `src/app/elder/conflict/[id]/page.tsx`. Two competing version cards,
/// resolution actions and an elder discussion thread.
class ElderConflictScreen extends StatefulWidget {
  const ElderConflictScreen({super.key, required this.id});

  final String id;

  @override
  State<ElderConflictScreen> createState() => _ElderConflictScreenState();
}

class _ElderConflictScreenState extends State<ElderConflictScreen> {
  final TextEditingController _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/elder');
    }
  }

  void _toast(String msg) {
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
    final conflict = Repository.instance.conflictById(widget.id);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.forest800,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: _back,
        ),
        title: Text('Conflict Resolution',
            style: display(18, color: Colors.white)),
      ),
      body: conflict == null
          ? _notFound()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: _content(conflict),
            ),
    );
  }

  Widget _notFound() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.help_outline_rounded,
              size: 40, color: AppColors.hint),
          const SizedBox(height: 12),
          Text('Conflict case not found',
              style: body(15,
                  weight: FontWeight.w600, color: AppColors.textMuted)),
          const SizedBox(height: 16),
          OutlineButtonX(label: 'Back to Overview', onPressed: _back),
        ],
      ),
    );
  }

  List<Widget> _content(Map<String, dynamic> c) {
    final isDuplicate = c['type'] == 'Duplicate';
    final discussion =
        (c['discussion'] as List).cast<Map<String, dynamic>>();
    return [
      // Caution banner header
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.soft,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PexelsImage(
                    url: c['photo'] as String,
                    name: c['subject'] as String,
                    size: 72,
                    radius: BorderRadius.circular(16),
                    borderColor: AppColors.gold500,
                    borderWidth: 2,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Pill(c['type'] as String,
                                bg: AppColors.forest800.withValues(alpha: 0.10),
                                fg: AppColors.forest800),
                            Text('Case #${(c['id'] as String).toUpperCase()}',
                                style: body(11, color: AppColors.hint)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(c['subject'] as String,
                            style: display(22, color: AppColors.forest900)),
                        Text('${c['born']} – ${c['died']}',
                            style: body(13, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Caution title banner (amber/red)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDuplicate
                    ? const Color(0xFFFEF3C7)
                    : const Color(0xFFFEE2E2),
                border: const Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          size: 16,
                          color: isDuplicate
                              ? const Color(0xFF92400E)
                              : const Color(0xFF991B1B)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(c['conflictTitle'] as String,
                            style: body(12,
                                weight: FontWeight.w700,
                                color: isDuplicate
                                    ? const Color(0xFF92400E)
                                    : const Color(0xFF991B1B))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(c['conflictDesc'] as String,
                      style: body(13,
                          color: const Color(0xFF92400E), height: 1.5)),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      // Versions (side-by-side wide / stacked mobile)
      LayoutBuilder(builder: (context, constraints) {
        final a = _versionCard(c['versionA'] as Map<String, dynamic>, 'A');
        final b = _versionCard(c['versionB'] as Map<String, dynamic>, 'B');
        if (constraints.maxWidth >= 720) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: a),
              const SizedBox(width: 14),
              Expanded(child: b),
            ],
          );
        }
        return Column(children: [a, const SizedBox(height: 14), b]);
      }),
      const SizedBox(height: 16),
      // Resolution actions
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Resolution',
                style: display(18, color: AppColors.forest900)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ForestButton(
                  label: 'Merge & Resolve',
                  icon: Icons.merge_rounded,
                  onPressed: () => _toast(
                      'Records submitted for merge review'),
                ),
                OutlineButtonX(
                  label: 'Escalate',
                  onPressed: () =>
                      _toast('Case escalated to the elder committee'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.shield_outlined,
                    size: 13, color: AppColors.hint),
                const SizedBox(width: 5),
                Text('Only verified Elders can resolve conflicts',
                    style: body(11, color: AppColors.hint)),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      // Discussion
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.forum_rounded,
                    size: 16, color: AppColors.gold700),
                const SizedBox(width: 8),
                Text('Elder Discussion Thread',
                    style: display(17, color: AppColors.forest900)),
              ],
            ),
            const SizedBox(height: 14),
            for (final d in discussion) _discussionEntry(d),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _noteCtrl,
                    minLines: 1,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Add your committee note…',
                      hintStyle: body(13, color: AppColors.hint),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      filled: true,
                      fillColor: const Color(0xFFF7F0E8),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppColors.forest700),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: AppColors.forest800,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      if (_noteCtrl.text.trim().isEmpty) return;
                      _noteCtrl.clear();
                      _toast('Note posted to the thread');
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(13),
                      child: Icon(Icons.send_rounded,
                          size: 18, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
    ];
  }

  Widget _versionCard(Map<String, dynamic> v, String letter) {
    final backed = v['backed'] as bool;
    final fields = (v['fields'] as List).cast<Map<String, dynamic>>();
    final evidence = (v['evidence'] as List).cast<String>();
    final votes = v['votes'] as int;
    final color = backed ? AppColors.forest800 : AppColors.textMuted;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: backed ? AppColors.forest800 : AppColors.border),
        boxShadow: AppShadows.soft,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (backed)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              color: const Color(0xFFD1FAE5),
              child: Row(
                children: [
                  const Icon(Icons.thumb_up_alt_rounded,
                      size: 12, color: Color(0xFF065F46)),
                  const SizedBox(width: 6),
                  Text('Backed by records · $votes vouches',
                      style: body(11,
                          weight: FontWeight.w700,
                          color: const Color(0xFF065F46))),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(letter,
                          style: display(18, color: Colors.white)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(v['label'] as String,
                          style: body(13,
                              weight: FontWeight.w700,
                              color: AppColors.forest900)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                for (final f in fields)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(f['label'] as String,
                            style: body(12, color: AppColors.textMuted)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(f['value'] as String,
                              textAlign: TextAlign.right,
                              style: body(12,
                                  weight: FontWeight.w600,
                                  color: AppColors.forest900)),
                        ),
                      ],
                    ),
                  ),
                const Divider(height: 20, color: AppColors.border),
                Text('EVIDENCE',
                    style: body(10,
                        weight: FontWeight.w700,
                        color: AppColors.hint,
                        letterSpacing: 1.2)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final e in evidence)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F0E8),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.description_outlined,
                                size: 12, color: AppColors.gold700),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(e,
                                  style: body(11, color: AppColors.label)),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F0E8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      PexelsImage(
                          url: v['submittedPhoto'] as String,
                          name: v['submittedBy'] as String,
                          size: 32),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(v['submittedBy'] as String,
                                style: body(11,
                                    weight: FontWeight.w600,
                                    color: AppColors.forest900)),
                            Text('Submitted this version',
                                style: body(10, color: AppColors.hint)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ForestButton(
                  label: 'Support this version ($votes)',
                  icon: Icons.thumb_up_alt_outlined,
                  expand: true,
                  gradient: backed ? AppGradients.forest : AppGradients.gold,
                  shadow: backed
                      ? AppShadows.forestGlow
                      : AppShadows.goldGlow,
                  onPressed: () =>
                      _toast('You supported ${v['label']}'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _discussionEntry(Map<String, dynamic> d) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PexelsImage(
              url: d['photo'] as String,
              name: d['author'] as String,
              size: 38),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(d['author'] as String,
                              style: body(13,
                                  weight: FontWeight.w700,
                                  color: AppColors.forest900)),
                          Pill(d['role'] as String,
                              bg: const Color(0xFFD1FAE5),
                              fg: const Color(0xFF065F46),
                              fontSize: 10),
                        ],
                      ),
                    ),
                    Text(d['time'] as String,
                        style: body(10, color: AppColors.hint)),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F0E8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(d['text'] as String,
                      style: body(12, color: AppColors.label, height: 1.5)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
