import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/demo_data.dart';
import '../theme/app_theme.dart';
import '../widgets/app_shell.dart';
import '../widgets/ui_kit.dart';

/// Family Tree — ported from `src/app/family-tree/page.tsx` (the static demo
/// tree). Renders the 6 [kFamilyMembers] across 4 generations as a node-and-line
/// tree drawn with [CustomPaint], wrapped in an [InteractiveViewer] for pan +
/// zoom. Tapping a node opens a bottom sheet with that member's details and a
/// "View Profile" action.
class FamilyTreeScreen extends StatefulWidget {
  const FamilyTreeScreen({super.key});

  @override
  State<FamilyTreeScreen> createState() => _FamilyTreeScreenState();
}

// Node radius and the canvas dimensions the static layout was authored against.
const double _r = 40;
const double _canvasW = 900;
const double _canvasH = 700;

/// Static layout positions (mirrors the web NODES array, re-tuned for mobile).
/// id 1 = Ramachandra (root), 2 = Savitribai (spouse), 3 = Venkatesh,
/// 4 = Suresh, 5 = Rekha, 6 = Priya (Self).
const Map<String, Offset> _pos = {
  '1': Offset(330, 90),
  '2': Offset(570, 90),
  '3': Offset(450, 260),
  '4': Offset(270, 430),
  '5': Offset(640, 430),
  '6': Offset(270, 600),
};

// Generation rows (y midline of each generation, for the guide labels).
const List<double> _genY = [90, 260, 430, 600];
const List<String> _genRoman = ['I', 'II', 'III', 'IV'];

class _FamilyTreeScreenState extends State<FamilyTreeScreen> {
  Map<String, dynamic> _member(String id) =>
      kFamilyMembers.firstWhere((m) => m['id'] == id);

  void _openMember(Map<String, dynamic> m) {
    final isLate = m['status'] == 'Late';
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TreeNode(
                  member: m,
                  size: 64,
                  isRoot: m['id'] == '1',
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${isLate ? "Late " : ""}${m['name']}',
                        style: display(20, color: AppColors.forest900),
                      ),
                      const SizedBox(height: 2),
                      Text(m['relation'] as String,
                          style: body(13,
                              weight: FontWeight.w600,
                              color: AppColors.forest700)),
                      const SizedBox(height: 8),
                      _statusBadge(isLate),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                    child: _infoTile(Icons.cake_outlined, 'Born',
                        (m['birthYear'] ?? '—').toString())),
                const SizedBox(width: 10),
                Expanded(
                    child: _infoTile(Icons.auto_awesome_outlined, 'Gotra',
                        m['gotra'] as String)),
                const SizedBox(width: 10),
                Expanded(
                    child: _infoTile(Icons.place_outlined, 'Native',
                        (m['native'] as String).split(',').first)),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FBF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFB7E4C7)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1FAE5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.work_outline_rounded,
                        size: 15, color: AppColors.forest800),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Occupation',
                            style: body(11, color: AppColors.textMuted)),
                        const SizedBox(height: 2),
                        Text(m['occupation'] as String,
                            style: body(13,
                                weight: FontWeight.w600,
                                color: AppColors.forest900,
                                height: 1.3)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            ForestButton(
              label: 'View Profile',
              icon: Icons.arrow_forward_rounded,
              expand: true,
              onPressed: () {
                Navigator.pop(ctx);
                context.go('/profile/${m['id']}');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(bool isLate) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isLate ? const Color(0xFFE5E7EB) : const Color(0xFFD1FAE5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
              isLate
                  ? Icons.local_florist_rounded
                  : Icons.check_circle_rounded,
              size: 12,
              color: isLate ? AppColors.textMuted : const Color(0xFF065F46)),
          const SizedBox(width: 4),
          Text(isLate ? 'In Memoriam' : 'Active Member',
              style: body(11,
                  weight: FontWeight.w700,
                  color:
                      isLate ? AppColors.textMuted : const Color(0xFF065F46))),
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F0E8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 14, color: AppColors.gold700),
          const SizedBox(height: 4),
          Text(label, style: body(10, color: AppColors.textMuted)),
          const SizedBox(height: 2),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: body(12,
                  weight: FontWeight.w700, color: AppColors.forest900)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Family Tree',
      currentRoute: '/family-tree',
      scrollable: false,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _controlRow(),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(gradient: AppGradients.cream),
              child: InteractiveViewer(
                constrained: false,
                minScale: 0.4,
                maxScale: 2.5,
                boundaryMargin: const EdgeInsets.all(80),
                child: SizedBox(
                  width: _canvasW,
                  height: _canvasH,
                  child: Stack(
                    children: [
                      // Connecting lines + generation guides.
                      Positioned.fill(
                        child: CustomPaint(painter: _TreePainter()),
                      ),
                      // Generation labels down the left edge.
                      for (var i = 0; i < _genY.length; i++)
                        Positioned(
                          left: 8,
                          top: _genY[i] - 9,
                          child: Text('GEN ${_genRoman[i]}',
                              style: body(11,
                                  weight: FontWeight.w700,
                                  color: AppColors.gold700,
                                  letterSpacing: 1.5)),
                        ),
                      // Nodes.
                      for (final entry in _pos.entries)
                        Positioned(
                          left: entry.value.dx - _r,
                          top: entry.value.dy - _r,
                          child: _NodeWithLabel(
                            member: _member(entry.key),
                            isRoot: entry.key == '1',
                            onTap: () => _openMember(_member(entry.key)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _controlRow() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: AppColors.cream,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('DAIVAJNA SAMAJA · LINEAGE',
              style: body(11,
                  weight: FontWeight.w700,
                  color: AppColors.gold700,
                  letterSpacing: 2)),
          const SizedBox(height: 4),
          Text('Our Family Tree',
              style: display(22, color: AppColors.forest900)),
          const SizedBox(height: 4),
          Text('Pinch to zoom · drag to pan · tap a node',
              style: body(12, color: AppColors.textMuted)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _Legend(color: AppColors.gold500, label: 'Root'),
              _Legend(color: AppColors.forest700, label: 'Living'),
              _Legend(color: Color(0xFF9CA3AF), label: 'Late'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label,
              style: body(11,
                  weight: FontWeight.w600, color: AppColors.forest900)),
        ],
      ),
    );
  }
}

/// A circular avatar node showing the member's initials over a forest gradient,
/// with a gold ring for the root and a gold/green or grey (Late) border.
class _TreeNode extends StatelessWidget {
  const _TreeNode({
    required this.member,
    this.size = _r * 2,
    this.isRoot = false,
  });

  final Map<String, dynamic> member;
  final double size;
  final bool isRoot;

  @override
  Widget build(BuildContext context) {
    final isLate = member['status'] == 'Late';
    final borderColor = isRoot
        ? AppColors.gold500
        : isLate
            ? const Color(0xFF9CA3AF)
            : AppColors.forest700;
    return Container(
      width: size,
      height: size,
      padding: isRoot ? const EdgeInsets.all(3) : EdgeInsets.zero,
      decoration: isRoot
          ? const BoxDecoration(
              gradient: AppGradients.gold, shape: BoxShape.circle)
          : null,
      child: Container(
        decoration: BoxDecoration(
          gradient: AppGradients.forest,
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          member['avatar'] as String,
          style: body(size * 0.3,
              weight: FontWeight.w700,
              color: isLate
                  ? Colors.white.withValues(alpha: 0.7)
                  : Colors.white),
        ),
      ),
    );
  }
}

/// A tappable node plus the name/relation caption beneath it.
class _NodeWithLabel extends StatelessWidget {
  const _NodeWithLabel({
    required this.member,
    required this.isRoot,
    required this.onTap,
  });

  final Map<String, dynamic> member;
  final bool isRoot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isSelf = member['relation'] == 'Self';
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: _r * 2,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _TreeNode(member: member, isRoot: isRoot),
            const SizedBox(height: 6),
            if (isSelf)
              Container(
                margin: const EdgeInsets.only(bottom: 2),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                decoration: BoxDecoration(
                  gradient: AppGradients.gold,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('YOU',
                    style: body(8,
                        weight: FontWeight.w800, color: Colors.white)),
              ),
            SizedBox(
              width: 110,
              child: Text(
                (member['name'] as String).split(' ').take(2).join(' '),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: body(11,
                    weight: FontWeight.w700, color: AppColors.forest900),
              ),
            ),
            SizedBox(
              width: 110,
              child: Text(
                member['relation'] as String,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: body(9, color: AppColors.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Draws the generation guide lines and the parent/child + spouse connectors.
class _TreePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Faint horizontal generation guides.
    final guide = Paint()
      ..color = AppColors.forest800.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    for (final y in _genY) {
      _dashedLine(canvas, Offset(40, y), Offset(_canvasW - 40, y), guide,
          dash: 4, gap: 10);
    }

    // Spouse link (Ramachandra ♥ Savitribai) — gold dashed.
    final spouse = Paint()
      ..color = AppColors.gold500.withValues(alpha: 0.65)
      ..strokeWidth = 1.5;
    _dashedLine(canvas, Offset(_pos['1']!.dx + _r, _pos['1']!.dy),
        Offset(_pos['2']!.dx - _r, _pos['2']!.dy), spouse,
        dash: 5, gap: 4);

    // Parent → child connectors (earth-brown, solid).
    final link = Paint()
      ..color = AppColors.gold700.withValues(alpha: 0.6)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final connections = <List<String>>[
      ['1', '3'],
      ['2', '3'],
      ['3', '4'],
      ['3', '5'],
      ['4', '6'],
    ];
    for (final c in connections) {
      canvas.drawLine(_pos[c[0]]!, _pos[c[1]]!, link);
    }

    // Junction dots at branch points.
    final dot = Paint()..color = AppColors.gold700.withValues(alpha: 0.45);
    canvas.drawCircle(_pos['3']!, 4, dot);
    canvas.drawCircle(_pos['4']!, 4, dot);
  }

  void _dashedLine(Canvas canvas, Offset a, Offset b, Paint paint,
      {double dash = 5, double gap = 4}) {
    final total = (b - a).distance;
    final dir = (b - a) / total;
    var drawn = 0.0;
    while (drawn < total) {
      final start = a + dir * drawn;
      final end = a + dir * (drawn + dash).clamp(0, total).toDouble();
      canvas.drawLine(start, end, paint);
      drawn += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _TreePainter oldDelegate) => false;
}
