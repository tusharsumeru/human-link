import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/repository.dart';
import '../l10n/generated/app_localizations.dart';
import '../theme/app_theme.dart';
import '../widgets/app_shell.dart';
import '../widgets/pexels_image.dart';
import '../widgets/ui_kit.dart';

/// Elder verification queue — ported from `src/app/elder/verifications/page.tsx`.
class ElderVerificationsScreen extends StatefulWidget {
  const ElderVerificationsScreen({super.key});

  @override
  State<ElderVerificationsScreen> createState() =>
      _ElderVerificationsScreenState();
}

class _ElderVerificationsScreenState extends State<ElderVerificationsScreen> {
  static const Color _low = Color(0xFF16A34A);
  static const Color _medium = Color(0xFFD97706);
  static const Color _high = Color(0xFFDC2626);

  String _riskFilter = 'All';
  String _aadhaarFilter = 'All';

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

  Color _aadhaarColor(String status) {
    switch (status) {
      case 'Verified':
        return _low;
      case 'Mismatch':
        return _high;
      default:
        return _medium;
    }
  }

  @override
  Widget build(BuildContext context) {
    final all = Repository.instance.verifications();
    final filtered = all.where((r) {
      final matchRisk =
          _riskFilter == 'All' || r['riskLevel'] == _riskFilter;
      final matchAadhaar =
          _aadhaarFilter == 'All' || r['aadhaarStatus'] == _aadhaarFilter;
      return matchRisk && matchAadhaar;
    }).toList();

    final t = AppLocalizations.of(context);
    return AppShell(
      title: t.elderMemberRequests,
      currentRoute: '/elder/verifications',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _filterSection(t),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              t.elderPendingClaims(filtered.length),
              style: display(18, color: AppColors.forest900),
            ),
          ),
          const SizedBox(height: 12),
          if (filtered.isEmpty)
            _empty(t)
          else
            for (final r in filtered) ...[
              _requestCard(r, t),
              const SizedBox(height: 12),
            ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _filterSection(AppLocalizations t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t.elderRiskLevel,
            style: body(11,
                weight: FontWeight.w700,
                color: AppColors.gold700,
                letterSpacing: 1.2)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final r in const ['All', 'low', 'medium', 'high'])
              _chip(
                r == 'All' ? t.elderAll : _riskLabel(r, t),
                selected: _riskFilter == r,
                onTap: () => setState(() => _riskFilter = r),
              ),
          ],
        ),
        const SizedBox(height: 14),
        Text(t.elderAadhaarStatus,
            style: body(11,
                weight: FontWeight.w700,
                color: AppColors.gold700,
                letterSpacing: 1.2)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final s in const ['All', 'Verified', 'Pending', 'Mismatch'])
              _chip(
                s,
                selected: _aadhaarFilter == s,
                onTap: () => setState(() => _aadhaarFilter = s),
              ),
          ],
        ),
      ],
    );
  }

  Widget _chip(String label,
      {required bool selected, required VoidCallback onTap}) {
    return Material(
      color: selected ? AppColors.forest800 : Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
                color: selected ? AppColors.forest800 : AppColors.border),
          ),
          child: Text(label,
              style: body(12,
                  weight: FontWeight.w600,
                  color: selected ? Colors.white : AppColors.label)),
        ),
      ),
    );
  }

  Widget _requestCard(Map<String, dynamic> r, AppLocalizations t) {
    final risk = r['riskLevel'] as String;
    final riskColor = _riskColor(risk);
    final aadhaar = r['aadhaarStatus'] as String;
    final aadhaarColor = _aadhaarColor(aadhaar);
    final vouches = (r['vouches'] as int?) ?? 0;
    final required = (r['vouchesRequired'] as int?) ?? 1;
    final genderLabel = r['gender'] == 'M' ? t.elderMale : t.elderFemale;

    return AppCard(
      onTap: () => context.push('/elder/verifications/${r['id']}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PexelsImage(
                url: r['photo'] as String?,
                name: r['name'] as String,
                size: 56,
                radius: BorderRadius.circular(16),
                borderColor: AppColors.border,
                borderWidth: 2,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(r['name'] as String,
                              style: display(16, color: AppColors.forest900)),
                        ),
                        Pill(_riskLabel(risk, t),
                            bg: riskColor.withValues(alpha: 0.14),
                            fg: riskColor),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(t.elderAgeGenderGotra(
                        '${r['age']}', genderLabel, r['gotra'] as String),
                        style: body(12, color: AppColors.textMuted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _kv(t.elderLineageNode, r['claimingFrom'] as String),
          const SizedBox(height: 6),
          _kv(t.elderRelation, r['relation'] as String),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(t.elderVouchesLabel,
                  style: body(11,
                      weight: FontWeight.w600, color: AppColors.textMuted)),
              const Spacer(),
              Text(t.elderVouchesOfRequired(vouches, required),
                  style: body(11,
                      weight: FontWeight.w700, color: AppColors.forest700)),
            ],
          ),
          const SizedBox(height: 6),
          ProgressBar(value: required == 0 ? 0 : vouches / required),
          const SizedBox(height: 12),
          Row(
            children: [
              Pill(t.elderAadhaarPrefix(aadhaar),
                  bg: aadhaarColor.withValues(alpha: 0.14), fg: aadhaarColor),
              const Spacer(),
              Text(t.elderSubmittedOn('${r['submittedOn']}'),
                  style: body(11, color: AppColors.hint)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _kv(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: body(10, weight: FontWeight.w600, color: AppColors.hint)),
        const SizedBox(height: 2),
        Text(value,
            style: body(12, weight: FontWeight.w600, color: AppColors.label)),
      ],
    );
  }

  Widget _empty(AppLocalizations t) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          const Icon(Icons.schedule_rounded, size: 36, color: AppColors.hint),
          const SizedBox(height: 12),
          Text(t.elderNoRequestsMatchFilter,
              style: body(14, weight: FontWeight.w600, color: AppColors.hint)),
        ],
      ),
    );
  }
}
