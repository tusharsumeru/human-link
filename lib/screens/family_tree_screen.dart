import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../data/api_client.dart';
import '../data/repository.dart';
import '../theme/app_theme.dart';
import '../widgets/app_shell.dart';
import '../widgets/ui_kit.dart';
import 'family_tree_layout.dart';

/// Family Tree — mobile client for the `/api/family` backend.
///
/// Each node is a *person* reached by traversing accepted relationships out from
/// the signed-in member's own node, so grandparents, in-laws and cousins appear
/// automatically as relatives join — the member only ever adds their own
/// immediate family (father/mother/spouse/sibling/child).
///
/// Where each of those people is *drawn* is decided by [FamilyTreeLayout], not by
/// the order of `nodes` or by the `generation` field: spouses sit side by side,
/// children hang under their parents, and a sibling appears beside the person
/// they are a sibling of — including when that person is your spouse. The view
/// opens compact (your immediate family only) and each person with relatives
/// behind them carries a "+n" badge that expands their branch.
///
/// Adding a living person who has an account sends a **request** they must
/// accept; adding a living person who has not joined creates a placeholder and
/// an **invitation** link; a **deceased** person is added immediately with no
/// approval. Incoming requests, invitations matching your phone, and event
/// notifications are all reachable from the control row.
class FamilyTreeScreen extends StatefulWidget {
  const FamilyTreeScreen({super.key});

  @override
  State<FamilyTreeScreen> createState() => _FamilyTreeScreenState();
}

const double _r = 40;
const double _nodeDiameter = _r * 2;
const double _canvasMinWidth = 900;
const List<String> _genRoman = ['I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII'];

const FamilyTreeMetrics _metrics = FamilyTreeMetrics(
  nodeDiameter: _nodeDiameter,
  nodeSlot: 112,
  spouseGap: 34,
  branchGap: 28,
  rowHeight: 150,
  padding: 60,
  top: 96,
  minWidth: _canvasMinWidth,
);

// The seven immediate relations the backend accepts, in display order.
const List<(String, String)> _relations = [
  ('father', 'Father'),
  ('mother', 'Mother'),
  ('spouse', 'Spouse'),
  ('brother', 'Brother'),
  ('sister', 'Sister'),
  ('son', 'Son'),
  ('daughter', 'Daughter'),
];

class _FamilyTreeScreenState extends State<FamilyTreeScreen> {
  List<Map<String, dynamic>> _nodes = const [];
  List<Map<String, dynamic>> _requests = const [];
  List<Map<String, dynamic>> _invites = const [];
  int _unread = 0;
  bool _truncated = false;
  bool _loading = true;
  String _error = '';

  /// The kinship structure behind the current tree, rebuilt on every load.
  FamilyGraph? _graph;

  /// People whose branch the member has opened. Everything reached *through*
  /// someone stays hidden until they are in here, which is what keeps the
  /// default view to your own immediate family.
  final Set<String> _expanded = {};

  // Pan/zoom. The tree opens zoomed-out to fit the whole canvas on screen.
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

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final graph = await Repository.instance.familyTree();
      // Requests, invites and the badge count are best-effort — a failure there
      // must not blank the tree, which is the primary content of the screen.
      List<Map<String, dynamic>> requests = const [];
      List<Map<String, dynamic>> invites = const [];
      int unread = 0;
      try {
        requests = await Repository.instance.familyRequests();
      } catch (_) {/* best-effort */}
      try {
        invites = await Repository.instance.familyInvites();
      } catch (_) {/* best-effort */}
      try {
        unread = await Repository.instance.familyUnreadCount();
      } catch (_) {/* best-effort */}
      if (!mounted) return;
      final nodes = _asList(graph['nodes']);
      final edges = _asList(graph['edges']);
      final built = FamilyGraph.fromTree(
        nodes: nodes,
        edges: edges,
        rootId: graph['rootId']?.toString(),
      );
      setState(() {
        _nodes = nodes;
        _graph = built;
        // Keep whatever the member had opened, minus anyone who is no longer in
        // the tree (a decline or a merge can remove people).
        _expanded.removeWhere((id) => !built.byId.containsKey(id));
        _truncated = graph['truncated'] == true;
        _requests = requests;
        _invites = invites;
        _unread = unread;
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

  static List<Map<String, dynamic>> _asList(Object? v) {
    if (v is List) {
      return v
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return const [];
  }

  /// Which row this person sits on, phrased relative to the viewer. Taken from
  /// the structural generation the layout derived, not from the payload field.
  String _generationLabel(String id) {
    final gen = _graph?.generationOf[id] ?? 0;
    if (gen == 0) return 'Your generation';
    final steps = gen.abs();
    final word = gen < 0
        ? (steps == 1 ? 'One generation above' : '$steps generations above')
        : (steps == 1 ? 'One generation below' : '$steps generations below');
    return word;
  }

  static bool _isDeceased(Map<String, dynamic> m) =>
      m['deceased'] == true || m['status'] == 'deceased';
  static bool _isPlaceholder(Map<String, dynamic> m) => m['isPlaceholder'] == true;
  static bool _isSelf(Map<String, dynamic> m) => m['isSelf'] == true;

  /// The server-derived, viewer-relative label ("Grandfather", "Sister-in-law",
  /// or "Relative" when the path runs past what kinship words cover). Never
  /// cached beyond this render — it is only valid for this tree's `rootId`.
  static String _relationOf(Map<String, dynamic> m) {
    final r = (m['relation'] ?? '').toString().trim();
    return r.isEmpty ? 'Relative' : r;
  }

  static String _photoOf(Map<String, dynamic> m) =>
      (m['profileUrl'] ?? '').toString();

  // ── Progressive expansion ──────────────────────────────────────────────────

  /// Opens or closes one person's branch. Collapsing is implicitly recursive:
  /// anyone reached through this person disappears with them, because visibility
  /// is evaluated along the whole chain.
  void _toggleBranch(String id) {
    setState(() {
      if (!_expanded.remove(id)) _expanded.add(id);
      _didFit = false; // the canvas just changed size
    });
  }

  bool get _allExpanded {
    final g = _graph;
    if (g == null) return false;
    final owners = g.branchOwners;
    return owners.isNotEmpty && owners.every(_expanded.contains);
  }

  void _toggleAllBranches() {
    final g = _graph;
    if (g == null) return;
    setState(() {
      if (_allExpanded) {
        _expanded.clear();
      } else {
        _expanded.addAll(g.branchOwners);
      }
      _didFit = false;
    });
  }

  /// Scale the canvas down so the whole tree is visible, centred horizontally.
  void _fitToViewport(double canvasW, double canvasH) {
    final vp = _viewport;
    if (vp == null || _didFit || vp.width <= 0 || vp.height <= 0) return;
    final raw = math.min(vp.width / canvasW, vp.height / canvasH);
    final s = (raw.isFinite && raw > 0 ? raw : 0.4).clamp(0.15, 1.0).toDouble();
    final dx = (vp.width - canvasW * s) / 2;
    _tc.value = Matrix4.identity()
      ..translateByDouble(dx, 8.0, 0.0, 1.0)
      ..scaleByDouble(s, s, s, 1.0);
    _didFit = true;
  }

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

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _openAddSheet() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _AddMemberSheet(),
    );
    if (result != null && result['ok'] == true) {
      await _load();
      if (!mounted) return;
      final invite = result['whatsappUrl']?.toString() ?? '';
      if (invite.isNotEmpty) {
        _showInviteDialog(
          result['name']?.toString() ?? 'Your relative',
          result['inviteLink']?.toString() ?? '',
        );
      } else {
        _toast(result['message']?.toString() ?? 'Member added');
      }
    }
  }

  Future<void> _openRequests() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _RequestsSheet(requests: _requests),
    );
    await _load();
  }

  Future<void> _openInvites() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _InvitesSheet(invites: _invites),
    );
    await _load();
  }

  Future<void> _openNotifications() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _NotificationsSheet(),
    );
    // A request can be answered straight from the inbox, and one new edge can
    // relabel a large part of the tree — so always refetch.
    await _load();
  }

  void _showInviteDialog(String name, String link) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Invite $name', style: display(18, color: AppColors.forest900)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A placeholder was added and the relationship is pending. Share '
              'this invite so they can join and connect back to you.',
              style: body(13, color: AppColors.textMuted, height: 1.5),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFBF8F3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(link,
                  style: body(12, color: AppColors.forest800), maxLines: 2),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close', style: body(13, color: AppColors.textMuted)),
          ),
          ForestButton(
            label: 'Copy link',
            icon: Icons.copy_rounded,
            onPressed: () {
              Clipboard.setData(ClipboardData(text: link));
              Navigator.pop(ctx);
              _toast('Invite link copied');
            },
          ),
        ],
      ),
    );
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.forest800),
    );
  }

  void _openMember(Map<String, dynamic> m) {
    final deceased = _isDeceased(m);
    final placeholder = _isPlaceholder(m);
    final self = _isSelf(m);
    final memberId = (m['id'] ?? '').toString();
    // How the label was derived — the stored relations walked out from me. Shown
    // for anything the server had to infer (grandfather, cousin, in-law…).
    final path = (m['path'] is List)
        ? (m['path'] as List).map((e) => e.toString()).toList()
        : const <String>[];
    final hiddenBehind = _graph?.hiddenCount(memberId, _expanded) ?? 0;
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
                        '${deceased ? "Late " : ""}${m['name']}',
                        style: display(20, color: AppColors.forest900),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        self
                            ? 'You'
                            : '${_relationOf(m)} · ${_generationLabel(memberId)}',
                        style: body(13,
                            weight: FontWeight.w600,
                            color: AppColors.forest700),
                      ),
                      const SizedBox(height: 8),
                      _statusBadge(deceased, placeholder),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _statusCard(deceased, placeholder),
            if (!self && path.length > 1) ...[
              const SizedBox(height: 10),
              Text('Derived from: your ${path.join(" → ")}',
                  style: body(11, color: AppColors.hint, height: 1.4)),
            ],
            const SizedBox(height: 14),
            if (memberId.isNotEmpty &&
                (_graph?.hasBranch(memberId) ?? false)) ...[
              OutlineButtonX(
                label: hiddenBehind > 0
                    ? 'Show their family ($hiddenBehind)'
                    : 'Hide their family',
                expand: true,
                onPressed: () {
                  Navigator.pop(ctx);
                  _toggleBranch(memberId);
                },
              ),
              const SizedBox(height: 10),
            ],
            if (memberId.isNotEmpty)
              ForestButton(
                label: 'View Profile',
                icon: Icons.arrow_forward_rounded,
                expand: true,
                onPressed: () {
                  Navigator.pop(ctx);
                  context.push(self ? '/profile/me' : '/profile/$memberId');
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _statusCard(bool deceased, bool placeholder) {
    final (String title, String body_) = deceased
        ? ('Verified Deceased', 'Added directly to the tree - no approval needed.')
        : placeholder
            ? ('Pending Invitation',
                'This person has not joined yet. The relationship activates when '
                    'they register and accept.')
            : ('Active Member', 'Linked to a verified member account.');
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
          Text(title,
              style: body(12, weight: FontWeight.w700, color: AppColors.forest800)),
          const SizedBox(height: 6),
          Text(body_, style: body(12, color: AppColors.textMuted, height: 1.4)),
        ],
      ),
    );
  }

  Widget _statusBadge(bool deceased, bool placeholder) {
    final (String label, Color bg, Color fg, IconData icon) = deceased
        ? ('In Memoriam', const Color(0xFFE5E7EB), AppColors.textMuted,
            Icons.local_florist_rounded)
        : placeholder
            ? ('Pending Invitation', const Color(0xFFFEF3C7),
                const Color(0xFFD97706), Icons.schedule_rounded)
            : ('Active Member', const Color(0xFFD1FAE5),
                const Color(0xFF065F46), Icons.check_circle_rounded);
    return Pill(label, bg: bg, fg: fg, icon: icon, fontSize: 10);
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
          if (_invites.isNotEmpty) _inviteBanner(),
          if (_truncated) _truncatedBanner(),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.forest700));
    }
    if (_error.isNotEmpty) {
      return _message(Icons.cloud_off_rounded, 'Unable to load', _error,
          action: OutlineButtonX(label: 'Retry', onPressed: _load));
    }
    // The first call to the tree lazily creates my own member node, so "empty"
    // means me and nobody else — not zero nodes.
    if (_nodes.isEmpty || (_nodes.length == 1 && _isSelf(_nodes.first))) {
      return _message(
        Icons.account_tree_outlined,
        'Your family tree is empty',
        'Add your immediate family - father, mother, spouse, siblings, children. '
            'Their trees connect to yours as they join.',
        action: ForestButton(
          label: 'Add Family Member',
          icon: Icons.add_rounded,
          onPressed: _openAddSheet,
        ),
      );
    }

    // Positions come from the relationship structure, not from the node order or
    // the `generation` field. See family_tree_layout.dart.
    final layout = FamilyTreeLayout.build(
      graph: _graph!,
      expanded: _expanded,
      metrics: _metrics,
    );
    final pos = layout.positions;
    final canvasW = math.max(layout.width, _canvasMinWidth);
    final canvasH = layout.height;

    return Container(
      decoration: const BoxDecoration(gradient: AppGradients.cream),
      child: LayoutBuilder(
        builder: (ctx, cons) {
          _viewport = Size(cons.maxWidth, cons.maxHeight);
          if (!_didFit) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _fitToViewport(canvasW, canvasH));
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
                  width: canvasW,
                  height: canvasH,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _TreePainter(
                            links: layout.links,
                            rowYs: [
                              for (final g in layout.generations) layout.rowY(g),
                            ],
                          ),
                        ),
                      ),
                      for (var row = 0; row < layout.generations.length; row++)
                        Positioned(
                          left: 8,
                          top: layout.rowY(layout.generations[row]) - 9,
                          child: Text(
                              'GEN ${row < _genRoman.length ? _genRoman[row] : (row + 1)}',
                              style: body(11,
                                  weight: FontWeight.w700,
                                  color: AppColors.gold700,
                                  letterSpacing: 1.5)),
                        ),
                      for (final id in layout.placed)
                        if (pos[id] != null && _graph!.byId[id] != null)
                          Positioned(
                            left: pos[id]!.dx - _r,
                            top: pos[id]!.dy - _r,
                            child: _NodeWithLabel(
                              member: _graph!.byId[id]!,
                              hidden: layout.hiddenCount(id),
                              expanded: layout.isExpanded(id),
                              onTap: () => _openMember(_graph!.byId[id]!),
                              onToggle: _graph!.hasBranch(id)
                                  ? () => _toggleBranch(id)
                                  : null,
                            ),
                          ),
                    ],
                  ),
                ),
              ),
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

  Widget _message(IconData icon, String title, String subtitle,
      {Widget? action}) {
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

  Widget _inviteBanner() {
    final first = _invites.first;
    final msg = (first['message'] ?? 'You have a pending invitation.').toString();
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      color: const Color(0xFFFEF9EC),
      child: Row(
        children: [
          const Icon(Icons.mark_email_unread_rounded,
              size: 20, color: Color(0xFFD97706)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _invites.length > 1
                  ? '$msg  (+${_invites.length - 1} more)'
                  : msg,
              style: body(12,
                  weight: FontWeight.w600, color: AppColors.forest900),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          GoldButton(label: 'Review', onPressed: _openInvites),
        ],
      ),
    );
  }

  /// The server stops walking past its node cap and flags the render as partial.
  Widget _truncatedBanner() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      color: const Color(0xFFF3F4F6),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              size: 18, color: AppColors.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Showing part of the tree — it has more relatives than one view can hold.',
              style: body(11, color: AppColors.textMuted, height: 1.4),
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
                    Text('Vamsha Vruksha',
                        style: display(22, color: AppColors.forest900)),
                  ],
                ),
              ),
              ForestButton(
                label: 'Add Member',
                icon: Icons.person_add_alt_1_rounded,
                onPressed: _openAddSheet,
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _actionChip(Icons.inbox_rounded, 'Requests', _requests.length,
                    _openRequests),
                const SizedBox(width: 8),
                _actionChip(Icons.mark_email_unread_rounded, 'Invites',
                    _invites.length, _openInvites),
                const SizedBox(width: 8),
                _actionChip(Icons.notifications_none_rounded, 'Alerts', _unread,
                    _openNotifications),
                if (_graph?.branchOwners.isNotEmpty ?? false) ...[
                  const SizedBox(width: 8),
                  _actionChip(
                    _allExpanded
                        ? Icons.unfold_less_rounded
                        : Icons.unfold_more_rounded,
                    _allExpanded ? 'Compact view' : 'Expand all',
                    0,
                    _toggleAllBranches,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionChip(IconData icon, String label, int count, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: AppColors.forest800),
            const SizedBox(width: 6),
            Text(label,
                style: body(12,
                    weight: FontWeight.w600, color: AppColors.forest900)),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.gold700,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('$count',
                    style: body(10,
                        weight: FontWeight.w700, color: Colors.white)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A circular avatar node — photo over a forest gradient (falling back to
/// initials). Border colour: self = gold, deceased = grey, pending placeholder
/// = amber, active member = forest green.
class _TreeNode extends StatelessWidget {
  const _TreeNode({required this.member, this.size = _r * 2});

  final Map<String, dynamic> member;
  final double size;

  @override
  Widget build(BuildContext context) {
    final deceased = _FamilyTreeScreenState._isDeceased(member);
    final placeholder = _FamilyTreeScreenState._isPlaceholder(member);
    final self = _FamilyTreeScreenState._isSelf(member);
    final photoUrl = _FamilyTreeScreenState._photoOf(member);
    final borderColor = self
        ? AppColors.gold700
        : deceased
            ? const Color.fromARGB(255, 251, 2, 2)
            : placeholder
                ? const Color(0xFFD97706)
                : AppColors.forest700;
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
              errorBuilder: (_, __, ___) => _initials(deceased))
          : _initials(deceased),
    );
  }

  Widget _initials(bool deceased) => Text(
        _initialsOf((member['name'] ?? '?').toString()),
        style: body(size * 0.3,
            weight: FontWeight.w700,
            color: deceased ? Colors.white.withValues(alpha: 0.7) : Colors.white),
      );

  static String _initialsOf(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}

/// A tappable node plus the name / relationship caption beneath it, and — when
/// this person has relatives who are not on screen — the badge that opens their
/// branch.
class _NodeWithLabel extends StatelessWidget {
  const _NodeWithLabel({
    required this.member,
    required this.onTap,
    this.hidden = 0,
    this.expanded = false,
    this.onToggle,
  });

  final Map<String, dynamic> member;
  final VoidCallback onTap;

  /// How many relatives are folded away behind this person right now.
  final int hidden;

  final bool expanded;

  /// Null when this person has no branch to open at all.
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final self = _FamilyTreeScreenState._isSelf(member);
    final rel = self ? 'You' : _FamilyTreeScreenState._relationOf(member);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: _r * 2,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                _TreeNode(member: member),
                if (onToggle != null && (hidden > 0 || expanded))
                  Positioned(
                    right: -6,
                    bottom: -4,
                    child: _BranchBadge(
                      label: hidden > 0 ? '+$hidden' : '−',
                      open: hidden == 0,
                      onTap: onToggle!,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 110,
              child: Text(
                (member['name'] ?? '').toString().split(' ').take(2).join(' '),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    body(11, weight: FontWeight.w700, color: AppColors.forest900),
              ),
            ),
            SizedBox(
              width: 110,
              child: Text(
                rel,
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

/// The "+n" / "−" control that opens and closes a person's branch.
class _BranchBadge extends StatelessWidget {
  const _BranchBadge({
    required this.label,
    required this.open,
    required this.onTap,
  });

  final String label;

  /// True when the branch is already showing, so the badge collapses it.
  final bool open;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minWidth: 22),
        height: 22,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: open ? Colors.white : AppColors.gold700,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
              color: open ? AppColors.gold700 : Colors.white, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: body(10,
              weight: FontWeight.w800,
              color: open ? AppColors.gold700 : Colors.white),
        ),
      ),
    );
  }
}

/// Draws the generation guide lines and the connectors the layout worked out:
/// a horizontal line between spouses, a shared fork from a couple down to their
/// children, and a bracket over a sibling group whose parents are not on screen.
class _TreePainter extends CustomPainter {
  _TreePainter({required this.links, required this.rowYs});

  final List<FamilyLink> links;
  final List<double> rowYs;

  @override
  void paint(Canvas canvas, Size size) {
    final guide = Paint()
      ..color = AppColors.forest800.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    for (final y in rowYs) {
      _dashedLine(canvas, Offset(40, y), Offset(size.width - 40, y), guide,
          dash: 4, gap: 10);
    }

    final spouse = Paint()
      ..color = AppColors.gold700
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final descent = Paint()
      ..color = AppColors.forest700.withValues(alpha: 0.55)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final sibling = Paint()
      ..color = AppColors.gold700.withValues(alpha: 0.5)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (final link in links) {
      if (link.points.length < 2) continue;
      switch (link.kind) {
        case FamilyLinkKind.spouse:
          canvas.drawLine(link.points.first, link.points.last, spouse);
          // A small tie in the middle, so a marriage reads differently from a
          // descent line even in a dense part of the tree.
          final mid = (link.points.first + link.points.last) / 2;
          canvas.drawCircle(mid, 3.5, Paint()..color = AppColors.gold700);
        case FamilyLinkKind.parentChild:
          canvas.drawPath(_polyline(link.points), descent);
        case FamilyLinkKind.sibling:
          for (var i = 0; i < link.points.length - 1; i++) {
            _dashedLine(canvas, link.points[i], link.points[i + 1], sibling,
                dash: 6, gap: 4);
          }
      }
    }
  }

  Path _polyline(List<Offset> points) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    return path;
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
      oldDelegate.links != links || oldDelegate.rowYs != rowYs;
}

// ── Add member ────────────────────────────────────────────────────────────────

/// Bottom-sheet form to add one of the caller's immediate family. Pick the
/// relationship, then either connect to an existing account (search) or create a
/// new profile (alive → invitation, deceased → added immediately).
class _AddMemberSheet extends StatefulWidget {
  const _AddMemberSheet();

  @override
  State<_AddMemberSheet> createState() => _AddMemberSheetState();
}

enum _AddMode { account, profile }

class _AddMemberSheetState extends State<_AddMemberSheet> {
  final _search = TextEditingController();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _placeOfDeath = TextEditingController();
  final _biography = TextEditingController();

  String _relation = 'father';
  _AddMode _mode = _AddMode.account;
  String _gender = 'M';
  String _status = 'alive'; // alive | deceased
  String _dob = '';
  String _dod = '';

  List<Map<String, dynamic>> _results = const [];
  Map<String, dynamic>? _selected;
  bool _searching = false;
  bool _saving = false;
  String _err = '';

  @override
  void dispose() {
    _search.dispose();
    _name.dispose();
    _phone.dispose();
    _placeOfDeath.dispose();
    _biography.dispose();
    super.dispose();
  }

  bool get _isDeceased => _status == 'deceased';

  Future<void> _runSearch() async {
    final q = _search.text.trim();
    if (q.isEmpty) return;
    setState(() {
      _searching = true;
      _err = '';
    });
    try {
      // A 10-digit query is treated as a phone; otherwise a name.
      final byPhone = RegExp(r'^\d{10}$').hasMatch(q);
      final samajId = q.toUpperCase().startsWith('DS-');
      final results = await Repository.instance.familyUserSearch(
        samajId: samajId ? q : null,
        phone: byPhone ? q : null,
        name: (!byPhone && !samajId) ? q : null,
      );
      if (!mounted) return;
      setState(() {
        _results = results;
        _searching = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _err = e.message;
        _searching = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _err = 'Search failed. Check your connection.';
        _searching = false;
      });
    }
  }

  Future<void> _pickDate(bool isDob) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1980),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      final s = DateFormat('yyyy-MM-dd').format(picked);
      setState(() => isDob ? _dob = s : _dod = s);
    }
  }

  Future<void> _save() async {
    // Mode: connect to an existing account.
    if (_mode == _AddMode.account) {
      final target = _selected;
      if (target == null) {
        setState(() => _err = 'Select the person to send a request to');
        return;
      }
      await _submit(targetUserId: target['_id']?.toString());
      return;
    }

    // Mode: create a new profile (placeholder / deceased). The backend requires
    // a date of birth in both cases.
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _err = 'Name is required');
      return;
    }
    if (_dob.isEmpty) {
      setState(() => _err = 'Date of birth is required');
      return;
    }
    await _submit(name: name);
  }

  Future<void> _submit({String? targetUserId, String? name}) async {
    setState(() {
      _saving = true;
      _err = '';
    });
    try {
      final res = await Repository.instance.addFamilyMember(
        relation: _relation,
        targetUserId: targetUserId,
        name: name,
        gender: _gender,
        status: _status,
        phone: _phone.text.trim(),
        dob: _dob,
        dod: _dod,
        placeOfDeath: _placeOfDeath.text.trim(),
        biography: _biography.text.trim(),
      );
      if (!mounted) return;
      final mode = (res['mode'] ?? '').toString();
      final member = res['member'];
      final personName = member is Map
          ? (member['name'] ?? name ?? 'Member').toString()
          : (name ?? 'Member');
      // Adding a relation that already exists is idempotent server-side — the
      // existing edge comes back, so an accepted status means we did not just
      // send a new request.
      final rel = res['relationship'];
      final already = rel is Map && rel['status'] == 'accepted';
      Navigator.pop(context, {
        'ok': true,
        'mode': mode,
        'name': personName,
        'inviteLink': res['inviteLink']?.toString() ?? '',
        'whatsappUrl': res['whatsappUrl']?.toString() ?? '',
        'message': switch (mode) {
          'request' when already => 'You are already connected to $personName.',
          'request' =>
            'Request sent to $personName - they’ll appear once they accept.',
          'invitation' => '$personName invited - share the link so they can join.',
          'deceased' => '$personName added to the family tree.',
          _ => '$personName added.',
        },
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
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(999)),
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
                    icon: const Icon(Icons.close_rounded,
                        color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: scroll,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                children: [
                  _label('Relationship to you *'),
                  _dropdown<String>(
                    value: _relation,
                    items: [
                      for (final r in _relations)
                        DropdownMenuItem(value: r.$1, child: Text(r.$2)),
                    ],
                    onChanged: (v) => setState(() {
                      _relation = v ?? _relation;
                      if (_relation == 'father' ||
                          _relation == 'brother' ||
                          _relation == 'son') {
                        _gender = 'M';
                      }
                      if (_relation == 'mother' ||
                          _relation == 'sister' ||
                          _relation == 'daughter') {
                        _gender = 'F';
                      }
                    }),
                  ),
                  const SizedBox(height: 16),
                  _modeToggle(),
                  const SizedBox(height: 16),
                  if (_mode == _AddMode.account)
                    _accountSection()
                  else
                    _profileSection(),
                  if (_err.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(_err,
                          style: body(12, color: const Color(0xFFB91C1C))),
                    ),
                  ],
                  const SizedBox(height: 18),
                  ForestButton(
                    label: _mode == _AddMode.account
                        ? 'Send Request'
                        : _isDeceased
                            ? 'Add to Family Tree'
                            : 'Create & Invite',
                    icon: Icons.check_rounded,
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

  Widget _modeToggle() {
    return Row(
      children: [
        _modeChip(_AddMode.account, 'Has an account', Icons.badge_outlined),
        const SizedBox(width: 10),
        _modeChip(_AddMode.profile, 'New profile', Icons.person_outline_rounded),
      ],
    );
  }

  Widget _modeChip(_AddMode mode, String label, IconData icon) {
    final selected = _mode == mode;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() {
          _mode = mode;
          _err = '';
        }),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.forest800 : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: selected ? AppColors.forest800 : AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 15,
                  color: selected ? Colors.white : AppColors.forest800),
              const SizedBox(width: 6),
              Text(label,
                  style: body(13,
                      weight: FontWeight.w600,
                      color: selected ? Colors.white : AppColors.label)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _accountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Find them by name, phone or Samaj ID'),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _search,
                onSubmitted: (_) => _runSearch(),
                style: body(14, color: AppColors.ink),
                decoration: _inputDecoration('e.g. 9876543210 or Ramesh'),
              ),
            ),
            const SizedBox(width: 8),
            OutlineButtonX(label: 'Search', onPressed: _runSearch),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'A living member with an account must accept your request before the '
          'relationship shows in both trees.',
          style: body(11, color: AppColors.hint, height: 1.4),
        ),
        const SizedBox(height: 12),
        if (_searching)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
                child: CircularProgressIndicator(color: AppColors.forest700)),
          )
        else
          for (final u in _results) _resultTile(u),
      ],
    );
  }

  Widget _resultTile(Map<String, dynamic> u) {
    final selected = _selected != null &&
        _selected!['_id']?.toString() == u['_id']?.toString();
    final photo = (u['profileUrl'] ?? '').toString();
    return InkWell(
      onTap: () => setState(() => _selected = u),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF0F6F1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected ? AppColors.forest700 : AppColors.border,
              width: selected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.forest300,
              backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
              child: photo.isEmpty
                  ? Text(
                      (u['name'] ?? '?').toString().characters.first.toUpperCase(),
                      style: body(14,
                          weight: FontWeight.w700, color: Colors.white))
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text((u['name'] ?? '').toString(),
                      style: body(14,
                          weight: FontWeight.w700, color: AppColors.forest900)),
                  const SizedBox(height: 2),
                  Text(
                    [
                      (u['samajId'] ?? '').toString(),
                      (u['native'] ?? '').toString(),
                    ].where((s) => s.isNotEmpty).join(' · '),
                    style: body(11, color: AppColors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.forest700, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _profileSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
        _label('Status'),
        Row(
          children: [
            _statusChip('alive', 'Alive'),
            const SizedBox(width: 10),
            _statusChip('deceased', 'Deceased'),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          _isDeceased
              ? 'A deceased person is added immediately - no invitation or approval.'
              : 'A living person is invited: they join and confirm the relationship.',
          style: body(11, color: AppColors.hint, height: 1.4),
        ),
        const SizedBox(height: 14),
        if (!_isDeceased) ...[
          _field('Phone (optional)', _phone,
              hint: '9876543210', keyboard: TextInputType.phone),
          const SizedBox(height: 4),
          Text('Used to link their account when they register.',
              style: body(11, color: AppColors.hint, height: 1.4)),
          const SizedBox(height: 14),
          _dateField('Date of Birth *', _dob, () => _pickDate(true)),
        ] else ...[
          Row(
            children: [
              Expanded(
                  child:
                      _dateField('Date of Birth *', _dob, () => _pickDate(true))),
              const SizedBox(width: 12),
              Expanded(
                  child:
                      _dateField('Date of Death', _dod, () => _pickDate(false))),
            ],
          ),
          const SizedBox(height: 14),
          _field('Place of Death', _placeOfDeath, hint: 'e.g. Kundapura'),
          const SizedBox(height: 14),
          _field('Biography', _biography,
              hint: 'A few words about their life…', maxLines: 3),
        ],
      ],
    );
  }

  // ── Small form widgets (mirrors the app's existing sheet styling) ──────────

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style:
                body(12, weight: FontWeight.w700, color: AppColors.forest800)),
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
                const Icon(Icons.calendar_today_rounded,
                    size: 15, color: AppColors.gold700),
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
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      items: items,
      onChanged: onChanged,
      style: body(14, color: AppColors.ink),
      icon: const Icon(Icons.keyboard_arrow_down_rounded,
          color: AppColors.textMuted),
      decoration: _inputDecoration(''),
    );
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: body(14, color: AppColors.hint),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
            border: Border.all(
                color: selected ? AppColors.forest800 : AppColors.border),
          ),
          child: Text(label,
              style: body(14,
                  weight: FontWeight.w600,
                  color: selected ? Colors.white : AppColors.label)),
        ),
      ),
    );
  }

  Widget _statusChip(String value, String label) {
    final selected = _status == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() {
          _status = value;
          _err = '';
        }),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.forest800 : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: selected ? AppColors.forest800 : AppColors.border),
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

// ── Requests / invites / notifications sheets ─────────────────────────────────

/// Incoming relationship requests addressed to me — accept or decline each —
/// plus the ones I sent that are still waiting, which are otherwise invisible
/// because a pending edge is left out of the tree.
class _RequestsSheet extends StatefulWidget {
  const _RequestsSheet({required this.requests});
  final List<Map<String, dynamic>> requests;

  @override
  State<_RequestsSheet> createState() => _RequestsSheetState();
}

class _RequestsSheetState extends State<_RequestsSheet> {
  late final List<Map<String, dynamic>> _items = List.of(widget.requests);
  List<Map<String, dynamic>> _sent = const [];
  final _busy = <String>{};

  @override
  void initState() {
    super.initState();
    _loadSent();
  }

  Future<void> _loadSent() async {
    try {
      final sent = await Repository.instance.familySentRequests();
      if (!mounted) return;
      setState(() => _sent = sent);
    } catch (_) {/* best-effort */}
  }

  Future<void> _cancel(Map<String, dynamic> r) async {
    final id = r['_id']?.toString() ?? '';
    if (id.isEmpty) return;
    setState(() => _busy.add(id));
    try {
      await Repository.instance.cancelFamilyRequest(id);
      if (!mounted) return;
      setState(() => _sent.removeWhere((x) => x['_id']?.toString() == id));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not withdraw the request')),
      );
    } finally {
      if (mounted) setState(() => _busy.remove(id));
    }
  }

  Future<void> _respond(Map<String, dynamic> r, bool accept) async {
    final id = r['_id']?.toString() ?? '';
    if (id.isEmpty) return;
    setState(() => _busy.add(id));
    try {
      if (accept) {
        await Repository.instance.acceptFamilyRequest(id);
      } else {
        await Repository.instance.declineFamilyRequest(id);
      }
      if (!mounted) return;
      setState(() => _items.removeWhere((x) => x['_id']?.toString() == id));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update the request')),
      );
    } finally {
      if (mounted) setState(() => _busy.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      title: 'Relationship Requests',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_items.isEmpty)
            _emptyState('No pending requests',
                'When a relative asks to connect with you, it shows up here.')
          else
            for (final r in _items)
              _requestTile(
                name: _nameOf(r['requester']),
                message: (r['message'] ?? '').toString(),
                busy: _busy.contains(r['_id']?.toString()),
                onAccept: () => _respond(r, true),
                onDecline: () => _respond(r, false),
              ),
          if (_sent.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text('Waiting on them',
                style: body(12,
                    weight: FontWeight.w700, color: AppColors.forest800)),
            const SizedBox(height: 4),
            Text(
              'These stay out of the tree until the other person accepts.',
              style: body(11, color: AppColors.hint, height: 1.4),
            ),
            const SizedBox(height: 10),
            for (final r in _sent) _sentTile(r),
          ],
        ],
      ),
    );
  }

  Widget _sentTile(Map<String, dynamic> r) {
    final id = r['_id']?.toString() ?? '';
    final busy = _busy.contains(id);
    final inviteLink = (r['inviteLink'] ?? '').toString();
    final name = _nameOf(r['relative']);
    final relation = (r['relation'] ?? '').toString();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF8F3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name,
              style: body(13,
                  weight: FontWeight.w700, color: AppColors.forest900)),
          if (relation.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text('Added as your $relation',
                style: body(11, color: AppColors.textMuted)),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              if (inviteLink.isNotEmpty) ...[
                Expanded(
                  child: OutlineButtonX(
                    label: 'Copy invite',
                    expand: true,
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: inviteLink));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Invite link copied')),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: OutlineButtonX(
                  label: 'Withdraw',
                  expand: true,
                  color: const Color(0xFFB91C1C),
                  onPressed: busy ? null : () => _cancel(r),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Invitations matching my phone — accept merges the placeholder(s) into my
/// account; decline dismisses them.
class _InvitesSheet extends StatefulWidget {
  const _InvitesSheet({required this.invites});
  final List<Map<String, dynamic>> invites;

  @override
  State<_InvitesSheet> createState() => _InvitesSheetState();
}

class _InvitesSheetState extends State<_InvitesSheet> {
  bool _busy = false;
  String _done = '';

  Future<void> _respond(bool accept) async {
    setState(() => _busy = true);
    try {
      if (accept) {
        final res = await Repository.instance.acceptFamilyInvites();
        final merged = ((res['merged'] ?? 0) as num).toInt();
        if (!mounted) return;
        setState(() => _done =
            merged > 0 ? 'Connected - your trees are now merged.' : 'Done.');
      } else {
        await Repository.instance.declineFamilyInvites();
        if (!mounted) return;
        setState(() => _done = 'Invitations declined.');
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update the invitations')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      title: 'Your Invitations',
      child: _done.isNotEmpty
          ? _emptyState('All set', _done)
          : widget.invites.isEmpty
              ? _emptyState('No invitations',
                  'Invitations others send to your number will appear here.')
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final i in widget.invites)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFBF8F3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text((i['message'] ?? '').toString(),
                              style: body(13, color: AppColors.forest900)),
                        ),
                      ),
                    const SizedBox(height: 6),
                    Text(
                      'Accepting confirms these people are your family and merges '
                      'their placeholder profiles into your account.',
                      style: body(11, color: AppColors.hint, height: 1.4),
                    ),
                    const SizedBox(height: 14),
                    ForestButton(
                      label: 'Accept & Connect',
                      icon: Icons.link_rounded,
                      expand: true,
                      loading: _busy,
                      onPressed: () => _respond(true),
                    ),
                    const SizedBox(height: 8),
                    OutlineButtonX(
                      label: 'Decline',
                      expand: true,
                      onPressed: _busy ? null : () => _respond(false),
                    ),
                  ],
                ),
    );
  }
}

/// The family-tree notifications inbox.
class _NotificationsSheet extends StatefulWidget {
  const _NotificationsSheet();

  @override
  State<_NotificationsSheet> createState() => _NotificationsSheetState();
}

class _NotificationsSheetState extends State<_NotificationsSheet> {
  List<Map<String, dynamic>> _items = const [];
  bool _loading = true;
  final _busy = <String>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await Repository.instance.familyNotifications();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _markRead(Map<String, dynamic> n) async {
    final id = n['_id']?.toString() ?? '';
    if (id.isEmpty || n['read'] == true) return;
    setState(() => n['read'] = true);
    try {
      await Repository.instance.markFamilyNotificationRead(id);
    } catch (_) {/* best-effort */}
  }

  Future<void> _markAllRead() async {
    final unread = _items.where((n) => n['read'] != true).toList();
    if (unread.isEmpty) return;
    setState(() {
      for (final n in unread) {
        n['read'] = true;
      }
    });
    try {
      await Repository.instance.markAllFamilyNotificationsRead();
    } catch (_) {/* best-effort */}
  }

  /// Answer a `relationship_request` straight from its notification — the
  /// `relationshipId` it carries is exactly what the accept/decline endpoints
  /// take in their body, so there is no request list to go through first.
  Future<void> _respond(Map<String, dynamic> n, bool accept) async {
    final rid = (n['relationshipId'] ?? '').toString();
    if (rid.isEmpty) return;
    setState(() => _busy.add(rid));
    try {
      if (accept) {
        await Repository.instance.acceptFamilyRequest(rid);
      } else {
        await Repository.instance.declineFamilyRequest(rid);
      }
      if (!mounted) return;
      setState(() {
        n['read'] = true;
        n['answered'] = accept ? 'accepted' : 'declined';
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update the request')),
      );
    } finally {
      if (mounted) setState(() => _busy.remove(rid));
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = _items.any((n) => n['read'] != true);
    return _SheetScaffold(
      title: 'Notifications',
      action: hasUnread
          ? TextButton(
              onPressed: _markAllRead,
              child: Text('Mark all read',
                  style: body(12,
                      weight: FontWeight.w700, color: AppColors.forest700)),
            )
          : null,
      child: _loading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                  child:
                      CircularProgressIndicator(color: AppColors.forest700)),
            )
          : _items.isEmpty
              ? _emptyState('No notifications',
                  'Relationship activity - requests, joins, merges - appears here.')
              : Column(
                  children: [
                    for (final n in _items) _notificationTile(n),
                  ],
                ),
    );
  }

  Widget _notificationTile(Map<String, dynamic> n) {
    final read = n['read'] == true;
    final rid = (n['relationshipId'] ?? '').toString();
    final answered = (n['answered'] ?? '').toString();
    // Only a request is actionable; everything else is a record of something
    // that already happened.
    final actionable = n['type'] == 'relationship_request' &&
        rid.isNotEmpty &&
        answered.isEmpty;
    return InkWell(
      onTap: () => _markRead(n),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: read ? Colors.white : const Color(0xFFF0F6F1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (!read)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: const BoxDecoration(
                      color: AppColors.gold700,
                      shape: BoxShape.circle,
                    ),
                  ),
                Expanded(
                  child: Text((n['message'] ?? '').toString(),
                      style: body(13, color: AppColors.forest900)),
                ),
              ],
            ),
            if (answered.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                answered == 'accepted' ? 'Accepted' : 'Declined',
                style: body(11,
                    weight: FontWeight.w700, color: AppColors.forest700),
              ),
            ],
            if (actionable) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlineButtonX(
                      label: 'Decline',
                      expand: true,
                      onPressed: _busy.contains(rid)
                          ? null
                          : () => _respond(n, false),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ForestButton(
                      label: 'Accept',
                      expand: true,
                      loading: _busy.contains(rid),
                      onPressed: () => _respond(n, true),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Shared sheet chrome + helpers (top-level so every sheet can use them) ──────

class _SheetScaffold extends StatelessWidget {
  const _SheetScaffold({required this.title, required this.child, this.action});
  final String title;
  final Widget child;

  /// Optional control shown to the left of the close button (e.g. "Mark all read").
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scroll) => Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(999)),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Text(title,
                      style: display(20, color: AppColors.forest900)),
                ),
                ?action,
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded,
                      color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              controller: scroll,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [child],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _requestTile({
  required String name,
  required String message,
  required bool busy,
  required VoidCallback onAccept,
  required VoidCallback onDecline,
}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(message.isNotEmpty ? message : '$name wants to connect.',
            style: body(13, color: AppColors.forest900, height: 1.4)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlineButtonX(
                label: 'Decline',
                expand: true,
                onPressed: busy ? null : onDecline,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ForestButton(
                label: 'Accept',
                expand: true,
                loading: busy,
                onPressed: onAccept,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

Widget _emptyState(String title, String subtitle) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 8),
    child: Column(
      children: [
        const Icon(Icons.inbox_rounded, size: 40, color: AppColors.forest300),
        const SizedBox(height: 12),
        Text(title,
            textAlign: TextAlign.center,
            style: display(18, color: AppColors.forest900)),
        const SizedBox(height: 6),
        Text(subtitle,
            textAlign: TextAlign.center,
            style: body(13, color: AppColors.textMuted, height: 1.5)),
      ],
    ),
  );
}

String _nameOf(Object? requester) {
  if (requester is Map && requester['name'] != null) {
    return requester['name'].toString();
  }
  return 'Someone';
}
