/// The botanical field the profile header is drawn on, and the flourish that
/// closes it.
///
/// Painted rather than shipped as an image: two PNGs at phone resolution cost
/// more than this does to draw, and a painted motif scales to any header
/// height without a second asset. No blur filters anywhere — a `MaskFilter`
/// or `BackdropFilter` behind a scrolling page is the one thing here that
/// would actually cost frames.
///
/// Everything is drawn at very low alpha. The motif is meant to be noticed on
/// the second look, never to compete with the name sitting on top of it.
library;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Paints the leaf field behind [child].
///
/// [pageColor] is what the bottom edge curves away to reveal — pass the
/// surface below and the header reads as something the page rises into.
class LeafBackdrop extends StatelessWidget {
  const LeafBackdrop({super.key, required this.child, this.pageColor});

  final Widget child;
  final Color? pageColor;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _LeafPainter(dark: context.isDarkMode, pageColor: pageColor),
      // isComplex: the same static field is repainted on every scroll frame
      // otherwise; this lets the engine cache it as a picture layer.
      isComplex: true,
      willChange: false,
      child: child,
    );
  }
}

class _LeafPainter extends CustomPainter {
  const _LeafPainter({required this.dark, this.pageColor});

  /// One motif, two readings. On ivory the leaves are soft sage fills with a
  /// pair of gold arcs threading between them; on near-black they are barely
  /// lifted greens and the arcs are dropped entirely — a gold line that
  /// reads as elegant over cream reads as a scratch over black.
  final bool dark;
  final Color? pageColor;

  /// Leaf silhouettes: centre x/y and length as fractions of the box, plus a
  /// rotation. Fractional so the composition survives a header that grows a
  /// line taller for a bio.
  static const _leaves = <(double, double, double, double)>[
    (0.02, 0.18, 0.46, -0.5),
    (0.14, 0.05, 0.34, 0.35),
    (0.97, 0.22, 0.44, 0.6),
    (0.86, 0.06, 0.30, -0.25),
    (0.06, 0.82, 0.34, -1.1),
    (0.95, 0.74, 0.32, 1.05),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? const [AppColors.darkCanvas, AppColors.darkCanvasLift]
              : const [AppColors.ivory, AppColors.ivoryLift],
        ).createShader(rect),
    );

    canvas.save();
    canvas.clipRect(rect);
    _paintLeaves(canvas, size);
    if (!dark) _paintArcs(canvas, size);
    canvas.restore();

    if (pageColor != null) _paintLip(canvas, size, pageColor!);
  }

  /// Broad, soft leaves — filled in a green barely lighter than the ground,
  /// with a slightly stronger midrib so the shape reads as a leaf rather than
  /// a smudge.
  void _paintLeaves(Canvas canvas, Size size) {
    // Sage carries on ivory at an alpha that would be invisible on black,
    // and vice versa — hence two sets of numbers rather than one colour.
    final fill = Paint()
      ..color = dark
          ? AppColors.emerald.withValues(alpha: 0.055)
          : AppColors.forest300.withValues(alpha: 0.30);
    final vein = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = dark
          ? AppColors.emerald.withValues(alpha: 0.10)
          : AppColors.forest600.withValues(alpha: 0.16);

    for (final (fx, fy, flen, angle) in _leaves) {
      final len = size.width * flen;
      canvas.save();
      canvas.translate(size.width * fx, size.height * fy);
      canvas.rotate(angle);
      final leaf = Path()
        ..moveTo(0, -len / 2)
        ..quadraticBezierTo(len * 0.34, 0, 0, len / 2)
        ..quadraticBezierTo(-len * 0.34, 0, 0, -len / 2)
        ..close();
      canvas.drawPath(leaf, fill);
      canvas.drawLine(Offset(0, -len / 2), Offset(0, len / 2), vein);
      canvas.restore();
    }
  }

  /// The champagne threads that run between the leaves on ivory. Struck from
  /// centres off-canvas so they read as long curves passing through rather
  /// than rings around anything.
  void _paintArcs(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (final (cx, cy, radius, width, alpha, start, sweep) in const [
      (-0.18, 0.26, 0.92, 1.4, 0.55, -1.0, 1.5),
      (1.18, 0.58, 0.88, 1.2, 0.45, 2.1, 1.4),
    ]) {
      canvas.drawArc(
        Rect.fromCircle(
          center: Offset(size.width * cx, size.height * cy),
          radius: size.width * radius,
        ),
        start,
        sweep,
        false,
        paint
          ..strokeWidth = width
          ..color = AppColors.champagne.withValues(alpha: alpha),
      );
    }
  }

  /// The page colour curving back up along the bottom edge.
  void _paintLip(Canvas canvas, Size size, Color color) {
    final lip = size.height * 0.045;
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height - lip)
        ..quadraticBezierTo(
          size.width / 2,
          size.height + lip,
          size.width,
          size.height - lip,
        )
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close(),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_LeafPainter old) =>
      old.dark != dark || old.pageColor != pageColor;
}

/// Rule — lotus — rule, in champagne: the flourish that closes the header.
class LotusOrnament extends StatelessWidget {
  const LotusOrnament({super.key, this.ruleWidth = 44});

  final double ruleWidth;

  @override
  Widget build(BuildContext context) {
    final gold = context.onBrightness(
      light: AppColors.champagneDeep,
      dark: AppColors.champagne,
    );
    // Faded at the outer end so each rule reads as tapering away rather than
    // stopping dead.
    Widget rule({required bool fadeLeft}) => Container(
      width: ruleWidth,
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: fadeLeft ? Alignment.centerLeft : Alignment.centerRight,
          end: fadeLeft ? Alignment.centerRight : Alignment.centerLeft,
          colors: [gold.withValues(alpha: 0), gold.withValues(alpha: 0.85)],
        ),
      ),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        rule(fadeLeft: true),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Icon(Icons.spa_rounded, size: 14, color: gold),
        ),
        rule(fadeLeft: false),
      ],
    );
  }
}

/// The same botanical field as [LeafBackdrop], composed for a whole page
/// rather than a header band.
///
/// [LeafBackdrop] is tuned for a short, wide box: its leaves are sized as a
/// fraction of the *width*, which on a full-height page would blow them up
/// into shapes the size of the content. This one works the other way round —
/// long arcs sweeping in from off-canvas carry the composition, and the
/// leaves are small accents tucked into the corners the form leaves empty.
///
/// Painted behind the child and never scrolled: the ambience is the page's
/// ground, so it staying put is what keeps it reading as depth rather than
/// as content that happens to be decorative.
class LeafCanvas extends StatelessWidget {
  const LeafCanvas({super.key, required this.child, this.lush = false});

  final Widget child;

  /// Turns the field up: large gold-edged leaves banked along the foot of the
  /// page instead of small accents in the margins.
  ///
  /// For short pages — a page that is two cards and then empty space, where
  /// the bottom half is the backdrop and nothing else. A long form would just
  /// bury the leaves under its own fields and pay for painting them, so the
  /// forms leave this off.
  final bool lush;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _CanvasPainter(dark: context.isDarkMode, lush: lush),
            // The field is static behind a scrolling list; without this the
            // engine redraws every arc on every frame instead of caching the
            // picture once.
            isComplex: true,
            willChange: false,
          ),
        ),
        child,
      ],
    );
  }
}

class _CanvasPainter extends CustomPainter {
  const _CanvasPainter({required this.dark, this.lush = false});

  final bool dark;
  final bool lush;

  /// Arcs struck from centres well off-canvas, so what lands on the page is a
  /// long shallow curve passing through rather than a ring around something.
  /// (centre x/y, radius, start, sweep) — all fractions of the width except
  /// the angles, so the composition holds on any phone.
  static const _arcs = <(double, double, double, double, double)>[
    (1.35, 0.06, 0.95, 1.9, 1.5),
    (1.18, 0.30, 1.15, 2.0, 1.3),
    (-0.42, 0.72, 1.05, -0.9, 1.4),
    (1.30, 0.92, 0.80, 2.3, 1.2),
  ];

  /// Small leaves in the margins — centre x/y, length, rotation. Kept to the
  /// left and right edges where a form's labels and values never reach.
  static const _leaves = <(double, double, double, double)>[
    (0.03, 0.14, 0.26, -0.55),
    (0.96, 0.42, 0.22, 0.75),
    (0.06, 0.60, 0.20, -1.15),
    (0.94, 0.86, 0.24, 0.95),
  ];

  /// The lush set: a bank of large leaves along the foot of the page, plus a
  /// pair up in the top-right corner the header doesn't reach. Several are
  /// centred past y = 1.0 so only their top halves are on the page and they
  /// read as growing in from beyond the edge rather than floating.
  static const _lushLeaves = <(double, double, double, double)>[
    (0.02, 0.90, 0.74, -0.30),
    (0.30, 1.04, 0.62, 0.42),
    (0.60, 1.09, 0.56, -0.18),
    (0.98, 0.86, 0.70, 0.62),
    (0.88, 1.06, 0.50, 1.00),
    (0.97, 0.10, 0.34, 0.70),
    (0.83, 0.03, 0.26, -0.28),
  ];

  /// Long gold threads passing through the leaf bank — the one thing on this
  /// backdrop that is a line rather than a shape, which is what keeps the
  /// bottom of the page from reading as a single green mass.
  static const _lushThreads = <(double, double, double, double, double)>[
    (-0.30, 1.30, 1.20, -1.25, 1.1),
    (1.25, 1.15, 1.00, 2.35, 1.0),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? const [AppColors.darkCanvas, AppColors.darkCanvasLift]
              : const [AppColors.ivory, AppColors.ivoryLift],
        ).createShader(rect),
    );

    canvas.save();
    canvas.clipRect(rect);
    _paintGlow(canvas, size);
    _paintArcs(canvas, size);
    if (lush) {
      _paintLushLeaves(canvas, size);
      _paintThreads(canvas, size);
    } else {
      _paintLeaves(canvas, size);
    }
    canvas.restore();
  }

  /// The leaf path every variant draws, centred on the origin and pointing up.
  Path _leafPath(double len) => Path()
    ..moveTo(0, -len / 2)
    ..quadraticBezierTo(len * 0.34, 0, 0, len / 2)
    ..quadraticBezierTo(-len * 0.34, 0, 0, -len / 2)
    ..close();

  /// Big leaves, each drawn three times: a green fill barely off the ground, a
  /// gold edge, and a gold midrib. The fill alone is a silhouette and the edge
  /// alone is a wireframe — together they read as a leaf catching light.
  void _paintLushLeaves(Canvas canvas, Size size) {
    final fill = Paint()
      ..color = dark
          ? AppColors.emerald.withValues(alpha: 0.07)
          : AppColors.forest300.withValues(alpha: 0.26);
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = dark
          ? AppColors.champagne.withValues(alpha: 0.16)
          : AppColors.champagneDeep.withValues(alpha: 0.30);
    final rib = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = dark
          ? AppColors.champagne.withValues(alpha: 0.20)
          : AppColors.champagneDeep.withValues(alpha: 0.34);

    for (final (fx, fy, flen, angle) in _lushLeaves) {
      final len = size.width * flen;
      canvas.save();
      canvas.translate(size.width * fx, size.height * fy);
      canvas.rotate(angle);
      final leaf = _leafPath(len);
      canvas.drawPath(leaf, fill);
      canvas.drawPath(leaf, edge);
      canvas.drawLine(Offset(0, -len / 2), Offset(0, len / 2), rib);
      canvas.restore();
    }
  }

  void _paintThreads(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.5
      ..color = dark
          ? AppColors.champagne.withValues(alpha: 0.26)
          : AppColors.champagneDeep.withValues(alpha: 0.38);
    for (final (cx, cy, r, start, sweep) in _lushThreads) {
      canvas.drawArc(
        Rect.fromCircle(
          center: Offset(size.width * cx, size.height * cy),
          radius: size.width * r,
        ),
        start,
        sweep,
        false,
        paint,
      );
    }
  }

  /// A single warm spill in the top-right corner. A radial *gradient*, not a
  /// blurred circle — it reads the same and costs a shader instead of a
  /// `MaskFilter` pass over a full-screen layer.
  void _paintGlow(Canvas canvas, Size size) {
    final centre = Offset(size.width * 1.02, size.height * 0.06);
    final radius = size.width * 0.95;
    canvas.drawCircle(
      centre,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: dark
              ? [
                  AppColors.forest600.withValues(alpha: 0.22),
                  AppColors.forest600.withValues(alpha: 0),
                ]
              : [
                  AppColors.sage.withValues(alpha: 0.9),
                  AppColors.sage.withValues(alpha: 0),
                ],
        ).createShader(Rect.fromCircle(center: centre, radius: radius)),
    );
  }

  /// Each arc twice: a broad band at an alpha you only register as a change
  /// in the ground, then a hairline along the same path so the curve has an
  /// edge to be read by. The band alone is a smudge; the line alone is a
  /// scratch.
  void _paintArcs(Canvas canvas, Size size) {
    final band = dark
        ? AppColors.emerald.withValues(alpha: 0.035)
        : AppColors.forest300.withValues(alpha: 0.18);
    final edge = dark
        ? AppColors.emerald.withValues(alpha: 0.10)
        : AppColors.champagneDeep.withValues(alpha: 0.35);

    for (final (cx, cy, r, start, sweep) in _arcs) {
      final oval = Rect.fromCircle(
        center: Offset(size.width * cx, size.height * cy),
        radius: size.width * r,
      );
      canvas.drawArc(
        oval,
        start,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = size.width * 0.14
          ..color = band,
      );
      canvas.drawArc(
        oval,
        start,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 1.1
          ..color = edge,
      );
    }
  }

  void _paintLeaves(Canvas canvas, Size size) {
    final fill = Paint()
      ..color = dark
          ? AppColors.emerald.withValues(alpha: 0.05)
          : AppColors.forest300.withValues(alpha: 0.22);
    final vein = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = dark
          ? AppColors.emerald.withValues(alpha: 0.09)
          : AppColors.forest600.withValues(alpha: 0.14);

    for (final (fx, fy, flen, angle) in _leaves) {
      final len = size.width * flen;
      canvas.save();
      canvas.translate(size.width * fx, size.height * fy);
      canvas.rotate(angle);
      canvas.drawPath(_leafPath(len), fill);
      canvas.drawLine(Offset(0, -len / 2), Offset(0, len / 2), vein);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_CanvasPainter old) =>
      old.dark != dark || old.lush != lush;
}
