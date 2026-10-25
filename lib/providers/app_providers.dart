import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_client.dart';
import '../core/api/smrc_repository.dart';
import '../core/demo_data.dart';
import '../models/member.dart';
import '../models/club_event.dart';
import '../models/api_models.dart';
import '../core/cache/content_cache.dart';

/// App-wide container, created once in main() before runApp. Needed so the
/// GoRouter's top-level `redirect` (which runs outside the widget tree, and
/// therefore has no BuildContext/WidgetRef to watch providers with) can
/// still read currentMemberProvider and enforce the membership gate on
/// *every* route — not just the ones whose screens happen to watch it.
late final ProviderContainer routerContainer;

/// Fires whenever the signed-in member (or their membership status) changes,
/// so GoRouter's `refreshListenable` can re-run the redirect immediately —
/// e.g. the instant a membership is cancelled, or activated, from anywhere
/// in the app, without waiting for the user to manually navigate.
class MemberChangeNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

final routerRefreshNotifier = MemberChangeNotifier();

void initRouterContainer() {
  routerContainer = ProviderContainer();
  routerContainer.listen<Member?>(
    currentMemberProvider,
    (previous, next) => routerRefreshNotifier.notify(),
    fireImmediately: true,
  );
}

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient.create());
final repoProvider = Provider<SmrcRepository>((ref) => SmrcRepository(ref.watch(apiClientProvider)));

/// Lets any screen hosted inside HomeShell's IndexedStack (Explore, Events,
/// SM Society, Benefits, Cheer) request a tab switch — e.g. Events' "Discover
/// more on home" button jumping to Explore.
///
/// Switching tabs via the bottom nav is purely internal to HomeShell
/// (IndexedStack + setState) and never changes GoRouter's current location.
/// So a button on one of those screens calling context.go('/explore') while
/// the router is already sitting on '/explore' (the common case — that's the
/// location HomeShell was built from) is a no-op: GoRouter sees no location
/// change and never rebuilds anything, so the tab visibly does nothing.
///
/// This provider sidesteps routing entirely: set it to the target tab index,
/// HomeShell's listener consumes it and switches, then resets it to null.
final homeShellTabRequestProvider = StateProvider<int?>((ref) => null);

/// The signed-in member. Null when logged out. Set by splash (token restore)
/// and by the sign-in screen after POST /login → GET /me.
final currentMemberProvider = StateProvider<Member?>((ref) => null);

/// Safe getter used by screens that can render before login completes.
final memberOrDemoProvider = Provider<Member>(
    (ref) => ref.watch(currentMemberProvider) ?? DemoData.you);

final isLoggedInProvider = Provider<bool>((ref) => ref.watch(currentMemberProvider) != null);

/// The route a member should land on after auth: the app if their membership
/// is active, otherwise the locked activation gate. Centralised so every
/// entry point (sign-in, splash, approval) behaves identically.
String memberHomeRoute(Member? m) {
  if (m == null) return '/membership-locked';
  if (!m.hasCompleteProfile) return '/profile-completion-2';
  return m.hasActiveMembership ? '/explore' : '/membership-locked';
}

/// Upcoming events from GET /app/events; demo seed only if the API is
/// unreachable so the UI never renders blank. Cache-first: shows the last
/// downloaded list instantly on every launch after the first, refreshing
/// quietly in the background instead of re-downloading before anything shows.
class _EventsNotifier extends CachedAsyncNotifier<List<ClubEvent>> {
  @override
  String get cacheKey => 'events';
  @override
  Future<dynamic> fetchRaw() => ref.watch(repoProvider).eventsRaw();
  @override
  List<ClubEvent> parse(dynamic raw) => (raw as List)
      .map((e) => ClubEvent.fromApi((e as Map).cast<String, dynamic>()))
      .where((e) => !e.isPast)
      .toList();
}

final eventsProvider = AsyncNotifierProvider<_EventsNotifier, List<ClubEvent>>(_EventsNotifier.new);

/// All events including past ones (for the Gallery/Footage pickers).
class _AllEventsNotifier extends CachedAsyncNotifier<List<ClubEvent>> {
  @override
  String get cacheKey => 'all_events';
  @override
  Future<dynamic> fetchRaw() => ref.watch(repoProvider).allEventsRaw();
  @override
  List<ClubEvent> parse(dynamic raw) =>
      (raw as List).map((e) => ClubEvent.fromApi((e as Map).cast<String, dynamic>())).toList();
}

final allEventsProvider = AsyncNotifierProvider<_AllEventsNotifier, List<ClubEvent>>(_AllEventsNotifier.new);

class _AnnouncementsNotifier extends CachedAsyncNotifier<List<Announcement>> {
  @override
  String get cacheKey => 'announcements';
  @override
  Future<dynamic> fetchRaw() => ref.watch(repoProvider).announcementsRaw();
  @override
  List<Announcement> parse(dynamic raw) => (raw as List)
      .map((e) => Announcement.fromApi((e as Map).cast<String, dynamic>()))
      .toList();
}

final announcementsProvider =
    AsyncNotifierProvider<_AnnouncementsNotifier, List<Announcement>>(_AnnouncementsNotifier.new);

class _DirectoryNotifier extends CachedAsyncNotifier<List<Member>> {
  @override
  String get cacheKey => 'directory';
  @override
  Future<dynamic> fetchRaw() => ref.watch(repoProvider).membersRaw();
  @override
  List<Member> parse(dynamic raw) =>
      (raw as List).map((e) => Member.fromApi((e as Map).cast<String, dynamic>())).toList();
}

final directoryProvider = AsyncNotifierProvider<_DirectoryNotifier, List<Member>>(_DirectoryNotifier.new);

/// Real membership billing history for the logged-in member.
class _BillingNotifier extends CachedAsyncNotifier<List<BillingEntry>> {
  @override
  String get cacheKey => 'billing';
  @override
  Future<dynamic> fetchRaw() => ref.watch(repoProvider).billingRaw();
  @override
  List<BillingEntry> parse(dynamic raw) =>
      (raw as List).map((e) => BillingEntry.fromApi((e as Map).cast<String, dynamic>())).toList();

  @override
  Future<List<BillingEntry>> build() async {
    try {
      return await super.build();
    } catch (_) {
      return <BillingEntry>[];
    }
  }
}

final billingProvider = AsyncNotifierProvider<_BillingNotifier, List<BillingEntry>>(_BillingNotifier.new);

class _TiersNotifier extends CachedAsyncNotifier<TiersPayload> {
  @override
  String get cacheKey => 'tiers';
  @override
  Future<dynamic> fetchRaw() => ref.watch(repoProvider).tiersRaw();
  @override
  TiersPayload parse(dynamic raw) => TiersPayload.fromApi((raw as Map).cast<String, dynamic>());
}

final tiersProvider = AsyncNotifierProvider<_TiersNotifier, TiersPayload>(_TiersNotifier.new);

class _BenefitsNotifier extends CachedAsyncNotifier<BenefitsPayload> {
  @override
  String get cacheKey => 'benefits';
  @override
  Future<dynamic> fetchRaw() => ref.watch(repoProvider).benefitsRaw();
  @override
  BenefitsPayload parse(dynamic raw) => BenefitsPayload.fromApi((raw as Map).cast<String, dynamic>());
}

final benefitsProvider = AsyncNotifierProvider<_BenefitsNotifier, BenefitsPayload>(_BenefitsNotifier.new);

final questionsProvider = FutureProvider<List<QuestionItem>>((ref) async {
  return await ref.watch(repoProvider).questions();
});

/// Support chat thread — always real. Errors surface in the UI with retry;
/// showing fake concierge messages would be worse than an honest error.
final supportThreadProvider =
    FutureProvider<SupportThread>((ref) => ref.watch(repoProvider).supportThread());

/// Group chat (The Circle Lounge) — always real, same reasoning.
final groupChatProvider =
    FutureProvider<GroupChatPayload>((ref) => ref.watch(repoProvider).groupChat());

/// Member's own support tickets.
final ticketsProvider =
    FutureProvider<List<TicketItem>>((ref) => ref.watch(repoProvider).tickets());

final foundersOfferProvider = FutureProvider<bool>((ref) async {
  try {
    return await ref.watch(repoProvider).hasActiveFoundersOffer();
  } catch (_) {
    return false;
  }
});

/// Full active benefit offer (tier, message, expiry) or null.
final benefitOfferProvider = FutureProvider<BenefitOffer?>((ref) async {
  try {
    return await ref.watch(repoProvider).benefitOffer();
  } catch (_) {
    return null;
  }
});

/// Real in-app notifications for the member.
final notificationsProvider = FutureProvider<List<AppNotification>>((ref) async {
  try {
    return await ref.watch(repoProvider).notifications();
  } catch (_) {
    return <AppNotification>[];
  }
});

/// Notification ids marked read locally the instant the user taps them —
/// an optimistic overlay so the unread dot clears immediately and can never
/// get stuck, regardless of server round-trip timing. Merged with the
/// server's own isRead flag in unreadCountProvider below.
final locallyReadNotificationIdsProvider = StateProvider<Set<int>>((ref) => {});

/// Unread notification count (drives the explore bell dot).
final unreadCountProvider = Provider<int>((ref) {
  final locallyRead = ref.watch(locallyReadNotificationIdsProvider);
  return ref.watch(notificationsProvider).maybeWhen(
      data: (list) => list.where((n) => !n.isRead && !locallyRead.contains(n.id)).length,
      orElse: () => 0);
});

/// Screen & Copy values from the admin panel (podcast link, cheer images...).
class _ScreenCopyNotifier extends CachedAsyncNotifier<Map<String, dynamic>> {
  @override
  String get cacheKey => 'screen_copy';
  @override
  Future<dynamic> fetchRaw() => ref.watch(repoProvider).screensRaw();
  @override
  Map<String, dynamic> parse(dynamic raw) => (raw as Map).cast<String, dynamic>();

  @override
  Future<Map<String, dynamic>> build() async {
    try {
      return await super.build();
    } catch (_) {
      return const {};
    }
  }
}

final screenCopyProvider =
    AsyncNotifierProvider<_ScreenCopyNotifier, Map<String, dynamic>>(_ScreenCopyNotifier.new);

/// Pinned message for the Circle Lounge — always fresh, dedicated endpoint.
final pinnedMessageProvider = FutureProvider.autoDispose<String>(
    (ref) => ref.watch(repoProvider).pinnedMessage());

/// Member's event tickets (passes).
final eventTicketsProvider = FutureProvider<List<EventTicket>>(
    (ref) => ref.watch(repoProvider).eventTickets());
