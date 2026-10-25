import 'package:flutter/foundation.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'api/smrc_repository.dart';
import 'error_classifier.dart';

/// Guards against re-fetching the publishable key and re-applying Stripe
/// settings more than once per app session.
bool _stripeReady = false;

/// Whether the active Stripe keys are test-mode ones. Only meaningful after
/// ensureStripeInitialized() has returned ready.
bool stripeTestMode = true;

enum StripeInitFailure {
  /// No member auth token is stored on this device at all — the person
  /// isn't actually signed in (or their session was cleared), so the
  /// request to fetch the publishable key was never even attempted.
  notSignedIn,

  /// The server was reached and answered normally, but says payments
  /// aren't configured yet (no Stripe keys saved in Settings → Payments
  /// (Stripe), or "Use Live Mode" is on with live keys still blank, etc.).
  serverNotConfigured,

  /// Everything else — connectivity failures, timeouts, certificate
  /// problems, and genuine server-side (HTTP 5xx) errors. See
  /// [StripeInitResult.detail] (from the shared describeError() classifier
  /// in core/error_classifier.dart) for exactly which one.
  other,
}

class StripeInitResult {
  final bool ready;
  final StripeInitFailure? failure;

  /// The shared classifier's full description — safe to show on screen,
  /// works in release builds without needing a debug console attached.
  final ErrorInfo? error;

  const StripeInitResult.ready()
      : ready = true,
        failure = null,
        error = null;
  const StripeInitResult.failed(StripeInitFailure this.failure, {this.error}) : ready = false;
}

/// Fetches the Stripe publishable key from the server and initializes the
/// Stripe SDK. Must be called (and awaited) before payWithPlatformPay().
///
/// Unlike OneSignal's App ID (set once at app boot in main.dart), the
/// publishable key requires a signed-in member token to fetch — so this is
/// called lazily, right before a payment, not at startup.
Future<StripeInitResult> ensureStripeInitialized(SmrcRepository repo) async {
  if (_stripeReady) return const StripeInitResult.ready();
  try {
    // Check locally first, before making any network call: if there's no
    // stored token at all, the server will correctly reject the request
    // with 401 either way, but that response looks identical to "payments
    // aren't configured" unless we distinguish it here. This is what a
    // "demo mode" member (browsing without ever signing in) hits.
    final token = await repo.api.readToken();
    if (token == null || token.isEmpty) {
      return const StripeInitResult.failed(StripeInitFailure.notSignedIn);
    }

    final info = await repo.stripeKeyInfo();
    if (info == null) {
      return const StripeInitResult.failed(StripeInitFailure.serverNotConfigured);
    }
    Stripe.publishableKey = info.publishableKey;
    // Apple Pay merchant ID (must match the Merchant ID registered in the
    // Apple Developer portal and the com.apple.developer.in-app-payments
    // entry in ios/Runner/Runner.entitlements).
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      Stripe.merchantIdentifier = 'merchant.com.smroyalcircle.app';
    }
    await Stripe.instance.applySettings();
    stripeTestMode = info.testMode;
    _stripeReady = true;
    return const StripeInitResult.ready();
  } catch (e) {
    final info = describeError(e);
    if (kDebugMode) debugPrint('ensureStripeInitialized: ${info.display}');
    return StripeInitResult.failed(StripeInitFailure.other, error: info);
  }
}

/// Whether Google Pay (Android) / Apple Pay (iOS) is available on this
/// device at all — e.g. no card ever added to the wallet, or an unsupported
/// device. Check this before showing the platform pay button.
Future<bool> isPlatformPayAvailable() async {
  try {
    return await Stripe.instance.isPlatformPaySupported();
  } catch (_) {
    return false;
  }
}

/// Runs the actual Google Pay / Apple Pay sheet for a given PaymentIntent
/// client secret, using Stripe's PlatformPay API — this shows ONLY the
/// native Google Pay / Apple Pay UI, never a card entry form.
///
/// [merchantCountryCode] should match where the business is registered
/// (e.g. 'US'). [testEnv] must be true while using Stripe test keys and
/// false once Stripe is switched to live mode — the repository already
/// tells the caller which mode is active (see PaymentIntentResult /
/// stripePublishableKey's testMode flag) so callers should thread that
/// through rather than hardcoding it here.
///
/// Returns true if the charge succeeded, false if the member cancelled or
/// it failed (in which case [onError] is called with a friendly message).
Future<bool> payWithPlatformPay({
  required String clientSecret,
  required double amount,
  required bool testEnv,
  String merchantCountryCode = 'US',
  String merchantName = 'SM Royal Circle',
  void Function(String message)? onError,
}) async {
  try {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await Stripe.instance.confirmPlatformPayPaymentIntent(
        clientSecret: clientSecret,
        confirmParams: PlatformPayConfirmParams.applePay(
          applePay: ApplePayParams(
            merchantCountryCode: merchantCountryCode,
            currencyCode: 'USD',
            cartItems: [
              ApplePayCartSummaryItem.immediate(
                label: merchantName,
                amount: amount.toStringAsFixed(2),
              ),
            ],
          ),
        ),
      );
    } else {
      await Stripe.instance.confirmPlatformPayPaymentIntent(
        clientSecret: clientSecret,
        confirmParams: PlatformPayConfirmParams.googlePay(
          googlePay: GooglePayParams(
            merchantCountryCode: merchantCountryCode,
            currencyCode: 'USD',
            testEnv: testEnv,
          ),
        ),
      );
    }
    return true;
  } on StripeException catch (e) {
    // localizedMessage covers "user cancelled" cleanly (no error shown) vs
    // an actual decline/failure (show the message).
    final code = e.error.code;
    if (code != FailureCode.Canceled) {
      onError?.call(e.error.localizedMessage ?? 'Payment could not be completed.');
    }
    return false;
  } catch (e) {
    onError?.call('Payment could not be completed.');
    return false;
  }
}
