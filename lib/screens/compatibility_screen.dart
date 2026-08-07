import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/api_client.dart';
import '../data/models/compatibility_models.dart';
import '../data/repository.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/compatibility_report_view.dart';
import '../widgets/ui_kit.dart';
import 'compatibility_consent_screen.dart';

/// Marriage Compatibility report — connects to the real backend Jataka
/// engine (`POST /api/v1/compatibility/calculate`). Only the JATAKA module
/// (South Indian 10 Porutham) is implemented server-side today; no
/// matching/astrology calculation happens on the Flutter side — this screen
/// only submits the request and renders the typed [CompatibilityReport] (or
/// [CompatibilityRequestError]) that comes back.
class CompatibilityScreen extends StatefulWidget {
  const CompatibilityScreen({
    super.key,
    required this.profileAId,
    required this.profileBId,
    required this.otherGender,
    this.otherName = '',
  });

  /// The signed-in member's own profile id (profileA in every request).
  final String profileAId;

  /// The matrimonial candidate's profile id (profileB).
  final String profileBId;

  /// The candidate's gender ('M'/'F') — derives their traditional role the
  /// same way the signed-in member's own role is derived from their gender.
  final String otherGender;

  /// Convenience display name for [profileBId] — passed by the caller (who
  /// already has it loaded) so the header renders immediately, without a
  /// second fetch just for a name.
  final String otherName;

  @override
  State<CompatibilityScreen> createState() => _CompatibilityScreenState();
}

class _CompatibilityScreenState extends State<CompatibilityScreen> {
  bool _loading = false;
  CompatibilityRequestError? _error;
  CompatibilityReport? _report;

  // The signed-in member's OWN consent status, shown proactively before they
  // even tap Calculate — never the other profile's; there is no endpoint to
  // read anyone else's (ConsentController is self-only by design).
  ConsentStatus? _myConsent;
  bool _loadingConsent = true;

  @override
  void initState() {
    super.initState();
    _loadConsentStatus();
  }

  Future<void> _loadConsentStatus() async {
    setState(() => _loadingConsent = true);
    try {
      final consents = await Repository.instance.myCompatibilityConsent();
      if (!mounted) return;
      ConsentStatus? birthData;
      for (final c in consents) {
        if (c.consentType == CompatibilityConsentType.birthDataMatching) birthData = c;
      }
      setState(() {
        _myConsent = birthData;
        _loadingConsent = false;
      });
    } catch (_) {
      // Best-effort — the proactive card just won't show if this fails; the
      // reactive error path (from an actual calculate attempt) still covers it.
      if (!mounted) return;
      setState(() => _loadingConsent = false);
    }
  }

  Future<void> _openConsentScreen() async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const CompatibilityConsentScreen()));
    if (!mounted) return;
    await _loadConsentStatus();
    // If the last attempt failed on consent specifically, retry now that the
    // member may have just granted it — harmless no-op if nothing changed.
    if (_error?.reason == CompatibilityErrorReason.missingConsent) {
      await _calculate();
    }
  }

  Future<void> _calculate() async {
    final myRole = TraditionalRole.forGender(
        context.read<AuthService>().user?.gender ?? '');
    final otherRole = TraditionalRole.forGender(widget.otherGender);

    if (myRole == null || otherRole == null) {
      setState(() {
        _report = null;
        _error = CompatibilityRequestError(
          reason: CompatibilityErrorReason.missingRole,
          message: myRole == null
              ? 'Add your gender in Profile → Edit first — it decides your '
                  'traditional bride/groom role.'
              : "This member's profile doesn't have a gender on file, so "
                  "their traditional role can't be determined.",
          profile: myRole == null
              ? CompatibilityErrorProfile.a
              : CompatibilityErrorProfile.b,
        );
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final report = await Repository.instance.calculateCompatibility(
        profileAId: widget.profileAId,
        profileBId: widget.profileBId,
        roleA: myRole,
        roleB: otherRole,
      );
      if (!mounted) return;
      setState(() {
        _report = report;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _report = null;
        _error = CompatibilityRequestError.fromApiException(e);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _report = null;
        _error = const CompatibilityRequestError(
          reason: CompatibilityErrorReason.apiError,
          message: 'Could not calculate compatibility right now.',
        );
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final myName = context.watch<AuthService>().user?.name ?? 'You';
    final otherName = widget.otherName.trim().isNotEmpty
        ? widget.otherName.trim()
        : 'This member';

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.forest800,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('Compatibility Report', style: display(18, color: Colors.white)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
          children: [
            _header(myName, otherName),
            const SizedBox(height: 16),
            _consentStatusCard(),
            const SizedBox(height: 16),
            if (_error != null) ...[
              _errorCard(_error!),
              const SizedBox(height: 16),
            ],
            if (_report != null) ...[
              CompatibilityReportView(report: _report!),
              const SizedBox(height: 16),
            ],
            SizedBox(
              width: double.infinity,
              child: ForestButton(
                label: _report != null
                    ? 'Recalculate'
                    : (_error != null ? 'Retry' : 'Calculate Compatibility'),
                icon: Icons.auto_awesome_rounded,
                expand: true,
                loading: _loading,
                onPressed: _calculate,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Displayed BEFORE the member ever taps Calculate — required consent,
  /// shown proactively rather than only after the API rejects a request.
  /// Only ever the signed-in member's own status (self-only endpoint); the
  /// other profile's consent is never fetched or shown here.
  Widget _consentStatusCard() {
    if (_loadingConsent) {
      return const AppCard(
        child: SizedBox(
          height: 20,
          child: Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.forest700),
            ),
          ),
        ),
      );
    }
    final consent = _myConsent;
    final ok = consent?.satisfiesCalculation ?? false;
    final outdated = consent != null && consent.granted && !consent.isCurrentPolicy;

    return AppCard(
      color: ok ? const Color(0xFFF0FBF4) : AppColors.cream,
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle_outline_rounded : Icons.privacy_tip_outlined,
            size: 18,
            color: ok ? AppColors.forest700 : AppColors.gold700,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your consent · Birth-data matching',
                    style: body(12, weight: FontWeight.w700, color: AppColors.forest900)),
                const SizedBox(height: 2),
                Text(
                  ok
                      ? 'Allowed — required for this calculation.'
                      : outdated
                          ? 'Our consent policy changed — please re-confirm.'
                          : 'Not allowed yet — required before calculating.',
                  style: body(11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _openConsentScreen,
            child: Text(ok ? 'Manage' : 'Review',
                style: body(12, weight: FontWeight.w700, color: AppColors.forest700)),
          ),
        ],
      ),
    );
  }

  Widget _header(String myName, String otherName) {
    return AppCard(
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Color(0xFFFCEBDD),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.favorite_rounded,
                size: 26, color: AppColors.gold700),
          ),
          const SizedBox(height: 14),
          Text('Compatibility Report',
              style: display(20, color: AppColors.forest900),
              textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text('$myName × $otherName',
              style: body(14, weight: FontWeight.w600, color: AppColors.textMuted),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  // ── Error / notice states ───────────────────────────────────────────────

  Widget _errorCard(CompatibilityRequestError error) {
    final mine = error.profile == CompatibilityErrorProfile.a;
    return switch (error.reason) {
      CompatibilityErrorReason.missingRole => _noticeCard(
          icon: Icons.person_outline_rounded,
          title: 'Traditional role unknown',
          message: error.message,
          actionLabel: mine ? 'Go to Profile' : null,
          onAction: mine ? () => context.push('/profile/edit') : null,
        ),
      CompatibilityErrorReason.missingBirthData => _noticeCard(
          icon: Icons.cake_outlined,
          title: mine
              ? 'Your birth details are incomplete'
              : 'Their birth details are incomplete',
          message: mine
              ? 'Add your exact birth time and place to calculate the Jataka match.'
              : "This member hasn't finished their birth details yet — "
                  'check back later.',
          actionLabel: mine ? 'Add birth details' : null,
          onAction: mine ? () => context.push('/matrimonial/birth-details') : null,
        ),
      CompatibilityErrorReason.missingConsent => _noticeCard(
          icon: Icons.privacy_tip_outlined,
          title: mine ? 'Your consent is needed' : 'Their consent is needed',
          message: mine
              ? "You haven't allowed birth-data matching yet — review and "
                  'grant it to run this check.'
              : "This member hasn't allowed birth-data matching yet.",
          actionLabel: mine ? 'Review consent' : null,
          onAction: mine ? _openConsentScreen : null,
        ),
      CompatibilityErrorReason.apiError => _noticeCard(
          icon: Icons.error_outline_rounded,
          title: 'Something went wrong',
          message: error.message,
          isError: true,
        ),
    };
  }

  Widget _noticeCard({
    required IconData icon,
    required String title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    bool isError = false,
  }) {
    final bg = isError ? const Color(0xFFFEF2F2) : const Color(0xFFFFF8E8);
    final fg = isError ? Colors.red.shade800 : AppColors.gold700;
    return AppCard(
      color: bg,
      border: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: fg),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: body(14, weight: FontWeight.w700, color: fg)),
                    const SizedBox(height: 4),
                    Text(message,
                        style: body(13, color: AppColors.textMuted, height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onAction,
                child: Text(actionLabel,
                    style: body(13, weight: FontWeight.w700, color: AppColors.forest700)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
