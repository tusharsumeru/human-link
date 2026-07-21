import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/api_client.dart';
import '../data/repository.dart';
import '../theme/app_theme.dart';
import '../widgets/app_shell.dart';
import 'matrimonial_list_screen.dart';

/// Stands in front of the matrimonial hub.
///
/// `GET /api/matrimonial/eligibility` is the single source of truth for who
/// gets in — the same check the browse endpoint enforces server-side, so this
/// screen can never let someone through the API would refuse. Three gates, in
/// the order the member has to clear them:
///
///   1. age within the permitted range (derived from their date of birth),
///   2. every required profile field filled in,
///   3. the profile has been published.
///
/// Whichever gate is closed, the member sees exactly what to do next rather
/// than a bare "not allowed".
class MatrimonialGateScreen extends StatefulWidget {
  const MatrimonialGateScreen({super.key});

  @override
  State<MatrimonialGateScreen> createState() => _MatrimonialGateScreenState();
}

class _MatrimonialGateScreenState extends State<MatrimonialGateScreen> {
  Map<String, dynamic>? _eligibility;
  String? _error;
  bool _loading = true;
  bool _submitting = false;

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
      final e = await Repository.instance.matrimonialEligibility();
      if (!mounted) return;
      setState(() {
        _eligibility = e;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is ApiException ? e.message : 'Could not reach the server';
        _loading = false;
      });
    }
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await Repository.instance.publishMatrimonialProfile();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Your profile is live in the Matrimonial Hub'),
      ));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e is ApiException ? e.message : 'Could not publish'),
      ));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const AppShell(
        title: 'Matrimonial',
        currentRoute: '/matrimonial',
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_error != null) {
      return AppShell(
        title: 'Matrimonial',
        currentRoute: '/matrimonial',
        child: _Panel(
          icon: Icons.wifi_off_rounded,
          title: 'Could not load',
          message: _error!,
          action: ('Try again', _load),
        ),
      );
    }

    final e = _eligibility!;
    // Cleared every gate — hand over to the hub itself.
    if (e['eligible'] == true) return const MatrimonialListScreen();

    return AppShell(
      title: 'Matrimonial',
      currentRoute: '/matrimonial',
      child: _blockedView(e),
    );
  }

  Widget _blockedView(Map<String, dynamic> e) {
    final ageOk = e['ageEligible'] == true;
    final range = (e['ageRange'] as Map?) ?? const {'min': 18, 'max': 50};
    final age = e['age'];
    final status = (e['status'] ?? 'none').toString();
    final missing = ((e['missing'] as List?) ?? const [])
        .whereType<Map>()
        .map((m) => (
              key: (m['key'] ?? '').toString(),
              label: (m['label'] ?? m['key'] ?? '').toString(),
            ))
        .toList();

    // Gate 1 — age. Nothing else matters until this passes, so it's the only
    // thing shown; listing 20 missing fields to a 16-year-old would be noise.
    if (!ageOk) {
      return _Panel(
        icon: age == null ? Icons.event_rounded : Icons.lock_outline_rounded,
        title: age == null ? 'Add your date of birth' : 'Not available',
        message: age == null
            ? 'The matrimonial section is open to members aged ${range['min']}–${range['max']}. Add your date of birth in your profile to continue.'
            : 'The matrimonial section is open to members aged ${range['min']}–${range['max']}. Your age is $age.',
        action: age == null ? ('Go to my profile', _goToProfile) : null,
      );
    }

    // Profiles left over from when review was still in force. Publishing is
    // immediate now, so the way out of either state is simply to publish.
    if ((status == 'pending' || status == 'rejected') && missing.isEmpty) {
      final note = (e['reviewNote'] ?? '').toString();
      return _Panel(
        icon: Icons.publish_rounded,
        title: 'Ready to publish',
        message: note.isEmpty
            ? 'Your details are complete. Publish your profile to enter the hub.'
            : 'Your details are complete. Earlier note on this profile: $note',
        action: _submitting ? null : ('Publish my profile', _submit),
      );
    }

    // Gate 2 — the checklist. This is the common case.
    return _ChecklistPanel(
      missing: missing,
      submitting: _submitting,
      onSubmit: missing.isEmpty ? _submit : null,
      onEditProfile: _goToProfile,
      onEditMatrimonial: _goToMatrimonialDetails,
    );
  }

  /// Identity fields (name, dob, gender, gotra, native, occupation, photo)
  /// live on the user, so they are edited in the profile screen.
  Future<void> _goToProfile() async {
    await context.push('/profile/edit');
    if (mounted) _load(); // the checklist may have shrunk
  }

  /// The matrimonial-only fields (career, physical, family, horoscope,
  /// preferences) have their own form.
  Future<void> _goToMatrimonialDetails() async {
    await context.push('/matrimonial/edit');
    if (mounted) _load();
  }
}

/// The "what's left to fill in" view — the answer to *why* the hub is locked.
typedef _MissingField = ({String key, String label});

class _ChecklistPanel extends StatelessWidget {
  const _ChecklistPanel({
    required this.missing,
    required this.submitting,
    required this.onSubmit,
    required this.onEditProfile,
    required this.onEditMatrimonial,
  });

  final List<_MissingField> missing;
  final bool submitting;
  final VoidCallback? onSubmit;
  final VoidCallback onEditProfile;
  final VoidCallback onEditMatrimonial;

  // Which form fixes which field. These keys are the identity fields the
  // server reads off the user document; everything else lives on the
  // matrimonial profile.
  static const _userFieldKeys = {
    'name', 'dob', 'gender', 'gotra', 'native', 'occupation', 'profileUrl',
  };

  @override
  Widget build(BuildContext context) {
    final complete = missing.isEmpty;
    final fromProfile =
        missing.where((m) => _userFieldKeys.contains(m.key)).toList();
    final fromMatrimonial =
        missing.where((m) => !_userFieldKeys.contains(m.key)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [AppColors.forest800, AppColors.forest600],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.favorite_rounded,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text('Matrimonial Hub',
                      style: display(17, color: Colors.white)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                complete
                    ? 'Your profile is complete. Publish it to enter the hub.'
                    : 'Complete your profile to enter. Every field below is shown to prospective matches, so the hub stays trustworthy for everyone.',
                style: body(13, color: Colors.white70, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        if (!complete) ...[
          Row(
            children: [
              Text('STILL TO FILL',
                  style: body(11,
                      weight: FontWeight.w700,
                      color: AppColors.gold700,
                      letterSpacing: 1.6)),
              const Spacer(),
              Text('${missing.length} remaining',
                  style: body(12,
                      weight: FontWeight.w600, color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: 10),

          // Grouped by the form that fixes them, so tapping a button always
          // leads to the fields listed directly above it.
          if (fromProfile.isNotEmpty) ...[
            _groupHeading('In your profile'),
            ...fromProfile.map((m) => _row(m.label)),
            const SizedBox(height: 10),
            _button('Edit my profile', onEditProfile, filled: true),
            const SizedBox(height: 18),
          ],
          if (fromMatrimonial.isNotEmpty) ...[
            _groupHeading('In your matrimonial details'),
            ...fromMatrimonial.map((m) => _row(m.label)),
            const SizedBox(height: 10),
            _button('Add matrimonial details', onEditMatrimonial,
                filled: fromProfile.isEmpty),
          ],
        ] else ...[
          Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  size: 20, color: AppColors.forest600),
              const SizedBox(width: 8),
              Expanded(
                child: Text('All required details are filled in.',
                    style: body(14,
                        weight: FontWeight.w600, color: AppColors.forest900)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.forest800,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: submitting ? null : onSubmit,
              child: Text(
                  submitting ? 'Publishing…' : 'Publish my profile',
                  style: body(14,
                      weight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ],

        const SizedBox(height: 14),
        Text(
          'Aadhaar verification is optional — every detail can be entered by hand. Your details are visible only to other members who have completed and published their own profile, and you can withdraw yours at any time.',
          style: body(12, color: AppColors.textMuted, height: 1.4),
        ),
      ],
    );
  }

  Widget _groupHeading(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: body(13,
                weight: FontWeight.w700, color: AppColors.forest900)),
      );

  Widget _row(String label) => Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 2),
        child: Row(
          children: [
            const Icon(Icons.radio_button_unchecked,
                size: 17, color: AppColors.hint),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label, style: body(14, color: AppColors.ink)),
            ),
          ],
        ),
      );

  Widget _button(String label, VoidCallback onTap, {required bool filled}) =>
      SizedBox(
        height: 48,
        child: filled
            ? FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.forest800,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: onTap,
                child: Text(label,
                    style: body(14,
                        weight: FontWeight.w700, color: Colors.white)),
              )
            : OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.forest800),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: onTap,
                child: Text(label,
                    style: body(14,
                        weight: FontWeight.w700, color: AppColors.forest800)),
              ),
      );
}

/// A single centred message with an optional action — used for the age block,
/// the pending-review state, and load failures.
class _Panel extends StatelessWidget {
  const _Panel({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  // Named `message`, not `body`, so it doesn't shadow the theme's body() text
  // style inside this class.
  final String message;
  final (String, VoidCallback)? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 8),
      child: Column(
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.creamDark,
            ),
            child: Icon(icon, size: 30, color: AppColors.forest700),
          ),
          const SizedBox(height: 16),
          Text(title, style: display(18, color: AppColors.forest900)),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: body(14, color: AppColors.textMuted, height: 1.45),
          ),
          if (action != null) ...[
            const SizedBox(height: 20),
            SizedBox(
              height: 46,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.forest800,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 26),
                ),
                onPressed: action!.$2,
                child: Text(action!.$1,
                    style: body(14,
                        weight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
