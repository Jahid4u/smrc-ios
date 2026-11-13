package com.smroyalcircle.app

import io.flutter.embedding.android.FlutterFragmentActivity

// flutter_stripe requires the host Activity to be a FlutterFragmentActivity
// (not the default FlutterActivity) because Stripe's native Android SDK
// needs Fragment support for its 3D Secure / payment sheet UI. Without
// this, Stripe.instance.applySettings() throws at runtime with:
// "PlatformException(flutter_stripe initialization failed, ... MainActivity
// is not a subclass FlutterFragmentActivity ...)" — exactly the error this
// app hit at checkout. See: https://github.com/flutter-stripe/flutter_stripe#android
class MainActivity : FlutterFragmentActivity()
