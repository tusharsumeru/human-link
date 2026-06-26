import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';
import '../widgets/ui_kit.dart';
import 'onboarding_identity_screen.dart';

/// Onboarding step 2 — Lineage.
///
/// Ported from `src/app/onboarding/lineage/page.tsx`, adapted to the mobile
/// brief: gotra dropdown, father's & grandfather's name, branch dropdown and
/// ancestral village. Continue advances to `/onboarding/heritage`; Back
/// returns to identity.
class OnboardingLineageScreen extends StatefulWidget {
  const OnboardingLineageScreen({super.key});

  @override
  State<OnboardingLineageScreen> createState() =>
      _OnboardingLineageScreenState();
}

class _OnboardingLineageScreenState extends State<OnboardingLineageScreen> {
  static const _gotras = [
    'Kashyap',
    'Bharadwaja',
    'Vasishtha',
    'Atreya',
    'Kaundinya',
  ];
  static const _branches = [
    'Kundapura',
    'Kumta',
    'Mangaluru',
    'Bengaluru',
    'Udupi',
    'Out-of-State',
  ];

  final _father = TextEditingController();
  final _grandfather = TextEditingController();
  final _village = TextEditingController();

  String _gotra = 'Kashyap';
  String _branch = 'Kundapura';

  @override
  void dispose() {
    _father.dispose();
    _grandfather.dispose();
    _village.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            const OnboardingStepHeader(current: 2),
            const SizedBox(height: 22),
            Text('STEP 2 OF 3',
                style: body(12,
                    weight: FontWeight.w700,
                    color: AppColors.gold700,
                    letterSpacing: 1.4)),
            const SizedBox(height: 6),
            Text('Find Your Roots',
                style: display(28, color: AppColors.forest900)),
            const SizedBox(height: 8),
            Text(
              'Tell us about your parents, gotra, and ancestral village so we can link you to an existing branch in the Daivajna Samaja tree.',
              style: body(13, color: AppColors.textMuted, height: 1.5),
            ),
            const SizedBox(height: 18),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OnboardingDropdown(
                    label: 'Gotra',
                    value: _gotra,
                    items: _gotras,
                    onChanged: (v) => setState(() => _gotra = v),
                  ),
                  const SizedBox(height: 14),
                  OnboardingField(
                      label: "Father's Name",
                      controller: _father,
                      hint: 'e.g. Suresh Haldankar'),
                  const SizedBox(height: 14),
                  OnboardingField(
                      label: "Grandfather's Name",
                      controller: _grandfather,
                      hint: 'e.g. Venkatesh Haldankar'),
                  const SizedBox(height: 14),
                  OnboardingDropdown(
                    label: 'Branch',
                    value: _branch,
                    items: _branches,
                    onChanged: (v) => setState(() => _branch = v),
                  ),
                  const SizedBox(height: 14),
                  OnboardingField(
                      label: 'Ancestral Village',
                      controller: _village,
                      hint: 'e.g. Gokarna, Uttara Kannada'),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.forest600.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AppColors.forest300.withValues(alpha: 0.6)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_tree_outlined,
                      size: 18, color: AppColors.forest700),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'To complete your lineage integrity, you will later nominate 3 verified members who can vouch for your connection.',
                      style: body(12, color: AppColors.forest800, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                OutlineButtonX(
                  label: 'Back',
                  onPressed: () => context.go('/onboarding/identity'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ForestButton(
                    label: 'Continue to Heritage',
                    icon: Icons.arrow_forward,
                    expand: true,
                    onPressed: () => context.go('/onboarding/heritage'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
