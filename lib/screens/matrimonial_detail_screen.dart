import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/repository.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/discovery_match_badge.dart';
import '../widgets/pexels_image.dart';
import '../widgets/ui_kit.dart';
import 'compatibility_check_screen.dart';

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
  // GET /api/matrimonial/:id. The endpoint applies the same gates as the
  // listing — approved-only and age-eligible — so a direct link can't reach a
  // draft, a withdrawn profile, or someone who has aged out.
  Map<String, dynamic>? _candidate;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final c = await Repository.instance.matrimonialProfile(widget.id);
      if (!mounted) return;
      setState(() {
        _candidate = c;
        _loading = false;
      });
    } catch (_) {
      // A 403/404 both mean "you can't see this" — the not-found view says so
      // without leaking whether the profile exists.
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/matrimonial');
    }
  }

  @override
  Widget build(BuildContext context) {
    final candidate = _candidate;

    return Scaffold(
      backgroundColor: context.onBrightness(
        light: AppColors.cream,
        dark: AppColors.darkBg,
      ),
      appBar: AppBar(
        backgroundColor: AppColors.forest800,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: _back,
        ),
        title: Text(
          AppLocalizations.of(context).matCandidateProfile,
          style: display(18, color: Colors.white),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : candidate == null
          ? _notFound()
          : _CandidateDetail(candidate: candidate),
    );
  }

  Widget _notFound() {
    final t = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 36,
            color: context.onBrightness(
              light: AppColors.hint,
              dark: AppColors.darkTextMuted,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            t.matProfileNotFound,
            style: body(
              15,
              weight: FontWeight.w600,
              color: context.onBrightness(
                light: AppColors.hint,
                dark: AppColors.darkTextMuted,
              ),
            ),
          ),
          const SizedBox(height: 14),
          ForestButton(
            label: t.matBackToHub,
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
    final t = AppLocalizations.of(context);
    final c = candidate;
    final premium = c['matrimonialFee'] == true;

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
          children: [
            _PhotoHeader(candidate: c),
            const SizedBox(height: 16),
            // Placed first: whether this profile fits what you're looking for
            // is the thing you want to know before reading the rest. Same
            // discoveryMatch percentage/level as the Hub card and Discover
            // Matches — never the older, separately-computed match.score.
            if (c['discoveryMatch'] != null &&
                (c['discoveryMatch'] as Map)['matchPercentage'] != null) ...[
              _section(
                context,
                title: t.matMatchSummary,
                icon: Icons.favorite_rounded,
                child: DiscoveryMatchDetail(
                  discoveryMatch: c['discoveryMatch'] as Map<String, dynamic>?,
                ),
              ),
              const SizedBox(height: 14),
            ],
            _section(
                context,
              title: t.matProfessional,
              icon: Icons.business_center_outlined,
              child: _KeyValueGrid(
                pairs: [
                  (t.matEducation, c['education'] as String),
                  (t.matCompany, c['company'] as String),
                  (t.matDesignation, c['designation'] as String),
                  (t.matAnnualIncome, c['income'] as String),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _section(
                context,
              title: t.matPersonal,
              icon: Icons.person_outline_rounded,
              child: _KeyValueGrid(
                pairs: [
                  (t.matHeight, c['height'] as String),
                  (t.matComplexion, c['complexion'] as String),
                  (t.matFamilyType, c['familyType'] as String),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _section(
                context,
              title: t.matFamily,
              icon: Icons.groups_outlined,
              child: _KeyValueColumn(
                pairs: [
                  (t.matFather, c['fatherOccupation'] as String),
                  (t.matMother, c['motherOccupation'] as String),
                  (t.matSiblings, c['siblings'] as String),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _section(
                context,
              title: t.matHoroscope,
              icon: Icons.star_outline_rounded,
              iconColor: AppColors.gold700,
              child: _KeyValueGrid(
                pairs: [
                  (t.matStarNakshatra, c['star'] as String),
                  (t.matRashi, c['rashi'] as String),
                  (
                    t.matMangal,
                    // The API sends a real boolean; null means "not answered".
                    c['mangal'] == true ? t.matMangalik : t.matNonMangalik,
                  ),
                  (t.matGotraSurname, c['gotraSurname'] as String),
                  (t.matTimeOfBirth, c['timeOfBirth'] as String),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _section(
                context,
              title: t.matAbout,
              icon: Icons.notes_rounded,
              child: Text(
                c['about'] as String,
                style: body(13, color: context.onBrightness(light: AppColors.textMuted, dark: AppColors.darkTextMuted), height: 1.6),
              ),
            ),
            if ((c['interests'] as List?)?.isNotEmpty ?? false) ...[
              const SizedBox(height: 14),
              _section(
                context,
                title: t.matInterests,
                icon: Icons.interests_rounded,
                iconColor: AppColors.gold700,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final i in (c['interests'] as List))
                      Pill(
                        _titleCase(i.toString()),
                        bg: const Color(0xFFF7F0E8),
                        fg: AppColors.gold700,
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            _section(
                context,
              title: t.matPartnerExpectations,
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

  static String _titleCase(String wire) {
    if (wire.isEmpty) return wire;
    final lower = wire.toLowerCase().replaceAll('_', ' ');
    return lower[0].toUpperCase() + lower.substring(1);
  }

  Widget _section(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
    Color? iconColor,
  }) {
    // Only ever called with the default (forest700) or AppColors.gold700 —
    // map each to its dark-mode-legible counterpart.
    final resolvedIconColor = iconColor == AppColors.gold700
        ? context.onBrightness(light: AppColors.gold700, dark: AppColors.goldSoft)
        : context.onBrightness(light: iconColor ?? AppColors.forest700, dark: AppColors.forest300);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 17, color: resolvedIconColor),
              const SizedBox(width: 8),
              Text(title, style: display(17, color: context.onBrightness(light: AppColors.forest900, dark: AppColors.darkText))),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.verified,
                        size: 14,
                        color: AppColors.gold500,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        AppLocalizations.of(context).matVerified,
                        style: body(
                          11,
                          weight: FontWeight.w700,
                          color: AppColors.forest800,
                        ),
                      ),
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
                  Text(
                    '${c['name']}, ${c['age']}',
                    style: display(24, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: AppColors.forest300,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${c['location']} · ${c['height']}',
                        style: body(13, color: AppColors.forest300),
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
}

class _KeyValueGrid extends StatelessWidget {
  const _KeyValueGrid({required this.pairs});
  final List<(String, String)> pairs;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
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
      },
    );
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
        Text(
          label,
          style: body(11, weight: FontWeight.w600, color: context.onBrightness(light: AppColors.textMuted, dark: AppColors.darkTextMuted)),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: body(13, weight: FontWeight.w600, color: context.onBrightness(light: AppColors.forest900, dark: AppColors.darkText)),
        ),
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
                child: const Icon(
                  Icons.check_rounded,
                  size: 12,
                  color: Color(0xFF065F46),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  items[i],
                  style: body(13, color: context.onBrightness(light: AppColors.textMuted, dark: AppColors.darkTextMuted), height: 1.5),
                ),
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

  void _premiumNotice(BuildContext context) {
    final t = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.onBrightness(light: Colors.white, dark: AppColors.darkSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          t.matPremiumProfileTitle,
          style: display(18, color: context.onBrightness(light: AppColors.forest900, dark: AppColors.darkText)),
        ),
        content: Text(
          t.matPremiumProfileBody,
          style: body(13, color: context.onBrightness(light: AppColors.textMuted, dark: AppColors.darkTextMuted), height: 1.5),
        ),
        actions: [
          GoldButton(
            label: t.matUnderstood,
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  // STEP 25B: opens the readiness/preparation screen first — it is what
  // pushes CompatibilityScreen (and only then, on a further tap inside it,
  // an actual calculation) once the member confirms Continue there.
  void _checkCompatibility(BuildContext context, String myProfileId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CompatibilityCheckScreen(
          myProfileId: myProfileId,
          // candidate['id'] is the matrimonial *profile's* own id (what
          // /api/matrimonial/:id routes on) — compatibility, like every other
          // endpoint, is keyed on the account id, which is candidate['userId'].
          candidateProfileId: (candidate['userId'] ?? '').toString(),
          candidateName: (candidate['name'] ?? '').toString(),
          candidateGender: (candidate['gender'] ?? '').toString(),
          discoveryMatch: candidate['discoveryMatch'] as Map<String, dynamic>?,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Only offer this when viewing someone else's profile — a member can't
    // run a compatibility check against their own.
    final myId = context.watch<AuthService>().user?.id ?? '';
    final candidateUserId = (candidate['userId'] ?? '').toString();
    final showCompatibility = myId.isNotEmpty && myId != candidateUserId;

    // Nothing left to offer (a non-premium profile with compatibility not
    // applicable, e.g. your own) — skip the bar rather than showing an empty
    // padded strip.
    if (!premium && !showCompatibility) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: AppColors.cream,
        border: Border(top: BorderSide(color: Color(0xFFE5DDD0))),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (premium)
              GoldButton(
                label: AppLocalizations.of(context).matPremiumConnectViaElder,
                icon: Icons.workspace_premium_rounded,
                expand: true,
                onPressed: () => _premiumNotice(context),
              ),
            if (showCompatibility) ...[
              if (premium) const SizedBox(height: 8),
              OutlineButtonX(
                label: AppLocalizations.of(context).matCheckCompatibility,
                expand: true,
                onPressed: () => _checkCompatibility(context, myId),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
