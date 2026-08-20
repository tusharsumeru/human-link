// Where each person in the family tree should be *drawn*.
//
// The backend answers "who is this person to me, and how" — every node carries a
// derived `relation` plus the `path` of stored relations it was derived from.
// This file answers the other half of the question, and deliberately does NOT
// use `generation`, `relationshipLevel` or `distance` as coordinates: those are
// metadata, not positions. A brother-in-law is `generation: 0`, but he does not
// belong beside you — he belongs in your spouse's sibling branch.
//
// Position comes from the structure instead:
//
// 1. FamilyGraph re-reads `edges` as a kinship graph (parents / children /
//    siblings / spouses) and walks it outward from the root, so every person
//    ends up attached to the person they were *reached through* (FamilyJoin).
//    `path` and `distance` are used only to pick the right attachment when two
//    are possible — never to place anybody.
// 2. FamilyTreeLayout turns that into FamilyLayoutNode frames — a person, their
//    spouse beside them, children below, parents above, siblings to the sides —
//    and measures each frame's subtree to assign real coordinates.
//
// Visibility is progressive: the compact default shows the root's immediate
// family (and the spouses of those people, since a spouse is drawn as part of
// their partner's unit); anything reached *through* someone else appears only
// once that person is expanded.

import 'dart:math' as math;
import 'dart:ui' show Offset;

/// How a person hangs off the person they were reached through.
enum FamilyJoin { self, spouse, parent, sibling, child }

/// The kinds of connector the painter draws.
enum FamilyLinkKind { spouse, parentChild, sibling }

/// A connector as a ready-to-stroke polyline in canvas coordinates.
class FamilyLink {
  const FamilyLink(this.kind, this.points);

  final FamilyLinkKind kind;
  final List<Offset> points;
}

/// Visual constants the layout needs. The widget owns these so the drawing code
/// and the maths can never disagree about how much room a node takes.
class FamilyTreeMetrics {
  const FamilyTreeMetrics({
    this.nodeDiameter = 80,
    this.nodeSlot = 112,
    this.spouseGap = 34,
    this.branchGap = 28,
    this.rowHeight = 150,
    this.padding = 60,
    this.top = 96,
    this.minWidth = 900,
  });

  /// Diameter of the avatar circle.
  final double nodeDiameter;

  /// Horizontal room one person occupies, including their name/relation caption.
  final double nodeSlot;

  /// Gap between the two circles of a couple.
  final double spouseGap;

  /// Gap between neighbouring branches on the same row.
  final double branchGap;

  final double rowHeight;
  final double padding;
  final double top;
  final double minWidth;

  double get radius => nodeDiameter / 2;

  /// Distance between the centres of a married pair.
  double get coupleInner => nodeDiameter + spouseGap;
}

/// The backend's `{nodes, edges}` answer re-expressed as "who hangs off whom".
class FamilyGraph {
  FamilyGraph._({
    required this.rootId,
    required this.byId,
    required this.spouses,
    required this.parents,
    required this.children,
    required this.siblings,
    required this.anchorOf,
    required this.joinOf,
    required this.generationOf,
    required this.dependentsOf,
  });

  /// Builds the graph from a `GET /api/family/tree` payload.
  factory FamilyGraph.fromTree({
    required List<Map<String, dynamic>> nodes,
    required List<Map<String, dynamic>> edges,
    String? rootId,
  }) {
    final byId = <String, Map<String, dynamic>>{};
    for (final n in nodes) {
      final id = (n['id'] ?? n['_id'] ?? '').toString();
      if (id.isNotEmpty) byId[id] = n;
    }

    var root = (rootId ?? '').toString();
    if (!byId.containsKey(root)) {
      root = '';
      for (final e in byId.entries) {
        if (e.value['isSelf'] == true) {
          root = e.key;
          break;
        }
      }
      if (root.isEmpty && byId.isNotEmpty) root = byId.keys.first;
    }

    final spouses = <String, Set<String>>{};
    final parents = <String, Set<String>>{};
    final children = <String, Set<String>>{};
    final siblings = <String, Set<String>>{};
    void link(Map<String, Set<String>> m, String a, String b) =>
        (m[a] ??= <String>{}).add(b);

    // An edge asserts "`to` is `from`'s <relation>", so each one gives both
    // directions of a single kinship fact.
    for (final e in edges) {
      final a = (e['from'] ?? '').toString();
      final b = (e['to'] ?? '').toString();
      final rel = (e['relation'] ?? '').toString();
      if (a == b || !byId.containsKey(a) || !byId.containsKey(b)) continue;
      if (rel == 'father' || rel == 'mother') {
        link(parents, a, b);
        link(children, b, a);
      } else if (rel == 'son' || rel == 'daughter') {
        link(children, a, b);
        link(parents, b, a);
      } else if (rel == 'brother' || rel == 'sister') {
        link(siblings, a, b);
        link(siblings, b, a);
      } else if (rel == 'spouse') {
        link(spouses, a, b);
        link(spouses, b, a);
      }
    }

    // Two people who share a parent are siblings even when no sibling edge was
    // ever stored — that is what keeps them on one row instead of drifting apart.
    for (final kids in children.values) {
      final list = kids.toList();
      for (var i = 0; i < list.length; i++) {
        for (var j = i + 1; j < list.length; j++) {
          link(siblings, list[i], list[j]);
          link(siblings, list[j], list[i]);
        }
      }
    }

    final anchorOf = <String, String>{};
    final joinOf = <String, FamilyJoin>{root: FamilyJoin.self};
    final generationOf = <String, int>{root: 0};
    final assigned = <String>{if (root.isNotEmpty) root};

    // Level-synchronous walk outward from the root: everyone one step further
    // out is attached in the same pass, so an attachment is always chosen among
    // equally-close anchors rather than by iteration luck.
    var current = <String>[if (root.isNotEmpty) root];
    var guard = 0;
    while (current.isNotEmpty && guard++ < 64) {
      final best = <String, _Candidate>{};
      for (final a in current) {
        void offer(Iterable<String>? ids, FamilyJoin join) {
          for (final b in (ids ?? const <String>{})) {
            if (b == a || assigned.contains(b) || !byId.containsKey(b)) continue;
            final score = _score(byId, a, b, join);
            final prev = best[b];
            if (prev == null ||
                score > prev.score ||
                (score == prev.score && a.compareTo(prev.anchor) < 0)) {
              best[b] = _Candidate(a, join, score);
            }
          }
        }

        offer(spouses[a], FamilyJoin.spouse);
        offer(parents[a], FamilyJoin.parent);
        offer(children[a], FamilyJoin.child);
        offer(siblings[a], FamilyJoin.sibling);
      }
      final next = <String>[];
      for (final b in best.keys.toList()..sort()) {
        final c = best[b]!;
        anchorOf[b] = c.anchor;
        joinOf[b] = c.join;
        generationOf[b] =
            (generationOf[c.anchor] ?? 0) + _generationDelta(c.join);
        assigned.add(b);
        next.add(b);
      }
      current = next;
    }

    // Anything the edges never reached still has to be drawable: hang it off the
    // root using its own path, and fall back to the metadata row.
    for (final id in byId.keys) {
      if (assigned.contains(id)) continue;
      final p = pathOf(byId[id]);
      anchorOf[id] = root;
      joinOf[id] = p.isEmpty ? FamilyJoin.sibling : joinOfWord(p.last);
      generationOf[id] = ((byId[id]?['generation'] ?? 0) as num).toInt();
    }

    final dependentsOf = <String, List<String>>{};
    for (final id in byId.keys) {
      if (id == root) continue;
      // A spouse is drawn as part of their partner's unit, so they are never
      // something you have to expand to see.
      if (joinOf[id] == FamilyJoin.spouse) continue;
      final a = anchorOf[id];
      if (a == null) continue;
      (dependentsOf[a] ??= <String>[]).add(id);
    }

    return FamilyGraph._(
      rootId: root,
      byId: byId,
      spouses: spouses,
      parents: parents,
      children: children,
      siblings: siblings,
      anchorOf: anchorOf,
      joinOf: joinOf,
      generationOf: generationOf,
      dependentsOf: dependentsOf,
    );
  }

  final String rootId;
  final Map<String, Map<String, dynamic>> byId;
  final Map<String, Set<String>> spouses;
  final Map<String, Set<String>> parents;
  final Map<String, Set<String>> children;
  final Map<String, Set<String>> siblings;

  /// The person each person was reached through.
  final Map<String, String> anchorOf;

  /// How they hang off that person.
  final Map<String, FamilyJoin> joinOf;

  /// Structural row: `0` = root, negative = above, positive = below. Derived by
  /// walking the joins, *not* copied from the backend's `generation`.
  final Map<String, int> generationOf;

  /// anchor → the people whose visibility depends on that anchor being expanded.
  final Map<String, List<String>> dependentsOf;

  bool get isEmpty => rootId.isEmpty;

  Map<String, dynamic>? node(String id) => byId[id];

  String nameOf(String id) => (byId[id]?['name'] ?? '').toString();

  String genderOf(String id) => (byId[id]?['gender'] ?? '').toString();

  DateTime? dobOf(String id) =>
      DateTime.tryParse((byId[id]?['dob'] ?? '').toString());

  /// Eldest first, then by name — a deterministic order that also happens to be
  /// the one people expect siblings and children to be drawn in.
  List<String> ordered(Iterable<String>? ids) {
    final list = (ids ?? const <String>{}).toList();
    list.sort((a, b) {
      final da = dobOf(a);
      final db = dobOf(b);
      if (da != null && db != null && da != db) return da.compareTo(db);
      if (da != null && db == null) return -1;
      if (da == null && db != null) return 1;
      final byName = nameOf(a).compareTo(nameOf(b));
      return byName != 0 ? byName : a.compareTo(b);
    });
    return list;
  }

  /// Is this person part of the current view? Spouses ride along with their
  /// partner; everyone else needs the person they were reached through to be the
  /// root or expanded.
  bool isVisible(String id, Set<String> expanded) {
    var cur = id;
    var guard = 0;
    while (cur != rootId && guard++ < 64) {
      final a = anchorOf[cur];
      if (a == null) return false;
      if (joinOf[cur] != FamilyJoin.spouse &&
          a != rootId &&
          !expanded.contains(a)) {
        return false;
      }
      cur = a;
    }
    return cur == rootId;
  }

  /// How many relatives are hidden behind this person right now.
  int hiddenCount(String id, Set<String> expanded) {
    var n = 0;
    for (final d in dependentsOf[id] ?? const <String>[]) {
      if (!isVisible(d, expanded)) n++;
    }
    return n;
  }

  /// Does this person have a branch worth an expand/collapse control at all?
  bool hasBranch(String id) => (dependentsOf[id] ?? const []).isNotEmpty;

  /// Everyone who can be expanded — used by "expand all".
  List<String> get branchOwners =>
      dependentsOf.entries.where((e) => e.value.isNotEmpty).map((e) => e.key).toList();

  static List<String> pathOf(Map<String, dynamic>? node) {
    final p = node?['path'];
    if (p is List) return p.map((e) => e.toString()).toList();
    return const [];
  }

  static FamilyJoin joinOfWord(String word) {
    switch (word) {
      case 'father':
      case 'mother':
        return FamilyJoin.parent;
      case 'son':
      case 'daughter':
        return FamilyJoin.child;
      case 'spouse':
        return FamilyJoin.spouse;
      default:
        return FamilyJoin.sibling;
    }
  }

  static int _generationDelta(FamilyJoin join) => switch (join) {
        FamilyJoin.parent => -1,
        FamilyJoin.child => 1,
        _ => 0,
      };

  static int? _distanceOf(Map<String, dynamic>? node) {
    final d = node?['distance'];
    return d is num ? d.toInt() : null;
  }

  /// Prefers the attachment the backend's own `path` describes, then the one its
  /// `distance` agrees with, then the more structural join.
  static int _score(
    Map<String, Map<String, dynamic>> byId,
    String a,
    String b,
    FamilyJoin join,
  ) {
    var s = switch (join) {
      FamilyJoin.spouse => 4,
      FamilyJoin.parent => 3,
      FamilyJoin.child => 2,
      _ => 1,
    };
    final pa = pathOf(byId[a]);
    final pb = pathOf(byId[b]);
    if (pb.length == pa.length + 1 &&
        joinOfWord(pb.last) == join &&
        _isPrefix(pa, pb)) {
      s += 100;
    }
    final da = _distanceOf(byId[a]);
    final db = _distanceOf(byId[b]);
    if (da != null && db != null && db == da + 1) s += 50;
    return s;
  }

  static bool _isPrefix(List<String> prefix, List<String> full) {
    for (var i = 0; i < prefix.length; i++) {
      if (prefix[i] != full[i]) return false;
    }
    return true;
  }
}

class _Candidate {
  const _Candidate(this.anchor, this.join, this.score);
  final String anchor;
  final FamilyJoin join;
  final int score;
}

/// One drawable family unit: a person, the spouse beside them, and the branches
/// that hang off the pair. This is the render model — the backend node model is
/// left untouched and stays the source data.
class FamilyLayoutNode {
  FamilyLayoutNode({
    required this.person,
    required this.spouse,
    required this.row,
  });

  /// The person this frame was reached through (connectors anchor here).
  final String person;

  /// Their partner, drawn beside them, or null.
  final String? spouse;

  /// The unit in drawing order, left to right (1 or 2 people).
  final List<String> row;

  /// Parent couples, drawn above.
  final List<FamilyLayoutNode> parents = [];

  /// Children (each with their own spouse and branches), drawn below.
  final List<FamilyLayoutNode> children = [];

  /// Siblings of the left-hand member, drawn outward to the left.
  final List<FamilyLayoutNode> siblingsLeft = [];

  /// Siblings of the right-hand member, drawn outward to the right.
  final List<FamilyLayoutNode> siblingsRight = [];

  List<FamilyLayoutNode> get siblings => [...siblingsLeft, ...siblingsRight];

  /// Every frame reachable from this one, including itself.
  Iterable<FamilyLayoutNode> get descendants => [
        this,
        for (final f in [...parents, ...children, ...siblingsLeft, ...siblingsRight])
          ...f.descendants,
      ];
}

class _Box {
  _Box({
    required this.width,
    required this.center,
    required this.own,
    required this.below,
    required this.above,
  });

  /// Total width of this frame and everything hanging off it.
  final double width;

  /// The unit's centre, relative to the box's left edge.
  final double center;

  /// Width of the unit itself.
  final double own;

  final double below;
  final double above;
}

/// The finished drawing plan: a position per visible person plus the connectors
/// between them.
class FamilyTreeLayout {
  FamilyTreeLayout._(this.graph, this.metrics, this.expanded);

  static FamilyTreeLayout build({
    required FamilyGraph graph,
    required Set<String> expanded,
    FamilyTreeMetrics metrics = const FamilyTreeMetrics(),
  }) {
    final layout = FamilyTreeLayout._(graph, metrics, expanded);
    layout._run();
    return layout;
  }

  final FamilyGraph graph;
  final FamilyTreeMetrics metrics;
  final Set<String> expanded;

  final Map<String, Offset> positions = {};
  final List<FamilyLink> links = [];

  /// Visible people in drawing order.
  final List<String> placed = [];

  final Map<FamilyLayoutNode, _Box> _boxes = {};

  FamilyLayoutNode? root;
  double width = 0;
  double height = 0;
  List<int> generations = const [];
  int _minGen = 0;

  double rowY(int generation) =>
      metrics.top + (generation - _minGen) * metrics.rowHeight;

  int hiddenCount(String id) => graph.hiddenCount(id, expanded);

  bool isExpanded(String id) => expanded.contains(id);

  void _run() {
    if (graph.isEmpty) return;
    final claimed = <String>{};
    final frame = _frame(graph.rootId, claimed);
    root = frame;
    _measure(frame);
    _place(frame, 0);
    _normalize();
    _buildLinks();
  }

  // ── Frames ─────────────────────────────────────────────────────────────────

  /// Builds the frame for [id] and, recursively, every branch hanging off it.
  /// [claimed] guarantees each person is drawn exactly once and keeps the
  /// recursion from walking back the way it came.
  FamilyLayoutNode _frame(String id, Set<String> claimed) {
    claimed.add(id);

    String? spouse;
    for (final s in graph.ordered(graph.spouses[id])) {
      if (claimed.contains(s) || !_visible(s)) continue;
      spouse = s;
      claimed.add(s);
      break;
    }

    final frame = FamilyLayoutNode(
      person: id,
      spouse: spouse,
      row: _orderCouple(id, spouse),
    );

    // Claim children and siblings before recursing: a branch further down must
    // not be able to steal a person who belongs on this frame's own row.
    final kids = <String>[];
    for (final member in frame.row) {
      for (final c in graph.ordered(graph.children[member])) {
        if (claimed.contains(c) || !_visible(c)) continue;
        claimed.add(c);
        kids.add(c);
      }
    }
    final left = <String>[];
    final right = <String>[];
    _collectSiblings(frame, claimed, left, right);

    for (final c in graph.ordered(kids)) {
      frame.children.add(_frame(c, claimed));
    }
    for (final s in left) {
      frame.siblingsLeft.add(_frame(s, claimed));
    }
    for (final s in right) {
      frame.siblingsRight.add(_frame(s, claimed));
    }
    // Parents are claimed lazily: building the father's frame picks up the
    // mother as his spouse, so the couple stays one unit.
    for (final member in frame.row) {
      for (final p in _parentsMaleFirst(member)) {
        if (claimed.contains(p) || !_visible(p)) continue;
        frame.parents.add(_frame(p, claimed));
      }
    }
    return frame;
  }

  /// Male on the left when the pair differs, otherwise the person we arrived
  /// through — the reading order every diagram in the spec uses.
  List<String> _orderCouple(String person, String? spouse) {
    if (spouse == null) return [person];
    final personMale = graph.genderOf(person) == 'M';
    final spouseMale = graph.genderOf(spouse) == 'M';
    if (spouseMale && !personMale) return [spouse, person];
    return [person, spouse];
  }

  /// Siblings sit beside the person they are a sibling *of*: the left member's
  /// siblings go left, the right member's go right, so a spouse's siblings stay
  /// on the spouse's side of the couple.
  void _collectSiblings(
    FamilyLayoutNode frame,
    Set<String> claimed,
    List<String> left,
    List<String> right,
  ) {
    if (frame.row.length == 2) {
      // Reversed so the eldest ends up furthest from the couple.
      left.addAll(_claimSiblings(frame.row[0], claimed).reversed);
      right.addAll(_claimSiblings(frame.row[1], claimed));
      return;
    }
    final me = frame.row.first;
    final mine = _claimSiblings(me, claimed);
    final myDob = graph.dobOf(me);
    final elders = <String>[];
    final youngers = <String>[];
    for (var i = 0; i < mine.length; i++) {
      final dob = graph.dobOf(mine[i]);
      if (myDob != null && dob != null) {
        (dob.isBefore(myDob) ? elders : youngers).add(mine[i]);
      } else {
        // No birth order to go on — balance them around the person instead.
        (i.isEven ? youngers : elders).add(mine[i]);
      }
    }
    left.addAll(elders.reversed);
    right.addAll(youngers);
  }

  /// Eldest first.
  List<String> _claimSiblings(String id, Set<String> claimed) {
    final out = <String>[];
    for (final s in graph.ordered(graph.siblings[id])) {
      if (claimed.contains(s) || !_visible(s)) continue;
      claimed.add(s);
      out.add(s);
    }
    return out;
  }

  List<String> _parentsMaleFirst(String id) {
    final list = graph.ordered(graph.parents[id]);
    list.sort((a, b) {
      final ma = graph.genderOf(a) == 'M' ? 0 : 1;
      final mb = graph.genderOf(b) == 'M' ? 0 : 1;
      return ma.compareTo(mb);
    });
    return list;
  }

  bool _visible(String id) => graph.isVisible(id, expanded);

  // ── Measure & place ────────────────────────────────────────────────────────

  _Box _measure(FamilyLayoutNode frame) {
    final cached = _boxes[frame];
    if (cached != null) return cached;

    final own = frame.row.length == 2
        ? metrics.coupleInner + metrics.nodeSlot
        : metrics.nodeSlot;

    double band(List<FamilyLayoutNode> list) {
      var total = 0.0;
      for (var i = 0; i < list.length; i++) {
        total += _measure(list[i]).width;
        if (i > 0) total += metrics.branchGap;
      }
      return total;
    }

    final leftW = band(frame.siblingsLeft);
    final rightW = band(frame.siblingsRight);
    final belowW = band(frame.children);
    final aboveW = band(frame.parents);

    final rowLeft = leftW > 0 ? leftW + metrics.branchGap : 0.0;
    final center = rowLeft + own / 2;
    var minX = 0.0;
    var maxX = rowLeft + own + (rightW > 0 ? metrics.branchGap + rightW : 0.0);
    // Children and parents are centred on the unit, so they can stick out past
    // the row band on either side.
    if (belowW > 0) {
      minX = math.min(minX, center - belowW / 2);
      maxX = math.max(maxX, center + belowW / 2);
    }
    if (aboveW > 0) {
      minX = math.min(minX, center - aboveW / 2);
      maxX = math.max(maxX, center + aboveW / 2);
    }

    final box = _Box(
      width: maxX - minX,
      center: center - minX,
      own: own,
      below: belowW,
      above: aboveW,
    );
    _boxes[frame] = box;
    return box;
  }

  void _place(FamilyLayoutNode frame, double left) {
    final box = _measure(frame);
    final cx = left + box.center;
    final y = (graph.generationOf[frame.person] ?? 0) * metrics.rowHeight;

    if (frame.row.length == 2) {
      final half = metrics.coupleInner / 2;
      positions[frame.row[0]] = Offset(cx - half, y);
      positions[frame.row[1]] = Offset(cx + half, y);
      placed.addAll(frame.row);
    } else {
      positions[frame.row.first] = Offset(cx, y);
      placed.add(frame.row.first);
    }

    var cursor = cx - box.below / 2;
    for (final c in frame.children) {
      _place(c, cursor);
      cursor += _measure(c).width + metrics.branchGap;
    }
    cursor = cx - box.above / 2;
    for (final p in frame.parents) {
      _place(p, cursor);
      cursor += _measure(p).width + metrics.branchGap;
    }
    var edge = cx - box.own / 2 - metrics.branchGap;
    for (final s in frame.siblingsLeft) {
      final w = _measure(s).width;
      _place(s, edge - w);
      edge -= w + metrics.branchGap;
    }
    edge = cx + box.own / 2 + metrics.branchGap;
    for (final s in frame.siblingsRight) {
      _place(s, edge);
      edge += _measure(s).width + metrics.branchGap;
    }
  }

  void _normalize() {
    if (positions.isEmpty) return;
    var minX = double.infinity;
    var maxX = -double.infinity;
    var minY = double.infinity;
    var maxY = -double.infinity;
    for (final o in positions.values) {
      minX = math.min(minX, o.dx);
      maxX = math.max(maxX, o.dx);
      minY = math.min(minY, o.dy);
      maxY = math.max(maxY, o.dy);
    }
    final dx = metrics.padding + metrics.nodeSlot / 2 - minX;
    final dy = metrics.top - minY;
    for (final id in positions.keys.toList()) {
      positions[id] = positions[id]!.translate(dx, dy);
    }
    width = math.max(
        metrics.minWidth, maxX + dx + metrics.nodeSlot / 2 + metrics.padding);
    height = maxY + dy + metrics.rowHeight;

    final gens = <int>{};
    for (final id in placed) {
      gens.add(graph.generationOf[id] ?? 0);
    }
    generations = gens.toList()..sort();
    _minGen = generations.isEmpty ? 0 : generations.first;
  }

  // ── Connectors ─────────────────────────────────────────────────────────────

  void _buildLinks() {
    final r = metrics.radius;

    // Spouses: a horizontal line between the pair.
    final drawn = <String>{};
    for (final id in placed) {
      for (final s in graph.spouses[id] ?? const <String>{}) {
        final a = positions[id];
        final b = positions[s];
        if (a == null || b == null) continue;
        if (!drawn.add(([id, s]..sort()).join('|'))) continue;
        if ((a.dy - b.dy).abs() < 1) {
          final leftEnd = a.dx <= b.dx ? a : b;
          final rightEnd = a.dx <= b.dx ? b : a;
          links.add(FamilyLink(FamilyLinkKind.spouse, [
            Offset(leftEnd.dx + r, leftEnd.dy),
            Offset(rightEnd.dx - r, rightEnd.dy),
          ]));
        } else {
          links.add(FamilyLink(FamilyLinkKind.spouse, [a, b]));
        }
      }
    }

    // Parents to child: down from between the couple, along a bus, then into the
    // child — so several children share one visible fork.
    for (final id in placed) {
      final visibleParents = (graph.parents[id] ?? const <String>{})
          .where(positions.containsKey)
          .toList();
      if (visibleParents.isEmpty) continue;
      final child = positions[id]!;
      var px = 0.0;
      var py = -double.infinity;
      for (final p in visibleParents) {
        px += positions[p]!.dx;
        py = math.max(py, positions[p]!.dy);
      }
      px /= visibleParents.length;
      if (child.dy <= py) {
        links.add(FamilyLink(
            FamilyLinkKind.parentChild, [Offset(px, py), child]));
        continue;
      }
      final busY = py + (child.dy - py) / 2;
      links.add(FamilyLink(FamilyLinkKind.parentChild, [
        Offset(px, py + (visibleParents.length == 1 ? r : 0)),
        Offset(px, busY),
        Offset(child.dx, busY),
        Offset(child.dx, child.dy - r),
      ]));
    }

    // Siblings with no visible parent get their own bracket, so a group like a
    // spouse and their brother still reads as one generation of one family.
    final grouped = <String>{};
    for (final id in placed) {
      if (!grouped.add(id)) continue;
      final group = <String>{id};
      final stack = <String>[id];
      while (stack.isNotEmpty) {
        for (final s in graph.siblings[stack.removeLast()] ?? const <String>{}) {
          if (!positions.containsKey(s) || !group.add(s)) continue;
          stack.add(s);
        }
      }
      grouped.addAll(group);
      if (group.length < 2) continue;
      if (group.any((p) => (graph.parents[p] ?? const <String>{})
          .any(positions.containsKey))) {
        continue; // the parent fork already shows the grouping
      }
      final ys = group.map((p) => positions[p]!.dy).toSet();
      if (ys.length != 1) continue;
      final y = ys.first;
      final xs = group.map((p) => positions[p]!.dx).toList()..sort();
      final barY = y - r - 20;
      links.add(FamilyLink(FamilyLinkKind.sibling,
          [Offset(xs.first, barY), Offset(xs.last, barY)]));
      for (final x in xs) {
        links.add(FamilyLink(
            FamilyLinkKind.sibling, [Offset(x, barY), Offset(x, y - r)]));
      }
    }
  }
}
