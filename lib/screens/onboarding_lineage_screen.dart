import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/demo_data.dart';
import '../l10n/generated/app_localizations.dart';
import '../theme/app_theme.dart';
import '../widgets/ui_kit.dart';
import 'onboarding_identity_screen.dart';

/// Onboarding step 2 — Lineage.
///
/// Ported from `src/app/onboarding/lineage/page.tsx` — "Find Your Roots":
/// search for an existing ancestor branch, request to connect, or establish a
/// new root node. Continue advances to `/onboarding/heritage`; Back to identity.
class OnboardingLineageScreen extends StatefulWidget {
  const OnboardingLineageScreen({super.key});

  @override
  State<OnboardingLineageScreen> createState() =>
      _OnboardingLineageScreenState();
}

class _Ancestor {
  const _Ancestor(this.id, this.name, this.location, this.nominator);
  final String id;
  final String name;
  final String location;
  final String nominator;
}

class _OnboardingLineageScreenState extends State<OnboardingLineageScreen> {
  final _search = TextEditingController();
  final Set<String> _connected = {};
  bool _newRoot = false;

  // Web's STATIC_ANCESTORS plus a few existing Samaj members as candidates.
  late final List<_Ancestor> _all = [
    const _Ancestor('s1', 'Rameshwar Rao Revankar',
        'Puttur, Kumta · Kashyap Gotra', 'Nominated by 3 Existing Members'),
    const _Ancestor('s2', 'Vinayak Gokarnakar Lineage',
        'Kumta, Karnataka · Bharadwaja Gotra', 'Nominated by 2 Existing Members'),
    ...kCommunityMembers.take(6).map((m) => _Ancestor(
          m['id'] as String,
          m['name'] as String,
          '${m['location']} · ${m['gotra']} Gotra',
          '${m['branch']} Branch · Samaj Member',
        )),
  ];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<_Ancestor> get _filtered {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return _all;
    return _all
        .where((a) =>
            a.name.toLowerCase().contains(q) ||
            a.location.toLowerCase().contains(q) ||
            a.nominator.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final results = _filtered;
    final hasQuery = _search.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: context.onBrightness(
        light: AppColors.cream,
        dark: AppColors.darkBg,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            const OnboardingStepHeader(current: 2),
            const SizedBox(height: 22),
            Text(t.lineageStepLabel,
                style: body(12,
                    weight: FontWeight.w700,
                    color: context.onBrightness(
                      light: AppColors.gold700,
                      dark: AppColors.goldSoft,
                    ),
                    letterSpacing: 1.4)),
            const SizedBox(height: 6),
            Text(
              t.lineageTitle,
              style: display(
                28,
                color: context.onBrightness(
                  light: AppColors.forest900,
                  dark: AppColors.darkText,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              t.lineageSubtitle,
              style: body(
                13,
                height: 1.5,
                color: context.onBrightness(
                  light: AppColors.textMuted,
                  dark: AppColors.darkTextMuted,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Search
            TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: t.lineageSearchHint,
                hintStyle: body(13, color: AppColors.hint),
                prefixIcon:
                    const Icon(Icons.search, size: 18, color: AppColors.hint),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.forest700, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              t.lineageResultsCount(
                  hasQuery
                      ? t.lineageResultsForQuery(_search.text.trim())
                      : t.lineagePotentialConnections,
                  results.length),
              style: body(
                13,
                weight: FontWeight.w600,
                color: context.onBrightness(
                  light: AppColors.forest800,
                  dark: AppColors.forest300,
                ),
              ),
            ),
            const SizedBox(height: 10),

            if (results.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    t.lineageNoMatches(_search.text.trim()),
                    style: body(
                      13,
                      color: context.onBrightness(
                        light: AppColors.textMuted,
                        dark: AppColors.darkTextMuted,
                      ),
                    ),
                  ),
                ),
              )
            else
              for (final a in results) ...[
                _ancestorCard(t, a),
                const SizedBox(height: 10),
              ],

            const SizedBox(height: 4),
            _newRootCard(t),
            const SizedBox(height: 18),

            Row(
              children: [
                OutlineButtonX(
                  label: t.lineageBack,
                  onPressed: () => context.go('/onboarding/identity'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ForestButton(
                    label: t.lineageContinueToHeritage,
                    icon: Icons.arrow_forward,
                    expand: true,
                    onPressed: () => context.go('/onboarding/heritage'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _ancestorCard(AppLocalizations t, _Ancestor a) {
    final requested = _connected.contains(a.id);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: requested ? AppColors.forest300 : AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.forest700,
            child: Text(_initials(a.name),
                style: body(13, weight: FontWeight.w700, color: Colors.white)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.name,
                    style:
                        body(13, weight: FontWeight.w700, color: AppColors.ink)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.place_outlined,
                        size: 11, color: AppColors.textMuted),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(a.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: body(11, color: AppColors.textMuted)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(t.lineageNominatedBy(a.nominator),
                    style: body(11, color: AppColors.forest700)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() {
              requested ? _connected.remove(a.id) : _connected.add(a.id);
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: requested
                    ? AppColors.forest600.withValues(alpha: 0.14)
                    : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: requested
                        ? AppColors.forest600
                        : AppColors.forest800),
              ),
              child: Text(requested ? t.lineageRequested : t.lineageConnect,
                  style: body(11,
                      weight: FontWeight.w700,
                      color: requested
                          ? AppColors.forest700
                          : AppColors.forest800)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _newRootCard(AppLocalizations t) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, style: BorderStyle.solid),
        color: Colors.white,
      ),
      child: _newRoot
          ? Column(
              children: [
                const Icon(Icons.check_circle,
                    size: 22, color: AppColors.forest700),
                const SizedBox(height: 8),
                Text(t.lineageNewRootEstablished,
                    style: body(13,
                        weight: FontWeight.w700, color: AppColors.forest700)),
                const SizedBox(height: 4),
                Text(t.lineageNewRootEstablishedDesc,
                    textAlign: TextAlign.center,
                    style: body(11, color: AppColors.textMuted, height: 1.4)),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () => setState(() => _newRoot = false),
                  child: Text(t.lineageUndo,
                      style: body(11, color: AppColors.textMuted)
                          .copyWith(decoration: TextDecoration.underline)),
                ),
              ],
            )
          : Column(
              children: [
                Text(t.lineageCantFindBranch,
                    style: body(13,
                        weight: FontWeight.w600, color: AppColors.forest800)),
                const SizedBox(height: 4),
                Text(t.lineageStartNewRootDesc,
                    textAlign: TextAlign.center,
                    style: body(11, color: AppColors.textMuted, height: 1.4)),
                const SizedBox(height: 12),
                OutlineButtonX(
                  label: t.lineageEstablishNewRoot,
                  onPressed: () => setState(() => _newRoot = true),
                ),
              ],
            ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}
