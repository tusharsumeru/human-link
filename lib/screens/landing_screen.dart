import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';
import '../widgets/ui_kit.dart';

/// Landing page — ported from web `src/app/page.tsx`.
/// Hero, mini family-tree preview, stats band, 4-pillar grid, trust section,
/// quote card, CTA and footer. Single-column, mobile-first.
class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TopBar(),
              const _Hero(),
              const _Pillars(),
              const _TrustSection(),
              const _Footer(),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Top bar ───────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cream.withValues(alpha: 0.95),
        border: const Border(bottom: BorderSide(color: AppColors.goldSoft)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: const _Logo(),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo({this.onDark = false});
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: onDark ? AppGradients.gold : AppGradients.forest,
            borderRadius: BorderRadius.circular(11),
          ),
          child: const Icon(Icons.park_rounded, size: 18, color: Colors.white),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text('Daivajna Samaja',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: display(17,
                  color: onDark ? Colors.white : AppColors.forest800)),
        ),
      ],
    );
  }
}

// ─── Hero ────────────────────────────────────────────────────────────────────
class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppGradients.hero),
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Eyebrow badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.forest800.withValues(alpha: 0.06),
              border:
                  Border.all(color: AppColors.forest800.withValues(alpha: 0.2)),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                      color: AppColors.forest800, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Text('Daivajna Samaja Bangalore — Est. 2024',
                    style: body(11,
                        weight: FontWeight.w700, color: AppColors.forest800)),
              ],
            ),
          ),
          const SizedBox(height: 22),
          // Headline
          Text(
            'Preserving our Roots,\nNurturing our Future',
            style: display(40,
                color: AppColors.forest900, height: 1.1, weight: FontWeight.w800),
          ),
          const SizedBox(height: 18),
          Text(
            'The official digital sanctuary for the Daivajna Samaja — connecting '
            'generations, preserving heritage, and building community welfare '
            'through a living family tree.',
            style: body(15, color: AppColors.textMuted, height: 1.55),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ForestButton(
                label: 'Begin Your Journey',
                icon: Icons.arrow_forward_rounded,
                onPressed: () => context.go('/register'),
              ),
              OutlineButtonX(
                label: 'Access Portal',
                onPressed: () => context.go('/login'),
              ),
            ],
          ),
          const SizedBox(height: 32),
          // Family-tree preview card
          const _TreePreviewCard(),
        ],
      ),
    );
  }
}

class _TreePreviewCard extends StatelessWidget {
  const _TreePreviewCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppGradients.deepForest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.forestGlow,
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.park_rounded,
                  size: 14, color: AppColors.forest500),
              const SizedBox(width: 8),
              Text('FAMILY LINEAGE PREVIEW',
                  style: body(11,
                      weight: FontWeight.w700,
                      color: AppColors.forest500,
                      letterSpacing: 1.2)),
            ],
          ),
          const SizedBox(height: 20),
          AspectRatio(
            aspectRatio: 280 / 220,
            child: CustomPaint(painter: _TreePainter()),
          ),
          const SizedBox(height: 20),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: const [
              _TreeTag('4 Generations', AppColors.gold500),
              _TreeTag('6 Members', AppColors.forest500),
              _TreeTag('Udupi Branch', AppColors.forest300),
            ],
          ),
        ],
      ),
    );
  }
}

class _TreeTag extends StatelessWidget {
  const _TreeTag(this.label, this.color);
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label,
          style: body(11, weight: FontWeight.w600, color: color)),
    );
  }
}

/// Draws the mini family tree: root RCB → VKB/SKB → RKS/MKS/AJH/SBH.
class _TreePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 280;
    final sy = size.height / 220;
    Offset p(double x, double y) => Offset(x * sx, y * sy);

    void line(Offset a, Offset b, Color c) {
      canvas.drawLine(
        a,
        b,
        Paint()
          ..color = c
          ..strokeWidth = 1.5,
      );
    }

    final root = p(140, 40);
    final vkb = p(80, 100);
    final skb = p(200, 100);
    final g3 = [p(50, 165), p(115, 165), p(175, 165), p(230, 165)];

    line(root, vkb, AppColors.gold500);
    line(root, skb, AppColors.gold500);
    line(vkb, g3[0], AppColors.forest500);
    line(vkb, g3[1], AppColors.forest500);
    line(skb, g3[2], AppColors.forest500);
    line(skb, g3[3], AppColors.forest500);

    void node(Offset c, double r, Color fill, Color? stroke, String label,
        Color textColor, double fontSize) {
      canvas.drawCircle(c, r, Paint()..color = fill);
      if (stroke != null) {
        canvas.drawCircle(
          c,
          r,
          Paint()
            ..color = stroke
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
              color: textColor,
              fontSize: fontSize,
              fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
    }

    node(root, 22 * sx, AppColors.gold700, null, 'RCB', Colors.white, 9);
    node(vkb, 18 * sx, AppColors.forest800, AppColors.forest500, 'VKB',
        Colors.white, 8);
    node(skb, 18 * sx, AppColors.forest800, AppColors.forest500, 'SKB',
        Colors.white, 8);
    const g3Labels = ['RKS', 'MKS', 'AJH', 'SBH'];
    for (var i = 0; i < g3.length; i++) {
      node(g3[i], 15 * sx, AppColors.forest900, AppColors.gold500,
          g3Labels[i], AppColors.gold500, 7);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


// ─── Pillars ─────────────────────────────────────────────────────────────────
class _Pillars extends StatelessWidget {
  const _Pillars();

  static const _pillars = [
    (
      Icons.park_rounded,
      'Family Tree',
      'Document your family lineage across generations. Interactive tree '
          'visualization with photo archives, life stories, and ancestral '
          'connections.',
      '/family-tree',
    ),
    (
      Icons.favorite_rounded,
      'Community Welfare',
      'Transparent crowdfunding for Samaj development. Every rupee accounted '
          'for — community center, scholarships, emergency support.',
      '/welfare',
    ),
    (
      Icons.groups_rounded,
      'Matrimonial Hub',
      'Elder-mediated matrimonial connections that honour lineage and '
          'cultural alignment. Verified profiles with complete family '
          'background.',
      '/matrimonial',
    ),
    (
      Icons.shield_rounded,
      'Elder Governance',
      'Community-driven decisions guided by our respected elders. Resolve '
          'conflicts, verify members, and govern with generational wisdom.',
      '/elder',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 48, 20, 48),
      child: Column(
        children: [
          ..._pillars.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _PillarCard(
                  icon: p.$1,
                  title: p.$2,
                  desc: p.$3,
                  // Public landing page: pillars are gated behind auth, so
                  // send visitors to sign in first (matches the router guard).
                  onTap: () => context.go('/login'),
                ),
              )),
        ],
      ),
    );
  }
}

class _PillarCard extends StatelessWidget {
  const _PillarCard({
    required this.icon,
    required this.title,
    required this.desc,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String desc;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: AppGradients.forest,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 22, color: Colors.white),
          ),
          const SizedBox(height: 14),
          Text(title, style: display(18, color: AppColors.forest800)),
          const SizedBox(height: 6),
          Text(desc,
              style: body(13, color: AppColors.textMuted, height: 1.5)),
          const SizedBox(height: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Explore',
                  style: body(13,
                      weight: FontWeight.w700, color: AppColors.gold700)),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward_rounded,
                  size: 14, color: AppColors.gold700),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Trust section ───────────────────────────────────────────────────────────
class _TrustSection extends StatelessWidget {
  const _TrustSection();

  static const _items = [
    (
      Icons.verified_rounded,
      'Aadhaar Verification',
      'Every member submits a government-issued ID. Aadhaar-matched and '
          'digitally registered.',
    ),
    (
      Icons.groups_rounded,
      'Peer Vouching',
      'New members are vouched by 3 existing verified family members within '
          'the Samaj network.',
    ),
    (
      Icons.shield_rounded,
      'Elder Approval',
      'Elder sub-committee reviews and approves all lineage connections and '
          'matrimonial requests.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppGradients.cream),
      padding: const EdgeInsets.fromLTRB(20, 44, 20, 44),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            eyebrow: 'A circle of absolute trust',
            title: 'Every member, every connection — verified.',
            titleSize: 26,
          ),
          const SizedBox(height: 24),
          ..._items.map((it) => Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: AppGradients.forest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(it.$1, size: 18, color: Colors.white),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(it.$2,
                              style: body(14,
                                  weight: FontWeight.w700,
                                  color: AppColors.forest900)),
                          const SizedBox(height: 3),
                          Text(it.$3,
                              style: body(13,
                                  color: AppColors.textMuted, height: 1.5)),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 8),
          // Quote card
          Container(
            decoration: BoxDecoration(
              gradient: AppGradients.deepForest,
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppShadows.forestGlow,
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🌳', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 16),
                Text(
                  '"A tree is only as strong as its roots. Verification ensures '
                  'the legacy you build is authentic and lasting."',
                  style: display(18,
                      color: AppColors.gold500,
                      height: 1.5,
                      weight: FontWeight.w500),
                ),
                const SizedBox(height: 12),
                Text('— Samaj Heritage Council',
                    style: body(13, color: AppColors.forest500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Footer ──────────────────────────────────────────────────────────────────
class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.forest900, AppColors.forest950],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 36, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const _Logo(onDark: true),
          const SizedBox(height: 8),
          Text('Daivajna Samaja Community Portal',
              style: body(12, color: AppColors.forest500)),
          const SizedBox(height: 20),
          Divider(color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 20),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 10,
            children: const [
              'Privacy Policy',
              'Terms of Service',
              'Heritage Guidelines',
              'Contact Admin',
              'Community Governance',
            ]
                .map((l) => Text(l,
                    style: body(12, color: AppColors.forest500)))
                .toList(),
          ),
          const SizedBox(height: 20),
          Text(
            '© 2024 Daivajna Samaja — Preserving Legacies for Generations.',
            textAlign: TextAlign.center,
            style: body(11, color: AppColors.forest700),
          ),
        ],
      ),
    );
  }
}
