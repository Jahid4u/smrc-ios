import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/push_helper.dart';
import '../../providers/app_providers.dart';
import '../../models/member.dart';
import '../../core/api/smrc_repository.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import '../auth/welcome_screen.dart';

/// Splash — no branding UI here anymore. The OS-level native splash
/// (assets/images/splash_native.png + splash_branding.png, wired up via
/// flutter_native_splash in pubspec.yaml) IS the branding moment now; this
/// screen is just an invisible, same-colour logic step in between: it stays
/// on screen exactly as long as it takes to restore the saved session token
/// and decide where to route the member (inside the app or to Welcome), with
/// no artificial minimum wait. Because the background matches the native
/// splash's ink colour exactly, the handoff from native splash → this route
/// → the destination screen reads as one continuous, brand-covered launch
/// with no second splash flashing up.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _boot();
  }

  // Cached member so returning users skip the /me round-trip. The server is
  // still consulted in the background and HomeShell's membership gate
  // remains authoritative.
  static const _meCacheKey = 'smrc_me_v1';

  bool _navigated = false;

  void _go(String route) {
    if (mounted && !_navigated) {
      _navigated = true;
      // The handoff moment: native splash stays on screen through all of
      // _boot()'s work above (session check, Welcome image precache), and
      // comes down right here — the same frame we start navigating to a
      // destination that's actually ready. Native splash → destination,
      // with nothing visible in between.
      FlutterNativeSplash.remove();
      context.go(route);
    }
  }

  Future<void> _boot() async {
    final repo = ref.read(repoProvider);
    final prefs = await SharedPreferences.getInstance();

    if (!await repo.hasToken()) {
      await _precacheWelcomeBg().timeout(const Duration(milliseconds: 2500), onTimeout: () {});
      _go('/welcome');
      return;
    }

    Member? cached;
    final raw = prefs.getString(_meCacheKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        cached = Member.fromApi((json.decode(raw) as Map).cast<String, dynamic>());
      } catch (_) {/* corrupt cache → ignore */}
    }

    if (cached != null) {
      ref.read(currentMemberProvider.notifier).state = cached;
      _go(memberHomeRoute(cached));
      _refreshMe(repo, prefs);
      return;
    }

    try {
      final map = await repo.meRaw();
      final me = Member.fromApi(map);
      ref.read(currentMemberProvider.notifier).state = me;
      await prefs.setString(_meCacheKey, json.encode(map));
      registerPushToken(repo);
      _go(memberHomeRoute(me));
    } catch (_) {
      await prefs.remove(_meCacheKey);
      await _precacheWelcomeBg().timeout(const Duration(milliseconds: 2500), onTimeout: () {});
      _go('/welcome');
    }
  }

  /// Warms both the widget-level image cache and CachedNetworkImage's disk
  /// cache for the Welcome background *before* navigating there, so the
  /// screen appears with the photo already in place — no placeholder tile,
  /// no visible download, no fade. This is the whole point of routing
  /// through this invisible splash step in the first place: everything the
  /// next screen needs is ready by the time it's shown, so the product
  /// feels instant and "already there" rather than something loading live.
  Future<void> _precacheWelcomeBg() async {
    try {
      final copy = await ref.read(screenCopyProvider.future);
      final raw = (copy['welcome_img'] as String?)?.trim();
      final url = (raw != null && raw.isNotEmpty) ? raw : WelcomeScreen.fallbackImg;
      if (!mounted) return;
      await precacheImage(CachedNetworkImageProvider(url), context);
    } catch (_) {
      // Best-effort only — if this fails Welcome still loads the image
      // itself, just with the normal (rare) placeholder moment.
    }
  }

  Future<void> _refreshMe(dynamic repo, SharedPreferences prefs) async {
    try {
      final map = await repo.meRaw();
      final me = Member.fromApi(map);
      await prefs.setString(_meCacheKey, json.encode(map));
      if (!mounted) return;
      ref.read(currentMemberProvider.notifier).state = me;
      registerPushToken(repo);
    } on ApiException catch (e) {
      // A real "you're not logged in anymore" answer from the server (bad
      // token, or the account itself was deleted) — must NOT be treated as
      // a transient network hiccup. Keeping the stale cached member here
      // was exactly what made a deleted account still show the app as
      // usable / stuck on "activate your membership" instead of logging
      // out to Welcome like a signed-out device should.
      final code = e.code;
      final loggedOut = code == 'account_deleted' ||
          code == 'rest_forbidden' ||
          code == 'rest_not_logged_in' ||
          code == 'invalid_token';
      if (loggedOut) {
        await repo.api.clearToken();
        await prefs.remove(_meCacheKey);
        if (!mounted) return;
        ref.read(currentMemberProvider.notifier).state = null;
        _go('/welcome');
      }
      // Any other ApiException (validation-style, server message, etc.) —
      // keep the cached session, same as before.
    } catch (_) {
      // Network/timeout/etc — keep cached session, don't log the user out
      // just because they're offline.
    }
  }

  @override
  Widget build(BuildContext context) {
    // Plain ink background only — identical to the native splash colour, so
    // no visible seam while the session check above resolves.
    return const Scaffold(backgroundColor: AppColors.ink);
  }
}
