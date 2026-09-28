import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/api_client.dart';
import '../data/models/welfare_campaign.dart';
import '../data/repository.dart';
import '../l10n/generated/app_localizations.dart';
import '../theme/app_theme.dart';
import '../widgets/app_shell.dart';
import '../widgets/ui_kit.dart';

/// Community Welfare hub — ported from `src/app/welfare/page.tsx`.
///
/// Campaigns come live from `GET /api/welfare/campaigns`; they are created by
/// the admin in the web admin panel, never here. Header band with running
/// totals + a column of campaign cards, plus a CTA to the Impact report.
class WelfareListScreen extends StatefulWidget {
  const WelfareListScreen({super.key});

  @override
  State<WelfareListScreen> createState() => _WelfareListScreenState();
}

class _WelfareListScreenState extends State<WelfareListScreen> {
  late Future<List<WelfareCampaign>> _future;

  @override
  void initState() {
    super.initState();
    _future = Repository.instance.fetchCampaigns();
  }

  Future<void> _reload() async {
    setState(() => _future = Repository.instance.fetchCampaigns());
    await _future.catchError((_) => <WelfareCampaign>[]);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return AppShell(
      title: t.welfareTitle,
      currentRoute: '/welfare',
      // No "Start campaign" button: campaigns are opened by the admin from the
      // web admin panel only, and the server rejects creation from members.
      child: FutureBuilder<List<WelfareCampaign>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 80),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (snap.hasError) {
            return _ErrorState(
              message: snap.error is ApiException
                  ? (snap.error as ApiException).message
                  : t.welfareLoadFailed,
              onRetry: _reload,
            );
          }
          final all = snap.data ?? const <WelfareCampaign>[];
          final active = all.where((c) => c.isActive).toList();
          final totalRaised = all.fold<int>(0, (s, c) => s + c.raised);
          final totalBackers = all.fold<int>(0, (s, c) => s + c.backers);

          return RefreshIndicator(
            onRefresh: _reload,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeaderBand(
                  totalRaised: totalRaised,
                  totalBackers: totalBackers,
                ),
                const SizedBox(height: 20),
                Text(
                  t.welfareActiveCampaigns,
                  style: display(
                    20,
                    color: context.onBrightness(
                      light: AppColors.forest900,
                      dark: AppColors.darkText,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                if (active.isEmpty)
                  _EmptyState(message: t.welfareNoCampaigns)
                else
                  for (final c in active) ...[
                    _CampaignCard(campaign: c),
                    const SizedBox(height: 14),
                  ],
                const SizedBox(height: 4),
                _ImpactCta(),
                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Icon(
            Icons.cloud_off_rounded,
            size: 36,
            color: context.onBrightness(
              light: AppColors.hint,
              dark: AppColors.darkTextMuted,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: body(
              14,
              color: context.onBrightness(
                light: AppColors.textMuted,
                dark: AppColors.darkTextMuted,
              ),
            ),
          ),
          const SizedBox(height: 14),
          ForestButton(label: t.welfareRetry, onPressed: () => onRetry()),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Icon(
              Icons.volunteer_activism_outlined,
              size: 32,
              color: context.onBrightness(
                light: AppColors.hint,
                dark: AppColors.darkTextMuted,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: body(
                14,
                color: context.onBrightness(
                  light: AppColors.textMuted,
                  dark: AppColors.darkTextMuted,
                ),
              ),
            ),
          ],
        ),
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
    final t = AppLocalizations.of(context);
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
          Text(
            t.welfareKicker,
            style: body(
              11,
              weight: FontWeight.w700,
              color: AppColors.forest300,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            t.welfareHeroLine,
            style: display(20, color: Colors.white, height: 1.25),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  value: formatLakh(totalRaised),
                  label: t.welfareTotalRaised,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatTile(
                  value: formatIndian(totalBackers),
                  label: t.welfareTotalBackers,
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
          Text(value, style: display(22, color: Colors.white)),
          const SizedBox(height: 4),
          Text(label, style: body(12, color: AppColors.forest300)),
        ],
      ),
    );
  }
}

/// Cover strip shared by the list card and the donate screen: the admin's
/// gradient, with either an emoji or a picture on top.
class CampaignCover extends StatelessWidget {
  const CampaignCover({
    super.key,
    required this.campaign,
    required this.height,
    this.emojiSize = 46,
    this.child,
  });
  final WelfareCampaign campaign;
  final double height;
  final double emojiSize;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(gradient: campaign.gradient),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (campaign.imageIsUrl)
              Image.network(
                campaign.image,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              )
            else
              Center(
                child: Text(
                  campaign.image.isEmpty ? '🏛️' : campaign.image,
                  style: TextStyle(fontSize: emojiSize),
                ),
              ),
            if (child != null) child!,
          ],
        ),
      ),
    );
  }
}

class _CampaignCard extends StatelessWidget {
  const _CampaignCard({required this.campaign});
  final WelfareCampaign campaign;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = campaign;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CampaignCover(
            campaign: c,
            height: 96,
            child: Positioned(
              top: 10,
              left: 12,
              child: Pill(
                c.categoryLabel,
                bg: Colors.white.withValues(alpha: 0.22),
                fg: Colors.white,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.title,
                  style: display(
                    17,
                    color: context.onBrightness(
                      light: AppColors.forest900,
                      dark: AppColors.darkText,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  c.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: body(
                    13,
                    color: context.onBrightness(
                      light: AppColors.textMuted,
                      dark: AppColors.darkTextMuted,
                    ),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 14),
                ProgressBar(value: c.progress, height: 8),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      t.welfareRaised(formatLakh(c.raised)),
                      style: body(
                        13,
                        weight: FontWeight.w700,
                        color: context.onBrightness(
                          light: AppColors.forest800,
                          dark: AppColors.forest300,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      t.welfareOfGoalPct(formatLakh(c.goal), c.percent),
                      style: body(
                        12,
                        color: context.onBrightness(
                          light: AppColors.textMuted,
                          dark: AppColors.darkTextMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 14,
                      color: context.onBrightness(
                        light: AppColors.hint,
                        dark: AppColors.darkTextMuted,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      c.daysLeft == null
                          ? t.welfareOpenEnded
                          : t.welfareDaysLeft(c.daysLeft!),
                      style: body(
                        12,
                        color: context.onBrightness(
                          light: AppColors.hint,
                          dark: AppColors.darkTextMuted,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Icon(
                      Icons.favorite_rounded,
                      size: 14,
                      color: context.onBrightness(
                        light: AppColors.gold700,
                        dark: AppColors.goldSoft,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      t.welfareBackers(c.backers),
                      style: body(
                        12,
                        color: context.onBrightness(
                          light: AppColors.hint,
                          dark: AppColors.darkTextMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ForestButton(
                    label: t.welfareDonate,
                    icon: Icons.volunteer_activism_rounded,
                    expand: true,
                    onPressed: () => context.push('/welfare/donate/${c.id}'),
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
    final t = AppLocalizations.of(context);
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
          const Icon(
            Icons.bar_chart_rounded,
            color: AppColors.forest300,
            size: 26,
          ),
          const SizedBox(height: 10),
          Text(t.welfareImpactTitle, style: display(17, color: Colors.white)),
          const SizedBox(height: 6),
          Text(
            t.welfareImpactBody,
            style: body(13, color: AppColors.forest300, height: 1.5),
          ),
          const SizedBox(height: 14),
          GoldButton(
            label: t.welfareViewImpactReport,
            icon: Icons.arrow_forward_rounded,
            onPressed: () => context.push('/welfare/impact'),
          ),
        ],
      ),
    );
  }
}
