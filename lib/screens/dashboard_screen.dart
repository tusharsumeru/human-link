import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/demo_data.dart';
import '../data/repository.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_shell.dart';
import '../widgets/pexels_image.dart';
import '../widgets/ui_kit.dart';

/// Dashboard — ported from `src/app/dashboard/page.tsx`.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().user;

    return AppShell(
      title: 'Dashboard',
      currentRoute: '/dashboard',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _WelcomeBanner(
            name: user?.name,
            gotra: user?.gotra,
            native: user?.native,
          ),
          const SizedBox(height: 24),
          // Stats grid — driven by Repository.instance.stats().
          FutureBuilder<Map<String, dynamic>>(
            future: Repository.instance.stats(),
            builder: (context, snapshot) {
              final stats = snapshot.data;
              return _StatsGrid(stats: stats);
            },
          ),
          const SizedBox(height: 24),
          Text('Quick Access', style: display(18, color: AppColors.forest900)),
          const SizedBox(height: 16),
          const _QuickActions(),
          const SizedBox(height: 24),
          const _InvitationPlannerCard(),
          const SizedBox(height: 24),
          _SectionHeaderRow(
            title: 'Active Campaigns',
            actionLabel: 'View All →',
            onAction: () => context.go('/welfare'),
          ),
          const SizedBox(height: 16),
          const _ActiveCampaigns(),
          const SizedBox(height: 24),
          _SectionHeaderRow(
            title: 'Family Activity',
            actionLabel: 'View All',
            onAction: () => context.go('/family-tree'),
          ),
          const SizedBox(height: 16),
          const _ActivityFeed(),
          const SizedBox(height: 24),
          const _FeaturedMatrimonial(),
        ],
      ),
    );
  }
}

class _WelcomeBanner extends StatelessWidget {
  const _WelcomeBanner({this.name, this.gotra, this.native});
  final String? name;
  final String? gotra;
  final String? native;

  @override
  Widget build(BuildContext context) {
    final firstName = (name ?? '').split(' ').first;
    final nativeShort = (native ?? '').split(',').first;

    return Container(
      decoration: BoxDecoration(
        gradient: AppGradients.deepForest,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'WELCOME BACK',
            style: body(
              11,
              weight: FontWeight.w700,
              color: AppColors.forest300,
              letterSpacing: 2.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name != null && name!.isNotEmpty
                ? 'Namaskara, $firstName!'
                : 'Namaskara!',
            style: display(28, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text(
            'Explore your lineage, connect with family, and contribute to '
            'the Samaj community. Your heritage is preserved here.',
            style: body(14, color: AppColors.forest300, height: 1.5),
          ),
          if (name != null && name!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Pill(
                  '✦ Gotra: ${gotra ?? ''}',
                  bg: AppColors.gold500.withValues(alpha: 0.2),
                  fg: AppColors.gold500,
                ),
                Pill(
                  nativeShort.isEmpty ? '—' : nativeShort,
                  icon: Icons.location_on_outlined,
                  bg: AppColors.forest500.withValues(alpha: 0.2),
                  fg: AppColors.forest300,
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              GoldButton(
                label: 'View Tree',
                icon: Icons.park_rounded,
                onPressed: () => context.go('/family-tree'),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => context.go('/welfare'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.favorite_rounded, size: 16),
                label: Text(
                  'Donate',
                  style: body(14, weight: FontWeight.w600, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem {
  const _StatItem(this.icon, this.value, this.label, this.sub, this.color);
  final IconData icon;
  final String value;
  final String label;
  final String sub;
  final Color color;
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({this.stats});
  final Map<String, dynamic>? stats;

  @override
  Widget build(BuildContext context) {
    final loading = stats == null;
    final totalMembers = (stats?['totalMembers'] as num?) ?? 1428;
    final familyMembers = (stats?['familyMembers'] as num?) ?? 0;
    final activeTrees = (stats?['activeTrees'] as num?) ?? 86;
    final pending = (stats?['pendingVerifications'] as num?) ?? 0;
    final matrimonial =
        (stats?['matrimonialProfiles'] as num?) ??
        kMatrimonialCandidates.length;
    final donations = (stats?['totalDonationAmount'] as num?) ?? 0;

    final items = <_StatItem>[
      _StatItem(
        Icons.groups_rounded,
        loading ? '—' : formatIndian(totalMembers),
        'Total Members',
        loading ? 'Loading…' : '$familyMembers family records',
        AppColors.forest800,
      ),
      _StatItem(
        Icons.park_rounded,
        loading ? '—' : '$activeTrees',
        'Active Trees',
        'Lineage connections mapped',
        AppColors.forest700,
      ),
      _StatItem(
        Icons.favorite_rounded,
        loading ? '—' : formatLakh(donations),
        'Welfare Raised',
        '$matrimonial matrimonial profiles',
        AppColors.gold500,
      ),
      _StatItem(
        Icons.shield_rounded,
        loading ? '—' : '$pending',
        'Pending Verifications',
        'Awaiting elder approval',
        AppColors.gold700,
      ),
    ];

    return Column(
      children: [
        for (var i = 0; i < items.length; i += 2)
          Padding(
            padding: EdgeInsets.only(bottom: i + 2 < items.length ? 12 : 0),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _StatCard(item: items[i])),
                  const SizedBox(width: 12),
                  if (i + 1 < items.length)
                    Expanded(child: _StatCard(item: items[i + 1]))
                  else
                    const Expanded(child: SizedBox()),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.item});
  final _StatItem item;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: item.color.withValues(alpha: 0.2)),
                ),
                child: Icon(item.icon, size: 20, color: item.color),
              ),
              const Icon(
                Icons.trending_up_rounded,
                size: 14,
                color: AppColors.forest500,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(item.value, style: display(26, color: AppColors.forest900)),
          const SizedBox(height: 4),
          Text(
            item.label,
            style: body(13, weight: FontWeight.w600, color: AppColors.label),
          ),
          const SizedBox(height: 2),
          Text(item.sub, style: body(11, color: AppColors.hint)),
        ],
      ),
    );
  }
}

class _QuickAction {
  const _QuickAction(this.label, this.icon, this.route, this.desc);
  final String label;
  final IconData icon;
  final String route;
  final String desc;
}

const _quickActions = <_QuickAction>[
  _QuickAction(
    'View Family Tree',
    Icons.park_rounded,
    '/family-tree',
    'Explore your lineage',
  ),
  _QuickAction(
    'Matrimonial Hub',
    Icons.favorite_rounded,
    '/matrimonial',
    '47 active profiles',
  ),
  _QuickAction(
    'Plan Invitations',
    Icons.navigation_rounded,
    '/invitations',
    'Route planner & map',
  ),
  _QuickAction(
    'Welfare Portal',
    Icons.groups_rounded,
    '/welfare',
    '₹42.5L raised',
  ),
  _QuickAction(
    'Member Directory',
    Icons.map_rounded,
    '/directory',
    'Find Samaj members',
  ),
];

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final a in _quickActions)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppCard(
              padding: const EdgeInsets.all(18),
              onTap: () => context.go(a.route),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: AppGradients.forest,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(a.icon, size: 22, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a.label,
                          style: body(
                            14,
                            weight: FontWeight.w600,
                            color: AppColors.forest900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(a.desc, style: body(12, color: AppColors.hint)),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: AppColors.hint,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _InvitationPlannerCard extends StatelessWidget {
  const _InvitationPlannerCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppGradients.deepForest,
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.navigation_rounded,
              size: 22,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Invitation Planner',
                  style: display(15, color: Colors.white),
                ),
                const SizedBox(height: 2),
                Text(
                  'Plan your visit route for the Annual Reunion',
                  style: body(12, color: AppColors.forest300),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GoldButton(
            label: 'Plan',
            icon: Icons.arrow_forward_rounded,
            onPressed: () => context.go('/invitations'),
          ),
        ],
      ),
    );
  }
}

class _ActiveCampaigns extends StatelessWidget {
  const _ActiveCampaigns();

  @override
  Widget build(BuildContext context) {
    final campaigns = kWelfareCampaigns.take(2).toList();
    return Column(
      children: [
        for (final c in campaigns)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _CampaignRow(campaign: c),
          ),
      ],
    );
  }
}

class _CampaignRow extends StatelessWidget {
  const _CampaignRow({required this.campaign});
  final Map<String, dynamic> campaign;

  @override
  Widget build(BuildContext context) {
    final raised = (campaign['raised'] as num).toDouble();
    final goal = (campaign['goal'] as num).toDouble();
    final pct = goal == 0 ? 0.0 : (raised / goal);
    final pctLabel = (pct * 100).round();

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Text(
            campaign['image'] as String,
            style: const TextStyle(fontSize: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  campaign['title'] as String,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: body(
                    13,
                    weight: FontWeight.w600,
                    color: AppColors.forest900,
                  ),
                ),
                const SizedBox(height: 8),
                ProgressBar(
                  value: pct,
                  height: 6,
                  gradient: LinearGradient(
                    colors: [
                      Color(campaign['colorA'] as int),
                      Color(campaign['colorB'] as int),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$pctLabel% · ${campaign['daysLeft']} days left',
                  style: body(11, color: AppColors.hint),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ForestButton(
            label: 'Donate',
            onPressed: () => context.go('/welfare'),
          ),
        ],
      ),
    );
  }
}

const _activityIcons = <String, String>{
  'archive': '📜',
  'tree': '🌳',
  'birthday': '🎂',
};

class _ActivityFeed extends StatelessWidget {
  const _ActivityFeed();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final item in kDashboardActivity)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PexelsImage(
                    url: item['photo'] as String?,
                    name: item['user'] as String,
                    size: 40,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: item['user'] as String,
                                style: body(
                                  13,
                                  weight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                              ),
                              TextSpan(
                                text: ' ${item['action']} ',
                                style: body(13, color: AppColors.textMuted),
                              ),
                              if ((item['detail'] as String?)?.isNotEmpty ??
                                  false)
                                TextSpan(
                                  text: item['detail'] as String,
                                  style: body(
                                    13,
                                    weight: FontWeight.w700,
                                    color: AppColors.forest800,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item['time'] as String,
                          style: body(11, color: AppColors.hint),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _activityIcons[item['type']] ?? '🌳',
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _FeaturedMatrimonial extends StatelessWidget {
  const _FeaturedMatrimonial();

  @override
  Widget build(BuildContext context) {
    final c = kMatrimonialCandidates.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeaderRow(
          title: 'Featured Matrimonial',
          actionLabel: 'See all →',
          onAction: () => context.go('/matrimonial'),
          titleSize: 15,
        ),
        const SizedBox(height: 12),
        AppCard(
          padding: const EdgeInsets.all(16),
          onTap: () => context.go('/matrimonial'),
          child: Row(
            children: [
              PexelsImage(
                url: c['photo'] as String?,
                name: c['name'] as String,
                size: 48,
                borderColor: AppColors.gold500,
                borderWidth: 2,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c['name'] as String,
                      style: body(
                        13,
                        weight: FontWeight.w600,
                        color: AppColors.forest900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${c['age']} yrs · ${c['location']}',
                      style: body(12, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 6),
                    Pill(
                      '✓ Verified',
                      bg: const Color(0xFFD1FAE5),
                      fg: const Color(0xFF065F46),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionHeaderRow extends StatelessWidget {
  const _SectionHeaderRow({
    required this.title,
    required this.actionLabel,
    required this.onAction,
    this.titleSize = 18,
  });
  final String title;
  final String actionLabel;
  final VoidCallback onAction;
  final double titleSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: display(titleSize, color: AppColors.forest900)),
        GestureDetector(
          onTap: onAction,
          child: Text(
            actionLabel,
            style: body(
              12,
              weight: FontWeight.w600,
              color: AppColors.forest800,
            ),
          ),
        ),
      ],
    );
  }
}
