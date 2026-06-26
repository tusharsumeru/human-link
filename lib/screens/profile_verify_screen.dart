import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';
import '../widgets/ui_kit.dart';

/// Identity verification — a 3-step flow (Aadhaar → Peer Vouch → Elder
/// Approval) shown as a vertical stepper with a progress indicator.
///
/// Inspired by `src/app/profile/verify/page.tsx` (the web "Verify & Update"
/// security flow) but reframed per the mobile brief into the Samaj's actual
/// 3-stage onboarding verification. All actions are mocked client-side.
class ProfileVerifyScreen extends StatefulWidget {
  const ProfileVerifyScreen({super.key});

  @override
  State<ProfileVerifyScreen> createState() => _ProfileVerifyScreenState();
}

class _ProfileVerifyScreenState extends State<ProfileVerifyScreen> {
  final _aadhaarCtrl = TextEditingController();

  bool _aadhaarVerified = false;
  bool _docUploaded = false;

  // Three peer-vouch slots; each becomes 'Requested' when invited.
  final List<_Vouch> _vouches = [
    _Vouch('Shri Narayanarao Suvarna', 'Elder, Kumta Branch'),
    _Vouch('Gopalakrishna Suvarna', 'Member, Kundapura Branch'),
    _Vouch('Invite a peer to vouch', '3rd vouch required'),
  ];

  @override
  void dispose() {
    _aadhaarCtrl.dispose();
    super.dispose();
  }

  bool get _step1Done => _aadhaarVerified && _docUploaded;
  int get _vouchCount => _vouches.where((v) => v.requested).length;
  bool get _step2Done => _vouchCount >= 3;
  // Elder approval is always pending until submission.
  int get _completed => (_step1Done ? 1 : 0) + (_step2Done ? 1 : 0);

  void _verifyAadhaar() {
    final digits = _aadhaarCtrl.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 12) {
      setState(() => _aadhaarVerified = true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Enter a valid 12-digit Aadhaar number'),
      ));
    }
  }

  void _submit() {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  gradient: AppGradients.forest,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 38),
              ),
              const SizedBox(height: 18),
              Text('Submitted for Verification',
                  textAlign: TextAlign.center,
                  style: display(20, color: AppColors.forest900)),
              const SizedBox(height: 8),
              Text(
                'Your identity has been submitted. The Elder committee has been notified and will review your lineage shortly.',
                textAlign: TextAlign.center,
                style: body(13, color: AppColors.textMuted, height: 1.5),
              ),
              const SizedBox(height: 20),
              ForestButton(
                label: 'Back to Dashboard',
                expand: true,
                onPressed: () {
                  Navigator.of(ctx).pop();
                  context.go('/dashboard');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.forest800,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/dashboard');
            }
          },
        ),
        title: Text('Verify Identity',
            style: display(18, color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
        children: [
          Text('Identity Verification',
              style: display(24, color: AppColors.forest900)),
          const SizedBox(height: 6),
          Text(
            'Complete the three stages below to verify your place in the Daivajna Samaja lineage tree.',
            style: body(13, color: AppColors.textMuted, height: 1.5),
          ),
          const SizedBox(height: 16),
          _progress(),
          const SizedBox(height: 20),
          _stepCard(
            index: 1,
            title: 'Aadhaar Verification',
            done: _step1Done,
            child: _aadhaarStep(),
          ),
          const SizedBox(height: 14),
          _stepCard(
            index: 2,
            title: 'Peer Vouch',
            done: _step2Done,
            child: _vouchStep(),
          ),
          const SizedBox(height: 14),
          _stepCard(
            index: 3,
            title: 'Elder Approval',
            done: false,
            pending: true,
            child: _elderStep(),
          ),
          const SizedBox(height: 24),
          ForestButton(
            label: 'Submit for Verification',
            icon: Icons.shield_outlined,
            expand: true,
            onPressed: _submit,
          ),
          const SizedBox(height: 16),
          Text(
            'Your documents are AES-256 encrypted and only visible to the Elder verification committee.',
            textAlign: TextAlign.center,
            style: body(11, color: AppColors.hint, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _progress() {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ProgressBar(value: _completed / 3, height: 8),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$_completed of 3 stages complete',
                  style: body(12,
                      weight: FontWeight.w600, color: AppColors.forest800)),
              Text('Elder approval pending',
                  style: body(11, color: AppColors.gold700)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stepCard({
    required int index,
    required String title,
    required bool done,
    bool pending = false,
    required Widget child,
  }) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: done ? AppGradients.forest : null,
                  color: done
                      ? null
                      : (pending
                          ? AppColors.gold500.withValues(alpha: 0.18)
                          : AppColors.creamDark),
                ),
                child: done
                    ? const Icon(Icons.check, size: 18, color: Colors.white)
                    : Text('$index',
                        style: body(13,
                            weight: FontWeight.w700,
                            color: pending
                                ? AppColors.gold700
                                : AppColors.forest800)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title,
                    style: display(16, color: AppColors.forest900)),
              ),
              if (done)
                Pill('Verified',
                    icon: Icons.check_circle,
                    bg: AppColors.forest600.withValues(alpha: 0.14),
                    fg: AppColors.forest700)
              else if (pending)
                Pill('Pending', fg: AppColors.gold700),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _aadhaarStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Aadhaar Number',
            style: body(12, weight: FontWeight.w600, color: AppColors.forest800)),
        const SizedBox(height: 6),
        TextField(
          controller: _aadhaarCtrl,
          enabled: !_aadhaarVerified,
          keyboardType: TextInputType.number,
          maxLength: 14,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')),
          ],
          decoration: _fieldDecoration('1234 5678 9012'),
          onSubmitted: (_) => _verifyAadhaar(),
        ),
        const SizedBox(height: 4),
        if (!_aadhaarVerified)
          Align(
            alignment: Alignment.centerLeft,
            child: OutlineButtonX(
              label: 'Verify Aadhaar',
              onPressed: _verifyAadhaar,
            ),
          )
        else
          Row(
            children: [
              const Icon(Icons.check_circle,
                  size: 16, color: AppColors.forest700),
              const SizedBox(width: 6),
              Text('Aadhaar number verified',
                  style: body(12,
                      weight: FontWeight.w600, color: AppColors.forest700)),
            ],
          ),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: () => setState(() => _docUploaded = true),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: _docUploaded
                  ? AppColors.forest600.withValues(alpha: 0.08)
                  : Colors.white,
              border: Border.all(
                color: _docUploaded ? AppColors.forest600 : AppColors.border,
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  _docUploaded ? Icons.check_circle : Icons.upload_file,
                  size: 30,
                  color: _docUploaded
                      ? AppColors.forest700
                      : AppColors.gold700,
                ),
                const SizedBox(height: 8),
                Text(
                  _docUploaded
                      ? 'aadhaar_document.pdf · Uploaded'
                      : 'Upload Aadhaar (PDF / JPG)',
                  style: body(13,
                      weight: FontWeight.w600,
                      color: _docUploaded
                          ? AppColors.forest700
                          : AppColors.label),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _vouchStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$_vouchCount of 3 peers have vouched for you.',
            style: body(12, color: AppColors.textMuted)),
        const SizedBox(height: 12),
        for (int i = 0; i < _vouches.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _vouchTile(i),
        ],
      ],
    );
  }

  Widget _vouchTile(int i) {
    final v = _vouches[i];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: v.requested ? AppColors.forest300 : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.forest700,
            child: Text(_initials(v.name),
                style: body(12, weight: FontWeight.w700, color: Colors.white)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(v.name,
                    style: body(13,
                        weight: FontWeight.w600, color: AppColors.ink)),
                Text(v.role, style: body(11, color: AppColors.textMuted)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => v.requested = !v.requested),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: v.requested
                    ? AppColors.forest600.withValues(alpha: 0.14)
                    : Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color:
                      v.requested ? AppColors.forest600 : AppColors.forest800,
                ),
              ),
              child: Text(
                v.requested ? '✓ Requested' : 'Invite',
                style: body(11,
                    weight: FontWeight.w700,
                    color: v.requested
                        ? AppColors.forest700
                        : AppColors.forest800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _elderStep() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.gold500.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.goldSoft),
      ),
      child: Row(
        children: [
          const Icon(Icons.hourglass_bottom,
              size: 20, color: AppColors.gold700),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Awaiting Elder committee approval. Once your Aadhaar and peer vouches are submitted, an elder will review and approve your lineage.',
              style: body(12, color: AppColors.gold700, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint) => InputDecoration(
        hintText: hint,
        counterText: '',
        hintStyle: body(14, color: AppColors.hint),
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
          borderSide: const BorderSide(color: AppColors.forest700, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
      );

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}

class _Vouch {
  _Vouch(this.name, this.role);
  final String name;
  final String role;
  bool requested = false;
}
