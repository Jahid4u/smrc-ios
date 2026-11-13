import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/demo_data.dart';
import '../../models/member.dart';
import '../../models/member_tier.dart';
import '../../models/club_event.dart';
import '../../providers/app_providers.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/tier_badge.dart';
import '../../widgets/app_top_nav.dart';

class ExploreScreen extends ConsumerWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Member member = ref.watch(memberOrDemoProvider);
    final hour = DateTime.now().hour;
    final greeting = hour < 5
        ? 'GOOD NIGHT'
        : hour < 12
            ? 'GOOD MORNING'
            : hour < 17
                ? 'GOOD AFTERNOON'
                : hour < 21
                    ? 'GOOD EVENING'
                    : 'GOOD NIGHT';
    final eventsAsync = ref.watch(eventsProvider);
    // Not falling back to DemoData: orElse fires while loading too, which
    // made demo/reference events flash before the real ones arrived.
    final events = eventsAsync.valueOrNull ?? const <ClubEvent>[];
    final featuredList = events.where((e) => e.featured).toList();

    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 84),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(26, 10, 26, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(greeting,
                            style: AppTextStyles.inter(
                                size: 9.5, weight: FontWeight.w600, color: AppColors.muted2, letterSpacing: 3)),
                        const SizedBox(height: 2),
                        Text(member.name.split(' ').first, style: AppTextStyles.serif(size: 24, color: Colors.white)),
                      ],
                    ),
                    Row(
                      children: [
                        HeaderIconButton(
                            icon: Icons.notifications_none,
                            showDot: ref.watch(unreadCountProvider) > 0,
                            onTap: () => context.push('/notifications')),
                        const SizedBox(width: 10),
                        InkWell(
                          onTap: () => context.push('/account'),
                          customBorder: const CircleBorder(),
                          child: RingAvatar(tier: member.tier, size: 38, imageUrl: member.avatarUrl, gender: member.gender),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(26, 18, 26, 0),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => context.push('/membership-tier-settings'),
                  child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1D1D21), Color(0xFF0F0F11)]),
                    border: Border.all(color: member.tier.ringColor.withValues(alpha: .4)),
                  ),
                  child: Row(
                    children: [
                      const AppLogo(size: 32),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                member.tier == MemberTier.ambassador
                                    ? 'Brand Ambassador'
                                    : member.tier == MemberTier.admin
                                        ? 'Admin'
                                        : 'SM Society Member',
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.inter(
                                    size: 12.5,
                                    color: (member.tier == MemberTier.ambassador || member.tier == MemberTier.admin)
                                        ? member.tier.ringColor
                                        : Colors.white)),
                            const SizedBox(height: 2),
                            Text('Member since ${member.joinedAt.year}. ${member.memberNo ?? ''}',
                                style: AppTextStyles.inter(size: 10, weight: FontWeight.w300, color: AppColors.muted)),
                          ],
                        ),
                      ),
                      if (member.tier != MemberTier.ambassador && member.tier != MemberTier.admin)
                        TierBadge(tier: member.tier),
                    ],
                  ),
                ),
                ),
              ),
              if (featuredList.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 18, 0, 0),
                  child: _FeaturedCarousel(events: featuredList),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(26, 22, 26, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('Media', style: AppTextStyles.serif(size: 18, color: Colors.white)),
                    GestureDetector(
                      onTap: () => context.go('/cheer'),
                      child: Text('SEE ALL ›', style: AppTextStyles.eyebrow),
                    ),
                  ],
                ),
              ),
              Builder(builder: (context) {
                final copy = ref.watch(screenCopyProvider).maybeWhen(data: (c) => c, orElse: () => const <String, dynamic>{});
                String cv(String k, String fallback) { final v = copy[k]?.toString() ?? ""; return v.trim().isNotEmpty ? v.trim() : fallback; }
                return SizedBox(
                  height: 134,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(26, 12, 26, 0),
                    scrollDirection: Axis.horizontal,
                    children: [
                      _cheerTile(
                          cv('cheer_podcast_title', 'Podcast'),
                          cv('cheer_podcast_image',
                              'https://images.unsplash.com/photo-1478737270239-2f02b77fc618?w=300&q=80'),
                          Icons.mic_none,
                          onTap: () => _openPodcast(context, copy)),
                      const SizedBox(width: 12),
                      _cheerTile(
                          cv('cheer_footage_title', 'Event Footage'),
                          cv('cheer_footage_image',
                              'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=300&q=80'),
                          Icons.play_arrow,
                          onTap: () => context.push('/event-footage-1')),
                      const SizedBox(width: 12),
                      _cheerTile(
                          cv('cheer_gallery_title', 'Event Gallery'),
                          cv('cheer_gallery_image',
                              'https://images.unsplash.com/photo-1492447166138-50c3889fccb1?w=300&q=80'),
                          Icons.image_outlined,
                          onTap: () => context.push('/event-gallery-1')),
                    ],
                  ),
                );
              }),
              Padding(
                padding: const EdgeInsets.fromLTRB(26, 24, 26, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('Quick Access', style: AppTextStyles.serif(size: 18, color: Colors.white)),
                    Text('THE CIRCLE', style: AppTextStyles.eyebrow),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(26, 14, 26, 0),
                child: InkWell(
                  onTap: () => context.push('/society-chat'),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.charcoal, AppColors.charcoal2],
                      ),
                      border: Border.all(color: AppColors.gold.withValues(alpha: .4)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.gold),
                          ),
                          child: const Icon(Icons.forum_outlined, size: 23, color: AppColors.gold),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text('Group Chat',
                                      style: AppTextStyles.serif(size: 18, color: Colors.white)),
                                  const SizedBox(width: 8),
                                  Container(
                                      width: 7,
                                      height: 7,
                                      decoration: const BoxDecoration(
                                          color: AppColors.success, shape: BoxShape.circle)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text('Join here — everyone shares openly and has fun here.',
                                  style: AppTextStyles.inter(
                                      size: 11.5, weight: FontWeight.w300, color: AppColors.muted, height: 1.4)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('›', style: AppTextStyles.inter(size: 20, color: AppColors.gold)),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(26, 14, 26, 0),
                child: GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.55,
                  children: [
                    _qa(context, Icons.shield_outlined, 'Benefits', 'City discounts', () => context.go('/benefits')),
                    _qa(context, Icons.campaign_outlined, 'Announcements', 'From the Circle',
                        () => context.push('/announcements')),
                    _qa(context, Icons.credit_card_outlined, 'Ticket Wallet', 'Your passes',
                        () => context.push('/ticket-wallet')),
                    _qa(context, Icons.headset_mic_outlined, 'Concierge', 'Online',
                        () => context.push('/concierge-support')),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openPodcast(BuildContext context, Map<String, dynamic> copy) async {
    final url = (copy['podcast_link']?.toString() ?? '').trim();
    if (url.isEmpty) {
      context.go('/cheer');
      return;
    }
    final ok = await launchUrlString(url, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) context.go('/cheer');
  }

  Widget _cheerTile(String label, String image, IconData icon, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 118,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 80,
              width: 118,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(14)),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(fadeInDuration: Duration.zero, imageUrl: image,
                      fit: BoxFit.cover, errorWidget: (_, __, ___) => Container(color: AppColors.charcoal)),
                  Container(color: const Color(0x590A0A0B)),
                  Center(
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0x660A0A0B),
                        border: Border.all(color: AppColors.gold),
                      ),
                      child: Icon(icon, size: 13, color: AppColors.gold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 7),
            Text(label, style: AppTextStyles.inter(size: 11.5, color: const Color(0xFFE9E7E1))),
          ],
        ),
      ),
    );
  }

  Widget _qa(BuildContext context, IconData icon, String title, String sub, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.charcoal,
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: AppColors.gold),
            const Spacer(),
            Text(title, style: AppTextStyles.inter(size: 11, color: Colors.white), overflow: TextOverflow.ellipsis),
            Text(sub, style: AppTextStyles.inter(size: 10, weight: FontWeight.w300, color: AppColors.muted)),
          ],
        ),
      ),
    );
  }
}

/// Swipeable carousel for the events an admin has marked "featured". Renders
/// exactly like the old single card when there's only one, and adds dot
/// paging underneath the moment there's more than one — so admins can
/// feature as many events as they want without the home screen changing
/// shape for the common one-event case.
class _FeaturedCarousel extends StatefulWidget {
  final List<ClubEvent> events;
  const _FeaturedCarousel({required this.events});

  @override
  State<_FeaturedCarousel> createState() => _FeaturedCarouselState();
}

class _FeaturedCarouselState extends State<_FeaturedCarousel> {
  late final PageController _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final events = widget.events;
    return Column(
      children: [
        SizedBox(
          height: 170,
          child: PageView.builder(
            controller: _controller,
            itemCount: events.length,
            onPageChanged: (i) => setState(() => _page = i),
            padEnds: false,
            itemBuilder: (context, i) {
              final featured = events[i];
              final isFirst = i == 0;
              final isLast = i == events.length - 1;
              return Padding(
                padding: EdgeInsets.fromLTRB(
                    isFirst ? 26 : 6, 0, isLast ? 26 : 6, 0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(19),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(19),
                      onTap: () => context.push('/event-detail', extra: featured),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CachedNetworkImage(fadeInDuration: Duration.zero, imageUrl: featured.coverImageUrl ?? '',
                              fit: BoxFit.cover, errorWidget: (_, __, ___) => Container(color: AppColors.charcoal)),
                          Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                stops: [0.3, 1],
                                colors: [Color(0x1A0A0A0B), Color(0xF20A0A0B)],
                              ),
                            ),
                          ),
                          Positioned(
                              top: 14,
                              left: 14,
                              right: 14,
                              child: Text(
                                'FEATURED',
                                style: AppTextStyles.eyebrow,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )),
                          Positioned(
                            left: 16,
                            right: 16,
                            bottom: 16,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(featured.title, style: AppTextStyles.serif(size: 23, color: Colors.white)),
                                const SizedBox(height: 3),
                                Text(featured.location.isNotEmpty ? featured.location : featured.dateLabel,
                                    style: AppTextStyles.inter(
                                        size: 11, weight: FontWeight.w300, color: const Color(0xFFBDB9B0))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (events.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(events.length, (i) {
              final active = i == _page;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 16 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: active ? AppColors.gold : AppColors.line,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}
