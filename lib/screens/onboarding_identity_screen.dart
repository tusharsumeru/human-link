import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../data/repository.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/digilocker_card.dart';
import '../widgets/ui_kit.dart';

/// Onboarding step 1 — Identity.
///
/// Real Aadhaar verification via Surepass: enter the Aadhaar number → an OTP is
/// sent to the Aadhaar-linked mobile → submit the OTP to verify. Plus a selfie.
/// Continue advances to `/onboarding/lineage`.
class OnboardingIdentityScreen extends StatefulWidget {
  const OnboardingIdentityScreen({super.key});

  @override
  State<OnboardingIdentityScreen> createState() =>
      _OnboardingIdentityScreenState();
}

class _OnboardingIdentityScreenState extends State<OnboardingIdentityScreen> {
  final _picker = ImagePicker();

  XFile? _selfie;
  bool _saving = false;

  Future<void> _takeSelfie() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 1200,
        imageQuality: 85,
      );
      if (picked != null && mounted) setState(() => _selfie = picked);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not capture image: $e')),
      );
    }
  }

  /// Uploads the selfie, saves it as the profile photo, advances to lineage.
  Future<void> _continue() async {
    final auth = context.read<AuthService>();
    final user = auth.user;
    setState(() => _saving = true);
    String? photoUrl;
    if (user != null) {
      if (_selfie != null) {
        final bytes = await File(_selfie!.path).readAsBytes();
        photoUrl = await Repository.instance
            .uploadImage(phone: user.phone, type: 'selfie', bytes: bytes);
      }
      await auth.updateUser(user.copyWith(
        photoPath: _selfie?.path,
        photoUrl: photoUrl,
      ));
    }
    if (!mounted) return;
    setState(() => _saving = false);
    context.go('/onboarding/lineage');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            const OnboardingStepHeader(current: 1),
            const SizedBox(height: 22),
            Text('STEP 1 OF 3',
                style: body(12,
                    weight: FontWeight.w700,
                    color: AppColors.gold700,
                    letterSpacing: 1.4)),
            const SizedBox(height: 6),
            Text('Verify Your Identity',
                style: display(28, color: AppColors.forest900)),
            const SizedBox(height: 8),
            Text(
              'Verify your Aadhaar to maintain the sanctity of our ancestral '
              'records. An OTP will be sent to your Aadhaar-linked mobile. Your '
              'data is encrypted and never shared with other members.',
              style: body(13, color: AppColors.textMuted, height: 1.5),
            ),
            const SizedBox(height: 18),
            const AppCard(
              child: DigilockerCard(
                description:
                    'Verify your Aadhaar securely through the government '
                    'DigiLocker. You\'ll sign in to DigiLocker and consent to '
                    'share your Aadhaar.',
              ),
            ),
            const SizedBox(height: 14),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Selfie Verification',
                      style: body(12,
                          weight: FontWeight.w600,
                          color: AppColors.forest800)),
                  const SizedBox(height: 6),
                  _selfieTile(),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _trustPanel(),
            const SizedBox(height: 18),
            ForestButton(
              label: 'Continue to Lineage',
              icon: Icons.arrow_forward,
              expand: true,
              loading: _saving,
              onPressed: _saving ? null : _continue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _selfieTile() {
    final done = _selfie != null;
    return GestureDetector(
      onTap: _takeSelfie,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color:
              done ? AppColors.forest600.withValues(alpha: 0.08) : Colors.white,
          border: Border.all(
            color: done ? AppColors.forest600 : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              clipBehavior: Clip.antiAlias,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFF0FBF4),
              ),
              child: done
                  ? Image.file(File(_selfie!.path), fit: BoxFit.cover)
                  : const Icon(Icons.camera_alt_outlined,
                      size: 24, color: AppColors.gold700),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      done
                          ? 'Selfie captured successfully'
                          : 'Take a selfie to match your ID photo',
                      style: body(13,
                          weight: FontWeight.w600, color: AppColors.ink)),
                  if (!done) ...[
                    const SizedBox(height: 2),
                    Text('Open Camera',
                        style: body(11,
                            weight: FontWeight.w600,
                            color: AppColors.forest700)),
                  ],
                ],
              ),
            ),
            if (done)
              const Icon(Icons.check_circle,
                  size: 20, color: AppColors.forest700),
          ],
        ),
      ),
    );
  }

  Widget _trustPanel() {
    const items = [
      (Icons.lock_outline, 'AES-256 end-to-end encryption'),
      (Icons.visibility_off_outlined, 'Never shared with other members'),
      (Icons.verified_user_outlined, 'Archival-grade secure vault'),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppGradients.deepForest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_outlined,
                  size: 16, color: AppColors.gold500),
              const SizedBox(width: 8),
              Text('Trust & Security',
                  style: body(13,
                      weight: FontWeight.w700, color: AppColors.gold500)),
            ],
          ),
          const SizedBox(height: 12),
          for (final (icon, text) in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(icon, size: 14, color: AppColors.forest500),
                  const SizedBox(width: 8),
                  Expanded(
                    child:
                        Text(text, style: body(12, color: AppColors.forest300)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

}

/// Shared 3-dot step progress header used by the onboarding flow.
class OnboardingStepHeader extends StatelessWidget {
  const OnboardingStepHeader({super.key, required this.current});

  /// 1-based current step (1..3).
  final int current;

  static const _labels = ['Identity', 'Lineage', 'Heritage'];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            for (int i = 0; i < 3; i++) ...[
              _dot(i + 1),
              if (i < 2) Expanded(child: _connector(i + 1)),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (int i = 0; i < 3; i++)
              Text(_labels[i],
                  style: body(11,
                      weight: (i + 1) == current
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: (i + 1) == current
                          ? AppColors.forest800
                          : AppColors.textMuted)),
          ],
        ),
      ],
    );
  }

  Widget _dot(int step) {
    final done = step < current;
    final active = step == current;
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: active ? AppGradients.forest : null,
        color: done
            ? AppColors.forest600
            : (active ? null : AppColors.creamDark),
      ),
      child: done
          ? const Icon(Icons.check, size: 16, color: Colors.white)
          : Text('$step',
              style: body(13,
                  weight: FontWeight.w700,
                  color: active ? Colors.white : AppColors.hint)),
    );
  }

  Widget _connector(int afterStep) {
    final filled = afterStep < current;
    return Container(
      height: 3,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: filled ? AppColors.forest700 : AppColors.creamDark,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

/// Shared labelled text field used across onboarding steps.
class OnboardingField extends StatelessWidget {
  const OnboardingField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.keyboardType,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboardType;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: body(12,
                weight: FontWeight.w600, color: AppColors.forest800)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
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
              borderSide:
                  const BorderSide(color: AppColors.forest700, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

/// Shared labelled dropdown used across onboarding steps.
class OnboardingDropdown extends StatelessWidget {
  const OnboardingDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: body(12,
                weight: FontWeight.w600, color: AppColors.forest800)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down,
                  color: AppColors.forest700),
              style: body(14, color: AppColors.ink),
              items: [
                for (final it in items)
                  DropdownMenuItem(value: it, child: Text(it)),
              ],
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ),
      ],
    );
  }
}
