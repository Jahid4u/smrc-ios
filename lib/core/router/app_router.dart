import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../models/club_event.dart';
import '../../models/member.dart';
import '../../models/api_models.dart';
import '../../models/member_tier.dart';
import '../../providers/app_providers.dart';

// Screens
import '../../screens/splash/splash_screen.dart';
import '../../screens/auth/welcome_screen.dart';
import '../../screens/auth/sign_in_screen.dart';
import '../../screens/auth/set_password_screen.dart';
import '../../screens/auth/invitation_code_screen.dart';
import '../../screens/auth/forgot_password_screens.dart';
import '../../screens/onboarding/onboarding_screens.dart';
import '../../screens/onboarding/membership_locked_screen.dart';
import '../../screens/home/home_shell.dart';
import '../../screens/account/account_screens.dart';
import '../../screens/support/support_screens.dart';
import '../../screens/events/events_screens.dart';
import '../../screens/society/society_screens.dart';

/// Routes reachable while logged out (auth + invite/application flow).
/// Anything not in this set redirects a logged-out user to /welcome.
const _publicRoutes = {
  '/welcome',
  '/sign-in',
  '/set-password',
  '/forgot-password-1',
  '/forgot-password-2',
  '/forgot-password-3',
  '/invitation-code',
  '/profile-completion-1',
  '/membership-path',
  '/application-form',
  '/verify-email',
  '/application-submitted',
  '/pending-review',
  '/approved',
  '/not-approved',
  '/profile-completion-2',
};

/// Routes a signed-in member WITHOUT an active membership may still reach —
/// the activation gate itself, the tier-selection/checkout flow needed to
/// activate, and notifications (kept reachable per MembershipLockedScreen's
/// own comment). Every other route is off-limits until membership is active.
const _membershipFlowRoutes = {
  '/membership-locked',
  '/membership-tiers',
  '/tier-comparison',
  '/membership-checkout',
  '/membership-confirmation',
  '/notifications',
};

/// Single source of truth for who can go where. This used to live only
/// inside HomeShell's build() (guarding the 5 tab routes) — every other
/// route (account, notifications, event-detail, support, tickets-wallet…)
/// had no check at all, so a member without an active membership could
/// reach them directly (e.g. by popping/leaving the locked screen) and use
/// the app normally. Centralising it here at the router level closes that
/// hole for every current and future route in one place.
String? _membershipRedirect(BuildContext context, GoRouterState state) {
  final loc = state.matchedLocation;
  if (loc == '/splash') return null; // splash decides its own first hop

  final me = routerContainer.read(currentMemberProvider);
  final loggedIn = me != null;
  final active = me?.hasActiveMembership ?? false;

  if (!loggedIn) {
    return _publicRoutes.contains(loc) ? null : '/welcome';
  }

  if (!me.hasCompleteProfile) {
    return loc == '/profile-completion-2' ? null : '/profile-completion-2';
  }

  if (!active) {
    if (_membershipFlowRoutes.contains(loc) || _publicRoutes.contains(loc)) return null;
    return '/membership-locked';
  }

  // Active member — don't let them sit on auth/activation screens.
  if (_publicRoutes.contains(loc) || loc == '/membership-locked') {
    return '/explore';
  }
  return null;
}

/// Router covering the full 58-screen catalog — every route is a real,
/// pixel-matched screen ported from the HTML simulator.
final appRouter = GoRouter(
  initialLocation: '/splash',
  redirect: _membershipRedirect,
  refreshListenable: routerRefreshNotifier,
  routes: [
    // ── I. Arrival & Onboarding ──
    GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/membership-locked', builder: (_, __) => const MembershipLockedScreen()),
    GoRoute(path: '/welcome', builder: (_, __) => const WelcomeScreen()),
    GoRoute(path: '/sign-in', builder: (_, __) => const SignInScreen()),
    GoRoute(
        path: '/set-password',
        builder: (_, s) => SetPasswordScreen(token: (s.extra as String?) ?? '')),
    GoRoute(path: '/forgot-password-1', builder: (_, __) => const ForgotPasswordEmailScreen()),
    GoRoute(
        path: '/forgot-password-2',
        builder: (_, s) => ForgotPasswordOtpScreen(email: (s.extra as String?) ?? '')),
    GoRoute(
        path: '/forgot-password-3',
        builder: (_, s) {
          final m = (s.extra as Map?)?.cast<String, dynamic>() ?? {};
          return ForgotPasswordResetScreen(
              email: (m['email'] as String?) ?? '', otp: (m['otp'] as String?) ?? '');
        }),
    GoRoute(path: '/invitation-code', builder: (_, __) => const InvitationCodeScreen()),
    GoRoute(path: '/profile-completion-1', builder: (_, __) => const ProfileCompletionScreen(invitation: true)),
    GoRoute(path: '/membership-path', builder: (_, __) => const MembershipPathScreen()),
    GoRoute(
        path: '/application-form',
        builder: (_, s) {
          final extra = s.extra;
          if (extra is Map) {
            return ApplicationFormScreen(
                inviteCode: extra['code'] as String?,
                inviteEmail: extra['email'] as String?,
                desiredRole: (extra['desiredRole'] as String?) ?? 'member');
          }
          return ApplicationFormScreen(inviteCode: extra as String?);
        }),
    GoRoute(
      path: '/verify-email',
      builder: (_, s) {
        final m = (s.extra as Map?)?.cast<String, dynamic>() ?? {};
        return VerifyEmailScreen(
            applicationId: (m['application_id'] as num?)?.toInt() ?? 0,
            email: (m['email'] as String?) ?? '');
      },
    ),
    GoRoute(path: '/application-submitted', builder: (_, state) => ApplicationSubmittedScreen(refNo: state.extra as String?)),
    GoRoute(path: '/pending-review', builder: (_, state) => PendingReviewScreen(refNo: state.extra as String?)),
    GoRoute(path: '/approved', builder: (_, __) => const ApprovedScreen()),
    GoRoute(path: '/not-approved', builder: (_, state) => NotApprovedScreen(refNo: state.extra as String?)),
    GoRoute(path: '/profile-completion-2', builder: (_, __) => const ProfileCompletionScreen()),

    // ── II. Member Experience — tabs (all live inside HomeShell) ──
    GoRoute(path: '/explore', builder: (_, __) => const HomeShell(initialTab: 0)),
    GoRoute(path: '/events', builder: (_, __) => const HomeShell(initialTab: 1)),
    GoRoute(path: '/society', builder: (_, __) => const HomeShell(initialTab: 2)),
    GoRoute(path: '/benefits', builder: (_, __) => const HomeShell(initialTab: 3)),
    GoRoute(path: '/cheer', builder: (_, __) => const HomeShell(initialTab: 4)),

    GoRoute(path: '/founders-benefit', builder: (_, __) => const FoundersBenefitScreen()),
    GoRoute(path: '/account', builder: (_, __) => const AccountScreen()),
    GoRoute(
        path: '/member-profile',
        builder: (_, s) => AccountScreen(previewMember: s.extra as Member?)),
    GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),
    GoRoute(path: '/edit-profile', builder: (_, __) => const EditProfileScreen()),
    GoRoute(path: '/membership-tier-settings', builder: (_, __) => const MembershipTierSettingsScreen()),
    GoRoute(path: '/payments-billing', builder: (_, __) => const PaymentsBillingScreen()),
    GoRoute(path: '/concierge-support', builder: (_, __) => const ConciergeSupportScreen()),
    GoRoute(path: '/ask-a-question', builder: (_, __) => const AskAQuestionScreen()),
    GoRoute(
        path: '/question-detail',
        builder: (_, s) => QuestionDetailScreen(question: s.extra as QuestionItem)),
    GoRoute(path: '/support-1', builder: (_, __) => const SupportListScreen()),
    GoRoute(path: '/support-2', builder: (_, __) => const SupportCreateScreen()),
    GoRoute(path: '/support-3', builder: (_, s) => SupportThreadScreen(ticket: s.extra as TicketItem?)),
    GoRoute(path: '/account-legal', builder: (_, __) => const AccountLegalScreen()),
    GoRoute(path: '/tickets-wallet', builder: (_, __) => const TicketsWalletHubScreen()),
    GoRoute(path: '/past-tickets', builder: (_, __) => const PastTicketsScreen()),

    // ── III. Events ──
    // One detail screen serves Weekly/Big/Trip × Buy/RSVP automatically:
    // the CTA & pricing flip based on the type-driven rules in ClubEvent.
    GoRoute(
      path: '/event-detail',
      builder: (_, state) => EventDetailScreen(event: state.extra as ClubEvent?),
    ),
    GoRoute(path: '/ticket-purchase', builder: (_, s) => TicketPurchaseScreen(event: s.extra as ClubEvent?)),
    GoRoute(
        path: '/confirmation',
        builder: (_, s) {
          final extra = s.extra;
          if (extra is Map) {
            final m = extra.cast<String, dynamic>();
            return ConfirmationScreen(
              event: m['event'] as ClubEvent?,
              ticketNo: (m['ticketNo'] as String?) ?? '',
            );
          }
          return ConfirmationScreen(event: extra as ClubEvent?);
        }),
    GoRoute(path: '/ticket-wallet', builder: (_, __) => const TicketWalletScreen()),

    // ── Society ──
    GoRoute(path: '/announcements', builder: (_, __) => const AnnouncementsScreen()),
    GoRoute(path: '/support-chat', builder: (_, __) => const SupportChatScreen()),
    GoRoute(path: '/society-chat', builder: (_, __) => const SocietyChatScreen()),
    GoRoute(path: '/member-directory', builder: (_, __) => const MemberDirectoryScreen()),
    GoRoute(path: '/event-gallery-1', builder: (_, __) => const DrivePickerScreen()),
    GoRoute(
        path: '/event-gallery-2',
        builder: (_, s) => DriveDetailScreen(event: s.extra as ClubEvent?)),
    GoRoute(path: '/event-footage-1', builder: (_, __) => const DrivePickerScreen(footage: true)),
    GoRoute(
        path: '/event-footage-2',
        builder: (_, s) => DriveDetailScreen(footage: true, event: s.extra as ClubEvent?)),

    // ── IV. Membership Tiers ──
    GoRoute(path: '/membership-tiers', builder: (_, __) => const MembershipTiersScreen()),
    GoRoute(path: '/tier-comparison', builder: (_, __) => const TierComparisonScreen()),
    GoRoute(
        path: '/membership-checkout',
        builder: (_, s) => MembershipCheckoutScreen(tier: s.extra as TierInfo?)),
    GoRoute(
        path: '/membership-confirmation',
        builder: (_, s) {
          final extra = s.extra;
          if (extra is Map) {
            return MembershipConfirmationScreen(
                tier: extra['tier'] as TierInfo?,
                action: (extra['action'] as String?) ?? 'new');
          }
          return MembershipConfirmationScreen(tier: extra as TierInfo?);
        }),

    // ── V. Profiles & Badges — same screen, identity via ring + badge ──
    GoRoute(
      path: '/profile-silver-man',
      builder: (_, __) => AccountScreen(
          previewMember: Member(
              id: 'p1', memberNo: 'No. 0203', name: 'James Okoro', gender: Gender.man, tier: MemberTier.silver,
              avatarUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=300&q=80',
              joinedAt: DateTime(2026))),
    ),
    GoRoute(
      path: '/profile-gold-woman',
      builder: (_, __) => AccountScreen(
          previewMember: Member(
              id: 'p2', memberNo: 'No. 0156', name: 'Selina Marwan', gender: Gender.woman, tier: MemberTier.gold,
              avatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=300&q=80',
              joinedAt: DateTime(2026))),
    ),
    GoRoute(
      path: '/profile-black-diamond',
      builder: (_, __) => AccountScreen(
          previewMember: Member(
              id: 'p3', memberNo: 'No. 0007', name: 'Sebastian Moreau', gender: Gender.man,
              tier: MemberTier.blackDiamond,
              avatarUrl: 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=300&q=80',
              joinedAt: DateTime(2026))),
    ),
    GoRoute(
      path: '/profile-brand-ambassador',
      builder: (_, __) => AccountScreen(
          previewMember: Member(
              id: 'p4', memberNo: 'No. AMB-014', name: 'Ava Lindholm', gender: Gender.woman,
              tier: MemberTier.ambassador,
              avatarUrl: 'https://images.unsplash.com/photo-1488426862026-3ee34a7d66df?w=300&q=80',
              joinedAt: DateTime(2026))),
    ),
    GoRoute(
      path: '/profile-admin',
      builder: (_, __) => AccountScreen(
          previewMember: Member(
              id: 'p5', memberNo: 'No. ADM-002', name: 'Helena Cruz', gender: Gender.woman, tier: MemberTier.admin,
              avatarUrl: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=300&q=80',
              joinedAt: DateTime(2025))),
    ),
    GoRoute(path: '/ambassador-benefits', builder: (_, __) => const AmbassadorBenefitsScreen()),
  ],
);
