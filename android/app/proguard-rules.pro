# Flutter wrapper — keep the embedding + plugin entry points so R8 doesn't
# strip classes that are only referenced reflectively at runtime.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# OneSignal push
-keep class com.onesignal.** { *; }

# package:jni resolves Java/Kotlin classes by name through JNI, so they must
# survive shrinking and obfuscation.
-keep class com.github.dart_lang.jni.** { *; }

# ---- Optional dependencies that are deliberately NOT bundled ----
# R8 walks every reference in the Flutter engine and the Stripe SDK, including
# code paths this app never takes, and fails the build when a referenced class
# isn't on the classpath. Both groups below are genuinely optional features
# that aren't used here, so the right fix is to silence the warnings rather
# than add megabytes of unused libraries.

# Flutter's Play Store deferred-components support. Only reachable if the app
# ships deferred/dynamic feature modules — this one doesn't.
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**
-dontwarn io.flutter.embedding.android.FlutterPlayStoreSplitApplication

# Stripe's "push provisioning" (adding a card to Google Wallet from inside the
# app). That's a separate opt-in Stripe product requiring its own SDK artifact;
# this app only takes payments, so those classes are never present or called.
-dontwarn com.stripe.android.pushProvisioning.**
-dontwarn com.reactnativestripesdk.pushprovisioning.**

# Additional official flutter_stripe-required rules (Google Pay's tap-and-pay
# module and Kotlin's @Parcelize annotation processor artifacts) — same
# reasoning as above: referenced by the Stripe SDK's code paths but not
# something this app calls directly.
-dontwarn com.google.android.gms.tapandpay.**
-dontwarn kotlinx.parcelize.Parceler$DefaultImpls
-dontwarn kotlinx.parcelize.Parceler
-dontwarn kotlinx.parcelize.Parcelize

# Keep the Stripe SDK itself — parts of it are reached reflectively.
-keep class com.stripe.android.** { *; }
