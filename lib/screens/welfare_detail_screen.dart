import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/repository.dart';
import '../theme/app_theme.dart';
import '../widgets/ui_kit.dart';

/// Make-a-contribution flow — ported from
/// `src/app/welfare/donate/[id]/page.tsx`.
class WelfareDonateScreen extends StatefulWidget {
  const WelfareDonateScreen({super.key, required this.id});

  final String id;

  @override
  State<WelfareDonateScreen> createState() => _WelfareDonateScreenState();
}

class _WelfareDonateScreenState extends State<WelfareDonateScreen> {
  static const _presets = [501, 1100, 2500, 5100, 11000];

  int _amount = 2500;
  final _customCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _anonymous = false;
  String _payMethod = 'upi';

  @override
  void dispose() {
    _customCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  int get _finalAmount {
    final custom = int.tryParse(_customCtrl.text.trim());
    if (custom != null && custom > 0) return custom;
    return _amount;
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/welfare');
    }
  }

  void _submit(Map<String, dynamic> campaign) {
    final title = campaign['title'] as String;
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
              child: Text('Dhanyavaad! 🙏',
                  style: display(20, color: AppColors.forest900)),
            ),
          ],
        ),
        content: Text(
          'Thank you! Your contribution to $title is received.',
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
    final campaign = Repository.instance.welfareById(widget.id);

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
        title:
            Text('Make a Contribution', style: display(18, color: Colors.white)),
      ),
      body: campaign == null ? _notFound() : _form(campaign),
    );
  }

  Widget _notFound() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off_rounded, size: 36, color: AppColors.hint),
          const SizedBox(height: 12),
          Text('Campaign not found',
              style: body(15, weight: FontWeight.w600, color: AppColors.hint)),
          const SizedBox(height: 14),
          ForestButton(
            label: 'Back to Welfare',
            onPressed: () => context.go('/welfare'),
          ),
        ],
      ),
    );
  }

  Widget _form(Map<String, dynamic> c) {
    final raised = c['raised'] as int;
    final goal = c['goal'] as int;
    final pct = goal == 0 ? 0 : ((raised / goal) * 100).round();

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
          children: [
            // Campaign header card.
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 140,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(c['colorA'] as int),
                          Color(c['colorB'] as int),
                        ],
                      ),
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(18)),
                    ),
                    child: Center(
                      child: Text(c['image'] as String,
                          style: const TextStyle(fontSize: 56)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Pill(c['category'] as String),
                        const SizedBox(height: 10),
                        Text(c['title'] as String,
                            style: display(18, color: AppColors.forest900)),
                        const SizedBox(height: 8),
                        Text(c['description'] as String,
                            style: body(13,
                                color: AppColors.textMuted, height: 1.5)),
                        const SizedBox(height: 14),
                        ProgressBar(
                            value: goal == 0 ? 0 : raised / goal, height: 8),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text('${formatLakh(raised)} raised',
                                style: body(13,
                                    weight: FontWeight.w700,
                                    color: AppColors.forest800)),
                            const Spacer(),
                            Text('$pct%',
                                style: body(12, color: AppColors.textMuted)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                            '${c['daysLeft']} days left · ${c['backers']} contributors',
                            style: body(12, color: AppColors.hint)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Transparency pledge.
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.forest500.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppColors.forest500.withValues(alpha: 0.35)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.verified_user_rounded,
                      size: 20, color: AppColors.forest700),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Transparency Pledge',
                            style: body(13,
                                weight: FontWeight.w700,
                                color: AppColors.forest800)),
                        const SizedBox(height: 4),
                        Text(
                            '100% of your contribution flows directly to a monitored committee account, published quarterly in the Impact Report.',
                            style: body(12,
                                color: AppColors.textMuted, height: 1.5)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Amount presets.
            _label('SELECT AMOUNT (₹)'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final a in _presets)
                  _AmountChip(
                    label: '₹${formatIndian(a)}',
                    selected:
                        _amount == a && _customCtrl.text.trim().isEmpty,
                    onTap: () => setState(() {
                      _amount = a;
                      _customCtrl.clear();
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _customCtrl,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              decoration: _inputDecoration('Enter custom amount'),
            ),
            const SizedBox(height: 18),

            // Donor name.
            _label('DONOR NAME'),
            const SizedBox(height: 10),
            TextField(
              controller: _nameCtrl,
              enabled: !_anonymous,
              decoration: _inputDecoration(
                  _anonymous ? 'Anonymous' : 'Your name'),
            ),
            const SizedBox(height: 6),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              activeThumbColor: AppColors.forest700,
              value: _anonymous,
              onChanged: (v) => setState(() => _anonymous = v),
              title: Text('Donate anonymously',
                  style: body(13, weight: FontWeight.w600)),
            ),
            const SizedBox(height: 8),

            // Payment method.
            _label('PAYMENT METHOD'),
            const SizedBox(height: 10),
            _PayOption(
              id: 'upi',
              icon: Icons.qr_code_rounded,
              label: 'UPI / QR Code',
              selected: _payMethod == 'upi',
              onTap: () => setState(() => _payMethod = 'upi'),
            ),
            const SizedBox(height: 8),
            _PayOption(
              id: 'card',
              icon: Icons.credit_card_rounded,
              label: 'Credit / Debit Card',
              selected: _payMethod == 'card',
              onTap: () => setState(() => _payMethod = 'card'),
            ),
            const SizedBox(height: 8),
            _PayOption(
              id: 'netbanking',
              icon: Icons.account_balance_rounded,
              label: 'Net Banking',
              selected: _payMethod == 'netbanking',
              onTap: () => setState(() => _payMethod = 'netbanking'),
            ),
          ],
        ),

        // Sticky donate bar.
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: const BoxDecoration(
              color: AppColors.cream,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                child: ForestButton(
                  label: 'Donate ₹${formatIndian(_finalAmount)}',
                  icon: Icons.favorite_rounded,
                  expand: true,
                  onPressed:
                      _finalAmount <= 0 ? null : () => _submit(c),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _label(String text) => Text(text,
      style: body(11,
          weight: FontWeight.w700,
          color: AppColors.hint,
          letterSpacing: 1.0));

  InputDecoration _inputDecoration(String hint) => InputDecoration(
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
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: AppColors.border.withValues(alpha: 0.5)),
        ),
      );
}

class _AmountChip extends StatelessWidget {
  const _AmountChip(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            gradient: selected ? AppGradients.forest : null,
            color: selected ? null : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: selected ? AppColors.forest800 : AppColors.border),
          ),
          child: Text(label,
              style: body(14,
                  weight: FontWeight.w700,
                  color: selected ? Colors.white : AppColors.label)),
        ),
      ),
    );
  }
}

class _PayOption extends StatelessWidget {
  const _PayOption({
    required this.id,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String id;
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.forest500.withValues(alpha: 0.10)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: selected ? AppColors.forest800 : AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: selected
                          ? AppColors.forest800
                          : const Color(0xFFD1D5DB),
                      width: 2),
                ),
                child: selected
                    ? const Center(
                        child: CircleAvatar(
                            radius: 5, backgroundColor: AppColors.forest800),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Icon(icon,
                  size: 18,
                  color:
                      selected ? AppColors.forest800 : AppColors.textMuted),
              const SizedBox(width: 10),
              Text(label,
                  style: body(14,
                      weight: FontWeight.w500, color: AppColors.label)),
            ],
          ),
        ),
      ),
    );
  }
}
