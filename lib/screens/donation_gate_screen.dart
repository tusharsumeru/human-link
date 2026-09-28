import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../data/api_client.dart';
import '../data/repository.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ui_kit.dart';

/// One-time registration donation gate.
///
/// The router (`buildRouter`) sends every logged-in member here whenever
/// `AppUser.hasDonated` is false — right after registration, and again on any
/// later login if they closed the app before finishing payment. There is
/// nothing else this screen can do but pay or log out: it is not in
/// `_publicPaths` and the redirect re-applies on every navigation attempt
/// while unpaid.
///
/// This donation does not renew — it is a Razorpay Order (see
/// `PaymentsService.createDonationOrder`), not a Subscription. Completing it
/// once flips `hasDonated` on the account forever; the router then routes
/// past this screen for good (see the "Paid" branch in router.dart).
class DonationGateScreen extends StatefulWidget {
  const DonationGateScreen({super.key});

  @override
  State<DonationGateScreen> createState() => _DonationGateScreenState();
}

class _DonationGateScreenState extends State<DonationGateScreen> {
  late final Razorpay _razorpay;

  // Plan details for display, loaded once from the backend so the amount
  // shown is always the real, current price — never guessed on this side.
  bool _loadingPlan = true;
  String _planName = 'Registration Donation';
  int _amountRupees = 0;
  String _currency = 'INR';

  bool _paying = false;
  String? _error;
  String? _pendingOrderId;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay()
      ..on(Razorpay.EVENT_PAYMENT_SUCCESS, _onSuccess)
      ..on(Razorpay.EVENT_PAYMENT_ERROR, _onError)
      ..on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
    _loadPlan();
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _loadPlan() async {
    try {
      final data = await _api.getJson('/api/payments/plans?type=donation');
      final plans = (data is List) ? data : const [];
      if (plans.isNotEmpty) {
        final plan = Map<String, dynamic>.from(plans.first as Map);
        if (mounted) {
          setState(() {
            _planName = (plan['name'] ?? _planName).toString();
            _amountRupees = (plan['amount'] as num?)?.toInt() ?? 0;
            _currency = (plan['currency'] ?? 'INR').toString();
            _loadingPlan = false;
          });
        }
        return;
      }
    } catch (_) {
      /* fall through — the Pay button still works, it just can't preview the
         amount; createDonationOrder() below is the source of truth anyway. */
    }
    if (mounted) setState(() => _loadingPlan = false);
  }

  ApiClient get _api => ApiClient();

  Future<void> _pay() async {
    // Read before the first await — using `context` after one without a
    // `mounted` guard is unsafe if the screen was disposed in between.
    final user = context.read<AuthService>().user;
    setState(() {
      _paying = true;
      _error = null;
    });
    try {
      final order = await Repository.instance.createDonationOrder();
      _pendingOrderId = (order['orderId'] ?? '').toString();
      if (!mounted) return;
      final options = {
        'key': order['key'],
        'amount': order['amount'], // paise — Checkout's unit, not rupees
        'currency': order['currency'] ?? 'INR',
        'order_id': _pendingOrderId,
        'name': 'Daivajna Samaja',
        'description': 'Registration donation',
        'prefill': {'contact': user?.phone ?? '', 'name': user?.name ?? ''},
        'theme': {'color': '#1B5E20'},
      };
      _razorpay.open(options);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _paying = false;
        _error = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _paying = false;
        _error = 'Could not start the payment. Please try again.';
      });
    }
  }

  Future<void> _onSuccess(PaymentSuccessResponse response) async {
    try {
      await Repository.instance.verifyDonation(
        orderId: response.orderId ?? _pendingOrderId ?? '',
        paymentId: response.paymentId ?? '',
        signature: response.signature ?? '',
      );
      // Pulls the fresh `hasDonated: true` from /api/user/me and merges it
      // into the cached session; AuthService.notifyListeners() then wakes the
      // router (`refreshListenable: auth`), whose redirect sends this screen
      // straight on to onboarding/dashboard — no manual navigation here.
      if (mounted) {
        await context.read<AuthService>().refreshFromServer();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error =
            'Payment received but verification failed. Please contact support '
            'if this keeps happening — do not pay again.';
      });
    } finally {
      if (mounted) setState(() => _paying = false);
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
          : (response.message ?? 'Payment failed. Please try again.');
    });
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    // Informational only — Checkout is already handling the wallet redirect.
  }

  Future<void> _logout() async {
    final auth = context.read<AuthService>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text(
          "You'll need to log back in and complete this donation before you "
          'can use the app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirmed == true) await auth.logout();
  }

  String get _amountLabel =>
      _currency == 'INR' ? '₹$_amountRupees' : '$_amountRupees $_currency';

  @override
  Widget build(BuildContext context) {
    final bg = context.onBrightness(
      light: AppColors.cream,
      dark: AppColors.darkBg,
    );
    final cardBg = context.onBrightness(light: Colors.white, dark: AppColors.darkSurface);
    final textColor = context.onBrightness(
      light: AppColors.ink,
      dark: Colors.white,
    );

    return PopScope(
      // A donation-gated session must not be able to back out of this screen
      // into the rest of the app — go_router's redirect would just bounce it
      // straight back here anyway, but blocking the pop keeps that invisible.
      canPop: false,
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        gradient: AppGradients.forest,
                        shape: BoxShape.circle,
                        boxShadow: AppShadows.forestGlow,
                      ),
                      child: const Icon(
                        Icons.volunteer_activism_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Welcome to Daivajna Samaja',
                      textAlign: TextAlign.center,
                      style: display(22, color: textColor),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'A one-time registration donation keeps this community '
                      'running — welfare campaigns, verification, and the '
                      'directory you just joined. It is a single payment, not '
                      'a subscription, and unlocks the app for good.',
                      textAlign: TextAlign.center,
                      style: body(
                        14,
                        height: 1.5,
                        color: textColor.withValues(alpha: 0.75),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppShadows.card,
                      ),
                      child: _loadingPlan
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Center(
                                child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            )
                          : Column(
                              children: [
                                Text(
                                  _planName,
                                  style: body(
                                    13,
                                    weight: FontWeight.w600,
                                    color: textColor.withValues(alpha: 0.65),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _amountLabel,
                                  style: display(
                                    36,
                                    color: AppColors.forest800,
                                  ),
                                ),
                              ],
                            ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: body(13, color: Colors.red.shade700),
                      ),
                    ],
                    const SizedBox(height: 24),
                    ForestButton(
                      label: _loadingPlan ? 'Pay to continue' : 'Pay $_amountLabel',
                      expand: true,
                      loading: _paying,
                      onPressed: _loadingPlan ? null : _pay,
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: _paying ? null : _logout,
                      child: Text(
                        'Log out',
                        style: body(13, color: textColor.withValues(alpha: 0.6)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
