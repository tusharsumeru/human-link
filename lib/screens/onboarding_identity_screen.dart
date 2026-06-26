import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';
import '../widgets/ui_kit.dart';

/// Onboarding step 1 — Identity.
///
/// Ported from `src/app/onboarding/identity/page.tsx`, adapted to the mobile
/// brief: collects name, phone, gender, date of birth, native place and
/// current city. A 3-dot step header ("Step 1 of 3") sits above. Continue
/// advances to `/onboarding/lineage`.
class OnboardingIdentityScreen extends StatefulWidget {
  const OnboardingIdentityScreen({super.key});

  @override
  State<OnboardingIdentityScreen> createState() =>
      _OnboardingIdentityScreenState();
}

class _OnboardingIdentityScreenState extends State<OnboardingIdentityScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _native = TextEditingController();
  final _city = TextEditingController();

  String _gender = 'Female';
  DateTime? _dob;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _native.dispose();
    _city.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(1995),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _dob = picked);
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
              'To maintain the sanctity of our ancestral records, tell us who you are. Your data is end-to-end encrypted and never shared with other members.',
              style: body(13, color: AppColors.textMuted, height: 1.5),
            ),
            const SizedBox(height: 18),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OnboardingField(
                      label: 'Full Name',
                      controller: _name,
                      hint: 'e.g. Priya Haldankar'),
                  const SizedBox(height: 14),
                  OnboardingField(
                      label: 'Phone Number',
                      controller: _phone,
                      hint: '+91 98765 43210',
                      keyboardType: TextInputType.phone),
                  const SizedBox(height: 14),
                  _genderField(),
                  const SizedBox(height: 14),
                  _dobField(),
                  const SizedBox(height: 14),
                  OnboardingField(
                      label: 'Native Place',
                      controller: _native,
                      hint: 'e.g. Kundapura, Karnataka'),
                  const SizedBox(height: 14),
                  OnboardingField(
                      label: 'Current City',
                      controller: _city,
                      hint: 'e.g. Bengaluru'),
                ],
              ),
            ),
            const SizedBox(height: 18),
            ForestButton(
              label: 'Continue to Lineage',
              icon: Icons.arrow_forward,
              expand: true,
              onPressed: () => context.go('/onboarding/lineage'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _genderField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Gender',
            style: body(12, weight: FontWeight.w600, color: AppColors.forest800)),
        const SizedBox(height: 6),
        Row(
          children: [
            for (final g in const ['Female', 'Male', 'Other'])
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(g),
                  selected: _gender == g,
                  onSelected: (_) => setState(() => _gender = g),
                  labelStyle: body(12,
                      weight: FontWeight.w600,
                      color: _gender == g
                          ? Colors.white
                          : AppColors.forest800),
                  selectedColor: AppColors.forest800,
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: AppColors.border),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _dobField() {
    final label = _dob == null
        ? 'Select date of birth'
        : '${_dob!.day.toString().padLeft(2, '0')}/${_dob!.month.toString().padLeft(2, '0')}/${_dob!.year}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Date of Birth',
            style: body(12, weight: FontWeight.w600, color: AppColors.forest800)),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: _pickDob,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 16, color: AppColors.gold700),
                const SizedBox(width: 10),
                Text(label,
                    style: body(14,
                        color: _dob == null ? AppColors.hint : AppColors.ink)),
              ],
            ),
          ),
        ),
      ],
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
