import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/repository.dart';
import '../theme/app_theme.dart';
import '../widgets/app_shell.dart';
import '../widgets/pexels_image.dart';
import '../widgets/ui_kit.dart';

/// Matrimonial Hub list — ported from `src/app/matrimonial/page.tsx`.
/// Elder-mediated, verified profiles with gender/gotra/location filtering.
class MatrimonialListScreen extends StatefulWidget {
  const MatrimonialListScreen({super.key});

  @override
  State<MatrimonialListScreen> createState() => _MatrimonialListScreenState();
}

class _MatrimonialListScreenState extends State<MatrimonialListScreen> {
  static const _gotras = [
    'All',
    'Kashyap',
    'Bharadwaja',
    'Vasishtha',
    'Atreya',
  ];

  String _gender = 'All'; // All / M / F
  String _gotra = 'All';
  String _location = 'All';

  List<Map<String, dynamic>> get _candidates =>
      Repository.instance.matrimonial();

  List<String> get _locations {
    final set = <String>{};
    for (final c in _candidates) {
      final loc = c['location'] as String?;
      if (loc != null && loc.isNotEmpty) set.add(loc);
    }
    return ['All', ...set];
  }

  List<Map<String, dynamic>> get _filtered {
    return _candidates.where((c) {
      final matchGender = _gender == 'All' || c['gender'] == _gender;
      final matchGotra = _gotra == 'All' || c['gotra'] == _gotra;
      final matchLocation = _location == 'All' || c['location'] == _location;
      return matchGender && matchGotra && matchLocation;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return AppShell(
      title: 'Matrimonial',
      currentRoute: '/matrimonial',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _HeroBanner(),
          const SizedBox(height: 18),
          _genderFilter(),
          const SizedBox(height: 12),
          _label('GOTRA'),
          const SizedBox(height: 6),
          _gotraChips(),
          const SizedBox(height: 12),
          _label('LOCATION'),
          const SizedBox(height: 6),
          _locationChips(),
          const SizedBox(height: 16),
          Text.rich(
            TextSpan(children: [
              TextSpan(
                text: '${filtered.length}',
                style: body(13,
                    weight: FontWeight.w700, color: AppColors.forest800),
              ),
              TextSpan(
                text: ' of ${_candidates.length} profiles',
                style: body(13, color: AppColors.textMuted),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          if (filtered.isEmpty)
            _emptyState()
          else
            ...filtered.map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _CandidateCard(candidate: c),
                )),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: body(11,
          weight: FontWeight.w700,
          color: AppColors.gold700,
          letterSpacing: 1.6));

  Widget _genderFilter() {
    const options = [
      ('All', 'All'),
      ('M', 'Grooms'),
      ('F', 'Brides'),
    ];
    return Row(
      children: [
        for (final (value, label) in options) ...[
          Expanded(
            child: _SegmentButton(
              label: label,
              active: _gender == value,
              onTap: () => setState(() => _gender = value),
            ),
          ),
          if (value != 'F') const SizedBox(width: 8),
        ],
      ],
    );
  }

  Widget _gotraChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final g in _gotras)
          _ChipButton(
            label: g,
            active: _gotra == g,
            onTap: () => setState(() => _gotra = g),
          ),
      ],
    );
  }

  Widget _locationChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final l in _locations)
          _ChipButton(
            label: l,
            active: _location == l,
            onTap: () => setState(() => _location = l),
          ),
      ],
    );
  }

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          const Icon(Icons.favorite_border_rounded,
              size: 30, color: AppColors.hint),
          const SizedBox(height: 10),
          Text('No profiles match your filter',
              style:
                  body(15, weight: FontWeight.w600, color: AppColors.hint)),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => setState(() {
              _gender = 'All';
              _gotra = 'All';
              _location = 'All';
            }),
            child: Text('Clear filters',
                style: body(13,
                    weight: FontWeight.w700, color: AppColors.forest800)),
          ),
        ],
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppGradients.deepForest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: AppGradients.gold,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.shield_rounded,
                size: 20, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Elder-Mediated Introductions',
                    style: display(16, color: Colors.white)),
                const SizedBox(height: 6),
                Text(
                  'All introductions in the Daivajna Samaja network are '
                  'facilitated by the Elder sub-committee — ensuring lineage '
                  'authenticity, gotra compatibility, and family alignment. '
                  'Every profile is verified.',
                  style:
                      body(12, color: AppColors.forest300, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CandidateCard extends StatelessWidget {
  const _CandidateCard({required this.candidate});
  final Map<String, dynamic> candidate;

  @override
  Widget build(BuildContext context) {
    final c = candidate;
    final verified = c['verified'] == true;
    final premium = c['matrimonialFee'] == true;
    final gender = c['gender'] == 'F' ? 'Bride' : 'Groom';
    final id = c['id'] as String;

    return AppCard(
      padding: EdgeInsets.zero,
      onTap: () => context.go('/matrimonial/$id'),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Photo header
            SizedBox(
              height: 200,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  PexelsImage(
                    url: c['photo'] as String?,
                    name: c['name'] as String,
                    size: 200,
                    radius: BorderRadius.zero,
                  ),
                  // Gender badge
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Pill(
                      gender,
                      bg: c['gender'] == 'F'
                          ? const Color(0xFFFDE8F6)
                          : const Color(0xFFE8F0FD),
                      fg: c['gender'] == 'F'
                          ? const Color(0xFF9D174D)
                          : const Color(0xFF1E40AF),
                      fontSize: 10,
                    ),
                  ),
                  if (verified)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified,
                                size: 13, color: AppColors.gold500),
                            const SizedBox(width: 4),
                            Text('Verified',
                                style: body(10,
                                    weight: FontWeight.w700,
                                    color: AppColors.forest800)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Body
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text('${c['name']}, ${c['age']}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: display(17, color: AppColors.forest900)),
                      ),
                      const Spacer(),
                      if (premium)
                        const _PremiumChip()
                      else
                        Pill('Free',
                            bg: const Color(0xFFF0FBF4),
                            fg: AppColors.forest700,
                            fontSize: 10),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _detailRow(Icons.height_rounded,
                      '${c['height']} · ${c['location']}'),
                  const SizedBox(height: 4),
                  _detailRow(Icons.school_outlined,
                      (c['education'] as String).split(',').first),
                  const SizedBox(height: 4),
                  _detailRow(Icons.business_center_outlined,
                      (c['company'] as String).split('—').first.trim()),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Pill(c['gotra'] as String,
                          bg: const Color(0xFFF7F0E8),
                          fg: AppColors.gold700,
                          fontSize: 10),
                      const Spacer(),
                      ForestButton(
                        label: 'View Profile',
                        icon: Icons.favorite_rounded,
                        onPressed: () => context.go('/matrimonial/$id'),
                      ),
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

  Widget _detailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.hint),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: body(12, color: AppColors.textMuted)),
        ),
      ],
    );
  }
}

class _PremiumChip extends StatelessWidget {
  const _PremiumChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: AppGradients.gold,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.workspace_premium_rounded,
              size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text('Premium',
              style:
                  body(10, weight: FontWeight.w700, color: Colors.white)),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton(
      {required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AppColors.forest800 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: active ? AppColors.forest800 : AppColors.border),
        ),
        child: Text(label,
            style: body(13,
                weight: FontWeight.w600,
                color: active ? Colors.white : AppColors.label)),
      ),
    );
  }
}

class _ChipButton extends StatelessWidget {
  const _ChipButton(
      {required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? AppColors.forest800 : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
              color: active ? AppColors.forest800 : AppColors.border),
        ),
        child: Text(label,
            style: body(12,
                weight: FontWeight.w600,
                color: active ? Colors.white : AppColors.label)),
      ),
    );
  }
}
