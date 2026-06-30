import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../data/repository.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/place_field.dart';
import '../widgets/ui_kit.dart';
import 'onboarding_identity_screen.dart';

/// Onboarding step 3 — Heritage.
///
/// Ported from `src/app/onboarding/heritage/page.tsx` — "Cultural Profile &
/// Heritage": Gotra, Native Place, Professional Bio, matrimonial opt-in and an
/// optional family-documents upload. Complete saves the profile and routes to
/// the dashboard; Back returns to lineage.
class OnboardingHeritageScreen extends StatefulWidget {
  const OnboardingHeritageScreen({super.key});

  @override
  State<OnboardingHeritageScreen> createState() =>
      _OnboardingHeritageScreenState();
}

class _OnboardingHeritageScreenState extends State<OnboardingHeritageScreen> {
  final _gotra = TextEditingController(text: 'Kashyap');
  final _native = TextEditingController(text: 'Udupi, Karnataka');
  final _bio = TextEditingController();
  final _picker = ImagePicker();

  XFile? _document;
  bool _matrimonial = false;
  bool _saving = false;
  bool _initialised = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialised) {
      final user = context.read<AuthService>().user;
      if (user != null) {
        if (user.gotra.isNotEmpty) _gotra.text = user.gotra;
        if (user.native.isNotEmpty) _native.text = user.native;
      }
      _initialised = true;
    }
  }

  @override
  void dispose() {
    _gotra.dispose();
    _native.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _pickDocument() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (picked != null && mounted) setState(() => _document = picked);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not pick file: $e')),
      );
    }
  }

  Future<void> _complete() async {
    setState(() => _saving = true);
    final auth = context.read<AuthService>();
    final current = auth.user;
    if (current != null) {
      final gotra =
          _gotra.text.trim().isEmpty ? current.gotra : _gotra.text.trim();
      final native =
          _native.text.trim().isEmpty ? current.native : _native.text.trim();
      final bio = _bio.text.trim();

      // Upload the optional family document (best-effort).
      if (_document != null) {
        final bytes = await File(_document!.path).readAsBytes();
        await Repository.instance
            .uploadImage(phone: current.phone, type: 'familyDoc', bytes: bytes);
      }

      // Save to the backend (best-effort).
      await Repository.instance.updateProfile(
        phone: current.phone,
        gotra: gotra,
        native: native,
        bio: bio,
        matrimonialOptIn: _matrimonial,
      );

      // Persist locally so it shows immediately on the profile, and mark
      // onboarding complete so the router stops redirecting here.
      await auth.updateUser(current.copyWith(
        gotra: gotra,
        native: native,
        bio: bio,
        matrimonialOptIn: _matrimonial,
        onboardingComplete: true,
      ));
    }
    if (!mounted) return;
    context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            const OnboardingStepHeader(current: 3),
            const SizedBox(height: 22),
            Text('STEP 3 OF 3',
                style: body(12,
                    weight: FontWeight.w700,
                    color: AppColors.gold700,
                    letterSpacing: 1.4)),
            const SizedBox(height: 6),
            Text('Cultural Profile & Heritage',
                style: display(28, color: AppColors.forest900)),
            const SizedBox(height: 8),
            Text(
              'The final step to documenting your legacy within the Daivajna '
              'community.',
              style: body(13, color: AppColors.textMuted, height: 1.5),
            ),
            const SizedBox(height: 18),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OnboardingField(
                      label: 'Gotra', controller: _gotra, hint: 'e.g. Kashyap'),
                  const SizedBox(height: 14),
                  PlaceField(
                      label: 'Native Place (Kula Devata Location)',
                      controller: _native,
                      hint: 'e.g. Gokarna'),
                  const SizedBox(height: 14),
                  OnboardingField(
                    label: 'Professional Bio',
                    controller: _bio,
                    hint: 'Tell the community about your work and skills.',
                    maxLines: 4,
                  ),
                  const SizedBox(height: 14),
                  _matrimonialTile(),
                  const SizedBox(height: 14),
                  Text(
                    'Optional: Upload Family Documents (birth certificate, old '
                    'letters or heirlooms — JPG / PNG)',
                    style: body(11, color: AppColors.textMuted, height: 1.4),
                  ),
                  const SizedBox(height: 6),
                  _document == null ? _uploadPrompt() : _documentPreview(),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _welcomePanel(),
            const SizedBox(height: 18),
            Row(
              children: [
                OutlineButtonX(
                  label: 'Back to Lineage',
                  onPressed: () => context.go('/onboarding/lineage'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ForestButton(
                    label: 'Complete Profile ✓',
                    expand: true,
                    loading: _saving,
                    onPressed: _saving ? null : _complete,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _matrimonialTile() {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => setState(() => _matrimonial = !_matrimonial),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 22,
              height: 22,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: _matrimonial ? AppColors.forest700 : Colors.white,
                border: Border.all(
                  color: _matrimonial ? AppColors.forest700 : AppColors.border,
                  width: 1.5,
                ),
              ),
              child: _matrimonial
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Opt-in to Matrimonial Hub',
                      style: body(13,
                          weight: FontWeight.w600, color: AppColors.ink)),
                  const SizedBox(height: 2),
                  Text(
                    'Make your profile discoverable to families seeking '
                    'matrimonial connections within the Samaj. You can change '
                    'this preference anytime.',
                    style: body(11, color: AppColors.textMuted, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _uploadPrompt() {
    return GestureDetector(
      onTap: _pickDocument,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.white,
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Column(
          children: [
            const Icon(Icons.upload_file, size: 28, color: AppColors.gold700),
            const SizedBox(height: 8),
            Text('Click to upload family documents',
                style: body(12, color: AppColors.label)),
          ],
        ),
      ),
    );
  }

  Widget _documentPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.file(File(_document!.path),
              height: 150, width: double.infinity, fit: BoxFit.cover),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.check_circle, size: 16, color: AppColors.forest700),
            const SizedBox(width: 6),
            Expanded(
              child: Text(_document!.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: body(12,
                      weight: FontWeight.w600, color: AppColors.forest700)),
            ),
            TextButton(
              onPressed: _pickDocument,
              child: Text('Change',
                  style: body(13,
                      weight: FontWeight.w700, color: AppColors.gold700)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _welcomePanel() {
    const benefits = [
      'Access to the Global Lineage Directory',
      'Participation in Samaja Governance',
      'Community Welfare Program Eligibility',
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
          Text('Welcome to the Samaj',
              style: body(12,
                  weight: FontWeight.w700, color: AppColors.forest300)),
          const SizedBox(height: 6),
          Text(
            'By completing this step, you become a verified member in our '
            'living digital tree. You help maintain the cultural integrity and '
            'social fabric of the Daivajna community.',
            style: body(13, color: Colors.white, height: 1.5),
          ),
          const SizedBox(height: 12),
          for (final b in benefits)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.check_circle,
                      size: 15, color: AppColors.forest500),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(b,
                        style: body(12, color: AppColors.forest300)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
