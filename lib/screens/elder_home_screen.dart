import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/demo_data.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_shell.dart';
import '../widgets/pexels_image.dart';
import '../widgets/ui_kit.dart';

/// Elder / admin dashboard — ported from `src/app/elder/page.tsx`.
class ElderHomeScreen extends StatefulWidget {
  const ElderHomeScreen({super.key});

  @override
  State<ElderHomeScreen> createState() => _ElderHomeScreenState();
}

class _ElderHomeScreenState extends State<ElderHomeScreen> {
  static const Color _low = Color(0xFF16A34A);
  static const Color _medium = Color(0xFFD97706);
  static const Color _high = Color(0xFFDC2626);

  Color _riskColor(String level) {
    switch (level) {
      case 'high':
        return _high;
      case 'medium':
        return _medium;
      default:
        return _low;
    }
  }

  String _riskLabel(String level, AppLocalizations t) {
    switch (level) {
      case 'high':
        return t.elderHighRisk;
      case 'medium':
        return t.elderMedRisk;
      default:
        return t.elderLowRisk;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final user = context.watch<AuthService>().user;
    final firstName = (user?.name ?? t.elderDefaultName).split(' ').first;
    final preview = kVerificationRequests.take(3).toList();

    return AppShell(
      title: t.elderLineageTree,
      currentRoute: '/elder',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _welcomeHeader(firstName, t),
          const SizedBox(height: 20),
          _statCards(t),
          const SizedBox(height: 20),
          _pendingPreview(preview, t),
          const SizedBox(height: 20),
          _alertsCard(t),
          const SizedBox(height: 20),
          _quickActions(t),
          const SizedBox(height: 20),
          _lineageOverview(t),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // ── Welcome header ───────────────────────────────────────────────────────
  Widget _welcomeHeader(String firstName, AppLocalizations t) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppGradients.deepForest,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.elderPortalKicker,
              style: body(11,
                  weight: FontWeight.w700,
                  color: AppColors.forest300,
                  letterSpacing: 1.4)),
          const SizedBox(height: 8),
          Text(t.elderWelcomeBack(firstName),
              style: display(26, color: Colors.white)),
          const SizedBox(height: 6),
          Text(t.elderGuardianOfTree,
              style: body(13,
                  weight: FontWeight.w600, color: const Color(0xFFFCD34D))),
          const SizedBox(height: 8),
          Text(
            t.elderDashboardBlurb,
            style: body(13, color: AppColors.forest300, height: 1.5),
          ),
        ],
      ),
    );
  }

  // ── Stat cards ───────────────────────────────────────────────────────────
  Widget _statCards(AppLocalizations t) {
    final stats = [
      (
        '${kVerificationRequests.length}',
        t.elderPendingVerifications,
        Icons.shield_rounded,
        AppColors.gold700
      ),
      (
        '${kConflictCases.length}',
        t.elderActiveConflicts,
        Icons.warning_amber_rounded,
        _high
      ),
      ('1,428', t.elderTotalMembers, Icons.groups_rounded, AppColors.forest700),
      ('86', t.elderActiveBranches, Icons.park_rounded, AppColors.forest600),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.55,
      children: [
        for (final (value, label, icon, color) in stats)
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
                const SizedBox(height: 10),
                Text(value, style: display(22, color: AppColors.forest900)),
                const SizedBox(height: 2),
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: body(11,
                        weight: FontWeight.w600, color: AppColors.textMuted)),
              ],
            ),
          ),
      ],
    );
  }

  // ── Pending member requests preview ──────────────────────────────────────
  Widget _pendingPreview(List<Map<String, dynamic>> preview, AppLocalizations t) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 14, 12),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                      color: _medium, shape: BoxShape.circle),
                  child: Text('!',
                      style: body(13,
                          weight: FontWeight.w700, color: Colors.white)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(t.elderPendingMemberRequests,
                      style: display(16, color: AppColors.forest900)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1ECE2)),
          for (var i = 0; i < preview.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: Color(0xFFF6F1E8)),
            _previewRow(preview[i], t),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 14),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.go('/elder/verifications'),
                child: Text(t.elderReview,
                    style: body(13,
                        weight: FontWeight.w700, color: AppColors.forest700)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _previewRow(Map<String, dynamic> r, AppLocalizations t) {
    final risk = r['riskLevel'] as String;
    final color = _riskColor(risk);
    final required = (r['vouchesRequired'] as int?) ?? 0;
    return InkWell(
      onTap: () => context.push('/elder/verifications/${r['id']}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Row(
          children: [
            PexelsImage(
              url: r['photo'] as String?,
              name: r['name'] as String,
              size: 44,
              radius: BorderRadius.circular(12),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r['name'] as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: body(14,
                          weight: FontWeight.w700,
                          color: AppColors.forest900)),
                  const SizedBox(height: 2),
                  Text(r['claimingFrom'] as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: body(11, color: AppColors.textMuted)),
                  const SizedBox(height: 3),
                  Text(t.elderVouches(r['vouches'] as int, required),
                      style: body(11,
                          weight: FontWeight.w600,
                          color: AppColors.forest700)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Pill(_riskLabel(risk, t),
                bg: color.withValues(alpha: 0.14), fg: color),
          ],
        ),
      ),
    );
  }

  // ── Alerts / conflicts card ──────────────────────────────────────────────
  Widget _alertsCard(AppLocalizations t) {
    return AppCard(
      onTap: () => context.push('/elder/conflict/ck-1'),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _medium.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.warning_amber_rounded,
                color: _medium, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.elderTreeAlertsConflicts,
                    style: display(15, color: AppColors.forest900)),
                const SizedBox(height: 4),
                Text(
                  t.elderAlertSample,
                  style: body(12, color: AppColors.textMuted, height: 1.45),
                ),
                const SizedBox(height: 6),
                Text(t.elderResolveNow,
                    style: body(12,
                        weight: FontWeight.w700, color: AppColors.forest700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Quick actions grid ───────────────────────────────────────────────────
  Widget _quickActions(AppLocalizations t) {
    final actions = [
      (t.elderMemberDirectory, Icons.groups_rounded, '/elder/members'),
      (t.elderDigitalArchive, Icons.inventory_2_rounded, '/elder/archive'),
      (t.elderManageEvents, Icons.calendar_month_rounded, '/elder/events'),
      (t.elderVerifications, Icons.shield_rounded, '/elder/verifications'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: t.elderManagement, titleSize: 20),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.6,
          children: [
            for (final (label, icon, route) in actions)
              AppCard(
                padding: const EdgeInsets.all(14),
                onTap: () => context.go(route),
                child: Row(
                  children: [
                    Icon(icon, size: 18, color: AppColors.forest700),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: body(12,
                              weight: FontWeight.w600,
                              color: AppColors.forest900)),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        size: 16, color: AppColors.hint),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  // ── Small lineage tree overview snippet ──────────────────────────────────
  Widget _lineageOverview(AppLocalizations t) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppGradients.deepForest,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.elderLineageWisdom,
              style: body(11,
                  weight: FontWeight.w700,
                  color: AppColors.forest300,
                  letterSpacing: 1.4)),
          const SizedBox(height: 14),
          // simple lineage tree representation
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _treeNode('Ramachandra', isRoot: true),
            ],
          ),
          const SizedBox(height: 6),
          const Icon(Icons.more_vert_rounded,
              size: 16, color: AppColors.forest500),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _treeNode('Venkatesh'),
              _treeNode('Savitribai'),
            ],
          ),
          const SizedBox(height: 6),
          const Icon(Icons.more_vert_rounded,
              size: 16, color: AppColors.forest500),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _treeNode('Suresh'),
              _treeNode('Rekha'),
              _treeNode('Priya'),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            t.elderLineageQuote,
            style: display(14,
                color: Colors.white, fontStyle: FontStyle.italic, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _treeNode(String name, {bool isRoot = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isRoot
            ? AppColors.gold500.withValues(alpha: 0.25)
            : Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: isRoot
                ? AppColors.gold500.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.12)),
      ),
      child: Text(name,
          style: body(11,
              weight: FontWeight.w600,
              color: isRoot ? AppColors.goldSoft : Colors.white)),
    );
  }
}
