import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/api_client.dart';
import '../../models/member.dart';
import '../../models/club_event.dart';
import '../../models/api_models.dart';

/// One repository for every smrc/v1 endpoint the app calls.
/// Every method throws [ApiException] with the backend's own message on
/// failure so screens can show real error text.
class SmrcRepository {
  final ApiClient api;
  SmrcRepository(this.api);

  Map<String, dynamic> _body(Response res) {
    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    throw ApiException('Unexpected server response.');
  }

  Map<String, dynamic> _ok(Response res) {
    final b = _body(res);
    if (b['success'] == true) return b;
    throw ApiException((b['message'] as String?) ?? 'Request failed.', code: b['code'] as String?, data: b);
  }

  // ─────────── AUTH ───────────

  /// POST /login → saves token, returns brief member payload.
  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await api.client.post('login', data: {
      'email': email,
      'password': password,
      'device_info': 'flutter-app',
    });
    final b = _ok(res);
    await api.saveToken(b['token'] as String);
    return (b['member'] as Map).cast<String, dynamic>();
  }

  /// GET /me → full signed-in member.
  /// Cache key for the last member payload, letting the splash enter the app
  /// within its 2s brand floor without waiting on /me. Kept in sync here so
  /// it is always tied to the current session.
  static const _meCacheKey = 'smrc_me_v1';

  Future<void> _cacheMe(Map<String, dynamic> map) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_meCacheKey, json.encode(map));
    } catch (_) {/* non-fatal */}
  }

  Future<void> _clearMeCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_meCacheKey);
    } catch (_) {/* non-fatal */}
  }

  Future<Map<String, dynamic>> meRaw() async {
    final res = await api.client.get('me');
    final b = _ok(res);
    final memberRaw = b['member'];
    if (memberRaw is! Map) {
      throw ApiException('Account not found.', code: 'account_deleted');
    }
    final map = memberRaw.cast<String, dynamic>();
    await _cacheMe(map); // keep the splash cache fresh
    return map;
  }

  Future<Member> me() async => Member.fromApi(await meRaw());

  /// POST /signup-invited — email+code already verified. Creates the member
  /// account directly (active, no application review, no OTP) and logs them
  /// straight in by saving the returned token.
  Future<void> signupInvited({
    required String fullName,
    required String email,
    required String password,
    required String inviteCode,
    String phone = '',
    String gender = '',
    String location = '',
  }) async {
    final res = await api.client.post('signup-invited', data: {
      'full_name': fullName,
      'email': email,
      'password': password,
      'invite_code': inviteCode,
      'phone': phone,
      'gender': gender,
      'location': location,
      'device_info': 'flutter-app',
    });
    final b = _ok(res);
    await api.saveToken(b['token'] as String);
  }

  /// POST /signup (requires a valid invite code). Returns application_id
  /// for the OTP verification step.
  /// Verifies an invite code against an email before the applicant fills out
  /// the whole form. Throws ApiException with a friendly message on mismatch.
  Future<void> checkInviteCode({required String email, required String inviteCode}) async {
    final res = await api.client.post('check-invite-code', data: {
      'email': email,
      'invite_code': inviteCode,
    });
    _ok(res);
  }

  Future<int> signup({
    required String fullName,
    required String email,
    required String password,
    String inviteCode = '',
    String phone = '',
    String gender = '',
    String location = '',
    String instagram = '',
    String whyJoin = '',
    String desiredTier = 'silver',
    String desiredRole = 'member',
  }) async {
    final res = await api.client.post('signup', data: {
      'full_name': fullName,
      'email': email,
      'password': password,
      'invite_code': inviteCode,
      'phone': phone,
      'gender': gender,
      'location': location,
      'instagram': instagram,
      'why_join': whyJoin,
      'desired_tier': desiredTier,
      'desired_role': desiredRole,
    });
    final b = _ok(res);
    return (b['application_id'] as num).toInt();
  }

  /// POST /verify-otp → moves application to pending review.
  /// Returns the application's real reference number (e.g. "APP-0007") so
  /// the confirmation screen can show it instead of a placeholder.
  Future<String?> verifyOtp(int applicationId, String otp) async {
    final res = await api.client.post('verify-otp', data: {
      'application_id': applicationId,
      'otp': otp,
    });
    final b = _ok(res);
    return b['refNo'] as String?;
  }

  /// POST /forgot-password — backend emails a 6-digit code (15 min, single-use).
  Future<void> forgotPassword(String email) async {
    final res = await api.client.post('forgot-password', data: {'email': email});
    _ok(res);
  }

  /// POST /verify-reset-otp — validates the code before the new-password step.
  Future<void> verifyResetOtp(String email, String otp) async {
    final res = await api.client.post('verify-reset-otp', data: {'email': email, 'otp': otp});
    _ok(res);
  }

  /// POST /reset-password — sets the new password and signs out all devices.
  Future<void> resetPassword(String email, String otp, String newPassword) async {
    final res = await api.client
        .post('reset-password', data: {'email': email, 'otp': otp, 'new_password': newPassword});
    _ok(res);
  }

  Future<void> logout() async {
    await _clearMeCache();
    await api.clearToken();
  }
  Future<bool> hasToken() async => ((await api.readToken()) ?? '').isNotEmpty;

  // ─────────── APP DATA ───────────

  Future<List<dynamic>> eventsRaw() async {
    final res = await api.client.get('app/events');
    final b = _ok(res);
    return b['events'] as List;
  }

  Future<List<ClubEvent>> events() async =>
      (await eventsRaw()).map((e) => ClubEvent.fromApi((e as Map).cast<String, dynamic>())).toList();

  /// Fetches ALL events including past ones — used by Gallery & Footage screens.
  Future<List<dynamic>> allEventsRaw() async {
    final res = await api.client.get('app/events', queryParameters: {'include_past': '1'});
    final b = _ok(res);
    return b['events'] as List;
  }

  Future<List<ClubEvent>> allEvents() async =>
      (await allEventsRaw()).map((e) => ClubEvent.fromApi((e as Map).cast<String, dynamic>())).toList();

  Future<List<dynamic>> announcementsRaw() async {
    final res = await api.client.get('app/announcements');
    final b = _ok(res);
    return b['announcements'] as List;
  }

  Future<List<Announcement>> announcements() async => (await announcementsRaw())
      .map((e) => Announcement.fromApi((e as Map).cast<String, dynamic>()))
      .toList();

  Future<List<dynamic>> membersRaw() async {
    final res = await api.client.get('app/members');
    final b = _ok(res);
    return b['members'] as List;
  }

  Future<List<Member>> members() async =>
      (await membersRaw()).map((e) => Member.fromApi((e as Map).cast<String, dynamic>())).toList();

  Future<Map<String, dynamic>> tiersRaw() async {
    final res = await api.client.get('app/tiers');
    return _ok(res);
  }

  Future<TiersPayload> tiers() async => TiersPayload.fromApi(await tiersRaw());

  Future<Map<String, dynamic>> benefitsRaw() async {
    final res = await api.client.get('app/benefits');
    return _ok(res);
  }

  Future<BenefitsPayload> benefits() async => BenefitsPayload.fromApi(await benefitsRaw());

  // Support chat
  Future<SupportThread> supportThread() async {
    final res = await api.client.get('app/support');
    final b = _ok(res);
    return SupportThread.fromApi(b);
  }

  Future<void> supportSend(String message, {String imageUrl = ''}) async {
    final res = await api.client.post('app/support', data: {'message': message, 'image_url': imageUrl});
    _ok(res);
  }

  /// Uploads a chat image (Group Chat or Support Chat) and returns its
  /// hosted URL, ready to send along with (or instead of) message text.
  Future<String> uploadChatImage(List<int> bytes) async {
    final b64 = base64Encode(bytes);
    final res = await api.client.post('app/chat/upload-image', data: {'image_base64': b64});
    final b = _ok(res);
    return b['url'] as String;
  }

  // Questions
  Future<List<QuestionItem>> questions() async {
    final res = await api.client.get('app/questions');
    final b = _ok(res);
    return (b['questions'] as List)
        .map((e) => QuestionItem.fromApi((e as Map).cast<String, dynamic>()))
        .toList();
  }

  Future<void> askQuestion(String question) async {
    final res = await api.client.post('app/questions', data: {'question': question});
    _ok(res);
  }

  // Group chat (The Circle Lounge)
  Future<GroupChatPayload> groupChat() async {
    final res = await api.client.get('app/group-chat');
    final b = _ok(res);
    return GroupChatPayload(
      pinned: (b['pinned_message'] as String?) ?? '',
      messages: (b['messages'] as List)
          .map((e) => GroupMsg.fromApi((e as Map).cast<String, dynamic>()))
          .toList(),
    );
  }

  Future<void> groupSend(String message, {String imageUrl = ''}) async {
    final res = await api.client.post('app/group-chat', data: {'message': message, 'image_url': imageUrl});
    _ok(res);
  }

  // Member support tickets
  Future<List<TicketItem>> tickets() async {
    final res = await api.client.get('app/tickets');
    final b = _ok(res);
    return (b['tickets'] as List)
        .map((e) => TicketItem.fromApi((e as Map).cast<String, dynamic>()))
        .toList();
  }

  Future<String> createTicket(
      {required String category, required String subject, required String body}) async {
    final res = await api.client
        .post('app/tickets', data: {'category': category, 'subject': subject, 'body': body});
    final b = _ok(res);
    return (b['ref_no'] as String?) ?? '';
  }

  Future<void> replyTicket(int id, String message) async {
    final res = await api.client.post('app/tickets/$id/reply', data: {'message': message});
    _ok(res);
  }

  // Founders benefit offer
  Future<bool> hasActiveFoundersOffer() async {
    final res = await api.client.get('app/me/benefit-offer');
    final b = _ok(res);
    return b['active'] == true;
  }

  /// Full active benefit offer (or null). Includes tier, message, expiry, seen.
  Future<BenefitOffer?> benefitOffer() async {
    final res = await api.client.get('app/me/benefit-offer');
    final b = _ok(res);
    if (b['active'] != true || b['offer'] == null) return null;
    return BenefitOffer.fromApi((b['offer'] as Map).cast<String, dynamic>());
  }

  Future<void> markBenefitOfferSeen() async {
    try { await api.client.post('app/me/benefit-offer/seen', data: {}); } catch (_) {}
  }

  Future<Map<String, dynamic>> acceptBenefitOffer() async {
    final res = await api.client.post('app/me/benefit-offer/accept', data: {});
    return _ok(res);
  }

  /// In-app notifications for the member.
  Future<List<AppNotification>> notifications() async {
    final res = await api.client.get('app/me/notifications');
    final b = _ok(res);
    final list = (b['notifications'] as List?) ?? const [];
    return list
        .map((e) => AppNotification.fromApi((e as Map).cast<String, dynamic>()))
        .toList();
  }

  Future<void> markNotificationsRead({int? id}) async {
    try {
      await api.client.post('app/me/notifications/read', data: id != null ? {'id': id} : {});
    } catch (_) {}
  }

  // Profile update
  Future<void> updateProfile({
    String? city,
    String? industry,
    String? instagram,
    String? bio,
    String? gender,
    List<String>? interests,
  }) async {
    final data = <String, dynamic>{};
    if (city != null) data['city'] = city;
    if (industry != null) data['industry'] = industry;
    if (instagram != null) data['instagram'] = instagram;
    if (bio != null) data['bio'] = bio;
    if (gender != null) data['gender'] = gender;
    if (interests != null) data['interests'] = interests;
    final res = await api.client.put('app/me/profile', data: data);
    _ok(res);
  }

  /// Screen & Copy key/value map (podcast link, cheer images, hero copy...).
  /// Fetches the Circle Lounge pinned message directly — bypasses the screens cache.
  /// Member purchases a ticket — returns ticket_no. Idempotent.
  Future<String> purchaseTicket(int eventId, {String? paymentIntentId}) async {
    final res = await api.client.post('app/me/purchase-ticket', data: {
      'event_id': eventId,
      if (paymentIntentId != null) 'payment_intent_id': paymentIntentId,
    });
    final b = _ok(res);
    return (b['ticket_no'] as String?) ?? '';
  }

  Future<List<EventTicket>> eventTickets() async {
    final res = await api.client.get('app/me/event-tickets');
    final b = _ok(res);
    return (b['tickets'] as List)
        .map((e) => EventTicket.fromApi((e as Map).cast<String, dynamic>()))
        .toList();
  }

  Future<String> pinnedMessage() async {
    try {
      final res = await api.client.get('app/pinned-message');
      final b = _body(res);
      return (b['message'] as String?) ?? '';
    } catch (_) {
      return '';
    }
  }

  Future<Map<String, dynamic>> screensRaw() async {
    final res = await api.client.get('app/screens');
    final b = _ok(res);
    return ((b['screens'] ?? {}) as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> screens() async => screensRaw();

  /// Upload a new profile photo (JPG/PNG bytes) — returns the hosted URL.
  Future<String> uploadProfilePhoto(List<int> bytes) async {
    final res = await api.client.post('app/me/photo', data: {
      'image_base64': base64Encode(bytes),
    });
    final b = _ok(res);
    return (b['url'] as String?) ?? '';
  }

  /// Schedules membership cancellation at the end of the current paid period.
  /// Returns the human-readable date access remains active until.
  Future<String> cancelMembership({String reason = ''}) async {
    final res = await api.client.post('app/me/cancel-membership', data: {'reason': reason});
    final b = _ok(res);
    return (b['message'] as String?) ?? '';
  }

  /// Permanently deletes the signed-in member's account (Google Play /
  /// Apple account-deletion requirement). Irreversible on the server side —
  /// the caller is responsible for clearing the local token afterwards.
  Future<String> deleteAccount() async {
    final res = await api.client.post('app/me/delete-account');
    final b = _ok(res);
    return (b['message'] as String?) ?? 'Your account has been deleted.';
  }

  /// Reverses a scheduled cancellation.
  Future<String> resumeMembership() async {
    final res = await api.client.post('app/me/resume-membership', data: {});
    final b = _ok(res);
    return (b['message'] as String?) ?? '';
  }

  /// Purchase / renew / upgrade a membership tier.
  /// [action] is one of 'new', 'renew', 'upgrade'. Returns the server payload
  /// (amount charged, new tier, refreshed dates).
  Future<Map<String, dynamic>> purchaseMembership(
      {required String tierKey, required String action, String? paymentIntentId}) async {
    final res = await api.client.post('app/me/purchase-membership', data: {
      'tier_key': tierKey,
      'action': action,
      if (paymentIntentId != null) 'payment_intent_id': paymentIntentId,
    });
    return _ok(res);
  }

  /// The Stripe publishable key + whether test or live mode is active,
  /// fetched at runtime rather than baked into the build — switching
  /// test/live mode is then a Settings change on the server, not a new app
  /// release. Returns null if payments aren't configured yet on the server
  /// (caller should show a friendly message).
  Future<StripeKeyInfo?> stripeKeyInfo() async {
    final res = await api.client.get('app/me/stripe-publishable-key');
    // Deliberately _body() not _ok() here: the server returns HTTP 200 with
    // success:false + a human-readable message when payments simply aren't
    // configured yet (that's a normal, expected state, not a request
    // failure) — _ok() would throw and swallow that message, leaving every
    // caller with the same generic "unavailable" wording no matter what
    // actually went wrong server-side.
    final b = _body(res);
    if (b['success'] != true) {
      if (kDebugMode) {
        debugPrint('stripeKeyInfo: not configured — ${b['message']}');
      }
      return null;
    }
    final key = b['publishableKey'] as String?;
    if (key == null || key.isEmpty) return null;
    return StripeKeyInfo(publishableKey: key, testMode: b['testMode'] == true);
  }

  /// Step 1 of any paid purchase — computes the correct amount server-side
  /// and opens a Stripe PaymentIntent for it. `purpose` is 'membership' or
  /// 'ticket'; pass tierKey+action for membership, eventId for a ticket.
  /// If the item is actually free for this member, `amount` comes back 0
  /// and `clientSecret` is null — the caller should skip payment entirely
  /// and go straight to purchaseMembership()/purchaseTicket().
  Future<PaymentIntentResult> createPaymentIntent({
    required String purpose,
    String? tierKey,
    String? action,
    int? eventId,
  }) async {
    final res = await api.client.post('app/me/create-payment-intent', data: {
      'purpose': purpose,
      if (tierKey != null) 'tier_key': tierKey,
      if (action != null) 'action': action,
      if (eventId != null) 'event_id': eventId,
    });
    final b = _ok(res);
    if (b['success'] != true) {
      throw ApiException((b['message'] as String?) ?? 'Could not start payment.');
    }
    return PaymentIntentResult(
      clientSecret: b['clientSecret'] as String?,
      paymentIntentId: b['paymentIntentId'] as String?,
      amount: (b['amount'] as num?)?.toDouble() ?? 0,
      freeNoPaymentNeeded: b['freeNoPaymentNeeded'] == true,
    );
  }

  /// Billing history — the member's membership payment transactions.
  Future<List<dynamic>> billingRaw() async {
    final res = await api.client.get('app/me/billing');
    final b = _ok(res);
    return (b['billing'] as List?) ?? const [];
  }

  Future<List<BillingEntry>> billing() async =>
      (await billingRaw()).map((e) => BillingEntry.fromApi((e as Map).cast<String, dynamic>())).toList();


  // Push token registration (OneSignal player id)
  /// Sets a password using the one-time token from the "set your password"
  /// deep link — the in-app equivalent of the web fallback page, same
  /// backend endpoint, no browser involved.
  Future<void> setPasswordByToken(String token, String newPassword) async {
    final res =
        await api.client.post('set-password-by-token', data: {'token': token, 'new_password': newPassword});
    _ok(res);
  }

  Future<void> registerPushToken(String playerId) async {
    try {
      await api.client.post('app/me/push-token', data: {'player_id': playerId});
    } catch (_) {/* non-fatal */}
  }

  /// Syncs the Lounge "Push notifications" toggle to the server — this is
  /// what actually makes it do something. Before this existed, the toggle
  /// only wrote a local SharedPreferences flag that nothing else read; the
  /// server had no way to know a member had opted out of Lounge pushes.
  Future<void> setGroupChatPushPref(bool enabled) async {
    try {
      await api.client.post('app/me/gc-push-pref', data: {'enabled': enabled});
    } catch (_) {/* non-fatal — local toggle still reflects the choice */}
  }
}

/// Result of SmrcRepository.stripeKeyInfo().
class StripeKeyInfo {
  final String publishableKey;
  final bool testMode;
  const StripeKeyInfo({required this.publishableKey, required this.testMode});
}

/// Result of SmrcRepository.createPaymentIntent(). When [freeNoPaymentNeeded]
/// is true, [clientSecret] and [paymentIntentId] are null — the item is free
/// for this member and the caller should skip Stripe entirely.
class PaymentIntentResult {
  final String? clientSecret;
  final String? paymentIntentId;
  final double amount;
  final bool freeNoPaymentNeeded;
  const PaymentIntentResult({
    required this.clientSecret,
    required this.paymentIntentId,
    required this.amount,
    required this.freeNoPaymentNeeded,
  });
}

class ApiException implements Exception {
  final String message;
  final String? code;
  final Map<String, dynamic>? data;
  ApiException(this.message, {this.code, this.data});
  @override
  String toString() => message;
}
