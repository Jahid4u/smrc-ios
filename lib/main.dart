import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:app_links/app_links.dart';

import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/push_helper.dart';
import 'widgets/notification_watcher.dart';
import 'providers/app_providers.dart';

/// Set this to your real OneSignal App ID before shipping.
const String _oneSignalAppId = '1c89c338-03d0-4415-b516-f4a93e28af89';

Future<void> main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();

  // Cormorant Garamond and Inter are now bundled locally in assets/fonts
  // (see pubspec.yaml) instead of being fetched over the network via
  // google_fonts. That package is no longer used, so there is nothing left
  // that can stall the first frame waiting on a font download — the exact
  // brand typeface is always available offline, instantly.

  // Hold the OS-level native splash on screen until Flutter paints its first
  // frame, so the branded splash appears instantly with no black/white flash.
  FlutterNativeSplash.preserve(widgetsBinding: binding);

  // A manually-created container (instead of a plain ProviderScope) so the
  // GoRouter's top-level `redirect` — which runs outside the widget tree —
  // can read currentMemberProvider directly. This is what makes the
  // membership gate authoritative for *every* route, not just the ones that
  // happen to watch the provider in their build() method.
  initRouterContainer();
  runApp(UncontrolledProviderScope(container: routerContainer, child: const SmRoyalCircleApp()));
}

class SmRoyalCircleApp extends StatefulWidget {
  const SmRoyalCircleApp({super.key});

  @override
  State<SmRoyalCircleApp> createState() => _SmRoyalCircleAppState();
}

class _SmRoyalCircleAppState extends State<SmRoyalCircleApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Native splash is intentionally NOT removed here anymore. Removing it
      // at "first frame painted" meant native splash → this frame is the
      // invisible ink SplashScreen (same colour, so no visible seam) → but
      // then _boot()'s async work (session check, image precache) still had
      // to run with native splash already gone, showing as a plain black
      // hold before Welcome/Explore appeared. Native splash now stays up
      // for that entire stretch instead, and SplashScreen removes it itself
      // right when it's actually navigating to a ready destination — so the
      // handoff is native splash → destination screen, nothing in between.
      _initPush();
      _initDeepLinks();
    });
  }

  final _appLinks = AppLinks();

  /// Catches smroyalcircle://set-password?token=... — both a cold-start
  /// link (app not running yet) and a link tapped while the app is already
  /// open — and routes straight to the in-app Set Password screen with the
  /// token, no browser step involved.
  Future<void> _initDeepLinks() async {
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) _handleDeepLink(initial);
    } catch (_) {/* non-fatal */}
    _appLinks.uriLinkStream.listen(_handleDeepLink, onError: (_) {});
  }

  void _handleDeepLink(Uri uri) {
    if (uri.scheme == 'smroyalcircle' && uri.host == 'set-password') {
      final token = uri.queryParameters['token'];
      if (token != null && token.isNotEmpty) {
        appRouter.push('/set-password', extra: token);
      }
    }
  }

  Future<void> _initPush() async {
    try {
      if (_oneSignalAppId == 'YOUR_ONESIGNAL_APP_ID') return; // not configured yet
      if (kDebugMode) OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
      OneSignal.initialize(_oneSignalAppId);
      // Attach the subscription observer before the permission prompt, so the
      // player id OneSignal issues once permission is granted is caught and
      // registered even on a first install — the login-time registration read
      // runs too early to ever see it.
      startPushTokenSync(routerContainer.read(repoProvider));
      // Ask for notification permission a moment later, not on the splash,
      // so the system dialog never covers the launch experience.
      await Future.delayed(const Duration(milliseconds: 1200));
      if (!mounted) return;
      OneSignal.Notifications.requestPermission(true);
    } catch (_) {/* non-fatal */}
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'SM Royal Circle',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: appRouter,
      builder: (context, child) =>
          NotificationWatcher(child: child ?? const SizedBox.shrink()),
    );
  }
}
