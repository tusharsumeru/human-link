import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/api_client.dart';
import '../data/repository.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_shell.dart';
import '../widgets/discovery_match_badge.dart';
import '../widgets/pexels_image.dart';
import '../widgets/ui_kit.dart';

/// Matrimonial Hub list — ported from `src/app/matrimonial/page.tsx`.
/// Elder-mediated, verified profiles with gotra/location filtering. Gender is
/// not a filter the member picks: a matrimonial hub only ever shows the
/// opposite gender to the one on the viewer's own account.
class MatrimonialListScreen extends StatefulWidget {
  const MatrimonialListScreen({super.key});

  @override
  State<MatrimonialListScreen> createState() => _MatrimonialListScreenState();
}

class _MatrimonialListScreenState extends State<MatrimonialListScreen> {
  // Fixed by the viewer's own gender, not a user-adjustable filter — a
  // member registered as 'M' only ever sees 'F' profiles here, and vice
  // versa. Falls back to showing everyone only if the viewer's own gender
  // isn't on file, which shouldn't happen once past MatrimonialGateScreen.
  late final String _gender;

  // Approved profiles from GET /api/matrimonial, already narrowed to the
  // opposite gender server-side. Reaching this screen means
  // MatrimonialGateScreen already cleared the caller, so a 403 here would be
  // a real error rather than the expected "not eligible" path.
  List<Map<String, dynamic>> _candidates = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final myGender = context.read<AuthService>().user?.gender ?? '';
    _gender = myGender == 'M' ? 'F' : (myGender == 'F' ? 'M' : 'All');
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profiles = await Repository.instance.matrimonialProfiles(
        gender: _gender,
      );
      if (!mounted) return;
      setState(() {
        _candidates = profiles;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is ApiException
            ? e.message
            : AppLocalizations.of(context).matCouldNotLoadProfiles;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return AppShell(
      title: t.matTitle,
      currentRoute: '/matrimonial',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _discoverMatchesButton(context, t),
          const SizedBox(height: 14),
          _genderLabel(t),
          const SizedBox(height: 16),
          Text(
            t.matProfilesCount(_candidates.length),
            style: body(
              13,
              color: context.onBrightness(
                light: AppColors.textMuted,
                dark: AppColors.darkTextMuted,
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            _errorState(_error!, t)
          else if (_candidates.isEmpty)
            _emptyState(t)
          else
            ..._candidates.map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _CandidateCard(candidate: c),
              ),
            ),
        ],
      ),
    );
  }

  Widget _discoverMatchesButton(BuildContext context, AppLocalizations t) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: context.onBrightness(
              light: AppColors.forest800,
              dark: AppColors.forest300,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onPressed: () => context.push('/matrimonial/discover'),
        icon: Icon(
          Icons.auto_awesome_rounded,
          size: 18,
          color: context.onBrightness(
            light: AppColors.forest800,
            dark: AppColors.forest300,
          ),
        ),
        label: Text(
          t.matDiscoverMatches,
          style: body(
            14,
            weight: FontWeight.w700,
            color: context.onBrightness(
              light: AppColors.forest800,
              dark: AppColors.forest300,
            ),
          ),
        ),
      ),
    );
  }

  Widget _genderLabel(AppLocalizations t) {
    final label = switch (_gender) {
      'F' => t.matShowingBrides,
      'M' => t.matShowingGrooms,
      _ => t.matShowingAllProfiles,
    };
    return Row(
      children: [
        const Icon(
          Icons.favorite_rounded,
          size: 15,
          color: AppColors.forest700,
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: body(
            13,
            weight: FontWeight.w700,
            color: context.onBrightness(
              light: AppColors.forest800,
              dark: AppColors.forest300,
            ),
          ),
        ),
      ],
    );
  }

  Widget _emptyState(AppLocalizations t) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(
            Icons.favorite_border_rounded,
            size: 30,
            color: context.onBrightness(
              light: AppColors.hint,
              dark: AppColors.darkTextMuted,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            t.matNoProfilesYet,
            style: body(
              15,
              weight: FontWeight.w600,
              color: context.onBrightness(
                light: AppColors.hint,
                dark: AppColors.darkText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorState(String message, AppLocalizations t) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(
            Icons.wifi_off_rounded,
            size: 30,
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
          const SizedBox(height: 10),
          TextButton(
            onPressed: _load,
            child: Text(
              t.matTryAgain,
              style: body(
                13,
                weight: FontWeight.w700,
                color: context.onBrightness(
                  light: AppColors.forest800,
                  dark: AppColors.forest300,
                ),
              ),
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
    final t = AppLocalizations.of(context);
    final c = candidate;
    final verified = c['verified'] == true;
    final premium = c['matrimonialFee'] == true;
    final gender = c['gender'] == 'F' ? t.matBride : t.matGroom;
    final id = c['id'] as String;

    return AppCard(
      padding: EdgeInsets.zero,
      onTap: () => context.push('/matrimonial/$id'),
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
                          horizontal: 8,
                          vertical: 4,
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
                              size: 13,
                              color: AppColors.gold500,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              t.matVerified,
                              style: body(
                                10,
                                weight: FontWeight.w700,
                                color: AppColors.forest800,
                              ),
                            ),
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
                        child: Text(
                          '${c['name']}, ${c['age']}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: display(
                            17,
                            color: context.onBrightness(
                              light: AppColors.forest900,
                              dark: AppColors.darkText,
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (premium)
                        _PremiumChip(t: t)
                      else
                        Pill(
                          t.matFree,
                          bg: const Color(0xFFF0FBF4),
                          fg: AppColors.forest700,
                          fontSize: 10,
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _detailRow(
                    context,
                    Icons.height_rounded,
                    '${c['height']} · ${c['location']}',
                  ),
                  const SizedBox(height: 4),
                  _detailRow(
                    context,
                    Icons.school_outlined,
                    (c['education'] as String).split(',').first,
                  ),
                  const SizedBox(height: 4),
                  _detailRow(
                    context,
                    Icons.business_center_outlined,
                    (c['company'] as String).split('—').first.trim(),
                  ),
                  const SizedBox(height: 10),
                  // Same Discovery Match % shown on the Discover Matches
                  // screen for this pair — one number for one pair of
                  // people, never a second, differently-computed score.
                  // Absent when the viewer has no profile yet.
                  DiscoveryMatchBadge(
                    discoveryMatch:
                        c['discoveryMatch'] as Map<String, dynamic>?,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Pill(
                        c['gotra'] as String,
                        bg: const Color(0xFFF7F0E8),
                        fg: AppColors.gold700,
                        fontSize: 10,
                      ),
                      const Spacer(),
                      ForestButton(
                        label: t.matViewProfile,
                        icon: Icons.favorite_rounded,
                        onPressed: () => context.push('/matrimonial/$id'),
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

  Widget _detailRow(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: context.onBrightness(
            light: AppColors.hint,
            dark: AppColors.darkTextMuted,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: body(
              12,
              color: context.onBrightness(
                light: AppColors.textMuted,
                dark: AppColors.darkTextMuted,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PremiumChip extends StatelessWidget {
  const _PremiumChip({required this.t});
  final AppLocalizations t;

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
          const Icon(
            Icons.workspace_premium_rounded,
            size: 12,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            t.matPremium,
            style: body(10, weight: FontWeight.w700, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
