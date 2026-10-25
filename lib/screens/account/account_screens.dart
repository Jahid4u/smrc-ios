import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/benefit_offer_dialog.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../../core/theme/app_colors.dart';
import '../../core/error_classifier.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/demo_data.dart';
import '../../models/member.dart';
import '../../models/member_tier.dart';
import '../../models/api_models.dart';
import '../../providers/app_providers.dart';
import '../../widgets/app_top_nav.dart';
import '../../widgets/tier_badge.dart';
import '../../widgets/ui_kit.dart';
import '../../core/cache/content_cache.dart';

// ═════════════ Account / Profile (shared by all 5 identities) ═════════════
// "Same gold and black app for all five users. Identity reads from the
//  profile ring and badge only."
Future<void> _openAdminPanel(BuildContext context) async {
  const url = 'https://app.smroyalcircle.club/wp-admin/admin.php?page=smrc-dashboard';
  final ok = await launchUrlString(url, mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Could not open the admin panel.')));
  }
}

Widget _kvRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        SizedBox(
            width: 78,
            child: Text(label.toUpperCase(),
                style: AppTextStyles.inter(size: 9.5, weight: FontWeight.w400, color: AppColors.muted, letterSpacing: .6))),
        Expanded(child: Text(value, style: AppTextStyles.inter(size: 12.5, weight: FontWeight.w300, color: Colors.white))),
      ],
    ),
  );
}

class AccountScreen extends ConsumerWidget {
  /// Pass a member to preview another identity (used by the 5 profile routes);
  /// otherwise shows the signed-in member.
  final Member? previewMember;
  const AccountScreen({super.key, this.previewMember});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Member m = previewMember ?? ref.watch(memberOrDemoProvider);
    final isAmb = m.tier == MemberTier.ambassador;
    final isAdmin = m.tier == MemberTier.admin;

    final bool isOwnProfile = previewMember == null;
    final menu = <(String, VoidCallback?)>[
      if (isOwnProfile) ...[
        ('Edit Profile', () => context.push('/edit-profile')),
        if (isAmb)
          ('Ambassador Benefits', () => context.push('/ambassador-benefits'))
        else if (isAdmin) ...[
          ('Review Applications', () => _openAdminPanel(context)),
          ('Manage Members & Tiers', () => _openAdminPanel(context)),
          ('Manage Events', () => _openAdminPanel(context)),
        ] else
          ('Membership & Tier', () => context.push('/membership-tier-settings')),
        if (!isAdmin) ('Payments & Billing', () => context.push('/payments-billing')),
        if (!isAdmin) ('My Tickets & Wallet', () => context.push('/ticket-wallet')),
        ('Concierge & Support', () => context.push('/concierge-support')),
      ],
    ];

    return Scaffold(
      backgroundColor: AppColors.ink,
      appBar: const AppTopNav(title: ''),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          children: [
            const SizedBox(height: 22),
            RingAvatar(tier: m.tier, size: 96, imageUrl: m.avatarUrl, gender: m.gender),
            const SizedBox(height: 16),
            Text(m.name, style: AppTextStyles.serif(size: 25, color: Colors.white)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TierBadge(tier: m.tier),
                const SizedBox(width: 8),
                Text(m.memberNo ?? '',
                    style: AppTextStyles.inter(size: 9.5, color: AppColors.muted, letterSpacing: 1)),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(26, 24, 26, 0),
              child: MembershipCard(
                name: m.name,
                sinceLabel: m.sinceLabel,
                tierLabel: m.tier == MemberTier.blackDiamond ? 'BLACK DIAMOND' : '${m.tier.label.toUpperCase()}${m.tier == MemberTier.silver || m.tier == MemberTier.gold ? ' TIER' : ''}',
                tierColor: m.tier.ringColor,
                diamondGlow: m.tier == MemberTier.blackDiamond,
              ),
            ),
            if (isOwnProfile)
              Padding(
                padding: const EdgeInsets.fromLTRB(26, 22, 26, 0),
                child: MenuRows(
                  items: menu,
                  trailingMutedLabel: 'Log Out',
                  onTrailingTap: () async {
                    await ref.read(repoProvider).logout();
                    ref.read(currentMemberProvider.notifier).state = null;
                    if (context.mounted) context.go('/welcome');
                  },
                ),
              )
            else if (m.bio.trim().isNotEmpty || m.industry.trim().isNotEmpty || m.location.trim().isNotEmpty) ...[
              const SizedBox(height: 22),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 26),
                child: AppCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (m.bio.trim().isNotEmpty) ...[
                        Text('BIO', style: AppTextStyles.eyebrow),
                        const SizedBox(height: 6),
                        Text(m.bio, style: AppTextStyles.inter(size: 12.5, weight: FontWeight.w300, color: Colors.white)),
                        const SizedBox(height: 14),
                      ],
                      if (m.industry.trim().isNotEmpty) _kvRow('Industry', m.industry),
                      if (m.location.trim().isNotEmpty) _kvRow('Location', m.location),
                      if (m.instagram.trim().isNotEmpty) _kvRow('Instagram', '@${m.instagram.replaceAll('@', '')}'),
                      if (m.interests.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text('INTERESTS', style: AppTextStyles.eyebrow),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: m.interests
                              .map((i) => Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                                    decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: .04),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: AppColors.line)),
                                    child: Text(i,
                                        style: AppTextStyles.inter(size: 10.5, weight: FontWeight.w300, color: AppColors.muted)),
                                  ))
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

// ═════════════ Founders Benefit ═════════════
class FoundersBenefitScreen extends ConsumerStatefulWidget {
  const FoundersBenefitScreen({super.key});

  @override
  ConsumerState<FoundersBenefitScreen> createState() => _FoundersBenefitScreenState();
}

class _FoundersBenefitScreenState extends ConsumerState<FoundersBenefitScreen> {
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowOffer());
  }

  Future<void> _maybeShowOffer() async {
    if (_checked || !mounted) return;
    _checked = true;
    final offer = await ref.read(benefitOfferProvider.future);
    if (!mounted) return;
    if (offer == null || offer.accepted) {
      // No pending offer (already accepted / expired) — nothing to show,
      // don't leave the member stranded on a dead-end screen.
      _leave();
      return;
    }
    ref.read(repoProvider).markBenefitOfferSeen();
    await showBenefitOfferDialog(context, ref, offer);
    if (mounted) _leave();
  }

  /// Never a blind pop: this screen can be reached with nothing underneath
  /// it in the stack — e.g. a push notification tapped while the app was
  /// fully closed cold-starts straight into this route. Popping in that
  /// case leaves an empty navigator, which is exactly what showed as a
  /// black screen after accepting. Only pop when there's actually
  /// somewhere to go back to; otherwise route to the member's normal home.
  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      final me = ref.read(currentMemberProvider);
      context.go(memberHomeRoute(me));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Same provider _maybeShowOffer() already fetches for the accept/decline
    // dialog — reused here (not a second network call) purely to read the
    // admin-editable heading/body for this screen. Falls back to the
    // original fixed copy while loading or if nothing's configured, so
    // there's never a blank flash.
    final offer = ref.watch(benefitOfferProvider).maybeWhen(data: (o) => o, orElse: () => null);
    final screenTitle = (offer?.screenTitle.trim().isNotEmpty ?? false)
        ? offer!.screenTitle.toUpperCase()
        : 'FOUNDING MEMBERS. SILVER';
    final screenBody = (offer?.screenBody.trim().isNotEmpty ?? false)
        ? offer!.screenBody
        : 'As one of our first founding members, your Silver membership is complimentary for 6 months. Events, benefits, photos and the whole SM Society are included.';
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(fadeInDuration: Duration.zero, imageUrl: 'https://images.unsplash.com/photo-1519671482749-fd09be7ccebf?w=700&q=80',
              fit: BoxFit.cover, errorWidget: (_, __, ___) => const SizedBox()),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x8C0A0A0B), Color(0xF70A0A0B)]),
            ),
          ),
          SafeArea(
            child: Stack(
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 74,
                          height: 74,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle, border: Border.all(color: AppColors.silver, width: 1.4)),
                          child: const Icon(Icons.diamond_outlined, color: AppColors.silver, size: 30),
                        ),
                        const SizedBox(height: 20),
                        Text(screenTitle,
                            style: AppTextStyles.inter(
                                size: 9.5, weight: FontWeight.w600, color: AppColors.silver, letterSpacing: 3)),
                        const SizedBox(height: 10),
                        const HeroTitle(line1: 'Try the Circle', em: 'free for 6 months.', size: 28),
                        const SizedBox(height: 14),
                        Text(
                            screenBody,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.inter(
                                size: 12.5, weight: FontWeight.w300, color: const Color(0xFFBDB9B0), height: 1.65)),
                        const SizedBox(height: 20),
                        AppCard(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          borderColor: AppColors.gold.withValues(alpha: .4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('After 6 months',
                                        style: AppTextStyles.inter(size: 12.5, color: Colors.white)),
                                    Text('Silver renews at \$299 per year, or move up a tier',
                                        style: AppTextStyles.inter(
                                            size: 10.5, weight: FontWeight.w300, color: AppColors.muted)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text('\$0 NOW', style: AppTextStyles.eyebrow),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 26,
                  right: 26,
                  bottom: 44,
                  child: Column(
                    children: [
                      GoldButton('Start 6 Months Free', onTap: () => context.go('/membership-locked')),
                      const SizedBox(height: 11),
                      Text('No charge today. We will remind you before it ends.',
                          style: AppTextStyles.inter(size: 10.5, color: AppColors.muted2)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════ Notifications ═════════════
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  String _cat = 'All';

  IconData _iconFor(String key) => switch (key) {
        'check' => Icons.check,
        'gift' => Icons.card_giftcard,
        'event' => Icons.event_outlined,
        'message' => Icons.person_outline,
        'reminder' => Icons.schedule,
        'support' => Icons.headset_mic_outlined,
        _ => Icons.notifications_none,
      };

  Future<void> _markAll() async {
    // Instant, guaranteed clear of the dot — then sync to the server.
    final async = ref.read(notificationsProvider);
    async.whenData((list) {
      ref.read(locallyReadNotificationIdsProvider.notifier).state = {
        ...ref.read(locallyReadNotificationIdsProvider),
        ...list.map((n) => n.id),
      };
    });
    await ref.read(repoProvider).markNotificationsRead();
    ref.invalidate(notificationsProvider);
  }

  Future<void> _open(AppNotification n) async {
    if (!n.isRead) {
      ref.read(locallyReadNotificationIdsProvider.notifier).state = {
        ...ref.read(locallyReadNotificationIdsProvider),
        n.id,
      };
      await ref.read(repoProvider).markNotificationsRead(id: n.id);
      ref.invalidate(notificationsProvider);
    }
    if (n.link.isNotEmpty && mounted) context.push(n.link);
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(notificationsProvider);
    return Scaffold(
      backgroundColor: AppColors.ink,
      appBar: AppTopNav(
        title: 'Notifications',
        trailing: GestureDetector(
          onTap: _markAll,
          child: Text('MARK ALL', style: AppTextStyles.eyebrow),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.gold,
        backgroundColor: AppColors.charcoal,
        onRefresh: () async => ref.invalidate(notificationsProvider),
        child: async.when(
          loading: () => const Center(
              child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(color: AppColors.gold, strokeWidth: 2))),
          error: (_, __) => ListView(children: [
            const SizedBox(height: 120),
            Center(
                child: Text('Could not load notifications.',
                    style: AppTextStyles.inter(size: 12, weight: FontWeight.w300, color: AppColors.muted))),
          ]),
          data: (all) {
            final cats = <String>{'All', ...all.map((n) => n.category)}.toList();
            final list = _cat == 'All' ? all : all.where((n) => n.category == _cat).toList();
            return ListView(
              padding: const EdgeInsets.fromLTRB(0, 12, 0, 40),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(26, 0, 26, 14),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: cats
                        .map((c) => FilterChipPill(c, on: _cat == c, onTap: () => setState(() => _cat = c)))
                        .toList(),
                  ),
                ),
                if (list.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(30),
                    child: Center(
                        child: Text(
                            all.isEmpty ? 'No notifications yet.' : 'No notifications in this category.',
                            style: AppTextStyles.inter(
                                size: 11.5, weight: FontWeight.w300, color: AppColors.muted))),
                  ),
                ...list.map((n) => InkWell(
                      onTap: () => _open(n),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 26),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration:
                            const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: n.isRead ? Colors.transparent : AppColors.gold.withValues(alpha: .1),
                                border: Border.all(color: n.isRead ? AppColors.line : AppColors.gold),
                              ),
                              child: Icon(_iconFor(n.icon),
                                  size: 16, color: n.isRead ? AppColors.muted : AppColors.gold),
                            ),
                            const SizedBox(width: 13),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(n.category.toUpperCase(),
                                      style: AppTextStyles.inter(
                                          size: 9,
                                          color: n.isRead ? AppColors.muted2 : AppColors.gold,
                                          letterSpacing: 2)),
                                  const SizedBox(height: 3),
                                  Text(n.title,
                                      style: AppTextStyles.inter(
                                          size: 13,
                                          weight: n.isRead ? FontWeight.w400 : FontWeight.w500,
                                          color: Colors.white)),
                                  if (n.body.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(n.body,
                                        style: AppTextStyles.inter(
                                            size: 11, weight: FontWeight.w300, color: AppColors.muted)),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(n.time, style: AppTextStyles.inter(size: 10, color: AppColors.muted2)),
                          ],
                        ),
                      ),
                    )),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ═════════════ Edit Profile ═════════════
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  File? _pickedPhoto;
  bool _uploadingPhoto = false;
  late final TextEditingController _bio;
  late final TextEditingController _location;
  late final TextEditingController _industry;
  late final TextEditingController _instagram;
  final _otherInterest = TextEditingController();
  final Set<String> _selectedInterests = {};
  bool _otherActive = false;
  bool _busy = false;

  static const _interestOptions = [
    'Arts & Culture', 'Business & Finance', 'Dining & Gastronomy', 'Fashion & Style',
    'Film & Theatre', 'Fitness & Wellness', 'Golf', 'Hospitality & Events',
    'Motorsport', 'Music', 'Philanthropy', 'Real Estate', 'Sport', 'Technology',
    'Travel & Adventure', 'Wine & Spirits',
  ];

  @override
  void initState() {
    super.initState();
    final m = ref.read(memberOrDemoProvider);
    _bio = TextEditingController(text: m.bio);
    _location = TextEditingController(text: m.location);
    _industry = TextEditingController(text: m.industry);
    _instagram = TextEditingController(text: m.instagram);
    _selectedInterests.addAll(m.interests);
    // Anything already saved that isn't one of the curated chips is a
    // previously-typed custom interest (from Complete Profile's Other
    // field) — surface it here too instead of it just vanishing from view.
    final custom = m.interests.where((i) => !_interestOptions.contains(i)).toList();
    if (custom.isNotEmpty) {
      _otherActive = true;
      _otherInterest.text = custom.first;
      _selectedInterests.removeWhere((i) => !_interestOptions.contains(i));
    }
  }

  @override
  void dispose() {
    for (final c in [_bio, _location, _industry, _instagram, _otherInterest]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery, maxWidth: 1024, maxHeight: 1024, imageQuality: 85);
    if (picked == null) return;
    setState(() {
      _pickedPhoto = File(picked.path);
      _uploadingPhoto = true;
    });
    try {
      final bytes = await picked.readAsBytes();
      final url = await ref.read(repoProvider).uploadProfilePhoto(bytes);
      // Refresh the member so the new portrait shows everywhere.
      final me = await ref.read(repoProvider).me();
      ref.read(currentMemberProvider.notifier).state = me;
      await ContentCache.clear('directory');
      ref.invalidate(directoryProvider); // your new photo appears in the Directory/Lounge right away
      if (mounted && url.isNotEmpty) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Portrait updated.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(describeError(e).display)));
      }
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _save() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final otherText = _otherInterest.text.trim();
      final hasOther = _otherActive && otherText.isNotEmpty;
      final interestsList = [..._selectedInterests, if (hasOther) otherText];
      await ref.read(repoProvider).updateProfile(
            bio: _bio.text.trim(),
            city: _location.text.trim(),
            industry: _industry.text.trim(),
            instagram: _instagram.text.trim(),
            interests: interestsList,
          );
      final me = ref.read(currentMemberProvider);
      if (me != null) {
        ref.read(currentMemberProvider.notifier).state = me.copyWith(
          bio: _bio.text.trim(),
          location: _location.text.trim(),
          industry: _industry.text.trim(),
          instagram: _instagram.text.trim(),
          interests: interestsList,
        );
      }
      await ContentCache.clear('directory');
      ref.invalidate(directoryProvider);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Profile saved.')));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not save. ${describeError(e).display}')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _f(String label, TextEditingController c, {bool readOnly = false, int maxLines = 1}) =>
      LabeledField(label: label, controller: c, readOnly: readOnly, maxLines: maxLines);

  @override
  Widget build(BuildContext context) {
    final Member m = ref.watch(memberOrDemoProvider);
    return Scaffold(
      backgroundColor: AppColors.ink,
      appBar: AppTopNav(
        title: 'Edit Profile',
        trailing: InkWell(onTap: _save, child: Text('SAVE', style: AppTextStyles.eyebrow)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(26, 16, 26, 30),
        child: Column(
          children: [
            InkWell(
              onTap: _pickPhoto,
              customBorder: const CircleBorder(),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  _pickedPhoto != null
                      ? Container(
                          width: 84,
                          height: 84,
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                              shape: BoxShape.circle, border: Border.all(color: m.tier.ringColor, width: 1.6)),
                          child: ClipOval(child: Image.file(_pickedPhoto!, fit: BoxFit.cover)),
                        )
                      : RingAvatar(tier: m.tier, size: 84, imageUrl: m.avatarUrl, gender: m.gender),
                  Positioned(
                    bottom: -4,
                    right: -4,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                          color: AppColors.gold,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.ink, width: 3)),
                      child: _uploadingPhoto
                          ? const Padding(
                              padding: EdgeInsets.all(7),
                              child: CircularProgressIndicator(color: AppColors.ink, strokeWidth: 2))
                          : const Icon(Icons.camera_alt_outlined, size: 14, color: AppColors.ink),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text('TAP TO CHANGE PORTRAIT', style: AppTextStyles.eyebrow),
            const SizedBox(height: 14),
            // Name and email are managed by the Circle; the rest is yours.
            _f('Full Name', TextEditingController(text: m.name), readOnly: true),
            const SizedBox(height: 9),
            _f('Email', TextEditingController(text: m.email), readOnly: true),
            const SizedBox(height: 9),
            _f('Bio', _bio, maxLines: 3),
            const SizedBox(height: 9),
            _f('Location', _location),
            const SizedBox(height: 9),
            _f('Industry', _industry),
            const SizedBox(height: 9),
            _f('Instagram', _instagram),
            const SizedBox(height: 16),
            Text('INTERESTS', style: AppTextStyles.label),
            const SizedBox(height: 4),
            Text('Tap to select what interests you.',
                style: AppTextStyles.inter(
                    size: 10.5, weight: FontWeight.w300, color: AppColors.muted2)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._interestOptions.map((opt) {
                final sel = _selectedInterests.contains(opt);
                return GestureDetector(
                  onTap: () => setState(() {
                    if (sel) {
                      _selectedInterests.remove(opt);
                    } else {
                      _selectedInterests.add(opt);
                    }
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: sel ? AppColors.gold.withValues(alpha: .14) : Colors.white.withValues(alpha: .02),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: sel ? AppColors.gold : AppColors.line,
                        width: sel ? 1.3 : 1,
                      ),
                    ),
                    child: Text(opt,
                        style: AppTextStyles.inter(
                            size: 11.5,
                            weight: sel ? FontWeight.w500 : FontWeight.w300,
                            color: sel ? AppColors.gold : AppColors.muted)),
                  ),
                );
              }).toList(),
                GestureDetector(
                  onTap: () => setState(() => _otherActive = !_otherActive),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: _otherActive ? AppColors.gold.withValues(alpha: .14) : Colors.white.withValues(alpha: .02),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: _otherActive ? AppColors.gold : AppColors.line, width: _otherActive ? 1.3 : 1),
                    ),
                    child: Text('Other',
                        style: AppTextStyles.inter(
                            size: 11.5,
                            weight: _otherActive ? FontWeight.w500 : FontWeight.w300,
                            color: _otherActive ? AppColors.gold : AppColors.muted)),
                  ),
                ),
              ],
            ),
            if (_otherActive) ...[
              const SizedBox(height: 9),
              _f('Your interest', _otherInterest),
            ],
            const SizedBox(height: 22),
            _busy
                ? const Center(
                    child: SizedBox(
                        width: 24, height: 24,
                        child: CircularProgressIndicator(color: AppColors.gold, strokeWidth: 2)))
                : GoldButton('Save Changes', onTap: _save),
          ],
        ),
      ),
    );
  }
}

// ═════════════ Membership & Tier ═════════════
class MembershipTierSettingsScreen extends ConsumerStatefulWidget {
  const MembershipTierSettingsScreen({super.key});

  @override
  ConsumerState<MembershipTierSettingsScreen> createState() => _MembershipTierSettingsScreenState();
}

class _MembershipTierSettingsScreenState extends ConsumerState<MembershipTierSettingsScreen> {
  bool _busy = false;

  static const _reasons = [
    'Too expensive',
    'Not using it enough',
    'Missing features I need',
    'Just taking a break',
    'Other',
  ];

  Future<void> _openCancelFlow(Member m) async {
    // Step 1 — retention screen: what they lose, framed honestly.
    final proceed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.charcoal,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _CancelIntroSheet(tier: m.tier),
    );
    if (proceed != true || !mounted) return;

    // Step 2 — reason (optional but professional apps collect it).
    final reason = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.charcoal,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => const _CancelReasonSheet(reasons: _reasons),
    );
    if (reason == null || !mounted) return;

    // Step 3 — final confirm.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.charcoal,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Cancel membership?', style: AppTextStyles.serif(size: 21, color: Colors.white)),
        content: Text(
            'Your membership stays active until the end of your current period. You can resume any time before then.',
            style: AppTextStyles.inter(
                size: 12.5, weight: FontWeight.w300, color: AppColors.muted, height: 1.6)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('KEEP MEMBERSHIP',
                style: AppTextStyles.inter(size: 11, color: AppColors.gold, letterSpacing: 1.5)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('CONFIRM CANCEL',
                style: AppTextStyles.inter(size: 11, color: const Color(0xFFE68688), letterSpacing: 1.5)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      final msg = await ref.read(repoProvider).cancelMembership(reason: reason);
      final me = await ref.read(repoProvider).me();
      ref.read(currentMemberProvider.notifier).state = me;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(describeError(e).display)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resume() async {
    setState(() => _busy = true);
    try {
      final msg = await ref.read(repoProvider).resumeMembership();
      final me = await ref.read(repoProvider).me();
      ref.read(currentMemberProvider.notifier).state = me;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(describeError(e).display)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Member m = ref.watch(memberOrDemoProvider);
    final cancelled = m.isCancelled;
    final expired = !cancelled && m.isExpired;

    // Purchasable tiers in ascending order.
    const purchasableTiers = [MemberTier.silver, MemberTier.gold, MemberTier.blackDiamond];
    final currentIdx = purchasableTiers.indexOf(m.tier);
    final MemberTier? upgradeTier =
        (currentIdx >= 0 && currentIdx < purchasableTiers.length - 1)
            ? purchasableTiers[currentIdx + 1]
            : null;

    // Pull price for current tier and next tier dynamically from API.
    final tiersAsync = ref.watch(tiersProvider);
    String currentPrice = '\$—';
    String upgradeLabel = upgradeTier != null ? 'Upgrade to ${upgradeTier.label}' : '';
    TierInfo? currentTierInfo;
    TierInfo? upgradeTierInfo;
    tiersAsync.whenData((p) {
      final curKey = m.tier == MemberTier.blackDiamond ? 'diamond' : m.tier.name;
      currentTierInfo = p.tiers.where((t) => t.tierKey == curKey).firstOrNull;
      if (currentTierInfo != null) currentPrice = '\$${currentTierInfo!.price.toInt()}';
      if (upgradeTier != null) {
        final upKey = upgradeTier == MemberTier.blackDiamond ? 'diamond' : upgradeTier.name;
        upgradeTierInfo = p.tiers.where((t) => t.tierKey == upKey).firstOrNull;
      }
    });

    return Scaffold(
      backgroundColor: AppColors.ink,
      appBar: const AppTopNav(title: 'Membership & Tier'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(26, 16, 26, 30),
        child: Column(
          children: [
            MembershipCard(
                name: m.name,
                sinceLabel: m.sinceLabel,
                tierLabel: '${m.tier.label.toUpperCase()} TIER',
                tierColor: m.tier.ringColor),
            const SizedBox(height: 16),

            // Cancellation banner
            if (cancelled) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE68688).withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE68688).withValues(alpha: .35)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline, size: 16, color: Color(0xFFE68688)),
                        const SizedBox(width: 8),
                        Text('Membership ending',
                            style: AppTextStyles.inter(
                                size: 12.5, weight: FontWeight.w600, color: const Color(0xFFE68688))),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                        m.cancelEffectiveAt != null
                            ? 'Your access remains active until ${m.cancelEffectiveAt}. Resume any time before then to keep your membership.'
                            : 'Your membership is scheduled to end. Resume any time before then to keep it.',
                        style: AppTextStyles.inter(
                            size: 11, weight: FontWeight.w300, color: AppColors.muted, height: 1.55)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Expired banner — membership end date has passed.
            if (expired) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE68688).withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE68688).withValues(alpha: .35)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.error_outline, size: 16, color: Color(0xFFE68688)),
                        const SizedBox(width: 8),
                        Text('Membership expired',
                            style: AppTextStyles.inter(
                                size: 12.5, weight: FontWeight.w600, color: const Color(0xFFE68688))),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                        m.expiresAt != null
                            ? 'Your membership expired on ${m.expiresAt}. Renew now to restore your access and benefits.'
                            : 'Your membership has expired. Renew now to restore your access and benefits.',
                        style: AppTextStyles.inter(
                            size: 11, weight: FontWeight.w300, color: AppColors.muted, height: 1.55)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Info cards
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Current tier', style: AppTextStyles.inter(size: 13, color: Colors.white)),
                      Text(
                          cancelled
                              ? 'Ends ${m.expiresAt ?? m.cancelEffectiveAt ?? 'soon'}'
                              : expired
                                  ? 'Expired ${m.expiresAt ?? ''}'
                                  : (m.renewsAt != null ? 'Renews ${m.renewsAt}' : 'Renews annually'),
                          style: AppTextStyles.inter(
                              size: 10.5, weight: FontWeight.w300, color: AppColors.muted)),
                    ],
                  ),
                  TierBadge(tier: m.tier),
                ],
              ),
            ),
            const SizedBox(height: 8),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Yearly price', style: AppTextStyles.inter(size: 13, color: Colors.white)),
                      Text('Billed once a year',
                          style: AppTextStyles.inter(
                              size: 10.5, weight: FontWeight.w300, color: AppColors.muted)),
                    ],
                  ),
                  Text(currentPrice,
                      style: AppTextStyles.inter(size: 15, color: AppColors.gold)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (_busy)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: CircularProgressIndicator(color: AppColors.gold, strokeWidth: 2),
              )
            else if (cancelled) ...[
              GoldButton('Resume Membership', compact: true, onTap: _resume),
              const SizedBox(height: 7),
              GoldButton('View All Tiers',
                  style: GoldBtnStyle.ghost,
                  compact: true,
                  onTap: () => context.push('/membership-tiers')),
            ] else if (expired) ...[
              GoldButton('Renew Membership',
                  compact: true,
                  onTap: () => currentTierInfo != null
                      ? context.push('/membership-checkout', extra: currentTierInfo)
                      : context.push('/membership-tiers')),
              const SizedBox(height: 7),
              GoldButton('View All Tiers',
                  style: GoldBtnStyle.ghost,
                  compact: true,
                  onTap: () => context.push('/membership-tiers')),
            ] else ...[
              if (upgradeTier != null) ...[
                GoldButton(upgradeLabel,
                    style: GoldBtnStyle.line,
                    compact: true,
                    onTap: () => upgradeTierInfo != null
                        ? context.push('/membership-checkout', extra: upgradeTierInfo)
                        : context.push('/membership-tiers')),
                const SizedBox(height: 7),
              ],
              if (m.tier != MemberTier.admin && m.tier != MemberTier.ambassador) ...[
                GoldButton('Renew Membership',
                    style: GoldBtnStyle.ghost,
                    compact: true,
                    onTap: () => currentTierInfo != null
                        ? context.push('/membership-checkout', extra: currentTierInfo)
                        : context.push('/membership-tiers')),
                const SizedBox(height: 7),
              ],
              if (m.tier != MemberTier.ambassador) ...[
                GoldButton('View All Tiers',
                    style: GoldBtnStyle.ghost,
                    compact: true,
                    onTap: () => context.push('/membership-tiers')),
                const SizedBox(height: 7),
              ],
              if (m.tier != MemberTier.admin && m.tier != MemberTier.ambassador)
                GoldButton('Cancel Membership',
                    style: GoldBtnStyle.ghost,
                    compact: true,
                    onTap: () => _openCancelFlow(m)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Step 1 of cancellation — honest "here's what you'll lose" retention sheet.
class _CancelIntroSheet extends StatelessWidget {
  final MemberTier tier;
  const _CancelIntroSheet({required this.tier});

  @override
  Widget build(BuildContext context) {
    const perks = [
      (Icons.event_outlined, 'Members-only events & the private calendar'),
      (Icons.shield_outlined, 'City partner benefits & member discounts'),
      (Icons.diamond_outlined, 'The Circle Lounge & member directory'),
      (Icons.headset_mic_outlined, 'Priority concierge support'),
    ];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Text('BEFORE YOU GO', style: AppTextStyles.eyebrow),
            const SizedBox(height: 8),
            Text('You’ll lose access to', style: AppTextStyles.serif(size: 24, color: Colors.white)),
            const SizedBox(height: 18),
            ...perks.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 34, height: 34,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle, border: Border.all(color: AppColors.line)),
                        child: Icon(p.$1, size: 16, color: AppColors.gold),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Text(p.$2,
                            style: AppTextStyles.inter(
                                size: 12.5, weight: FontWeight.w300, color: const Color(0xFFBDB9B0))),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 8),
            GoldButton('Keep My Membership', onTap: () => Navigator.of(context).pop(false)),
            const SizedBox(height: 10),
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('Continue to cancel',
                    style: AppTextStyles.inter(size: 12, color: AppColors.muted2)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Step 2 of cancellation — reason picker.
class _CancelReasonSheet extends StatefulWidget {
  final List<String> reasons;
  const _CancelReasonSheet({required this.reasons});

  @override
  State<_CancelReasonSheet> createState() => _CancelReasonSheetState();
}

class _CancelReasonSheetState extends State<_CancelReasonSheet> {
  int _selected = -1;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Text('HELP US IMPROVE', style: AppTextStyles.eyebrow),
            const SizedBox(height: 8),
            Text('Why are you leaving?', style: AppTextStyles.serif(size: 24, color: Colors.white)),
            const SizedBox(height: 18),
            ...List.generate(widget.reasons.length, (i) {
              final on = _selected == i;
              return Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: InkWell(
                  onTap: () => setState(() => _selected = i),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: on ? AppColors.gold : AppColors.line),
                      color: on ? AppColors.gold.withValues(alpha: .08) : Colors.transparent,
                    ),
                    child: Row(
                      children: [
                        Icon(on ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                            size: 18, color: on ? AppColors.gold : AppColors.muted2),
                        const SizedBox(width: 12),
                        Text(widget.reasons[i],
                            style: AppTextStyles.inter(
                                size: 13, color: on ? Colors.white : const Color(0xFFBDB9B0))),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
            GoldButton('Continue',
                onTap: _selected < 0 ? null : () => Navigator.of(context).pop(widget.reasons[_selected])),
          ],
        ),
      ),
    );
  }
}

// ═════════════ Payments & Billing ═════════════
class PaymentsBillingScreen extends ConsumerWidget {
  const PaymentsBillingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Native wallet differs per platform — Apple Pay on iOS, Google Pay on Android.
    final isIOS = Platform.isIOS;
    final walletName = isIOS ? 'Apple Pay' : 'Google Pay';
    final walletIcon = isIOS ? Icons.apple : Icons.account_balance_wallet;

    final Member me = ref.watch(memberOrDemoProvider);
    final billingAsync = ref.watch(billingProvider);

    // Current plan summary from live tier data.
    final tiers = ref.watch(tiersProvider).maybeWhen(data: (p) => p.tiers, orElse: () => <TierInfo>[]);
    final myKey = me.tier == MemberTier.blackDiamond ? 'diamond' : me.tier.name;
    final myTierInfo = tiers.where((t) => t.tierKey == myKey).firstOrNull;

    return Scaffold(
      backgroundColor: AppColors.ink,
      appBar: const AppTopNav(title: 'Payments & Billing'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(26, 16, 26, 40),
        children: [
          // Current plan
          Text('CURRENT PLAN', style: AppTextStyles.eyebrow),
          const SizedBox(height: 10),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${me.tier.label} membership',
                        style: AppTextStyles.inter(size: 13, color: Colors.white)),
                    Text(me.isExpired
                        ? 'Expired ${me.expiresAt ?? ''}'
                        : (me.renewsAt != null ? 'Renews ${me.renewsAt}' : 'Billed yearly'),
                        style: AppTextStyles.inter(
                            size: 10.5, weight: FontWeight.w300, color: AppColors.muted)),
                  ],
                ),
                Text(myTierInfo != null ? '\$${myTierInfo.price.toStringAsFixed(0)}/yr' : '—',
                    style: AppTextStyles.inter(size: 14, weight: FontWeight.w500, color: AppColors.gold)),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Text('PAYMENT METHOD', style: AppTextStyles.eyebrow),
          const SizedBox(height: 10),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            borderColor: AppColors.gold.withValues(alpha: .35),
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(7)),
                  child: Icon(walletIcon, size: 16, color: Colors.white),
                ),
                const SizedBox(width: 11),
                Expanded(
                    child: Text(walletName,
                        style: AppTextStyles.inter(size: 12, color: const Color(0xFFCFCDC6)))),
                Text('Connected', style: AppTextStyles.inter(size: 11, color: AppColors.gold)),
              ],
            ),
          ),
          const SizedBox(height: 9),
          Text(
              "SM Royal Circle uses your device's native wallet only — $walletName on this device.",
              style: AppTextStyles.inter(size: 10, weight: FontWeight.w300, color: AppColors.muted2, height: 1.5)),
          const SizedBox(height: 22),
          Text('BILLING HISTORY', style: AppTextStyles.eyebrow),
          const SizedBox(height: 10),
          billingAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(
                  child: SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(color: AppColors.gold, strokeWidth: 2))),
            ),
            error: (_, __) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Text('Could not load billing history.',
                  style: AppTextStyles.inter(size: 12, weight: FontWeight.w300, color: AppColors.muted)),
            ),
            data: (entries) {
              if (entries.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Text('No payments yet. Your membership charges will appear here.',
                      style: AppTextStyles.inter(
                          size: 12, weight: FontWeight.w300, color: AppColors.muted, height: 1.5)),
                );
              }
              return Column(
                children: [
                  for (int i = 0; i < entries.length; i++)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 4),
                      decoration: BoxDecoration(
                          border: i == entries.length - 1
                              ? null
                              : const Border(bottom: BorderSide(color: AppColors.line))),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(entries[i].title,
                                    style: AppTextStyles.inter(size: 12.5, color: Colors.white)),
                                Text(entries[i].date,
                                    style: AppTextStyles.inter(
                                        size: 10, weight: FontWeight.w300, color: AppColors.muted)),
                              ],
                            ),
                          ),
                          Text(entries[i].amount,
                              style: AppTextStyles.inter(size: 12.5, color: const Color(0xFFE9E7E1))),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
