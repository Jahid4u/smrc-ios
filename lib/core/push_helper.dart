import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'api/smrc_repository.dart';

/// The last player id successfully sent to the server this session, so the
/// subscription observer firing repeatedly doesn't hammer the endpoint with
/// the same value.
String? _lastRegisteredId;

/// Registers this device's OneSignal player id against the signed-in member
/// (POST /app/me/push-token) so the admin panel can target push to them.
/// Silently no-ops if OneSignal isn't ready or the network is down.
Future<void> registerPushToken(SmrcRepository repo) async {
  try {
    final id = OneSignal.User.pushSubscription.id;
    if (id != null && id.isNotEmpty && id != _lastRegisteredId) {
      await repo.registerPushToken(id);
      _lastRegisteredId = id;
    }
  } catch (_) {/* non-fatal */}
}

/// Watches for the OneSignal player id becoming available and registers it
/// the moment it does.
///
/// This is what makes push work on a *first* install. registerPushToken() on
/// its own reads the id at the instant of login, but at that point the id
/// usually doesn't exist yet: OneSignal only issues one after the system
/// permission dialog has been answered and the device has finished its
/// handshake with FCM/APNs. So the login-time read finds null, no-ops, and
/// the member ends up with no player id on the server — meaning every push
/// aimed at them silently goes nowhere until some later app launch happens
/// to catch it.
///
/// The observer also covers the other cases where the id appears or changes
/// after login: permission granted later from system settings, OneSignal
/// re-issuing a subscription, or the app being reinstalled.
///
/// Registration is skipped while signed out, since /app/me/push-token needs
/// a member token; the registerPushToken() call after login picks it up then.
void startPushTokenSync(SmrcRepository repo) {
  try {
    OneSignal.User.pushSubscription.addObserver((state) async {
      try {
        final id = state.current.id;
        if (id == null || id.isEmpty || id == _lastRegisteredId) return;
        if (!await repo.hasToken()) return; // signed out — nothing to attach it to
        await repo.registerPushToken(id);
        _lastRegisteredId = id;
      } catch (_) {/* non-fatal */}
    });
  } catch (_) {/* non-fatal */}
}

/// Update the member's group chat push preference.
Future<void> setGroupChatPushPreference(
  SmrcRepository repo,
  bool enabled,
) async {
  try {
    await repo.setGroupChatPushPref(enabled);
  } catch (_) {/* non-fatal */}
}
