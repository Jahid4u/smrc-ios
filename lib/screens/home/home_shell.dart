import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/app_providers.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/benefit_offer_dialog.dart';
import '../../widgets/app_bottom_nav.dart';
import 'explore_screen.dart';
import '../events/events_screens.dart';
import '../society/society_screens.dart';

/// Hosts the persistent 5-tab bottom bar. System back walks back through the
/// visited tabs; from the last one it asks before closing the app.
class HomeShell extends ConsumerStatefulWidget {
  final int initialTab;
  const HomeShell({super.key, this.initialTab = 0});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  late AppTab _tab = AppTab.values[widget.initialTab.clamp(0, AppTab.values.length - 1)];
  final List<AppTab> _history = [];
  Timer? _copyRefresh;
  bool _offerShownThisSession = false;

  @override
  void initState() {
    super.initState();
    // Explore/Cheer stay alive in the IndexedStack for the whole session, so
    // their Screen & Copy data (podcast link, cheer images/titles, hero
    // text) would otherwise never refresh after an admin edit. Re-pull it
    // periodically so edits show up without needing an app restart.
    _copyRefresh = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted) {
        ref.invalidate(screenCopyProvider);
        ref.invalidate(notificationsProvider);
      }
    });
    // Warm up notifications so the explore bell dot reflects unread state.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationsProvider);
    });
    // Show any active benefit offer once the shell is up. It re-appears on a
    // fresh app launch until the member accepts it (backend keeps returning it).
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowBenefitOffer());
  }

  Future<void> _maybeShowBenefitOffer() async {
    if (_offerShownThisSession || !mounted) return;
    final offer = await ref.read(benefitOfferProvider.future);
    if (offer == null || offer.accepted || !mounted) return;
    _offerShownThisSession = true;
    // Mark seen so we don't repeatedly log/push a notification, but the popup
    // still shows on each fresh launch until accepted.
    ref.read(repoProvider).markBenefitOfferSeen();
    (await SharedPreferences.getInstance()).setInt('smrc_seen_offer_id', offer.id);
    if (!mounted) return;
    await showBenefitOfferDialog(context, ref, offer);
  }

  @override
  void didUpdateWidget(covariant HomeShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    // GoRouter reuses this same State when navigating between routes that
    // both build HomeShell (e.g. Events' "Discover more on home" button doing
    // context.go('/explore') while already showing HomeShell(initialTab: 1)).
    // _tab is only seeded from widget.initialTab once, in initState, so
    // without this the tab silently stayed put — the button looked like it
    // did nothing. Re-sync _tab whenever the requested initial tab changes.
    if (widget.initialTab != oldWidget.initialTab) {
      final newTab = AppTab.values[widget.initialTab.clamp(0, AppTab.values.length - 1)];
      if (newTab != _tab) {
        setState(() {
          _history.add(_tab);
          _tab = newTab;
        });
      }
    }
  }

  @override
  void dispose() {
    _copyRefresh?.cancel();
    super.dispose();
  }

  void _select(AppTab t) {
    if (t == _tab) return;
    setState(() {
      _history.add(_tab);
      _tab = t;
    });
  }

  Future<void> _onBack() async {
    // Walk back through visited tabs first.
    if (_history.isNotEmpty) {
      setState(() => _tab = _history.removeLast());
      return;
    }
    // Then confirm before closing the app.
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.charcoal,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Leave the Circle?', style: AppTextStyles.serif(size: 20, color: Colors.white)),
        content: Text('Do you want to close the app?',
            style: AppTextStyles.inter(size: 12.5, weight: FontWeight.w300, color: AppColors.muted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('STAY', style: AppTextStyles.inter(size: 11, color: AppColors.muted, letterSpacing: 2)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('CLOSE', style: AppTextStyles.inter(size: 11, color: AppColors.gold, letterSpacing: 2)),
          ),
        ],
      ),
    );
    if (leave == true) {
      await SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Screens hosted inside this shell's IndexedStack (e.g. Events' "Discover
    // more on home" button) can't reliably switch tabs with context.go() —
    // switching tabs via the bottom nav never changes GoRouter's location, so
    // the router is usually already sitting on '/explore' and a repeat
    // context.go('/explore') is a no-op. Those buttons instead set this
    // provider, which we consume here directly.
    ref.listen<int?>(homeShellTabRequestProvider, (previous, next) {
      if (next == null) return;
      final newTab = AppTab.values[next.clamp(0, AppTab.values.length - 1)];
      if (newTab != _tab) {
        setState(() {
          _history.add(_tab);
          _tab = newTab;
        });
      }
      // Consume the request so it doesn't keep re-firing on later rebuilds.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.read(homeShellTabRequestProvider.notifier).state = null;
      });
    });

    // Hard gate: only a signed-in member with an active membership may see the
    // app shell. Logged-out (null) or inactive members go to the activation
    // screen — no demo fallback can slip a Silver/Gold view through here.
    final me = ref.watch(currentMemberProvider);
    if (me == null || !me.hasActiveMembership) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(me == null ? '/welcome' : '/membership-locked');
      });
      return const Scaffold(
        backgroundColor: AppColors.ink,
        body: Center(
            child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(color: AppColors.gold, strokeWidth: 2))),
      );
    }
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBack();
      },
      child: Scaffold(
        backgroundColor: AppColors.ink,
        extendBody: true,
        body: IndexedStack(
          index: AppTab.values.indexOf(_tab),
          children: const [
            ExploreScreen(),
            EventsListingScreen(),
            SocietyHubScreen(),
            BenefitsScreen(),
            CheerHubScreen(),
          ],
        ),
        bottomNavigationBar: AppBottomNav(
          current: _tab,
          onTap: _select,
        ),
      ),
    );
  }
}
