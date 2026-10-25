import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import '../core/theme/app_colors.dart';
import '../core/payment_helper.dart';
import '../core/error_classifier.dart';

/// The OFFICIAL Apple Pay (black, Apple logo) / Google Pay (Google's own
/// multicolor button) button — required by Apple's and Google's brand
/// guidelines for any checkout that charges through their wallet. This is
/// not a custom-styled GoldButton; it's flutter_stripe's PlatformPayButton,
/// rendered natively per platform.
///
/// This app takes payment through Google Pay / Apple Pay only — there's no
/// card-entry fallback — so if the device has no card set up in its wallet,
/// there's genuinely nothing to tap. In that case this shows a short
/// explanatory message instead of a non-functional button.
class PlatformPayCheckoutButton extends StatefulWidget {
  final bool busy;
  final Future<void> Function() onPressed;

  /// Must set Stripe.publishableKey and call Stripe.instance.applySettings()
  /// — see ensureStripeInitialized() in core/payment_helper.dart. This is
  /// called and awaited BEFORE checking device wallet availability below;
  /// calling isPlatformPaySupported() before Stripe has a publishable key
  /// set is what used to risk a native-side crash here.
  final Future<StripeInitResult> Function() ensureReady;

  const PlatformPayCheckoutButton({
    super.key,
    required this.busy,
    required this.onPressed,
    required this.ensureReady,
  });

  @override
  State<PlatformPayCheckoutButton> createState() => _PlatformPayCheckoutButtonState();
}

enum _PlatformPayState { checking, notSignedIn, notConfigured, otherError, unavailable, ready }

class _PlatformPayCheckoutButtonState extends State<PlatformPayCheckoutButton> {
  _PlatformPayState _state = _PlatformPayState.checking;
  ErrorInfo? _error;

  @override
  void initState() {
    super.initState();
    _checkAvailability();
  }

  Future<void> _checkAvailability() async {
    final result = await widget.ensureReady();
    if (!result.ready) {
      if (!mounted) return;
      setState(() {
        _error = result.error;
        _state = switch (result.failure!) {
          StripeInitFailure.notSignedIn => _PlatformPayState.notSignedIn,
          StripeInitFailure.serverNotConfigured => _PlatformPayState.notConfigured,
          StripeInitFailure.other => _PlatformPayState.otherError,
        };
      });
      return;
    }
    try {
      final supported = await stripe.Stripe.instance.isPlatformPaySupported();
      if (mounted) setState(() => _state = supported ? _PlatformPayState.ready : _PlatformPayState.unavailable);
    } catch (_) {
      if (mounted) setState(() => _state = _PlatformPayState.unavailable);
    }
  }

  Widget _spinner() => const SizedBox(
        height: 48,
        child: Center(
          child: SizedBox(
              width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold)),
        ),
      );

  Widget _message(String text) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.charcoal2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.line),
        ),
        child: Text(text,
            textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
      );

  @override
  Widget build(BuildContext context) {
    switch (_state) {
      case _PlatformPayState.checking:
        return _spinner();
      case _PlatformPayState.notSignedIn:
        // No member token stored on this device — most commonly hit while
        // browsing in "demo" mode (memberOrDemoProvider) without ever
        // signing in, since the checkout UI itself doesn't require a real
        // session to render, only to actually pay.
        return _message('Please sign in to your account to complete this purchase.');
      case _PlatformPayState.notConfigured:
        // Reached the server with a valid session, but it says payments
        // aren't set up (Settings → Payments (Stripe) is empty for the
        // active mode) — this is an admin/setup issue, not the member's.
        return _message('Payments are temporarily unavailable. Please try again shortly.');
      case _PlatformPayState.otherError:
        // Connectivity failure, timeout, certificate problem, or a genuine
        // server-side error — see core/error_classifier.dart. .display
        // includes the specific technical reason so this is
        // self-diagnosing even in a release build with no debug console.
        return _message(_error?.display ?? 'Something went wrong. Please try again.');
      case _PlatformPayState.unavailable:
        // No card set up in the device's wallet — this app has no
        // card-entry fallback, so be upfront about what's needed.
        return _message(Platform.isIOS
            ? 'Add a card to Apple Wallet to complete this purchase.'
            : 'Add a card to Google Pay to complete this purchase.');
      case _PlatformPayState.ready:
        if (widget.busy) return _spinner();
        return SizedBox(
          width: double.infinity,
          height: 48,
          child: stripe.PlatformPayButton(
            type: stripe.PlatformButtonType.pay,
            onPressed: widget.onPressed,
            // White, not black: this button sits on the app's dark checkout
            // background (AppColors.charcoal2 etc.), and Google Pay's brand
            // guidelines require the light/white button on dark backgrounds
            // for contrast — a dark button on dark background is exactly
            // what Google's Android-integration screenshot review flagged.
            appearance: stripe.PlatformButtonStyle.white,
          ),
        );
    }
  }
}
