import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../data/api_client.dart';
import '../data/models/welfare_campaign.dart';
import '../data/repository.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ui_kit.dart';
import 'welfare_list_screen.dart' show CampaignCover;

/// Make-a-contribution flow — ported from `src/app/welfare/donate/[id]/page.tsx`.
///
/// Real money: the chosen amount becomes a Razorpay Order created by the server
/// (`POST /api/payments/campaigns/order`), which stamps the campaign id and
/// title into the order's notes and receipt so the Razorpay dashboard shows
/// which campaign every payment was for. After Checkout the payment is
/// confirmed with `POST /api/payments/campaigns/verify`, which records the
/// donation and moves the campaign's raised total.
class WelfareDonateScreen extends StatefulWidget {
  const WelfareDonateScreen({super.key, required this.id});

  final String id;

  @override
  State<WelfareDonateScreen> createState() => _WelfareDonateScreenState();
}

class _WelfareDonateScreenState extends State<WelfareDonateScreen> {
  static const _presets = [501, 1100, 2500, 5100, 11000];

  late Future<WelfareCampaign> _future;
  late final Razorpay _razorpay;

  int _amount = 2500;
  final _customCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  bool _anonymous = false;

  bool _paying = false;
  String? _error;
  String? _pendingOrderId;
  WelfareCampaign? _pendingCampaign;

  @override
  void initState() {
    super.initState();
    _future = Repository.instance.fetchCampaign(widget.id);
    _razorpay = Razorpay()
      ..on(Razorpay.EVENT_PAYMENT_SUCCESS, _onSuccess)
      ..on(Razorpay.EVENT_PAYMENT_ERROR, _onError)
      ..on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    _customCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _messageCtrl.dispose();
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

  // ── Payment ───────────────────────────────────────────────────────────────

  Future<void> _pay(WelfareCampaign campaign) async {
    final t = AppLocalizations.of(context);
    // Read before the first await — using `context` after one without a
    // `mounted` guard is unsafe if the screen was disposed in between.
    final user = context.read<AuthService>().user;
    final donorName = _anonymous ? '' : _nameCtrl.text.trim();
    final prefillName = donorName.isNotEmpty ? donorName : (user?.name ?? '');
    final email = _emailCtrl.text.trim();

    setState(() {
      _paying = true;
      _error = null;
    });
    try {
      final order = await Repository.instance.createCampaignOrder(
        campaignId: campaign.id,
        amount: _finalAmount,
        donorName: donorName.isNotEmpty ? donorName : user?.name,
        anonymous: _anonymous,
        message: _messageCtrl.text.trim(),
        contactName: prefillName,
        contactPhone: user?.phone,
        contactEmail: email,
      );
      _pendingOrderId = (order['orderId'] ?? '').toString();
      _pendingCampaign = campaign;
      if (!mounted) return;
      _razorpay.open({
        'key': order['key'],
        'amount': order['amount'], // paise — Checkout's unit, not rupees
        'currency': order['currency'] ?? 'INR',
        'order_id': _pendingOrderId,
        'name': 'Daivajna Samaja',
        // Shown on the Checkout sheet and on the payment in Razorpay.
        'description': t.welfareDonationFor(campaign.title),
        'notes': {
          'campaignId': campaign.id,
          'campaignTitle': campaign.title,
          'donorName': _anonymous ? 'Anonymous' : prefillName,
        },
        'prefill': {
          'contact': user?.phone ?? '',
          'name': prefillName,
          'email': email,
        },
        'theme': {'color': '#1B5E20'},
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _paying = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _paying = false;
        _error = t.welfarePaymentFailed;
      });
    }
  }

  Future<void> _onSuccess(PaymentSuccessResponse response) async {
    final t = AppLocalizations.of(context);
    try {
      await Repository.instance.verifyCampaignPayment(
        orderId: response.orderId ?? _pendingOrderId ?? '',
        paymentId: response.paymentId ?? '',
        signature: response.signature ?? '',
      );
      if (!mounted) return;
      final campaign = _pendingCampaign;
      setState(() {
        _paying = false;
        // Refresh so the raised total reflects this gift.
        _future = Repository.instance.fetchCampaign(widget.id);
      });
      if (campaign != null) _showThanks(campaign.title);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _paying = false;
        _error = t.welfarePaymentVerifyFailed;
      });
    }
  }

  void _onError(PaymentFailureResponse response) {
    if (!mounted) return;
    setState(() {
      _paying = false;
      // Code 2 is Razorpay's own "payment cancelled by user" — not a real
      // error, so no need to alarm anyone over a closed Checkout sheet.
      _error = response.code == 2
          ? null
          : (response.message ??
                AppLocalizations.of(context).welfarePaymentFailed);
    });
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    // Informational only — Checkout is already handling the wallet redirect.
  }

  void _showThanks(String title) {
    final t = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                gradient: AppGradients.forest,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                t.welfareDhanyavaad,
                style: display(20, color: AppColors.forest900),
              ),
            ),
          ],
        ),
        content: Text(
          t.welfareThankYouReceived(title),
          style: body(14, color: AppColors.textMuted, height: 1.5),
        ),
        actions: [
          ForestButton(
            label: t.welfareBackToWelfare,
            onPressed: () {
              Navigator.of(ctx).pop();
              context.go('/welfare');
            },
          ),
        ],
      ),
    );
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.onBrightness(
        light: AppColors.cream,
        dark: AppColors.darkBg,
      ),
      appBar: AppBar(
        backgroundColor: AppColors.forest800,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: _back,
        ),
        title: Text(
          AppLocalizations.of(context).welfareMakeContribution,
          style: display(18, color: Colors.white),
        ),
      ),
      body: FutureBuilder<WelfareCampaign>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError || !snap.hasData) return _notFound();
          return _form(snap.data!);
        },
      ),
    );
  }

  Widget _notFound() {
    final t = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 36,
            color: context.onBrightness(
              light: AppColors.hint,
              dark: AppColors.darkTextMuted,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            t.welfareCampaignNotFound,
            style: body(
              15,
              weight: FontWeight.w600,
              color: context.onBrightness(
                light: AppColors.hint,
                dark: AppColors.darkTextMuted,
              ),
            ),
          ),
          const SizedBox(height: 14),
          ForestButton(
            label: t.welfareBackToWelfare,
            onPressed: () => context.go('/welfare'),
          ),
        ],
      ),
    );
  }

  Widget _form(WelfareCampaign c) {
    final t = AppLocalizations.of(context);
    final closed = !c.isActive;

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 130),
          children: [
            // Campaign header card.
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CampaignCover(campaign: c, height: 140, emojiSize: 56),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Pill(c.categoryLabel),
                        const SizedBox(height: 10),
                        Text(
                          c.title,
                          style: display(
                            18,
                            color: context.onBrightness(
                              light: AppColors.forest900,
                              dark: AppColors.darkText,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          c.description,
                          style: body(
                            13,
                            color: context.onBrightness(
                              light: AppColors.textMuted,
                              dark: AppColors.darkTextMuted,
                            ),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 14),
                        ProgressBar(value: c.progress, height: 8),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              t.welfareRaised(formatLakh(c.raised)),
                              style: body(
                                13,
                                weight: FontWeight.w700,
                                color: context.onBrightness(
                                  light: AppColors.forest800,
                                  dark: AppColors.forest300,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              t.welfarePctLabel(c.percent),
                              style: body(
                                12,
                                color: context.onBrightness(
                                  light: AppColors.textMuted,
                                  dark: AppColors.darkTextMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          c.daysLeft == null
                              ? '${t.welfareOpenEnded} · ${t.welfareBackers(c.backers)}'
                              : t.welfareDaysLeftContributors(
                                  c.daysLeft!,
                                  c.backers,
                                ),
                          style: body(
                            12,
                            color: context.onBrightness(
                              light: AppColors.hint,
                              dark: AppColors.darkTextMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            if (closed) ...[
              _Notice(
                icon: Icons.lock_clock_rounded,
                text: t.welfareCampaignClosed,
                tone: AppColors.gold700,
              ),
              const SizedBox(height: 14),
            ],

            // Transparency pledge.
            _Notice(
              icon: Icons.verified_user_rounded,
              title: t.welfareTransparencyPledge,
              text: t.welfareTransparencyPledgeBody,
              tone: AppColors.forest700,
            ),
            const SizedBox(height: 18),

            // Amount presets.
            _label(t.welfareSelectAmount),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final a in _presets)
                  _AmountChip(
                    label: '₹${formatIndian(a)}',
                    selected: _amount == a && _customCtrl.text.trim().isEmpty,
                    onTap: closed
                        ? null
                        : () => setState(() {
                            _amount = a;
                            _customCtrl.clear();
                          }),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _customCtrl,
              enabled: !closed,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              decoration: _inputDecoration(t.welfareEnterCustomAmount),
            ),
            const SizedBox(height: 18),

            // Donor name.
            _label(t.welfareDonorName),
            const SizedBox(height: 10),
            TextField(
              controller: _nameCtrl,
              enabled: !_anonymous && !closed,
              decoration: _inputDecoration(
                _anonymous ? t.welfareAnonymous : t.welfareYourName,
              ),
            ),
            const SizedBox(height: 6),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              activeThumbColor: AppColors.forest700,
              value: _anonymous,
              onChanged: closed ? null : (v) => setState(() => _anonymous = v),
              title: Text(
                t.welfareDonateAnonymously,
                style: body(13, weight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 8),

            // Email, for the Razorpay receipt.
            _label(t.welfareEmailLabel),
            const SizedBox(height: 10),
            TextField(
              controller: _emailCtrl,
              enabled: !closed,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: _inputDecoration(t.welfareEmailHint),
            ),
            const SizedBox(height: 18),

            // Optional message.
            _label(t.welfareMessageOptional),
            const SizedBox(height: 10),
            TextField(
              controller: _messageCtrl,
              enabled: !closed,
              maxLength: 500,
              maxLines: 2,
              decoration: _inputDecoration(t.welfareMessageHint),
            ),
            const SizedBox(height: 8),

            // Payment method note: Razorpay Checkout offers UPI, cards, net
            // banking and wallets itself, so there is nothing to pick here.
            Row(
              children: [
                const Icon(Icons.lock_rounded, size: 14, color: AppColors.hint),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    t.welfareSecurePayment,
                    style: body(
                      12,
                      color: context.onBrightness(
                        light: AppColors.hint,
                        dark: AppColors.darkTextMuted,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: body(13, color: Colors.red)),
            ],
          ],
        ),

        // Sticky donate bar.
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: context.onBrightness(
                light: AppColors.cream,
                dark: AppColors.darkSurface,
              ),
              border: const Border(top: BorderSide(color: AppColors.border)),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                child: ForestButton(
                  label: _paying
                      ? '…'
                      : t.welfareDonateAmount(formatIndian(_finalAmount)),
                  icon: Icons.favorite_rounded,
                  expand: true,
                  onPressed: closed || _paying || _finalAmount <= 0
                      ? null
                      : () => _pay(c),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _label(String text) => Text(
    text,
    style: body(
      11,
      weight: FontWeight.w700,
      color: context.onBrightness(
        light: AppColors.hint,
        dark: AppColors.darkTextMuted,
      ),
      letterSpacing: 1.0,
    ),
  );

  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: body(14, color: AppColors.hint),
    filled: true,
    fillColor: Colors.white,
    counterText: '',
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
      borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
    ),
  );
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.icon,
    required this.text,
    required this.tone,
    this.title,
  });
  final IconData icon;
  final String? title;
  final String text;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tone.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: tone),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Text(
                    title!,
                    style: body(13, weight: FontWeight.w700, color: tone),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  text,
                  style: body(12, color: AppColors.textMuted, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountChip extends StatelessWidget {
  const _AmountChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback? onTap;

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
            color: selected
                ? null
                : context.onBrightness(
                    light: Colors.white,
                    dark: AppColors.darkSurface,
                  ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? AppColors.forest800
                  : context.onBrightness(
                      light: AppColors.border,
                      dark: AppColors.darkBorder,
                    ),
            ),
          ),
          child: Text(
            label,
            style: body(
              14,
              weight: FontWeight.w700,
              color: selected
                  ? Colors.white
                  : context.onBrightness(
                      light: AppColors.label,
                      dark: AppColors.darkText,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
