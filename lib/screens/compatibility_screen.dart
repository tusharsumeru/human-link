import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/api_client.dart';
import '../data/models/compatibility_models.dart';
import '../data/repository.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
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
              _reportCard(_report!),
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

  // ── Success — the Jataka report ─────────────────────────────────────────

  Widget _reportCard(CompatibilityReport report) {
    final jataka = report.jataka;
    if (jataka == null) {
      return _noticeCard(
        icon: Icons.info_outline_rounded,
        title: 'No Jataka result',
        message: 'The report was generated but did not include a Jataka section.',
      );
    }
    final boundaryRiskCard = _boundaryRiskCard(jataka);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (boundaryRiskCard != null) ...[boundaryRiskCard, const SizedBox(height: 14)],
        _verdictCard(jataka),
        const SizedBox(height: 14),
        _countsRow(jataka),
        const SizedBox(height: 14),
        if (jataka.criticalAlerts.isNotEmpty) ...[
          _criticalAlertsCard(jataka.criticalAlerts),
          const SizedBox(height: 14),
        ],
        _poruthamListCard(jataka),
      ],
    );
  }

  /// The confidence/review message for birth-time uncertainty (compatibility
  /// spec §10) — shown only when the backend actually signaled some risk.
  /// Never computed here: [CompatibilityJataka.nakshatraBoundaryRiskOverride]
  /// and each side's [BoundaryRisk] flags come straight from the API: this
  /// widget only chooses how to *display* them, never whether they're true.
  Widget? _boundaryRiskCard(CompatibilityJataka jataka) {
    final bride = jataka.brideBoundaryRisk;
    final groom = jataka.groomBoundaryRisk;
    if (bride == null || groom == null) return null;

    final anyRisk = jataka.nakshatraBoundaryRiskOverride || bride.hasAnyRisk || groom.hasAnyRisk;
    if (!anyRisk) return null;

    // Nakshatra-level risk is the severe case — the backend already forced
    // every Porutham to REVIEW_REQUIRED because of it. Anything less (only
    // Pada/Rashi/Lagna/Navamsha uncertain) is a softer "lower confidence"
    // note, matching spec §10: "If only Lagna changes... low confidence,"
    // not a full review-required state.
    final critical = jataka.nakshatraBoundaryRiskOverride;
    final bg = critical ? const Color(0xFFFEF2F2) : const Color(0xFFFFF8E8);
    final fg = critical ? Colors.red.shade700 : AppColors.gold700;

    return AppCard(
      color: bg,
      border: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(critical ? Icons.warning_amber_rounded : Icons.info_outline_rounded,
                  size: 18, color: fg),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  critical
                      ? 'Review required — birth-time uncertainty'
                      : 'Reduced confidence — birth-time uncertainty',
                  style: body(13, weight: FontWeight.w700, color: fg),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            critical
                ? "One or both birth times aren't precise enough to rule out a "
                    'different Nakshatra — every Porutham below is marked '
                    '"Review required" rather than trusting a single estimate.'
                : 'Birth-time uncertainty may affect some factors below (e.g. '
                    'Lagna) — treat those as lower-confidence.',
            style: body(12, color: AppColors.textMuted, height: 1.4),
          ),
          const SizedBox(height: 10),
          _boundaryRiskRow('Bride', bride),
          const SizedBox(height: 6),
          _boundaryRiskRow('Groom', groom),
        ],
      ),
    );
  }

  Widget _boundaryRiskRow(String who, BoundaryRisk risk) {
    final flags = <String>[
      if (risk.nakshatraMayChange) 'Nakshatra',
      if (risk.padaMayChange) 'Pada',
      if (risk.rashiMayChange) 'Rashi',
      if (risk.lagnaMayChange) 'Lagna',
      if (risk.navamshaMayChange) 'Navamsha',
    ];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 46,
          child: Text(who, style: body(11, weight: FontWeight.w700, color: AppColors.ink)),
        ),
        Expanded(
          child: Text(
            '${birthTimeAccuracyLabels[risk.birthTimeAccuracy]} '
            '(${(risk.confidence * 100).round()}% confidence)'
            '${flags.isEmpty ? '' : ' — may affect: ${flags.join(', ')}'}',
            style: body(11, color: AppColors.textMuted, height: 1.35),
          ),
        ),
      ],
    );
  }

  Widget _verdictCard(CompatibilityJataka jataka) {
    final (Color bg, Color fg, IconData icon) = switch (jataka.verdict) {
      TraditionalVerdictCode.strong =>
        (const Color(0xFFF0FBF4), AppColors.forest700, Icons.favorite_rounded),
      TraditionalVerdictCode.good => (
          const Color(0xFFF0FBF4),
          AppColors.forest700,
          Icons.favorite_outline_rounded
        ),
      TraditionalVerdictCode.moderate =>
        (const Color(0xFFFFF8E8), AppColors.gold700, Icons.balance_rounded),
      TraditionalVerdictCode.low =>
        (const Color(0xFFFEF2F2), Colors.red.shade700, Icons.trending_down_rounded),
      TraditionalVerdictCode.criticalReview =>
        (const Color(0xFFFEF2F2), Colors.red.shade700, Icons.warning_amber_rounded),
      TraditionalVerdictCode.expertReviewRequired || TraditionalVerdictCode.unknown =>
        (const Color(0xFFFFF8E8), AppColors.gold700, Icons.hourglass_top_rounded),
    };
    return AppCard(
      color: bg,
      border: false,
      child: Row(
        children: [
          Icon(icon, size: 28, color: fg),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('South Indian Jataka',
                    style: body(11,
                        weight: FontWeight.w700, color: fg, letterSpacing: 1)),
                const SizedBox(height: 3),
                Text('${jataka.matched}/10 matched',
                    style: display(20, color: AppColors.forest900)),
                const SizedBox(height: 4),
                Text(jataka.verdictLabel,
                    style: body(13, weight: FontWeight.w600, color: fg)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _countsRow(CompatibilityJataka jataka) {
    final items = [
      ('Matched', jataka.matched, AppColors.forest700),
      ('Partial', jataka.partial, AppColors.gold700),
      ('Not matched', jataka.notMatched, Colors.red.shade700),
      if (jataka.reviewRequired > 0)
        ('Review', jataka.reviewRequired, AppColors.gold700),
      if (jataka.notCalculable > 0)
        ('Unavailable', jataka.notCalculable, AppColors.hint),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (label, count, color) in items)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.border),
            ),
            child: Text('$label: $count',
                style: body(12, weight: FontWeight.w700, color: color)),
          ),
      ],
    );
  }

  Widget _criticalAlertsCard(List<PoruthamResult> alerts) {
    return AppCard(
      color: const Color(0xFFFEF2F2),
      border: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, size: 18, color: Colors.red.shade700),
              const SizedBox(width: 8),
              Text('Important traditional concern',
                  style: body(14, weight: FontWeight.w700, color: Colors.red.shade800)),
            ],
          ),
          const SizedBox(height: 8),
          for (final a in alerts)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('${poruthamLabel(a.code)} did not match',
                  style: body(13, color: Colors.red.shade800)),
            ),
        ],
      ),
    );
  }

  Widget _poruthamListCard(CompatibilityJataka jataka) {
    final pending = jataka.poruthams.any((p) => p.status == PoruthamStatus.notCalculable);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('The 10 Poruthams', style: display(15, color: AppColors.forest900)),
          const SizedBox(height: 4),
          Text('Rule version: ${jataka.ruleVersion}',
              style: body(11, color: AppColors.textMuted)),
          const SizedBox(height: 10),
          for (final p in jataka.poruthams) _poruthamRow(p),
          if (pending) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E8), borderRadius: BorderRadius.circular(10)),
              child: Text(
                'Some Poruthams show "Unavailable" because their Karnataka rule '
                'tables are still awaiting astrologer approval — not an error.',
                style: body(12, color: AppColors.gold700, height: 1.4),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Status → indicator icon/color/label. This only maps what the API
  /// returned in `status` — it never infers or recomputes a status itself.
  Widget _poruthamRow(PoruthamResult p) {
    final (IconData icon, Color color, String label) = switch (p.status) {
      PoruthamStatus.matched => (Icons.check_circle_rounded, AppColors.forest700, 'Matched'),
      PoruthamStatus.partial =>
        (Icons.adjust_rounded, AppColors.gold700, 'Partial'),
      PoruthamStatus.notMatched =>
        (Icons.cancel_rounded, Colors.red.shade700, 'Not matched'),
      PoruthamStatus.reviewRequired =>
        (Icons.rate_review_outlined, AppColors.gold700, 'Review required'),
      PoruthamStatus.notCalculable =>
        (Icons.remove_circle_outline_rounded, AppColors.hint, 'Unavailable'),
      PoruthamStatus.unknown => (Icons.help_outline_rounded, AppColors.hint, 'Unknown'),
    };
    final explanation = _explanationFor(p);
    final critical = p.isCritical;

    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(poruthamLabel(p.code),
                        style: body(13,
                            weight: FontWeight.w700,
                            color: critical ? Colors.red.shade800 : AppColors.ink)),
                  ),
                  if (critical) ...[
                    Icon(Icons.priority_high_rounded, size: 14, color: Colors.red.shade700),
                    const SizedBox(width: 2),
                  ],
                  Text(label, style: body(12, weight: FontWeight.w700, color: color)),
                ],
              ),
              // The backend's own explanation for this result — the computed
              // inputs (distance, tara position, gana/yoni compared, …) and,
              // for an unavailable result, the reason no rule matched. Shown
              // only when the API actually sent something.
              if (explanation.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(explanation, style: body(11, color: AppColors.textMuted, height: 1.3)),
              ],
            ],
          ),
        ),
      ],
    );

    if (!critical) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: content,
      );
    }

    // Rajju mismatches must always be prominent — a red-bordered card, not
    // just a small icon buried in the list.
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: content,
    );
  }

  /// The backend's explanation for one Porutham result: its computed
  /// `details` (free-form per Porutham — distance, tara position, gana/yoni
  /// compared, …), plus a readable form of `ruleId` when it's an
  /// "unavailable" reason code (e.g. "DINA_RULE_NOT_FOUND") rather than an
  /// approved rule-table row id. Purely a display transform — the underlying
  /// status/data always comes straight from the API.
  String _explanationFor(PoruthamResult p) {
    final parts = <String>[];
    if (p.details.isNotEmpty) {
      parts.add(p.details.entries
          .map((e) => '${_humanizeKey(e.key)}: ${e.value}')
          .join(' · '));
    }
    if (p.status == PoruthamStatus.notCalculable && p.ruleId.isNotEmpty) {
      parts.add(_humanizeReasonCode(p.ruleId));
    }
    return parts.join(' — ');
  }

  String _humanizeKey(String key) {
    final spaced = key.replaceAllMapped(
        RegExp(r'([a-z0-9])([A-Z])'), (m) => '${m[1]} ${m[2]}');
    return spaced.isEmpty
        ? spaced
        : spaced[0].toUpperCase() + spaced.substring(1).toLowerCase();
  }

  String _humanizeReasonCode(String code) {
    return code
        .split('_')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0] + w.substring(1).toLowerCase())
        .join(' ');
  }
}
