import 'dart:async';

import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../data/api_client.dart';
import '../data/repository.dart';

enum AdCheckoutStatus { paid, cancelled, failed }

/// How a sponsored-post payment ended. [message] is set for [failed].
class AdCheckoutResult {
  const AdCheckoutResult(this.status, [this.message]);
  final AdCheckoutStatus status;
  final String? message;
}

/// Pays for a sponsored post: creates the campaign + Razorpay order on the
/// server, opens Checkout, then has the server verify the payment — which is
/// what activates the campaign. The amount always comes from the server's
/// plan; this side only passes the plan id.
///
/// A singleton rather than a screen's own Razorpay instance (as the donation
/// screen has) because this runs from the create-post flow after it has
/// already navigated back to the feed, so no single screen owns it.
class AdCheckout {
  AdCheckout._();
  static final AdCheckout instance = AdCheckout._();

  Razorpay? _razorpay;
  Completer<AdCheckoutResult>? _pending;
  String? _orderId;

  Future<AdCheckoutResult> promote({
    required String postId,
    required String planId,
    String name = '',
    String phone = '',
  }) async {
    if (_pending != null) {
      return const AdCheckoutResult(
        AdCheckoutStatus.failed,
        'Another payment is already in progress.',
      );
    }
    final completer = Completer<AdCheckoutResult>();
    _pending = completer;
    try {
      final res = await Repository.instance.createAdCampaign(
        postId: postId,
        planId: planId,
      );
      final payment = Map<String, dynamic>.from(res['payment'] as Map);
      _orderId = (payment['orderId'] ?? '').toString();
      final razorpay = _razorpay ??= Razorpay()
        ..on(Razorpay.EVENT_PAYMENT_SUCCESS, _onSuccess)
        ..on(Razorpay.EVENT_PAYMENT_ERROR, _onError);
      razorpay.open({
        'key': payment['key'],
        'amount': payment['amount'], // paise — Checkout's unit, not rupees
        'currency': payment['currency'] ?? 'INR',
        'order_id': _orderId,
        'name': 'Daivajna Samaja',
        'description': 'Sponsored post',
        'prefill': {'contact': phone, 'name': name},
        'theme': {'color': '#1B5E20'},
      });
    } on ApiException catch (e) {
      _finish(AdCheckoutResult(AdCheckoutStatus.failed, e.message));
    } catch (_) {
      _finish(
        const AdCheckoutResult(
          AdCheckoutStatus.failed,
          'Could not start the payment. Please try again.',
        ),
      );
    }
    return completer.future;
  }

  void _finish(AdCheckoutResult result) {
    final pending = _pending;
    _pending = null;
    _orderId = null;
    if (pending != null && !pending.isCompleted) pending.complete(result);
  }

  Future<void> _onSuccess(PaymentSuccessResponse response) async {
    try {
      await Repository.instance.verifyAdCampaign(
        orderId: response.orderId ?? _orderId ?? '',
        paymentId: response.paymentId ?? '',
        signature: response.signature ?? '',
      );
      _finish(const AdCheckoutResult(AdCheckoutStatus.paid));
    } catch (_) {
      _finish(
        const AdCheckoutResult(
          AdCheckoutStatus.failed,
          'Payment received but could not be confirmed yet. Do not pay '
          'again — your sponsored post will start once it is confirmed.',
        ),
      );
    }
  }

  void _onError(PaymentFailureResponse response) {
    // Code 2 is Razorpay's own "payment cancelled by user".
    _finish(
      response.code == 2
          ? const AdCheckoutResult(AdCheckoutStatus.cancelled)
          : AdCheckoutResult(
              AdCheckoutStatus.failed,
              response.message ?? 'Payment failed. Please try again.',
            ),
    );
  }
}
