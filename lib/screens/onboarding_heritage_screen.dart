import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';
import '../widgets/ui_kit.dart';
import 'onboarding_identity_screen.dart';

/// Onboarding step 3 — Heritage.
///
/// Ported from `src/app/onboarding/heritage/page.tsx`, adapted to the mobile
/// brief: family occupation / heritage notes, a mock family-photo upload and an
/// "I agree to Samaj heritage guidelines" checkbox. Complete shows a success
/// dialog then routes to `/dashboard`; Back returns to lineage.
class OnboardingHeritageScreen extends StatefulWidget {
  const OnboardingHeritageScreen({super.key});

  @override
  State<OnboardingHeritageScreen> createState() =>
      _OnboardingHeritageScreenState();
}

class _OnboardingHeritageScreenState extends State<OnboardingHeritageScreen> {
  final _heritage = TextEditingController();

  bool _photoUploaded = false;
  bool _matrimonial = false;
  bool _agreed = false;

  @override
  void dispose() {
    _heritage.dispose();
    super.dispose();
  }

  void _complete() {
    if (!_agreed) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please agree to the Samaj heritage guidelines'),
      ));
      return;
    }
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
              Text('Welcome to the Samaj',
                  textAlign: TextAlign.center,
                  style: display(20, color: AppColors.forest900)),
              const SizedBox(height: 8),
              Text(
                'Your profile is complete. You are now a verified member of our living digital tree.',
                textAlign: TextAlign.center,
                style: body(13, color: AppColors.textMuted, height: 1.5),
              ),
              const SizedBox(height: 20),
              ForestButton(
                label: 'Enter Portal',
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
              'The final step to documenting your legacy within the Daivajna community.',
              style: body(13, color: AppColors.textMuted, height: 1.5),
            ),
            const SizedBox(height: 18),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OnboardingField(
                    label: 'Family Occupation & Heritage Notes',
                    controller: _heritage,
                    hint:
                        'Tell the community about your family\'s craft, work and traditions.',
                    maxLines: 4,
                  ),
                  const SizedBox(height: 16),
                  Text('Family Photo',
                      style: body(12,
                          weight: FontWeight.w600,
                          color: AppColors.forest800)),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () => setState(() => _photoUploaded = true),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 22),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: _photoUploaded
                            ? AppColors.forest600.withValues(alpha: 0.08)
                            : Colors.white,
                        border: Border.all(
                          color: _photoUploaded
                              ? AppColors.forest600
                              : AppColors.border,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            _photoUploaded
                                ? Icons.check_circle
                                : Icons.add_a_photo_outlined,
                            size: 30,
                            color: _photoUploaded
                                ? AppColors.forest700
                                : AppColors.gold700,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _photoUploaded
                                ? 'family_photo.jpg · Uploaded'
                                : 'Upload a family photo',
                            style: body(13,
                                weight: FontWeight.w600,
                                color: _photoUploaded
                                    ? AppColors.forest700
                                    : AppColors.label),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _checkTile(
                    value: _matrimonial,
                    onTap: () => setState(() => _matrimonial = !_matrimonial),
                    title: 'Opt-in to Matrimonial Hub',
                    subtitle:
                        'Make your profile discoverable to families seeking matrimonial connections. You can change this anytime.',
                  ),
                  const SizedBox(height: 4),
                  _checkTile(
                    value: _agreed,
                    onTap: () => setState(() => _agreed = !_agreed),
                    title: 'I agree to Samaj heritage guidelines',
                    subtitle:
                        'I confirm the information provided is accurate and consent to elder verification of my lineage.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                OutlineButtonX(
                  label: 'Back',
                  onPressed: () => context.go('/onboarding/lineage'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ForestButton(
                    label: 'Complete & Enter Portal',
                    icon: Icons.check,
                    expand: true,
                    onPressed: _complete,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _checkTile({
    required bool value,
    required VoidCallback onTap,
    required String title,
    required String subtitle,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 22,
              height: 22,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: value ? AppColors.forest700 : Colors.white,
                border: Border.all(
                  color: value ? AppColors.forest700 : AppColors.border,
                  width: 1.5,
                ),
              ),
              child: value
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: body(13,
                          weight: FontWeight.w600, color: AppColors.ink)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: body(11,
                          color: AppColors.textMuted, height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
