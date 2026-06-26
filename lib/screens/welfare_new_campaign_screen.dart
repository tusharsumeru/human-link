import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';
import '../widgets/ui_kit.dart';

/// Launch-a-campaign form — ported from
/// `src/app/welfare/campaign/new/page.tsx`. Single-screen form (the web
/// 3-step wizard is flattened into one scrolling form on mobile).
class NewCampaignScreen extends StatefulWidget {
  const NewCampaignScreen({super.key});

  @override
  State<NewCampaignScreen> createState() => _NewCampaignScreenState();
}

class _NewCampaignScreenState extends State<NewCampaignScreen> {
  static const _categories = [
    'Infrastructure',
    'Cultural Heritage',
    'Education',
    'Emergency',
    'Healthcare',
  ];
  static const _emojis = ['🏛️', '🪔', '🎓', '❤️', '🏥'];

  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _goalCtrl = TextEditingController();

  String _category = 'Infrastructure';
  double _duration = 30;
  String _emoji = '🏛️';

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _goalCtrl.dispose();
    super.dispose();
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/welfare');
    }
  }

  void _submit() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                  gradient: AppGradients.forest, shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded,
                  color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Campaign Submitted!',
                  style: display(20, color: AppColors.forest900)),
            ),
          ],
        ),
        content: Text(
          'Your campaign will be reviewed by the Elder Committee. You’ll receive a notification within 48 hours.',
          style: body(14, color: AppColors.textMuted, height: 1.5),
        ),
        actions: [
          ForestButton(
            label: 'Back to Welfare',
            onPressed: () {
              Navigator.of(ctx).pop();
              context.go('/welfare');
            },
          ),
        ],
      ),
    );
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: _back,
        ),
        title: Text('Launch a New Campaign',
            style: display(18, color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // Transparency note.
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFCD34D)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ℹ️', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('A Note on Transparency',
                          style: body(13,
                              weight: FontWeight.w700,
                              color: const Color(0xFF92400E))),
                      const SizedBox(height: 4),
                      Text(
                          'Each campaign is vetted by the Elder sub-committee to ensure heritage alignment and financial integrity.',
                          style: body(12,
                              color: const Color(0xFFB45309), height: 1.5)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          _label('Campaign Title'),
          const SizedBox(height: 8),
          TextField(
            controller: _titleCtrl,
            decoration:
                _dec('e.g. Restoration of Heritage Library'),
          ),
          const SizedBox(height: 16),

          _label('Category'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: _dec(''),
            items: [
              for (final c in _categories)
                DropdownMenuItem(
                    value: c,
                    child: Text(c, style: body(14, color: AppColors.label))),
            ],
            onChanged: (v) => setState(() => _category = v ?? _category),
          ),
          const SizedBox(height: 16),

          _label('Campaign Story'),
          const SizedBox(height: 8),
          TextField(
            controller: _descCtrl,
            maxLines: 4,
            decoration: _dec(
                'Describe the history, the need, and the impact on our community…'),
          ),
          const SizedBox(height: 16),

          _label('Fundraising Goal (₹)'),
          const SizedBox(height: 8),
          TextField(
            controller: _goalCtrl,
            keyboardType: TextInputType.number,
            decoration: _dec('e.g. 500000'),
          ),
          const SizedBox(height: 16),

          _label('Duration'),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _duration,
                  min: 7,
                  max: 90,
                  divisions: 83,
                  activeColor: AppColors.forest700,
                  inactiveColor: AppColors.border,
                  label: '${_duration.round()} days',
                  onChanged: (v) => setState(() => _duration = v),
                ),
              ),
              const SizedBox(width: 8),
              Text('${_duration.round()} days',
                  style: body(13,
                      weight: FontWeight.w700, color: AppColors.forest800)),
            ],
          ),
          const SizedBox(height: 12),

          _label('Choose an Icon'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final e in _emojis)
                _EmojiChip(
                  emoji: e,
                  selected: _emoji == e,
                  onTap: () => setState(() => _emoji = e),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Verification checklist.
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.forest500.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: AppColors.forest500.withValues(alpha: 0.35)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Verification Checklist',
                    style: body(13,
                        weight: FontWeight.w700,
                        color: AppColors.forest800)),
                const SizedBox(height: 8),
                for (final item in const [
                  'Campaign is for community benefit',
                  'Funds will be managed by committee',
                  'Monthly progress reports will be shared',
                  'Elder sub-committee has been informed',
                ]) ...[
                  Row(
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          size: 15, color: AppColors.forest700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(item,
                            style: body(12, color: AppColors.forest800)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ForestButton(
              label: 'Submit for Review',
              icon: Icons.check_rounded,
              expand: true,
              onPressed: _submit,
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: body(13, weight: FontWeight.w600, color: AppColors.label));

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: body(14, color: AppColors.hint),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.forest700, width: 1.5),
        ),
      );
}

class _EmojiChip extends StatelessWidget {
  const _EmojiChip(
      {required this.emoji, required this.selected, required this.onTap});
  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? AppColors.forest500.withValues(alpha: 0.14)
                : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: selected ? AppColors.forest800 : AppColors.border,
                width: selected ? 2 : 1),
          ),
          child: Text(emoji, style: const TextStyle(fontSize: 26)),
        ),
      ),
    );
  }
}
