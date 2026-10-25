import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/app_providers.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/ui_kit.dart';
import '../../widgets/benefit_offer_dialog.dart';

/// Shown when a member is signed in but has no active membership. The rest of
/// the app stays locked until they activate a tier. Notifications stay
/// reachable, and any active benefit offer is surfaced here as a popup.
class MembershipLockedScreen extends ConsumerStatefulWidget {
  const MembershipLockedScreen({super.key});

  @override
  ConsumerState<MembershipLockedScreen> createState() => _MembershipLockedScreenState();
}

class _MembershipLockedScreenState extends ConsumerState<MembershipLockedScreen> {
  bool _offerShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowOffer());
  }

  Future<void> _maybeShowOffer() async {
    if (_offerShown || !mounted) return;
    final offer = await ref.read(benefitOfferProvider.future);
    if (offer == null || offer.accepted || !mounted) return;
    _offerShown = true;
    ref.read(repoProvider).markBenefitOfferSeen();
    (await SharedPreferences.getInstance()).setInt('smrc_seen_offer_id', offer.id);
    if (!mounted) return;
    await showBenefitOfferDialog(context, ref, offer);
    // If accepting activated the membership, move into the app.
    final me = ref.read(currentMemberProvider);
    if (me != null && me.hasActiveMembership && mounted) {
      context.go('/explore');
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(currentMemberProvider);
    final name = me?.name.split(' ').first ?? '';
    final unread = ref.watch(unreadCountProvider);

    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(30, 12, 30, 30),
          child: Column(
            children: [
              // Top bar — notifications access even while locked.
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const AppLogo(size: 34),
                  InkWell(
                    onTap: () => context.push('/notifications'),
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.line),
                          ),
                          child: const Icon(Icons.notifications_none, size: 20, color: Colors.white),
                        ),
                        if (unread > 0)
                          Positioned(
                            right: 2,
                            top: 2,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: AppColors.gold,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.ink, width: 1.5),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 78,
                          height: 78,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.gold.withValues(alpha: .1),
                            border: Border.all(color: AppColors.gold.withValues(alpha: .5)),
                          ),
                          child: const Icon(Icons.lock_outline, size: 34, color: AppColors.gold),
                        ),
                        const SizedBox(height: 26),
                        Text('MEMBERS ONLY', style: AppTextStyles.eyebrow),
                        const SizedBox(height: 10),
                        HeroTitle(
                            line1: name.isEmpty ? 'Activate your' : '$name, activate your',
                            em: 'membership',
                            size: 28),
                        const SizedBox(height: 16),
                        Text(
                            'Your account is ready, but your membership isn\u2019t active yet. Choose a tier to unlock events, the community, benefits and everything inside SM Royal Circle.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.inter(
                                size: 13, weight: FontWeight.w300, color: AppColors.muted, height: 1.6)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GoldButton('Activate Membership',
                  onTap: () => context.push('/membership-tiers')),
            ],
          ),
        ),
      ),
    );
  }
}
