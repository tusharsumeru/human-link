import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/api_client.dart';
import '../data/models/compatibility_models.dart';
import '../data/models/compatibility_prerequisites.dart';
import '../data/repository.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ui_kit.dart';
import 'compatibility_dashboard_screen.dart';
import 'south_indian_jataka_screen.dart';

/// STEP 25B/25D — Check Compatibility preparation screen: shown between a
/// candidate's profile and the Marriage Compatibility dashboard
/// ([CompatibilityDashboardScreen], STEP 73). Reads the Step 25A readiness
/// check and shows, per module, whether it's ready to calculate and — only
/// for gaps the signed-in member can fix themselves — an action to fix it.
/// Tapping Continue submits `POST /api/v1/compatibility/calculate` (Step
/// 25D) and, on success, navigates to the dashboard by the `reportId` the
/// backend returns. Nothing in this file computes a Nakshatra, Rashi,
/// Porutham, or any percentage — it only decides which already-ready
/// modules to ask the backend to calculate.
class CompatibilityCheckScreen extends StatefulWidget {
  const CompatibilityCheckScreen({
    super.key,
    required this.myProfileId,
    required this.candidateProfileId,
    required this.candidateName,
    required this.candidateGender,
    this.discoveryMatch,
  });

  /// The signed-in member's own User id (becomes profileA if Continue is
  /// tapped).
  final String myProfileId;

  /// The candidate's User id — what the prerequisites endpoint and
  /// [CompatibilityScreen] both key on (not the matrimonial profile's own
  /// document id).
  final String candidateProfileId;
  final String candidateName;
  final String candidateGender;

  /// The candidate's `discoveryMatch` object (`{matchPercentage, matchLevel,
  /// factors}`), already loaded by the caller (matrimonial profile fetch) —
  /// carried through to [CompatibilityDashboardScreen] purely as a display
  /// fallback for its Profile Compatibility card when the questionnaire-based
  /// `ProfileCompatibility` hasn't been calculated yet. Never merged with or
  /// treated as equivalent to that figure.
  final Map<String, dynamic>? discoveryMatch;

  @override
  State<CompatibilityCheckScreen> createState() => _CompatibilityCheckScreenState();
}

class _CompatibilityCheckScreenState extends State<CompatibilityCheckScreen> {
  bool _loading = true;
  String? _error;
  CompatibilityPrerequisites? _prereqs;

  // STEP 25D — the calculate submission itself, separate from [_loading]
  // (the initial readiness fetch above).
  bool _calculating = false;
  CompatibilityRequestError? _calcError;

  // STEP F1 — South Indian Jataka's own scoped "Check Compatibility" action
  // on its module card, independent of the bulk [_calculate]/[_continueBar]
  // flow above (which still calculates every ready module together and is
  // left untouched). Guards against a double tap the same way [_calculating]
  // does for the bulk flow.
  bool _jatakaCalculating = false;
  CompatibilityRequestError? _jatakaCalcError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final p = await Repository.instance
          .compatibilityPrerequisites(widget.candidateProfileId);
      if (!mounted) return;
      setState(() {
        _prereqs = p;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error =
            e is ApiException ? e.message : 'Could not check compatibility readiness';
        _loading = false;
      });
    }
  }

  /// STEP 25D — the only place this screen submits anything. Sends the two
  /// profile ids, both traditional roles, and whichever modules the Step 25A
  /// readiness check already found ready — never a score, never astrology
  /// math; the backend computes and returns the report, and the id it hands
  /// back is all this navigates on.
  Future<void> _calculate() async {
    if (_calculating) return; // guards against a double tap firing twice

    final prereqs = _prereqs;
    if (prereqs == null) return;

    final myRole =
        TraditionalRole.forGender(context.read<AuthService>().user?.gender ?? '');
    final otherRole = TraditionalRole.forGender(widget.candidateGender);

    if (myRole == null || otherRole == null) {
      setState(() {
        _calcError = CompatibilityRequestError(
          reason: CompatibilityErrorReason.missingRole,
          message: myRole == null
              ? 'Add your gender in Profile → Edit first - it decides your '
                  'traditional bride/groom role.'
              : "This member's profile doesn't have a gender on file, so "
                  "their traditional role can't be determined.",
          profile:
              myRole == null ? CompatibilityErrorProfile.a : CompatibilityErrorProfile.b,
        );
      });
      return;
    }

    // Only ask the backend to calculate what Step 25A already found ready —
    // "available/requested modules" per this step's spec, not a blind
    // request for every module regardless of readiness.
    final include = <String>[
      if (prereqs.jataka.isReady) 'JATAKA',
      if (prereqs.profileCompatibility.isReady) 'PROFILE',
    ];
    if (include.isEmpty) return; // Continue is disabled in this case already

    setState(() {
      _calculating = true;
      _calcError = null;
    });
    try {
      final response = await Repository.instance.calculateCompatibility(
        profileAId: widget.myProfileId,
        profileBId: widget.candidateProfileId,
        roleA: myRole,
        roleB: otherRole,
        include: include,
      );
      if (!mounted) return;
      // The persisted report's id is `response.reportId` — POST /calculate's
      // own response shape, NOT `response.id` (that field belongs to the
      // richer GET /reports/:id shape only). A blank id here means the
      // backend didn't actually hand back a usable report; surface that as
      // an error instead of navigating to a screen that can only 404.
      if (response.reportId.trim().isEmpty) {
        setState(() {
          _calculating = false;
          _calcError = const CompatibilityRequestError(
            reason: CompatibilityErrorReason.apiError,
            message: 'Could not calculate compatibility right now.',
          );
        });
        return;
      }
      setState(() => _calculating = false);
      // §4 — a report with some modules NOT_CALCULABLE/notImplementedInclude
      // is still a valid report; it's rendered as-is, never treated as a
      // failure here. STEP 73 — lands on the Marriage Compatibility
      // dashboard (Overall/Profile/Astrology summary) rather than the
      // detailed report directly; "View Detailed Report" on that screen is
      // what reaches [CompatibilityReportScreen] now.
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => CompatibilityDashboardScreen(
          reportId: response.reportId,
          otherName: widget.candidateName,
          discoveryMatch: widget.discoveryMatch,
        ),
      ));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _calculating = false;
        _calcError = CompatibilityRequestError.fromApiException(e);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _calculating = false;
        _calcError = const CompatibilityRequestError(
          reason: CompatibilityErrorReason.apiError,
          message: 'Could not calculate compatibility right now.',
        );
      });
    }
  }

  /// STEP F1 — South Indian Jataka's own scoped calculate action, fired from
  /// the Jataka module card's own "Check Compatibility" button rather than
  /// the bulk Continue bar. Submits only `include: ['JATAKA']`, then opens
  /// [SouthIndianJatakaScreen] (the richer Karnataka-Porutham + Ashtakoota
  /// card) instead of the generic [CompatibilityReportScreen]. Never touches
  /// [_calculate]/[_calculating]/[_calcError] — the bulk flow for the other
  /// modules is unaffected.
  Future<void> _checkJataka() async {
    if (_jatakaCalculating) return; // guards against a double tap firing twice

    final prereqs = _prereqs;
    if (prereqs == null || !prereqs.jataka.isReady) return;

    final myRole =
        TraditionalRole.forGender(context.read<AuthService>().user?.gender ?? '');
    final otherRole = TraditionalRole.forGender(widget.candidateGender);

    if (myRole == null || otherRole == null) {
      setState(() {
        _jatakaCalcError = CompatibilityRequestError(
          reason: CompatibilityErrorReason.missingRole,
          message: myRole == null
              ? 'Add your gender in Profile → Edit first - it decides your '
                  'traditional bride/groom role.'
              : "This member's profile doesn't have a gender on file, so "
                  "their traditional role can't be determined.",
          profile:
              myRole == null ? CompatibilityErrorProfile.a : CompatibilityErrorProfile.b,
        );
      });
      return;
    }

    setState(() {
      _jatakaCalculating = true;
      _jatakaCalcError = null;
    });
    try {
      final response = await Repository.instance.calculateCompatibility(
        profileAId: widget.myProfileId,
        profileBId: widget.candidateProfileId,
        roleA: myRole,
        roleB: otherRole,
        include: const ['JATAKA'],
      );
      if (!mounted) return;
      // Same fix as [_calculate]: the persisted report's id is
      // `response.reportId` (POST /calculate's own response shape), never
      // `response.id`. A blank id must never reach [SouthIndianJatakaScreen]
      // — that would call `GET /reports//south-indian-jataka` with a missing
      // segment, exactly the bug this guard prevents.
      if (response.reportId.trim().isEmpty) {
        setState(() {
          _jatakaCalculating = false;
          _jatakaCalcError = const CompatibilityRequestError(
            reason: CompatibilityErrorReason.apiError,
            message: 'Could not calculate compatibility right now.',
          );
        });
        return;
      }
      setState(() => _jatakaCalculating = false);
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => SouthIndianJatakaScreen(
          reportId: response.reportId,
          otherName: widget.candidateName,
        ),
      ));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _jatakaCalculating = false;
        _jatakaCalcError = CompatibilityRequestError.fromApiException(e);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _jatakaCalculating = false;
        _jatakaCalcError = const CompatibilityRequestError(
          reason: CompatibilityErrorReason.apiError,
          message: 'Could not calculate compatibility right now.',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.forest800,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('Check Compatibility', style: display(18, color: Colors.white)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _errorState(_error!)
              : _content(_prereqs!),
    );
  }

  Widget _errorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 32, color: AppColors.hint),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: body(14, color: AppColors.textMuted)),
            const SizedBox(height: 14),
            OutlineButtonX(label: 'Try again', onPressed: _load),
          ],
        ),
      ),
    );
  }

  Widget _content(CompatibilityPrerequisites p) {
    final canContinue = p.overallStatus.hasAnyReadyModule && !_calculating;

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 150),
          children: [
            Text('You × ${widget.candidateName}',
                style: display(18, color: AppColors.forest900)),
            const SizedBox(height: 6),
            Text(
              'See your Jataka and profile compatibility.',
              style: body(13, color: AppColors.textMuted, height: 1.5),
            ),
            const SizedBox(height: 16),
            _moduleCard(context, 'Profile Compatibility', p.profileCompatibility),
            const SizedBox(height: 10),
            _moduleCard(
              context,
              'South Indian Jataka',
              p.jataka,
              readyExtra: p.jataka.isReady ? _jatakaReadyAction() : null,
            ),
          ],
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _continueBar(canContinue, p.overallStatus),
        ),
      ],
    );
  }

  Widget _continueBar(bool canTap, OverallReadinessStatus overallStatus) {
    // "Nothing is ready at all" (dim the button) is a different state from
    // "a request is in flight" (spinner, but still a normal-looking button)
    // — [canTap] already folds in `!_calculating`, so recover the former on
    // its own for the dimming decision.
    final hasReadyModules = overallStatus.hasAnyReadyModule;

    final button = SizedBox(
      height: 48,
      child: ForestButton(
        label: 'Check Compatibility',
        icon: Icons.favorite_rounded,
        expand: true,
        loading: _calculating,
        onPressed: canTap ? _calculate : null,
      ),
    );

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
            if (_calculating) ...[
              Text('Checking Compatibility...',
                  textAlign: TextAlign.center,
                  style: body(12, weight: FontWeight.w600, color: AppColors.forest700)),
              const SizedBox(height: 8),
            ] else if (_calcError != null) ...[
              _calcErrorBanner(_calcError!),
              const SizedBox(height: 8),
            ] else if (!hasReadyModules) ...[
              Text(
                overallStatus == OverallReadinessStatus.actionRequired
                    ? 'Complete the highlighted sections above to check compatibility.'
                    : "Compatibility can't be checked with this profile yet.",
                textAlign: TextAlign.center,
                style: body(12, color: AppColors.textMuted),
              ),
              const SizedBox(height: 8),
            ],
            hasReadyModules
                ? button
                : Opacity(opacity: 0.5, child: IgnorePointer(child: button)),
          ],
        ),
      ),
    );
  }

  /// STEP 25D §5 — inline failure surface for the calculate call itself
  /// (missing consent / missing required data / network / server error).
  /// Only offers an action when the gap is the signed-in member's own
  /// ([CompatibilityErrorProfile.a]) and Flutter has a screen for it —
  /// mirrors [_actionFor]'s "only actionable, only real screens" rule.
  Widget _calcErrorBanner(CompatibilityRequestError error) {
    final mine = error.profile == CompatibilityErrorProfile.a;
    final (String? actionLabel, VoidCallback? onAction) = !mine
        ? (null, null)
        : switch (error.reason) {
            CompatibilityErrorReason.missingRole => (
                'Go to Profile',
                () => context.push('/profile/edit'),
              ),
            CompatibilityErrorReason.missingBirthData => (
                'Add Birth Details',
                () => context.push('/matrimonial/birth-details'),
              ),
            CompatibilityErrorReason.missingConsent => (
                'Manage Consent',
                () => context.push('/matrimonial/compatibility-consent'),
              ),
            CompatibilityErrorReason.apiError => (null, null),
          };

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.error_outline_rounded, size: 16, color: Colors.red.shade700),
              const SizedBox(width: 6),
              Expanded(
                child: Text(error.message,
                    style: body(12, color: Colors.red.shade800, height: 1.35)),
              ),
            ],
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(
                    padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
                child: Text(actionLabel,
                    style: body(12, weight: FontWeight.w700, color: AppColors.forest700)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Per-module card ───────────────────────────────────────────────────────

  Widget _moduleCard(
    BuildContext context,
    String title,
    ModuleReadiness readiness, {
    String readyLabel = 'Ready',
    Widget? readyExtra,
  }) {
    final visual = _statusVisual(readiness.status, readyLabel: readyLabel);
    final action = (readiness.status == ReadinessStatus.actionRequired &&
            readiness.reason.isActionableByViewer)
        ? _actionFor(context, readiness.reason)
        : null;

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title,
                    style: body(14, weight: FontWeight.w700, color: AppColors.forest900)),
              ),
              Icon(visual.icon, size: 16, color: visual.color),
              const SizedBox(width: 4),
              Text(visual.label,
                  style: body(12, weight: FontWeight.w700, color: visual.color)),
            ],
          ),
          if (action != null) ...[
            const SizedBox(height: 8),
            Text(action.description, style: body(12, color: AppColors.textMuted)),
            const SizedBox(height: 8),
            OutlineButtonX(label: action.actionLabel, onPressed: action.onTap),
          ] else if (readiness.status == ReadinessStatus.actionRequired &&
              readiness.reason == PrerequisiteReason.yourVerificationIncomplete) ...[
            const SizedBox(height: 6),
            Text('Verification required.', style: body(12, color: AppColors.textMuted)),
          ] else if (readiness.status == ReadinessStatus.unavailable) ...[
            const SizedBox(height: 6),
            // Deliberately generic — never names what specifically the
            // candidate is missing, whether it's their data or their
            // consent (§5/§6 of the spec).
            Text('Compatibility data is not available for this section yet.',
                style: body(12, color: AppColors.textMuted)),
          ],
          if (readiness.status == ReadinessStatus.ready && readyExtra != null) ...[
            const SizedBox(height: 10),
            readyExtra,
          ],
        ],
      ),
    );
  }

  /// STEP F1 — the South Indian Jataka module card's own scoped action:
  /// button → loading → inline error, independent of the bulk Continue bar.
  Widget _jatakaReadyAction() {
    if (_jatakaCalculating) {
      return Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          Text('Checking compatibility...',
              style: body(12, weight: FontWeight.w600, color: AppColors.forest700)),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_jatakaCalcError != null) ...[
          _calcErrorBanner(_jatakaCalcError!),
          const SizedBox(height: 8),
        ],
        OutlineButtonX(label: 'Check Compatibility', onPressed: _checkJataka),
      ],
    );
  }

  ({IconData icon, Color color, String label}) _statusVisual(
    ReadinessStatus status, {
    required String readyLabel,
  }) {
    switch (status) {
      case ReadinessStatus.ready:
        return (icon: Icons.check_circle_rounded, color: AppColors.forest700, label: readyLabel);
      case ReadinessStatus.actionRequired:
        return (
          icon: Icons.error_outline_rounded,
          color: AppColors.gold500,
          label: 'More information needed',
        );
      case ReadinessStatus.unavailable:
      case ReadinessStatus.unknown:
        return (
          icon: Icons.remove_circle_outline_rounded,
          color: AppColors.hint,
          label: 'Not available yet',
        );
    }
  }

  /// Only for `YOUR_*` reasons Flutter actually has a self-service screen
  /// for — every entry here routes to an existing screen (§6 of this step:
  /// reuse the existing consent screen rather than building another one).
  ({String description, String actionLabel, VoidCallback onTap})? _actionFor(
    BuildContext context,
    PrerequisiteReason reason,
  ) {
    switch (reason) {
      case PrerequisiteReason.yourBirthDetailsMissing:
        return (
          description: 'Birth details required.',
          actionLabel: 'Add Birth Details',
          onTap: () => context.push('/matrimonial/birth-details'),
        );
      case PrerequisiteReason.yourConsentRequired:
        return (
          description: 'Compatibility permission required.',
          actionLabel: 'Manage Consent',
          onTap: () => context.push('/matrimonial/compatibility-consent'),
        );
      case PrerequisiteReason.insufficientProfileData:
        return (
          description: 'Complete a few compatibility questions.',
          actionLabel: 'Complete Questions',
          onTap: () => context.push('/matrimonial/edit'),
        );
      case PrerequisiteReason.yourFamilyTreeIncomplete:
        return (
          description: 'Add a few more family relationships to enable this.',
          actionLabel: 'Update Family Tree',
          onTap: () => context.push('/family-tree'),
        );
      default:
        // yourVerificationIncomplete has no self-service Flutter screen to
        // send the member to (verification is elder-side); handled as plain
        // text by the caller instead of a dead-end button.
        return null;
    }
  }
}
