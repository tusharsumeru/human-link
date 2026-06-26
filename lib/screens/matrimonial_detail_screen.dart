import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/repository.dart';
import '../theme/app_theme.dart';
import '../widgets/pexels_image.dart';
import '../widgets/ui_kit.dart';

/// Matrimonial candidate detail — ported from
/// `src/app/matrimonial/[id]/page.tsx` (static candidate view).
class MatrimonialDetailScreen extends StatefulWidget {
  const MatrimonialDetailScreen({super.key, required this.id});

  final String id;

  @override
  State<MatrimonialDetailScreen> createState() =>
      _MatrimonialDetailScreenState();
}

class _MatrimonialDetailScreenState extends State<MatrimonialDetailScreen> {
  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/matrimonial');
    }
  }

  @override
  Widget build(BuildContext context) {
    final candidate = Repository.instance.matrimonialById(widget.id);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.forest800,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: _back,
        ),
        title: Text('Candidate Profile',
            style: display(18, color: Colors.white)),
      ),
      body: candidate == null
          ? _notFound()
          : _CandidateDetail(candidate: candidate),
    );
  }

  Widget _notFound() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off_rounded, size: 36, color: AppColors.hint),
          const SizedBox(height: 12),
          Text('Profile not found',
              style: body(15, weight: FontWeight.w600, color: AppColors.hint)),
          const SizedBox(height: 14),
          ForestButton(
            label: 'Back to Matrimonial Hub',
            onPressed: () => context.go('/matrimonial'),
          ),
        ],
      ),
    );
  }
}

class _CandidateDetail extends StatelessWidget {
  const _CandidateDetail({required this.candidate});
  final Map<String, dynamic> candidate;

  @override
  Widget build(BuildContext context) {
    final c = candidate;
    final premium = c['matrimonialFee'] == true;

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
          children: [
            _PhotoHeader(candidate: c),
            const SizedBox(height: 16),
            _section(
              title: 'Professional',
              icon: Icons.business_center_outlined,
              child: _KeyValueGrid(pairs: [
                ('Education', c['education'] as String),
                ('Company', c['company'] as String),
                ('Designation', c['designation'] as String),
                ('Annual Income', c['income'] as String),
              ]),
            ),
            const SizedBox(height: 14),
            _section(
              title: 'Personal',
              icon: Icons.person_outline_rounded,
              child: _KeyValueGrid(pairs: [
                ('Height', c['height'] as String),
                ('Complexion', c['complexion'] as String),
                ('Family Type', c['familyType'] as String),
              ]),
            ),
            const SizedBox(height: 14),
            _section(
              title: 'Family',
              icon: Icons.groups_outlined,
              child: _KeyValueColumn(pairs: [
                ('Father', c['fatherOccupation'] as String),
                ('Mother', c['motherOccupation'] as String),
                ('Siblings', c['siblings'] as String),
              ]),
            ),
            const SizedBox(height: 14),
            _section(
              title: 'Horoscope',
              icon: Icons.star_outline_rounded,
              iconColor: AppColors.gold700,
              child: _KeyValueGrid(pairs: [
                ('Star / Nakshatra', c['star'] as String),
                ('Rashi', c['rashi'] as String),
                ('Mangal',
                    c['mangal'] == 'Yes' ? 'Mangalik' : 'Non-Mangalik'),
                ('Gotra / Surname', c['gotraSurname'] as String),
                ('Time of Birth', c['timeOfBirth'] as String),
              ]),
            ),
            const SizedBox(height: 14),
            _section(
              title: 'About',
              icon: Icons.notes_rounded,
              child: Text(c['about'] as String,
                  style: body(13, color: AppColors.textMuted, height: 1.6)),
            ),
            const SizedBox(height: 14),
            _section(
              title: 'Partner Expectations',
              icon: Icons.favorite_outline_rounded,
              child: _ExpectationsList(
                items: (c['partnerExpectations'] as List)
                    .map((e) => e as String)
                    .toList(),
              ),
            ),
          ],
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _Footer(candidate: c, premium: premium),
        ),
      ],
    );
  }

  Widget _section({
    required String title,
    required IconData icon,
    required Widget child,
    Color iconColor = AppColors.forest700,
  }) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 17, color: iconColor),
              const SizedBox(width: 8),
              Text(title, style: display(17, color: AppColors.forest900)),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _PhotoHeader extends StatelessWidget {
  const _PhotoHeader({required this.candidate});
  final Map<String, dynamic> candidate;

  @override
  Widget build(BuildContext context) {
    final c = candidate;
    final verified = c['verified'] == true;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 320,
        child: Stack(
          fit: StackFit.expand,
          children: [
            PexelsImage(
              url: c['photo'] as String?,
              name: c['name'] as String,
              size: 320,
              radius: BorderRadius.zero,
            ),
            // Gradient overlay
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppColors.forest900.withValues(alpha: 0.92),
                  ],
                  stops: const [0.45, 1.0],
                ),
              ),
            ),
            if (verified)
              Positioned(
                top: 14,
                left: 14,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified,
                          size: 14, color: AppColors.gold500),
                      const SizedBox(width: 5),
                      Text('Verified',
                          style: body(11,
                              weight: FontWeight.w700,
                              color: AppColors.forest800)),
                    ],
                  ),
                ),
              ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${c['name']}, ${c['age']}',
                      style: display(24, color: Colors.white)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 14, color: AppColors.forest300),
                      const SizedBox(width: 4),
                      Text('${c['location']} · ${c['height']}',
                          style: body(13, color: AppColors.forest300)),
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
}

class _KeyValueGrid extends StatelessWidget {
  const _KeyValueGrid({required this.pairs});
  final List<(String, String)> pairs;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      const spacing = 12.0;
      final colWidth = (constraints.maxWidth - spacing) / 2;
      return Wrap(
        spacing: spacing,
        runSpacing: 12,
        children: [
          for (final (label, value) in pairs)
            SizedBox(
              width: colWidth,
              child: _KeyValue(label: label, value: value),
            ),
        ],
      );
    });
  }
}

class _KeyValueColumn extends StatelessWidget {
  const _KeyValueColumn({required this.pairs});
  final List<(String, String)> pairs;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < pairs.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          _KeyValue(label: pairs[i].$1, value: pairs[i].$2),
        ],
      ],
    );
  }
}

class _KeyValue extends StatelessWidget {
  const _KeyValue({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: body(11,
                weight: FontWeight.w600, color: AppColors.textMuted)),
        const SizedBox(height: 3),
        Text(value,
            style:
                body(13, weight: FontWeight.w600, color: AppColors.forest900)),
      ],
    );
  }
}

class _ExpectationsList extends StatelessWidget {
  const _ExpectationsList({required this.items});
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 2),
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: Color(0xFFD1FAE5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    size: 12, color: Color(0xFF065F46)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(items[i],
                    style:
                        body(13, color: AppColors.textMuted, height: 1.5)),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.candidate, required this.premium});
  final Map<String, dynamic> candidate;
  final bool premium;

  void _expressInterest(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: Color(0xFFD1FAE5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_outline_rounded,
                  size: 20, color: Color(0xFF065F46)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Interest Initiated',
                  style: display(18, color: AppColors.forest900)),
            ),
          ],
        ),
        content: Text(
          'Your interest will be reviewed by the Elder Committee. '
          'They will reach out within 3 working days to facilitate a '
          'formal introduction.',
          style: body(13, color: AppColors.textMuted, height: 1.5),
        ),
        actions: [
          ForestButton(
            label: 'Close',
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  void _premiumNotice(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Premium Profile',
            style: display(18, color: AppColors.forest900)),
        content: Text(
          'This is a premium profile. Connections are arranged exclusively '
          'through the Elder Committee. Please contact a Samaj elder to '
          'proceed with an introduction.',
          style: body(13, color: AppColors.textMuted, height: 1.5),
        ),
        actions: [
          GoldButton(
            label: 'Understood',
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: AppColors.cream,
        border: Border(top: BorderSide(color: Color(0xFFE5DDD0))),
      ),
      child: SafeArea(
        top: false,
        child: premium
            ? GoldButton(
                label: 'Premium — Connect via Elder Committee',
                icon: Icons.workspace_premium_rounded,
                expand: true,
                onPressed: () => _premiumNotice(context),
              )
            : ForestButton(
                label: 'Express Interest',
                icon: Icons.favorite_rounded,
                expand: true,
                onPressed: () => _expressInterest(context),
              ),
      ),
    );
  }
}
