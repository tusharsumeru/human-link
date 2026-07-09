import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/api_client.dart';
import '../data/repository.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_shell.dart';
import '../widgets/ui_kit.dart';

/// Family Tree — the mobile port of the web `family-tree` page, styled after the
/// Stitch "Vamsha Vruksha" mockup (circular photo nodes, paternal/maternal
/// lines, an "Add Member" action, zoom + pan).
///
/// Renders the real `family_members` collection (GET `/api/family`). A node is a
/// *person*, not an account — it may be unclaimed (no login yet). You add
/// relatives via a relationship picker (Father / Mother / Child / Spouse) that
/// auto-derives the generation and link direction, and the person can later
/// claim their node ("This is me — link my account"), which an elder approves.
class FamilyTreeScreen extends StatefulWidget {
  const FamilyTreeScreen({super.key});

  @override
  State<FamilyTreeScreen> createState() => _FamilyTreeScreenState();
}

// Layout constants. Generations are normalized (see _layout): the oldest
// generation present renders at the top row, so ancestors added above the root
// (generation 0, -1, …) still fit on-screen.
const double _r = 40;
const double _w = 860;
const double _pad = 80;
const double _canvasW = 900;
const double _top = 100;
const double _rowH = 140;
const List<String> _genRoman = ['I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII'];

const List<String> _gotras = [
  'Kashyap', 'Bharadwaja', 'Vasishtha', 'Atreya', 'Kaundinya', 'Vishwamitra', 'Gautama',
];
const List<String> _branches = [
  'Bengaluru', 'Kundapura', 'Kumta', 'Mangaluru', 'Udupi', 'Out-of-State',
];

class _FamilyTreeScreenState extends State<FamilyTreeScreen> {
  List<Map<String, dynamic>> _members = const [];
  bool _loading = true;
  String _error = '';

  // Pan/zoom. The tree opens zoomed-out to fit the whole canvas on screen; the
  // user pinches (or taps the zoom buttons) to go closer.
  final TransformationController _tc = TransformationController();
  bool _didFit = false;
  Size? _viewport;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  /// Scale the canvas down so the whole tree is visible, centred horizontally.
  /// Runs once per (re)load; the user can then zoom freely.
  void _fitToViewport(double canvasH) {
    final vp = _viewport;
    if (vp == null || _didFit || vp.width <= 0 || vp.height <= 0) return;
    final raw = math.min(vp.width / _canvasW, vp.height / canvasH);
    final s = (raw.isFinite && raw > 0 ? raw : 0.4).clamp(0.15, 1.0).toDouble();
    final dx = (vp.width - _canvasW * s) / 2;
    _tc.value = Matrix4.identity()
      ..translateByDouble(dx, 8.0, 0.0, 1.0)
      ..scaleByDouble(s, s, s, 1.0);
    _didFit = true;
  }

  /// Zoom in/out about the viewport centre, clamped to a sane range.
  void _applyZoom(double factor) {
    final vp = _viewport;
    if (vp == null) return;
    final current = _tc.value.getMaxScaleOnAxis();
    if (current * factor < 0.15 || current * factor > 3.0) return;
    final focal = _tc.toScene(Offset(vp.width / 2, vp.height / 2));
    _tc.value = _tc.value.clone()
      ..translateByDouble(focal.dx, focal.dy, 0.0, 1.0)
      ..scaleByDouble(factor, factor, factor, 1.0)
      ..translateByDouble(-focal.dx, -focal.dy, 0.0, 1.0);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final members = await Repository.instance.familyTree();
      if (!mounted) return;
      setState(() {
        _members = members;
        _loading = false;
        _didFit = false; // refit to the new tree size
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load the family tree. Check your connection.';
        _loading = false;
      });
    }
  }

  int _gen(Map<String, dynamic> m) => ((m['generation'] ?? 1) as num).toInt();

  static bool _isLate(Map<String, dynamic> m) =>
      (m['dod'] ?? '').toString().isNotEmpty;

  static String _claim(Map<String, dynamic> m) =>
      (m['claimStatus'] ?? 'unclaimed').toString();

  /// Distributes members by generation across the canvas width, normalizing so
  /// the smallest generation number sits at the top row.
  Map<String, Offset> _layout() {
    if (_members.isEmpty) return {};
    final groups = <int, List<Map<String, dynamic>>>{};
    for (final m in _members) {
      (groups[_gen(m)] ??= []).add(m);
    }
    final minGen = groups.keys.reduce((a, b) => a < b ? a : b);
    final pos = <String, Offset>{};
    groups.forEach((gen, mems) {
      final y = _top + (gen - minGen) * _rowH;
      final step = mems.length > 1 ? (_w - 2 * _pad) / (mems.length - 1) : 0.0;
      final startX = mems.length == 1 ? _w / 2 : _pad;
      for (var i = 0; i < mems.length; i++) {
        pos[mems[i]['_id'].toString()] = Offset(startX + i * step, y);
      }
    });
    return pos;
  }

  String? get _currentPhone => context.read<AuthService>().user?.phone;

  Future<void> _openAddSheet({String? anchorId}) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _AddMemberSheet(
        members: _members,
        currentPhone: _currentPhone,
        initialAnchorId: anchorId ?? (_members.isNotEmpty ? _members.first['_id'].toString() : null),
      ),
    );
    if (result != null && result['ok'] == true) {
      await _load();
      if (!mounted) return;
      _toast(result['message']?.toString() ?? 'Member added');
    }
  }

  Future<void> _claimNode(Map<String, dynamic> m) async {
    final user = context.read<AuthService>().user;
    if (user == null || user.phone.isEmpty) {
      _toast('Please sign in to link your account.');
      return;
    }
    try {
      await Repository.instance.requestConnect(
        memberId: m['_id'].toString(),
        requesterPhone: user.phone,
        requesterName: user.name,
        relation: 'self',
        note: '${user.name} requests to link their account to ${m['name']}.',
      );
      if (!mounted) return;
      _toast('Request sent — an elder will review and approve the link.');
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      _toast(e.message);
    } catch (_) {
      if (!mounted) return;
      _toast('Could not send the request. Please try again.');
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.forest800),
    );
  }

  void _openMember(Map<String, dynamic> m) {
    final isLate = _isLate(m);
    final gen = _gen(m);
    final claim = _claim(m);
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
                _TreeNode(member: m, size: 64),
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
                      Text('${(m['branch'] ?? 'Bengaluru')} Branch · Gen $gen',
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
                Expanded(child: _infoTile(Icons.cake_outlined, 'Born', _dash(m['dob']))),
                const SizedBox(width: 10),
                Expanded(child: _infoTile(Icons.auto_awesome_outlined, 'Gotra', _dash(m['gotra']))),
                const SizedBox(width: 10),
                Expanded(child: _infoTile(Icons.place_outlined, 'Native', _dash(m['native']).split(',').first)),
              ],
            ),
            const SizedBox(height: 14),
            _claimCard(ctx, m, claim),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlineButtonX(
                    label: 'Add Relative',
                    expand: true,
                    onPressed: () {
                      Navigator.pop(ctx);
                      _openAddSheet(anchorId: m['_id'].toString());
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ForestButton(
                    label: 'View Profile',
                    icon: Icons.arrow_forward_rounded,
                    expand: true,
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.push('/profile/${m['_id']}');
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Account-link status + the "This is me" claim action for unclaimed nodes.
  Widget _claimCard(BuildContext ctx, Map<String, dynamic> m, String claim) {
    final meta = _claimMeta(claim);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF8F3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Account',
                  style: body(12, weight: FontWeight.w700, color: AppColors.forest800)),
              Pill(meta.$1, bg: meta.$2, fg: meta.$3, icon: meta.$4, fontSize: 10),
            ],
          ),
          if (claim == 'unclaimed') ...[
            const SizedBox(height: 8),
            Text(
              'This person has no account yet. If this is you, request to link '
              'your account — an elder will approve it.',
              style: body(12, color: AppColors.textMuted, height: 1.4),
            ),
            const SizedBox(height: 10),
            GoldButton(
              label: 'This is me — link my account',
              icon: Icons.link_rounded,
              expand: true,
              onPressed: () {
                Navigator.pop(ctx);
                _claimNode(m);
              },
            ),
          ] else if (claim == 'pending') ...[
            const SizedBox(height: 8),
            Text('A link request is awaiting elder approval.',
                style: body(12, color: AppColors.textMuted)),
          ] else ...[
            const SizedBox(height: 8),
            Text('Linked to a verified member account.',
                style: body(12, color: AppColors.textMuted)),
          ],
        ],
      ),
    );
  }

  // (label, bg, fg, icon) for each claim status.
  (String, Color, Color, IconData) _claimMeta(String claim) {
    switch (claim) {
      case 'claimed':
        return ('Account linked', const Color(0xFFD1FAE5), const Color(0xFF065F46), Icons.check_circle_rounded);
      case 'pending':
        return ('Claim pending', const Color(0xFFFEF3C7), const Color(0xFFD97706), Icons.schedule_rounded);
      default:
        return ('No account yet', const Color(0xFFF3F4F6), AppColors.textMuted, Icons.link_off_rounded);
    }
  }

  static String _dash(Object? v) {
    final s = (v ?? '').toString().trim();
    return s.isEmpty ? '—' : s;
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
          Icon(isLate ? Icons.local_florist_rounded : Icons.check_circle_rounded,
              size: 12,
              color: isLate ? AppColors.textMuted : const Color(0xFF065F46)),
          const SizedBox(width: 4),
          Text(isLate ? 'In Memoriam' : 'Active Member',
              style: body(11,
                  weight: FontWeight.w700,
                  color: isLate ? AppColors.textMuted : const Color(0xFF065F46))),
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
              style: body(12, weight: FontWeight.w700, color: AppColors.forest900)),
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
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.forest700));
    }
    if (_error.isNotEmpty) {
      return _message(Icons.cloud_off_rounded, 'Unable to load', _error,
          action: OutlineButtonX(label: 'Retry', onPressed: _load));
    }
    if (_members.isEmpty) {
      return _message(
        Icons.account_tree_outlined,
        'Your family tree is empty',
        'Add the first member to start your lineage — they become the root of your tree.',
        action: ForestButton(
          label: 'Add First Member',
          icon: Icons.add_rounded,
          onPressed: () => _openAddSheet(),
        ),
      );
    }

    final pos = _layout();
    final gens = _members.map(_gen);
    final minGen = gens.reduce((a, b) => a < b ? a : b);
    final maxGen = gens.reduce((a, b) => a > b ? a : b);
    final rowCount = maxGen - minGen + 1;
    double rowY(int row) => _top + row * _rowH;
    final canvasH = rowY(rowCount - 1) + 130;

    return Container(
      decoration: const BoxDecoration(gradient: AppGradients.cream),
      child: LayoutBuilder(
        builder: (ctx, cons) {
          _viewport = Size(cons.maxWidth, cons.maxHeight);
          if (!_didFit) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _fitToViewport(canvasH));
            });
          }
          return Stack(
            children: [
              InteractiveViewer(
                transformationController: _tc,
                constrained: false,
                minScale: 0.1,
                maxScale: 3,
                boundaryMargin: const EdgeInsets.all(200),
                child: SizedBox(
                  width: _canvasW,
                  height: canvasH,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                            painter: _TreePainter(members: _members, pos: pos)),
                      ),
                      for (var r = 0; r < rowCount; r++)
                        Positioned(
                          left: 8,
                          top: rowY(r) - 9,
                          child: Text(
                              'GEN ${r < _genRoman.length ? _genRoman[r] : (r + 1)}',
                              style: body(11,
                                  weight: FontWeight.w700,
                                  color: AppColors.gold700,
                                  letterSpacing: 1.5)),
                        ),
                      for (final m in _members)
                        if (pos[m['_id'].toString()] != null)
                          Positioned(
                            left: pos[m['_id'].toString()]!.dx - _r,
                            top: pos[m['_id'].toString()]!.dy - _r,
                            child: _NodeWithLabel(
                                member: m, onTap: () => _openMember(m)),
                          ),
                    ],
                  ),
                ),
              ),
              // Zoom + fit controls (bottom-right), mirroring the Stitch mockup.
              Positioned(
                right: 12,
                bottom: 12,
                child: Column(
                  children: [
                    _zoomButton(Icons.add_rounded, () => _applyZoom(1.3)),
                    const SizedBox(height: 8),
                    _zoomButton(Icons.remove_rounded, () => _applyZoom(1 / 1.3)),
                    const SizedBox(height: 8),
                    _zoomButton(Icons.center_focus_strong_rounded,
                        () => setState(() => _didFit = false)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _zoomButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(icon, size: 20, color: AppColors.forest800),
        ),
      ),
    );
  }

  Widget _message(IconData icon, String title, String subtitle, {Widget? action}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: AppColors.forest300),
            const SizedBox(height: 14),
            Text(title,
                textAlign: TextAlign.center,
                style: display(20, color: AppColors.forest900)),
            const SizedBox(height: 8),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: body(13, color: AppColors.textMuted, height: 1.5)),
            if (action != null) ...[
              const SizedBox(height: 18),
              action,
            ],
          ],
        ),
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('DAIVAJNA SAMAJA · LINEAGE',
                        style: body(11,
                            weight: FontWeight.w700,
                            color: AppColors.gold700,
                            letterSpacing: 2)),
                    const SizedBox(height: 4),
                    Text('Vamsha Vruksha', style: display(22, color: AppColors.forest900)),
                  ],
                ),
              ),
              if (_members.isNotEmpty)
                ForestButton(
                  label: 'Add Member',
                  icon: Icons.person_add_alt_1_rounded,
                  onPressed: () => _openAddSheet(),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Pinch to zoom · drag to pan · tap a node',
              style: body(12, color: AppColors.textMuted)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _Legend(color: AppColors.forest700, label: 'Paternal line'),
              _Legend(color: AppColors.gold700, label: 'Maternal line'),
              _Legend(color: Color(0xFF9CA3AF), label: 'In Memoriam'),
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
          Text(label, style: body(11, weight: FontWeight.w600, color: AppColors.forest900)),
        ],
      ),
    );
  }
}

/// A circular avatar node — photo over a forest gradient (falling back to
/// initials). Border colour follows the Stitch legend: paternal = green,
/// maternal = brown, In Memoriam = grey.
class _TreeNode extends StatelessWidget {
  const _TreeNode({required this.member, this.size = _r * 2});

  final Map<String, dynamic> member;
  final double size;

  @override
  Widget build(BuildContext context) {
    final isLate = _FamilyTreeScreenState._isLate(member);
    final isMaternal = (member['relationType'] ?? '').toString() == 'mother';
    final photoUrl = (member['photoUrl'] ?? '').toString();
    final borderColor = isLate
        ? const Color(0xFF9CA3AF)
        : (isMaternal ? AppColors.gold700 : AppColors.forest700);
    return Container(
      width: size,
      height: size,
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
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: photoUrl.isNotEmpty
          ? Image.network(photoUrl,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _initials(isLate))
          : _initials(isLate),
    );
  }

  Widget _initials(bool isLate) => Text(
        _initialsOf((member['name'] ?? '?').toString()),
        style: body(size * 0.3,
            weight: FontWeight.w700,
            color: isLate ? Colors.white.withValues(alpha: 0.7) : Colors.white),
      );

  static String _initialsOf(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}

/// A tappable node plus the name/generation caption beneath it.
class _NodeWithLabel extends StatelessWidget {
  const _NodeWithLabel({required this.member, required this.onTap});

  final Map<String, dynamic> member;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final gen = ((member['generation'] ?? 1) as num).toInt();
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: _r * 2,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _TreeNode(member: member),
            const SizedBox(height: 6),
            SizedBox(
              width: 110,
              child: Text(
                (member['name'] ?? '').toString().split(' ').take(2).join(' '),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: body(11, weight: FontWeight.w700, color: AppColors.forest900),
              ),
            ),
            SizedBox(
              width: 110,
              child: Text(
                '${(member['gotra'] ?? '').toString()} · Gen $gen',
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

/// Draws generation guide lines and parent→child connectors (by `parentId`).
class _TreePainter extends CustomPainter {
  _TreePainter({required this.members, required this.pos});

  final List<Map<String, dynamic>> members;
  final Map<String, Offset> pos;

  @override
  void paint(Canvas canvas, Size size) {
    final guide = Paint()
      ..color = AppColors.forest800.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    final gens = pos.values.map((o) => o.dy).toSet();
    for (final y in gens) {
      _dashedLine(canvas, Offset(40, y), Offset(_w - 40, y), guide, dash: 4, gap: 10);
    }

    final link = Paint()
      ..color = AppColors.gold700.withValues(alpha: 0.6)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final dot = Paint()..color = AppColors.gold700.withValues(alpha: 0.45);
    for (final m in members) {
      final parentId = (m['parentId'] ?? '').toString();
      if (parentId.isEmpty) continue;
      final child = pos[m['_id'].toString()];
      final parent = pos[parentId];
      if (child == null || parent == null) continue;
      canvas.drawLine(parent, child, link);
      canvas.drawCircle(parent, 4, dot);
    }
  }

  void _dashedLine(Canvas canvas, Offset a, Offset b, Paint paint,
      {double dash = 5, double gap = 4}) {
    final total = (b - a).distance;
    if (total == 0) return;
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
  bool shouldRepaint(covariant _TreePainter oldDelegate) =>
      oldDelegate.members != members || oldDelegate.pos != pos;
}

/// Bottom-sheet form to add a family member. Picks a relationship to an anchor
/// member, from which the generation and link direction are derived. Phone is
/// required for living members (used to invite/link their account).
class _AddMemberSheet extends StatefulWidget {
  const _AddMemberSheet({
    required this.members,
    required this.currentPhone,
    required this.initialAnchorId,
  });

  final List<Map<String, dynamic>> members;
  final String? currentPhone;
  final String? initialAnchorId;

  @override
  State<_AddMemberSheet> createState() => _AddMemberSheetState();
}

class _AddMemberSheetState extends State<_AddMemberSheet> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _native = TextEditingController();
  final _occupation = TextEditingController();
  final _notes = TextEditingController();

  String _gender = 'M';
  String _gotra = 'Kashyap';
  String _branch = 'Bengaluru';
  String _dob = '';
  String _dod = '';
  String _relation = '';
  String? _anchorId;
  bool _saving = false;
  String _err = '';

  static const _relationships = [
    ('father', 'Father'),
    ('mother', 'Mother'),
    ('child', 'Son / Daughter'),
    ('spouse', 'Spouse'),
  ];

  @override
  void initState() {
    super.initState();
    _anchorId = widget.initialAnchorId;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _native.dispose();
    _occupation.dispose();
    _notes.dispose();
    super.dispose();
  }

  bool get _hasMembers => widget.members.isNotEmpty;
  bool get _isDeceased => _dod.isNotEmpty;

  Map<String, dynamic>? get _anchor {
    for (final m in widget.members) {
      if (m['_id'].toString() == _anchorId) return m;
    }
    return null;
  }

  Future<void> _pickDate(bool isDob) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1980),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) {
      final s = DateFormat('yyyy-MM-dd').format(picked);
      setState(() => isDob ? _dob = s : _dod = s);
    }
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _err = 'Name is required');
      return;
    }
    final phone = _phone.text.trim();
    if (!_isDeceased && !RegExp(r'^\d{10}$').hasMatch(phone)) {
      setState(() => _err = 'A 10-digit phone number is required for living members');
      return;
    }
    final anchor = _anchor;
    if (_hasMembers && _relation.isEmpty) {
      setState(() => _err = 'Please choose a relationship');
      return;
    }
    if (_hasMembers && anchor == null) {
      setState(() => _err = 'Please choose who this person is related to');
      return;
    }

    // Derive generation + link direction from the relationship.
    String parentId = '', spouseId = '';
    int generation = 1;
    String gender = _gender;
    if (anchor != null) {
      final g = ((anchor['generation'] ?? 1) as num).toInt();
      switch (_relation) {
        case 'father':
        case 'mother':
          generation = g - 1;
          gender = _relation == 'father' ? 'M' : 'F';
          break;
        case 'child':
          parentId = anchor['_id'].toString();
          generation = g + 1;
          break;
        case 'spouse':
          spouseId = anchor['_id'].toString();
          generation = g;
          break;
      }
    }

    setState(() {
      _saving = true;
      _err = '';
    });
    try {
      final res = await Repository.instance.addFamilyMember({
        'name': name,
        'gender': gender,
        'dob': _dob,
        'dod': _dod,
        'gotra': _gotra,
        'native': _native.text.trim(),
        'occupation': _occupation.text.trim(),
        'phone': phone,
        'branch': _branch,
        'notes': _notes.text.trim(),
        'parentId': parentId,
        'spouseId': spouseId,
        'generation': generation,
        'relationType': _relation.isEmpty ? null : _relation,
        'createdByPhone': widget.currentPhone,
      });
      final newId = res['id']?.toString();

      // Ancestors: the new node is the anchor's parent, so point the anchor's
      // parentId at it. Spouse: record the partner on the anchor too.
      if (newId != null && anchor != null) {
        if (_relation == 'father' || _relation == 'mother') {
          await Repository.instance
              .updateFamilyMember(anchor['_id'].toString(), {'parentId': newId});
        } else if (_relation == 'spouse') {
          await Repository.instance
              .updateFamilyMember(anchor['_id'].toString(), {'spouseId': newId});
        }
      }

      if (!mounted) return;
      final matched = res['matchedExistingUser'] == true;
      Navigator.pop(context, {
        'ok': true,
        'message': matched
            ? '$name added — they already have an account, a link request was sent.'
            : '$name added to the family tree.',
      });
    } on ApiException catch (e) {
      setState(() {
        _err = e.message;
        _saving = false;
      });
    } catch (_) {
      setState(() {
        _err = 'Could not add the member. Check your connection.';
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final anchor = _anchor;
    final showPlacement = _relation.isNotEmpty && anchor != null;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scroll) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.border, borderRadius: BorderRadius.circular(999)),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Add Family Member',
                        style: display(20, color: AppColors.forest900)),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: scroll,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                children: [
                  _field('Full Name *', _name, hint: 'e.g. Ramesh Haldankar'),
                  const SizedBox(height: 14),
                  _label('Gender'),
                  Row(
                    children: [
                      _genderChip('M', 'Male'),
                      const SizedBox(width: 10),
                      _genderChip('F', 'Female'),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (_hasMembers) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBF8F3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('How is this person related?',
                              style: body(12,
                                  weight: FontWeight.w700, color: AppColors.forest800)),
                          const SizedBox(height: 10),
                          _label('Relationship *'),
                          _dropdown<String>(
                            value: _relation.isEmpty ? null : _relation,
                            hint: 'Select',
                            items: [
                              for (final r in _relationships)
                                DropdownMenuItem(value: r.$1, child: Text(r.$2)),
                            ],
                            onChanged: (v) => setState(() {
                              _relation = v ?? '';
                              if (_relation == 'father') _gender = 'M';
                              if (_relation == 'mother') _gender = 'F';
                            }),
                          ),
                          const SizedBox(height: 10),
                          _label('Relative of *'),
                          _dropdown<String>(
                            value: _anchorId,
                            hint: 'Select member',
                            items: [
                              for (final m in widget.members)
                                DropdownMenuItem(
                                    value: m['_id'].toString(),
                                    child: Text((m['name'] ?? '').toString())),
                            ],
                            onChanged: (v) => setState(() => _anchorId = v),
                          ),
                          if (showPlacement) ...[
                            const SizedBox(height: 10),
                            Text(
                              '${_name.text.trim().isEmpty ? "This person" : _name.text.trim()} '
                              'will be placed ${_hintFor(_relation)} ${anchor['name']}.',
                              style: body(12, color: AppColors.textMuted, height: 1.4),
                            ),
                          ],
                          const SizedBox(height: 6),
                          Text('Tip: add a grandfather by choosing Father and selecting your father above.',
                              style: body(11, color: AppColors.hint, height: 1.4)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  _field('Phone ${_isDeceased ? "(optional)" : "*"}', _phone,
                      hint: '9876543210', keyboard: TextInputType.phone),
                  const SizedBox(height: 4),
                  Text(
                    _isDeceased
                        ? 'Not needed for a member who has passed away.'
                        : 'We’ll link their account by this number — now if they have one, or when they sign up.',
                    style: body(11, color: AppColors.hint, height: 1.4),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('Gotra'),
                            _dropdown<String>(
                              value: _gotra,
                              items: [for (final g in _gotras) DropdownMenuItem(value: g, child: Text(g))],
                              onChanged: (v) => setState(() => _gotra = v ?? _gotra),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('Branch'),
                            _dropdown<String>(
                              value: _branch,
                              items: [for (final b in _branches) DropdownMenuItem(value: b, child: Text(b))],
                              onChanged: (v) => setState(() => _branch = v ?? _branch),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _field('Native Place', _native, hint: 'e.g. Kundapura, Karnataka'),
                  const SizedBox(height: 14),
                  _field('Occupation', _occupation, hint: 'e.g. Goldsmith, Engineer'),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(child: _dateField('Date of Birth', _dob, () => _pickDate(true))),
                      const SizedBox(width: 12),
                      Expanded(child: _dateField('Date of Death', _dod, () => _pickDate(false))),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _field('Life Notes', _notes,
                      hint: 'A few words about their life…', maxLines: 3),
                  if (_err.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(_err, style: body(12, color: const Color(0xFFB91C1C))),
                    ),
                  ],
                  const SizedBox(height: 18),
                  ForestButton(
                    label: 'Add to Family Tree',
                    icon: Icons.add_rounded,
                    expand: true,
                    loading: _saving,
                    onPressed: _save,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _hintFor(String rel) {
    switch (rel) {
      case 'father':
      case 'mother':
        return 'one generation above';
      case 'child':
        return 'one generation below';
      case 'spouse':
        return 'beside';
      default:
        return 'in the tree';
    }
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: body(12, weight: FontWeight.w700, color: AppColors.forest800)),
      );

  Widget _field(String label, TextEditingController c,
      {String hint = '', TextInputType? keyboard, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        TextField(
          controller: c,
          keyboardType: keyboard,
          maxLines: maxLines,
          onChanged: (_) => setState(() {}),
          style: body(14, color: AppColors.ink),
          decoration: _inputDecoration(hint),
        ),
      ],
    );
  }

  Widget _dateField(String label, String value, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 15, color: AppColors.gold700),
                const SizedBox(width: 8),
                Text(value.isEmpty ? 'Select' : value,
                    style: body(14,
                        color: value.isEmpty ? AppColors.hint : AppColors.ink)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _dropdown<T>({
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    String? hint,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      hint: hint == null ? null : Text(hint, style: body(14, color: AppColors.hint)),
      items: items,
      onChanged: onChanged,
      style: body(14, color: AppColors.ink),
      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textMuted),
      decoration: _inputDecoration(''),
    );
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: body(14, color: AppColors.hint),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.forest700, width: 1.5),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      );

  Widget _genderChip(String value, String label) {
    final selected = _gender == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _gender = value),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.forest800 : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? AppColors.forest800 : AppColors.border),
          ),
          child: Text(label,
              style: body(14,
                  weight: FontWeight.w600,
                  color: selected ? Colors.white : AppColors.label)),
        ),
      ),
    );
  }
}
