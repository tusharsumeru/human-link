import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/repository.dart';
import '../l10n/generated/app_localizations.dart';
import '../theme/app_theme.dart';
import '../widgets/pexels_image.dart';
import '../widgets/ui_kit.dart';

/// Annual transparency / impact report — ported from
/// `src/app/welfare/impact/page.tsx`.
class WelfareImpactScreen extends StatelessWidget {
  const WelfareImpactScreen({super.key});

  static List<_Alloc> _allocationOf(AppLocalizations t) => [
        _Alloc(t.welfareAllocTempleHeritage, 40, AppColors.forest800),
        _Alloc(t.welfareAllocEducation, 30, AppColors.forest700),
        _Alloc(t.welfareAllocHealthWelfare, 15, AppColors.gold700),
        _Alloc(t.welfareAllocCulturalEvents, 15, AppColors.gold500),
      ];

  static List<_Donor> _donorsOf(AppLocalizations t) => [
        _Donor('Shri Narayanarao Shet', '₹90,000', t.welfareDonorHeadRole, 17815020),
        _Donor('Dr. Suma Rao', '₹51,000', t.welfareDonorPatronRole, 11138457),
        _Donor('Vivek Kamath', '₹40,000', t.welfareDonorItRole, 2601464),
        _Donor('Rajesh Pai', '₹35,000', t.welfareDonorEntrepreneurRole, 5746790),
      ];

  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/welfare');
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final campaigns = Repository.instance.welfare();
    final totalRaised =
        campaigns.fold<int>(0, (s, c) => s + (c['raised'] as int));

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.forest800,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => _back(context),
        ),
        title: Text(t.welfareImpactReport, style: display(18, color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Text(t.welfareAnnualReportKicker,
              style: body(11,
                  weight: FontWeight.w700,
                  color: AppColors.gold700,
                  letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Text(t.welfareImpactTitle,
              style: display(26, color: AppColors.forest900)),
          const SizedBox(height: 6),
          Text(
              t.welfareRecordOfContributions,
              style: body(13, color: AppColors.textMuted, height: 1.5)),
          const SizedBox(height: 18),

          // Top stat cards.
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.trending_up_rounded,
                  value: formatLakh(totalRaised),
                  label: t.welfareTotalRaised,
                  color: AppColors.forest800,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.people_alt_rounded,
                  value: '1,240',
                  label: t.welfareFamiliesHelped,
                  color: AppColors.forest700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.campaign_rounded,
                  value: '${campaigns.length}',
                  label: t.welfareCampaignsFunded,
                  color: AppColors.gold700,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.school_rounded,
                  value: '30',
                  label: t.welfareScholarships,
                  color: AppColors.gold500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Category breakdown pie (from kWelfareCampaigns raised amounts).
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.welfareCategoryBreakdown,
                    style: display(17, color: AppColors.forest900)),
                const SizedBox(height: 4),
                Text(t.welfareCategoryBreakdownSubtitle,
                    style: body(12, color: AppColors.textMuted)),
                const SizedBox(height: 16),
                _CategoryPie(campaigns: campaigns, total: totalRaised),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Fund allocation.
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.welfareFundAllocation,
                    style: display(17, color: AppColors.forest900)),
                const SizedBox(height: 14),
                for (final a in _allocationOf(t)) ...[
                  _AllocRow(alloc: a),
                  const SizedBox(height: 12),
                ],
                const Divider(color: AppColors.border, height: 1),
                const SizedBox(height: 12),
                Text(
                    t.welfareAuditQuote,
                    style: body(12,
                        color: AppColors.hint,
                        height: 1.5,
                        weight: FontWeight.w500)),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Testimonials / guardian donors.
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.favorite_rounded,
                        size: 16, color: AppColors.gold700),
                    const SizedBox(width: 8),
                    Text(t.welfareGuardianDonors,
                        style: display(17, color: AppColors.forest900)),
                  ],
                ),
                const SizedBox(height: 14),
                for (var i = 0, donors = _donorsOf(t); i < donors.length; i++) ...[
                  _DonorRow(donor: donors[i]),
                  if (i != donors.length - 1) ...[
                    const SizedBox(height: 12),
                    const Divider(color: AppColors.border, height: 1),
                    const SizedBox(height: 12),
                  ],
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Testimonial cards.
          _Testimonial(
            photoId: 7485047,
            quote: t.welfareTestimonial1,
            author: t.welfareTestimonial1Author,
          ),
          const SizedBox(height: 12),
          _Testimonial(
            photoId: 17184880,
            quote: t.welfareTestimonial2,
            author: t.welfareTestimonial2Author,
          ),
          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,
            child: ForestButton(
              label: t.welfareSupportCampaign,
              icon: Icons.arrow_forward_rounded,
              expand: true,
              onPressed: () => context.go('/welfare'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Alloc {
  const _Alloc(this.label, this.pct, this.color);
  final String label;
  final int pct;
  final Color color;
}

class _Donor {
  const _Donor(this.name, this.amount, this.role, this.photoId);
  final String name;
  final String amount;
  final String role;
  final int photoId;
}

// Empty URL → initials fallback instead of a dummy stock photo.
String _px(int id) => '';

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 19, color: color),
          ),
          const SizedBox(height: 12),
          Text(value, style: display(24, color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: body(12,
                  weight: FontWeight.w600, color: AppColors.label)),
        ],
      ),
    );
  }
}

class _CategoryPie extends StatelessWidget {
  const _CategoryPie({required this.campaigns, required this.total});
  final List<Map<String, dynamic>> campaigns;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 130,
          height: 130,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 34,
              sections: [
                for (final c in campaigns)
                  PieChartSectionData(
                    value: (c['raised'] as int).toDouble(),
                    color: Color(c['colorB'] as int),
                    radius: 28,
                    title: total == 0
                        ? ''
                        : '${((c['raised'] as int) / total * 100).round()}%',
                    titleStyle: body(11,
                        weight: FontWeight.w700, color: Colors.white),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final c in campaigns) ...[
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Color(c['colorB'] as int),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(c['category'] as String,
                          style: body(12, color: AppColors.textMuted)),
                    ),
                    Text(formatLakh(c['raised'] as int),
                        style: body(12,
                            weight: FontWeight.w700,
                            color: AppColors.forest900)),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _AllocRow extends StatelessWidget {
  const _AllocRow({required this.alloc});
  final _Alloc alloc;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: alloc.color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(alloc.label,
                  style: body(13,
                      weight: FontWeight.w600, color: AppColors.label)),
            ),
            Text('${alloc.pct}%',
                style: body(13,
                    weight: FontWeight.w700, color: AppColors.forest900)),
          ],
        ),
        const SizedBox(height: 6),
        ProgressBar(
          value: alloc.pct / 100,
          height: 7,
          gradient: LinearGradient(
            colors: [alloc.color, alloc.color.withValues(alpha: 0.7)],
          ),
        ),
      ],
    );
  }
}

class _DonorRow extends StatelessWidget {
  const _DonorRow({required this.donor});
  final _Donor donor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        PexelsImage(
          url: _px(donor.photoId),
          name: donor.name,
          size: 44,
          borderColor: AppColors.gold500,
          borderWidth: 2,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(donor.name,
                  style: body(13,
                      weight: FontWeight.w700, color: AppColors.forest900)),
              Text(donor.role, style: body(12, color: AppColors.hint)),
            ],
          ),
        ),
        Text(donor.amount,
            style: body(13,
                weight: FontWeight.w700, color: AppColors.forest800)),
      ],
    );
  }
}

class _Testimonial extends StatelessWidget {
  const _Testimonial({
    required this.photoId,
    required this.quote,
    required this.author,
  });
  final int photoId;
  final String quote;
  final String author;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F0E8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PexelsImage(
            url: _px(photoId),
            name: author,
            size: 48,
            borderColor: AppColors.gold500,
            borderWidth: 2,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(quote,
                    style: body(13,
                        color: AppColors.label,
                        height: 1.5,
                        weight: FontWeight.w500)),
                const SizedBox(height: 6),
                Text('- $author',
                    style: body(12,
                        color: AppColors.gold700, weight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
