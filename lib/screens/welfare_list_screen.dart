import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/repository.dart';
import '../theme/app_theme.dart';
import '../widgets/app_shell.dart';
import '../widgets/ui_kit.dart';

/// Community Welfare hub — ported from `src/app/welfare/page.tsx`.
/// Header band with running totals + a column of campaign cards, plus CTAs to
/// the Impact report and the New Campaign flow.
class WelfareListScreen extends StatefulWidget {
  const WelfareListScreen({super.key});

  @override
  State<WelfareListScreen> createState() => _WelfareListScreenState();
}

class _WelfareListScreenState extends State<WelfareListScreen> {
  @override
  Widget build(BuildContext context) {
    final campaigns = Repository.instance.welfare();
    final totalRaised =
        campaigns.fold<int>(0, (s, c) => s + (c['raised'] as int));
    final totalBackers =
        campaigns.fold<int>(0, (s, c) => s + (c['backers'] as int));

    return AppShell(
      title: 'Welfare',
      currentRoute: '/welfare',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/welfare/new'),
        backgroundColor: AppColors.gold500,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: Text('Start a Campaign',
            style: body(13, weight: FontWeight.w700, color: Colors.white)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeaderBand(totalRaised: totalRaised, totalBackers: totalBackers),
          const SizedBox(height: 20),
          Text('Active Fundraising Campaigns',
              style: display(20, color: AppColors.forest900)),
          const SizedBox(height: 14),
          for (final c in campaigns) ...[
            _CampaignCard(campaign: c),
            const SizedBox(height: 14),
          ],
          const SizedBox(height: 4),
          _ImpactCta(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _HeaderBand extends StatelessWidget {
  const _HeaderBand({required this.totalRaised, required this.totalBackers});
  final int totalRaised;
  final int totalBackers;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppGradients.deepForest,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppShadows.forestGlow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('COMMUNITY WELFARE & DEVELOPMENT',
              style: body(11,
                  weight: FontWeight.w700,
                  color: AppColors.forest300,
                  letterSpacing: 1.4)),
          const SizedBox(height: 8),
          Text('Build the Samaj tree, one contribution at a time.',
              style: display(20, color: Colors.white, height: 1.25)),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  value: formatLakh(totalRaised),
                  label: 'Total Raised',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatTile(
                  value: formatIndian(totalBackers),
                  label: 'Total Backers',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(value,
              style: display(22, color: Colors.white)),
          const SizedBox(height: 4),
          Text(label,
              style: body(12, color: AppColors.forest300)),
        ],
      ),
    );
  }
}

class _CampaignCard extends StatelessWidget {
  const _CampaignCard({required this.campaign});
  final Map<String, dynamic> campaign;

  @override
  Widget build(BuildContext context) {
    final c = campaign;
    final raised = c['raised'] as int;
    final goal = c['goal'] as int;
    final pct = goal == 0 ? 0 : ((raised / goal) * 100).round();

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gradient header strip with emoji + category pill.
          Container(
            height: 96,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(c['colorA'] as int),
                  Color(c['colorB'] as int),
                ],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Stack(
              children: [
                Center(
                  child: Text(c['image'] as String,
                      style: const TextStyle(fontSize: 46)),
                ),
                Positioned(
                  top: 10,
                  left: 12,
                  child: Pill(
                    c['category'] as String,
                    bg: Colors.white.withValues(alpha: 0.22),
                    fg: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c['title'] as String,
                    style: display(17, color: AppColors.forest900)),
                const SizedBox(height: 6),
                Text(c['description'] as String,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: body(13, color: AppColors.textMuted, height: 1.5)),
                const SizedBox(height: 14),
                ProgressBar(value: goal == 0 ? 0 : raised / goal, height: 8),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('${formatLakh(raised)} raised',
                        style: body(13,
                            weight: FontWeight.w700,
                            color: AppColors.forest800)),
                    const Spacer(),
                    Text('of ${formatLakh(goal)} · $pct%',
                        style: body(12, color: AppColors.textMuted)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.schedule_rounded,
                        size: 14, color: AppColors.hint),
                    const SizedBox(width: 4),
                    Text('${c['daysLeft']} days left',
                        style: body(12, color: AppColors.hint)),
                    const SizedBox(width: 14),
                    const Icon(Icons.favorite_rounded,
                        size: 14, color: AppColors.gold700),
                    const SizedBox(width: 4),
                    Text('${c['backers']} backers',
                        style: body(12, color: AppColors.hint)),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ForestButton(
                    label: 'Donate',
                    icon: Icons.volunteer_activism_rounded,
                    expand: true,
                    onPressed: () =>
                        context.go('/welfare/donate/${c['id']}'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ImpactCta extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppGradients.deepForest,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppShadows.soft,
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.bar_chart_rounded,
              color: AppColors.forest300, size: 26),
          const SizedBox(height: 10),
          Text('Heritage Impact 2024–25',
              style: display(17, color: Colors.white)),
          const SizedBox(height: 6),
          Text('See exactly where every rupee goes — full transparency report.',
              style: body(13, color: AppColors.forest300, height: 1.5)),
          const SizedBox(height: 14),
          GoldButton(
            label: 'View Impact Report',
            icon: Icons.arrow_forward_rounded,
            onPressed: () => context.go('/welfare/impact'),
          ),
        ],
      ),
    );
  }
}
