import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/api_models.dart';
import '../../models/club_event.dart';
import '../../models/member.dart';
import '../../models/member_tier.dart';
import '../../providers/app_providers.dart';
import '../../core/api/smrc_repository.dart';
import '../../core/error_classifier.dart';
import '../../core/payment_helper.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/demo_data.dart';
import '../../widgets/app_top_nav.dart';
import '../../widgets/tier_badge.dart';
import '../../widgets/platform_pay_checkout_button.dart';
import '../../widgets/ui_kit.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/async_view.dart';
import '../../widgets/notification_watcher.dart';
import '../support/support_screens.dart' show ChatBubble;
import '../../core/cache/content_cache.dart';

// ═════════════ SM Society Hub (tab) ═════════════
class SocietyHubScreen extends ConsumerWidget {
  const SocietyHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pinned = ref.watch(screenCopyProvider).maybeWhen(
        data: (c) => (c['society_pinned_msg']?.toString() ?? '').trim(),
        orElse: () => '');
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 84),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(26, 14, 26, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('MEMBERS ONLY', style: AppTextStyles.eyebrow),
                  const SizedBox(height: 6),
                  Text('The SM Society', style: AppTextStyles.serif(size: 28, color: Colors.white)),
                ],
              ),
            ),
            if (pinned.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(26, 18, 26, 0),
              child: AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                borderColor: AppColors.gold.withValues(alpha: .35),
                child: Row(
                  children: [
                    const Icon(Icons.push_pin_outlined, size: 16, color: AppColors.gold),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('PINNED',
                              style: AppTextStyles.inter(
                                  size: 9, weight: FontWeight.w600, color: AppColors.gold, letterSpacing: 2)),
                          const SizedBox(height: 2),
                          Text(pinned,
                              style: AppTextStyles.inter(size: 12, color: const Color(0xFFE9E7E1))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(26, 18, 26, 0),
              child: Column(
                children: [
                  _row(context, Icons.person_outline, 'Group Chat', "The members\u2019 room",
                      '/society-chat', liveDot: true),
                  const SizedBox(height: 12),
                  _row(context, Icons.campaign_outlined, 'Announcements', 'Official notes from the Circle',
                      '/announcements'),
                  const SizedBox(height: 12),
                  _row(context, Icons.chat_bubble_outline, 'Support Chat',
                      'Concierge desk', '/support-chat'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, IconData icon, String title, String sub, String route, {bool liveDot = false}) {
    return InkWell(
      onTap: () => context.push(route),
      borderRadius: BorderRadius.circular(20),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.gold)),
              child: Icon(icon, size: 17, color: AppColors.gold),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.inter(size: 13.5, color: Colors.white)),
                  Text(sub, style: AppTextStyles.inter(size: 10.5, weight: FontWeight.w300, color: AppColors.muted)),
                ],
              ),
            ),
            if (liveDot)
              Container(
                  width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle))
            else
              Text('›', style: AppTextStyles.inter(size: 16, color: AppColors.gold)),
          ],
        ),
      ),
    );
  }
}

// ═════════════ Announcements ═════════════
class AnnouncementsScreen extends ConsumerWidget {
  const AnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(announcementsProvider).maybeWhen(
          data: (a) => a,
          orElse: () => const <Announcement>[],
        );
    return Scaffold(
      backgroundColor: AppColors.ink,
      appBar: const AppTopNav(title: ''),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(26, 6, 26, 40),
        children: [
          Column(
            children: [
              const AppLogo(size: 64),
              const SizedBox(height: 12),
              Text('FROM THE CIRCLE', style: AppTextStyles.eyebrow),
              const SizedBox(height: 6),
              Text('Announcements', style: AppTextStyles.serif(size: 27, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 24),
          ...items.map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: AppCard(
                  padding: const EdgeInsets.all(18),
                  borderColor: a.featured ? AppColors.gold.withValues(alpha: .4) : null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(a.tag.toUpperCase(),
                              style: AppTextStyles.inter(
                                  size: 9,
                                  weight: FontWeight.w600,
                                  color: a.featured ? AppColors.gold : AppColors.muted2,
                                  letterSpacing: 2)),
                          Text(a.dateLabel, style: AppTextStyles.inter(size: 10, color: AppColors.muted2)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(a.title, style: AppTextStyles.serif(size: 19, color: Colors.white)),
                      const SizedBox(height: 6),
                      Text(a.description,
                          style: AppTextStyles.inter(
                              size: 12, weight: FontWeight.w300, color: AppColors.muted, height: 1.6)),
                      if (a.signedBy.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text('— ${a.signedBy}',
                            style: AppTextStyles.serif(
                                size: 13, color: AppColors.goldSoft, style: FontStyle.italic)),
                      ],
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

// ═════════════ Support Chat (live concierge) ═════════════
class SupportChatScreen extends ConsumerStatefulWidget {
  const SupportChatScreen({super.key});

  @override
  ConsumerState<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends ConsumerState<SupportChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  Timer? _poll;
  bool _sending = false;
  bool _showJumpButton = false;
  int _lastMsgCount = 0;

  @override
  void initState() {
    super.initState();
    // Refresh every 3 seconds so concierge replies appear live.
    _poll = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) ref.invalidate(supportThreadProvider);
    });
    _scroll.addListener(() {
      final nearBottom = _scroll.position.maxScrollExtent - _scroll.position.pixels < 80;
      if (nearBottom == _showJumpButton) {
        setState(() => _showJumpButton = !nearBottom);
      }
    });
  }

  void _scrollToBottom({bool animated = true}) {
    if (!_scroll.hasClients) return;
    final target = _scroll.position.maxScrollExtent;
    if (animated) {
      _scroll.animateTo(target, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    } else {
      _scroll.jumpTo(target);
    }
  }

  /// Only auto-scrolls to the new message if the person was already near
  /// the bottom — otherwise it would yank them away from whatever they
  /// scrolled up to read, same principle as the admin panel fix.
  void _maybeAutoScroll(int msgCount) {
    final isNew = msgCount != _lastMsgCount;
    _lastMsgCount = msgCount;
    if (!isNew) return;
    final wasNearBottom = !_scroll.hasClients ||
        _scroll.position.maxScrollExtent - _scroll.position.pixels < 80;
    if (wasNearBottom) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom(animated: false));
    }
  }

  @override
  void dispose() {
    _poll?.cancel();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await ref.read(repoProvider).supportSend(text);
      _input.clear();
      ref.invalidate(supportThreadProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Message could not be sent. ${describeError(e).display}')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _sendImage() async {
    if (_sending) return;
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    if (!mounted) return;
    final confirmed = await _previewBeforeSend(context, File(picked.path));
    if (confirmed != true || !mounted) return;
    setState(() => _sending = true);
    try {
      final bytes = await picked.readAsBytes();
      final url = await ref.read(repoProvider).uploadChatImage(bytes);
      await ref.read(repoProvider).supportSend('', imageUrl: url);
      ref.invalidate(supportThreadProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not send photo. ${describeError(e).display}')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final thread = ref.watch(supportThreadProvider);
    return Scaffold(
      backgroundColor: AppColors.ink,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(58),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: const BoxDecoration(
            color: Color(0xE60A0A0B),
            border: Border(bottom: BorderSide(color: AppColors.line)),
          ),
          child: SafeArea(
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.muted),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.gold)),
                  child: const Icon(Icons.chat_bubble_outline, size: 15, color: AppColors.gold),
                ),
                const SizedBox(width: 10),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Support Chat', style: AppTextStyles.inter(size: 14, color: Colors.white)),
                    Text('Concierge desk', style: AppTextStyles.inter(size: 10, color: AppColors.success)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                thread.when(
              loading: () => const Center(
                  child: SizedBox(
                      width: 24, height: 24,
                      child: CircularProgressIndicator(color: AppColors.gold, strokeWidth: 2))),
              error: (err, __) => _ChatError(error: err, onRetry: () => ref.invalidate(supportThreadProvider)),
              data: (t) {
                _maybeAutoScroll(t.messages.length);
                return ListView(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                children: [
                  if (t.messages.isEmpty)
                    Center(
                        child: Padding(
                      padding: const EdgeInsets.only(top: 30),
                      child: Text('Good evening. How can we help you tonight?',
                          style: AppTextStyles.inter(
                              size: 12, weight: FontWeight.w300, color: AppColors.muted)),
                    )),
                  for (final m in t.messages) ...[
                    ChatBubble(
                        fromMember: m.fromMember,
                        text: m.message,
                        imageUrl: m.imageUrl,
                        senderName: m.fromMember ? null : (m.senderName.isEmpty ? 'Concierge' : m.senderName)),
                    const SizedBox(height: 14),
                  ],
                ],
                );
              },
            ),
                if (_showJumpButton)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 14,
                    child: Center(child: _JumpToBottomButton(onTap: () => _scrollToBottom())),
                  ),
              ],
            ),
          ),
          ref.watch(supportThreadProvider).maybeWhen(
                data: (t) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (t.closed)
                      Container(
                        width: double.infinity,
                        color: const Color(0xEB0A0A0B),
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                        child: Text(
                            'This conversation was closed by the concierge. Sending a message starts a new one.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.inter(
                                size: 10.5, weight: FontWeight.w300, color: AppColors.muted2)),
                      ),
                    _LiveChatInputBar(
                        controller: _input, sending: _sending, onSend: _send, onAttach: _sendImage, hint: 'Message the concierge.'),
                  ],
                ),
                orElse: () => _LiveChatInputBar(
                    controller: _input, sending: _sending, onSend: _send, onAttach: _sendImage, hint: 'Message the concierge.'),
              ),
        ],
      ),
    );
  }
}

/// Chat input wired to a live send action.
class _LiveChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;
  final VoidCallback? onAttach;
  final String hint;
  const _LiveChatInputBar(
      {required this.controller, required this.sending, required this.onSend, required this.hint, this.onAttach});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      decoration: const BoxDecoration(
        color: Color(0xEB0A0A0B),
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          if (onAttach != null)
            InkWell(
              onTap: sending ? null : onAttach,
              customBorder: const CircleBorder(),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(Icons.image_outlined, size: 21, color: sending ? AppColors.muted : AppColors.gold),
              ),
            ),
          Expanded(
            child: TextField(
              autofillHints: const [],
              controller: controller,
              onSubmitted: (_) => onSend(),
              style: AppTextStyles.inter(size: 13, color: Colors.white),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: AppTextStyles.inter(
                    size: 13, weight: FontWeight.w300, color: const Color(0xFF55555C)),
                filled: true,
                fillColor: AppColors.charcoal2,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppColors.line),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                      color: AppColors.gold.withValues(alpha: .55), width: 1.2),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: onSend,
            customBorder: const CircleBorder(),
            child: sending
                ? const SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(color: AppColors.gold, strokeWidth: 2))
                : const Icon(Icons.send_outlined, size: 22, color: AppColors.gold),
          ),
        ],
      ),
    );
  }
}

// ═════════════ SM Society Chat (The Circle Lounge) ═════════════
class SocietyChatScreen extends ConsumerStatefulWidget {
  const SocietyChatScreen({super.key});

  @override
  ConsumerState<SocietyChatScreen> createState() => _SocietyChatScreenState();
}

class _SocietyChatScreenState extends ConsumerState<SocietyChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  Timer? _poll;
  bool _sending = false;
  bool _showJumpButton = false;
  int _lastMsgCount = 0;

  @override
  void initState() {
    super.initState();
    // Refresh every 3 seconds so the room feels live.
    _poll = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) ref.invalidate(groupChatProvider);
    });
    // This list is reverse:true (latest message at visual bottom = scroll
    // offset 0), so "near bottom" means a small offset, not near maxExtent.
    _scroll.addListener(() {
      final nearBottom = _scroll.position.pixels < 80;
      if (nearBottom == _showJumpButton) {
        setState(() => _showJumpButton = !nearBottom);
      }
    });
  }

  void _scrollToBottom() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(0, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  void _maybeAutoScroll(int msgCount) {
    final isNew = msgCount != _lastMsgCount;
    _lastMsgCount = msgCount;
    if (!isNew) return;
    final wasNearBottom = !_scroll.hasClients || _scroll.position.pixels < 80;
    if (wasNearBottom) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) _scroll.jumpTo(0);
      });
    }
  }

  @override
  void dispose() {
    _poll?.cancel();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _showChatSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.charcoal,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => FutureBuilder<SharedPreferences>(
        future: SharedPreferences.getInstance(),
        builder: (ctx, snap) {
          if (!snap.hasData) {
            return const SizedBox(
                height: 140,
                child: Center(
                    child: SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(color: AppColors.gold, strokeWidth: 2))));
          }
          final prefs = snap.data!;
          return StatefulBuilder(builder: (ctx, setSheet) {
            final inApp = prefs.getBool(NotificationWatcher.prefGroupInApp) ?? true;
            final pushOn = prefs.getBool('smrc_gc_push') ?? true;
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('LOUNGE NOTIFICATIONS', style: AppTextStyles.eyebrow),
                    const SizedBox(height: 14),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeThumbColor: AppColors.gold,
                      title: Text('In-app popup',
                          style: AppTextStyles.inter(size: 13.5, color: Colors.white)),
                      subtitle: Text('Show a banner inside the app when someone writes',
                          style: AppTextStyles.inter(
                              size: 10.5, weight: FontWeight.w300, color: AppColors.muted)),
                      value: inApp,
                      onChanged: (v) {
                        prefs.setBool(NotificationWatcher.prefGroupInApp, v);
                        setSheet(() {});
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeThumbColor: AppColors.gold,
                      title: Text('Push notifications',
                          style: AppTextStyles.inter(size: 13.5, color: Colors.white)),
                      subtitle: Text('Get push notifications for new Lounge messages',
                          style: AppTextStyles.inter(
                              size: 10.5, weight: FontWeight.w300, color: AppColors.muted)),
                      value: pushOn,
                      onChanged: (v) {
                        prefs.setBool('smrc_gc_push', v);
                        ref.read(repoProvider).setGroupChatPushPref(v);
                        setSheet(() {});
                      },
                    ),
                  ],
                ),
              ),
            );
          });
        },
      ),
    );
  }

  void _showMembers(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.charcoal,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => Consumer(builder: (ctx, r, _) {
        final members = r.watch(directoryProvider).valueOrNull ?? const <Member>[];
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('IN THE LOUNGE', style: AppTextStyles.eyebrow),
                const SizedBox(height: 6),
                Text('Members', style: AppTextStyles.serif(size: 22, color: Colors.white)),
                const SizedBox(height: 14),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: members.length,
                    itemBuilder: (_, i) {
                      final m = members[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () {
                            Navigator.of(ctx).pop();
                            context.push('/member-profile', extra: m);
                          },
                          child: Row(
                          children: [
                            RingAvatar(tier: m.tier, size: 40, imageUrl: m.avatarUrl, gender: m.gender),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Text(m.name,
                                    style: AppTextStyles.inter(size: 13, color: Colors.white))),
                            TierBadge(tier: m.tier),
                          ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await ref.read(repoProvider).groupSend(text);
      _input.clear();
      ref.invalidate(groupChatProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(describeError(e).display)));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _sendImage() async {
    if (_sending) return;
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    if (!mounted) return;
    final confirmed = await _previewBeforeSend(context, File(picked.path));
    if (confirmed != true || !mounted) return;
    setState(() => _sending = true);
    try {
      final bytes = await picked.readAsBytes();
      final url = await ref.read(repoProvider).uploadChatImage(bytes);
      await ref.read(repoProvider).groupSend('', imageUrl: url);
      ref.invalidate(groupChatProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(describeError(e).display)));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chat = ref.watch(groupChatProvider);
    return Scaffold(
      backgroundColor: AppColors.ink,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(58),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: const BoxDecoration(
            color: Color(0xE60A0A0B),
            border: Border(bottom: BorderSide(color: AppColors.line)),
          ),
          child: SafeArea(
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.muted),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const AppLogo(size: 34),
                    Positioned(
                      bottom: 0,
                      right: -2,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.ink, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: () => _showMembers(context),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('The Circle Lounge', style: AppTextStyles.inter(size: 14, color: Colors.white)),
                        Text("The members\u2019 room",
                            style: AppTextStyles.inter(size: 10, color: AppColors.success)),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined, size: 18, color: AppColors.muted),
                  onPressed: () => _showChatSettings(context),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                chat.when(
              loading: () => const Center(
                  child: SizedBox(
                      width: 24, height: 24,
                      child: CircularProgressIndicator(color: AppColors.gold, strokeWidth: 2))),
              error: (err, __) => _ChatError(error: err, onRetry: () => ref.invalidate(groupChatProvider)),
              data: (payload) {
                final msgs = payload.messages;
                _maybeAutoScroll(msgs.length);
                return ListView(
                  controller: _scroll,
                  reverse: true,
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                  children: [
                    for (final m in msgs.reversed) ...[
                      const SizedBox(height: 14),
                    m.mine
                        ? ChatBubble(fromMember: true, text: m.message, imageUrl: m.imageUrl)
                        : ChatBubble(
                            fromMember: false,
                            text: m.message,
                            imageUrl: m.imageUrl,
                            senderName: m.senderType == 'member'
                                ? m.senderName.split(' ').first
                                : (m.senderName.isEmpty ? 'Concierge' : m.senderName),
                            avatarUrl: m.avatar.isEmpty ? null : m.avatar),
                  ],
                  if (msgs.isEmpty)
                    Center(
                        child: Padding(
                      padding: const EdgeInsets.only(top: 30),
                      child: Text('The room is quiet. Say good evening.',
                          style: AppTextStyles.inter(
                              size: 12, weight: FontWeight.w300, color: AppColors.muted)),
                    )),
                ],
                );
              },
            ),
                if (_showJumpButton)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 14,
                    child: Center(child: _JumpToBottomButton(onTap: _scrollToBottom)),
                  ),
              ],
            ),
          ),
          _LiveChatInputBar(
              controller: _input, sending: _sending, onSend: _send, onAttach: _sendImage, hint: 'Message the Society.'),
        ],
      ),
    );
  }
}

/// Shared error state with retry for the live rooms.
class _ChatError extends StatelessWidget {
  final VoidCallback onRetry;
  final Object? error;
  const _ChatError({required this.onRetry, this.error});

  @override
  Widget build(BuildContext context) {
    final info = error != null ? describeError(error!) : null;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(info?.message ?? 'Could not reach the Circle.',
              style: AppTextStyles.inter(size: 12.5, color: AppColors.muted)),
          const SizedBox(height: 4),
          Text(info?.detail ?? 'Check your connection and make sure you are signed in.',
              style: AppTextStyles.inter(size: 11, weight: FontWeight.w300, color: AppColors.muted2)),
          const SizedBox(height: 16),
          SizedBox(
            width: 140,
            child: GoldButton('Retry', style: GoldBtnStyle.line, onTap: onRetry),
          ),
        ],
      ),
    );
  }
}

// ═════════════ Member Directory ═════════════
class MemberDirectoryScreen extends ConsumerStatefulWidget {
  const MemberDirectoryScreen({super.key});

  @override
  ConsumerState<MemberDirectoryScreen> createState() => _MemberDirectoryScreenState();
}

class _MemberDirectoryScreenState extends ConsumerState<MemberDirectoryScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final directoryAsync = ref.watch(directoryProvider);
    // Not falling back to DemoData: orElse fires while loading too, so the
    // demo/reference member list used to flash before the real one arrived.
    final all = directoryAsync.valueOrNull ?? const <Member>[];
    final members = _query.isEmpty
        ? all
        : all
            .where((m) =>
                m.name.toLowerCase().contains(_query) || m.industry.toLowerCase().contains(_query))
            .toList();
    return Scaffold(
      backgroundColor: AppColors.ink,
      appBar: const AppTopNav(title: ''),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(26, 6, 26, 40),
        children: [
          Text('PRIVATE NETWORK', style: AppTextStyles.eyebrow),
          const SizedBox(height: 6),
          Text('Members', style: AppTextStyles.serif(size: 28, color: Colors.white)),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.line),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, size: 16, color: AppColors.muted),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    autofillHints: const [],
                    onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
                    style: AppTextStyles.inter(size: 12.5, color: Colors.white),
                    decoration: InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      hintText: 'Search by name or industry.',
                      hintStyle: AppTextStyles.inter(
                          size: 12.5, weight: FontWeight.w300, color: const Color(0xFF55555C)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              FilterChipPill('All', on: true),
              SizedBox(width: 8),
              FilterChipPill('Ambassadors'),
              SizedBox(width: 8),
              FilterChipPill('By tier'),
            ],
          ),
          const SizedBox(height: 18),
          if (directoryAsync.isLoading && all.isEmpty)
            const SkeletonList(count: 4, padding: EdgeInsets.zero)
          else if (directoryAsync.hasError && all.isEmpty)
            AsyncErrorState(
                message: "Couldn't load the directory. ${describeError(directoryAsync.error!).display}",
                onRetry: () => ref.invalidate(directoryProvider))
          else
            ...members.map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => context.push('/member-profile', extra: m),
                  child: AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  child: Row(
                    children: [
                      RingAvatar(tier: m.tier, size: 44, imageUrl: m.avatarUrl, gender: m.gender),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m.name, style: AppTextStyles.inter(size: 13.5, color: Colors.white)),
                            Text(m.memberNo ?? '',
                                style: AppTextStyles.inter(
                                    size: 10, weight: FontWeight.w300, color: AppColors.muted)),
                          ],
                        ),
                      ),
                      TierBadge(tier: m.tier),
                    ],
                  ),
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

// ═════════════ Benefits (tab) ═════════════
class BenefitsScreen extends ConsumerStatefulWidget {
  const BenefitsScreen({super.key});

  @override
  ConsumerState<BenefitsScreen> createState() => _BenefitsScreenState();
}

class _BenefitsScreenState extends ConsumerState<BenefitsScreen> {
  String? _category; // null = All

  @override
  Widget build(BuildContext context) {
    final payload = ref.watch(benefitsProvider).maybeWhen(data: (b) => b, orElse: () => null);
    final categories = payload?.categories ?? const <BenefitCategory>[];
    final visible = _category == null
        ? categories
        : categories.where((c) => c.name == _category).toList();
    final totalItems = visible.fold<int>(0, (n, c) => n + c.items.length);

    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 120),
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(26, 14, 26, 0),
              child: ScreenHeader(
                eyebrow: 'YOUR MEMBER DISCOUNTS',
                title: 'Benefits',
                titleSize: 30,
                subtitle:
                    'Everywhere SM Royal Circle has partnered. Tap a category to see what you save around the city.',
              ),
            ),
            // Category filter chips
            Padding(
              padding: const EdgeInsets.fromLTRB(26, 16, 26, 0),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilterChipPill('All', on: _category == null, onTap: () => setState(() => _category = null)),
                  ...categories.map((c) => FilterChipPill(c.name,
                      on: _category == c.name, onTap: () => setState(() => _category = c.name))),
                ],
              ),
            ),
            if (categories.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(26, 14, 26, 2),
                child: Text(
                    '$totalItems ${totalItems == 1 ? 'benefit' : 'benefits'} available to you',
                    style: AppTextStyles.inter(
                        size: 10.5, weight: FontWeight.w500, color: AppColors.muted2, letterSpacing: 1)),
              ),
            // Category sections
            ...visible.map((cat) => _categorySection(cat)),
            if (categories.isEmpty)
              Padding(
                padding: const EdgeInsets.all(40),
                child: Center(
                    child: Text('Benefits are being curated.',
                        style: AppTextStyles.inter(size: 12, color: AppColors.muted))),
              ),
          ],
        ),
      ),
    );
  }

  Widget _categorySection(BenefitCategory cat) {
    if (cat.items.isEmpty) return const SizedBox.shrink();
    // A "feature" category leads with its first item as a hero image card.
    final feature = cat.style == 'feature';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(26, 22, 26, 4),
          child: Text(cat.name.toUpperCase(),
              style: AppTextStyles.inter(
                  size: 10, weight: FontWeight.w600, color: AppColors.gold, letterSpacing: 2)),
        ),
        ...cat.items.map((item) {
          final asFeature = feature && item.image.isNotEmpty;
          return Padding(
            padding: const EdgeInsets.fromLTRB(26, 10, 26, 0),
            child: asFeature ? _featureCard(item) : _benefitRow(item),
          );
        }),
      ],
    );
  }

  /// Small chips showing which tiers a benefit is exclusive to.
  Widget _tierChips(BenefitItem item) {
    final labels = item.tierLabels;
    if (labels.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 7),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: labels
            .map((l) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.gold.withValues(alpha: .4)),
                  ),
                  child: Text(l.toUpperCase(),
                      style: AppTextStyles.inter(
                          size: 7.5, weight: FontWeight.w600, color: AppColors.gold, letterSpacing: 1)),
                ))
            .toList(),
      ),
    );
  }

  Widget _featureCard(BenefitItem item) => Container(
        height: 156,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.line),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(19),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(fadeInDuration: Duration.zero, imageUrl: item.image,
                  fit: BoxFit.cover, errorWidget: (a, b, c) => Container(color: AppColors.charcoal)),
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x1A0A0A0B), Color(0xF00A0A0B)]),
                ),
              ),
              if (item.badge.isNotEmpty)
                Positioned(
                  top: 14,
                  right: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(item.badge.toUpperCase(),
                        style: AppTextStyles.inter(
                            size: 8.5, weight: FontWeight.w700, color: AppColors.ink, letterSpacing: 1.2)),
                  ),
                ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, style: AppTextStyles.serif(size: 21, color: Colors.white)),
                    if (item.subtitle.isNotEmpty)
                      Text(item.subtitle,
                          style: AppTextStyles.inter(
                              size: 11, weight: FontWeight.w300, color: const Color(0xFFBDB9B0))),
                    _tierChips(item),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _benefitRow(BenefitItem item) => AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Leading: item image thumbnail if set, else the chosen icon medallion.
            if (item.image.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CachedNetworkImage(fadeInDuration: Duration.zero, imageUrl: 
                  item.image,
                  width: 46,
                  height: 46,
                  fit: BoxFit.cover,
                  errorWidget: (a, b, c) => _iconMedallion(item),
                ),
              )
            else
              _iconMedallion(item),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: AppTextStyles.inter(size: 13.5, color: Colors.white)),
                  if (item.subtitle.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(item.subtitle,
                          style: AppTextStyles.inter(
                              size: 10.5, weight: FontWeight.w300, color: AppColors.muted)),
                    ),
                  _tierChips(item),
                ],
              ),
            ),
            if (item.off.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(left: 10, top: 2),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: AppColors.gold.withValues(alpha: .12),
                ),
                child: Text(item.off.toUpperCase(),
                    style: AppTextStyles.inter(
                        size: 10, weight: FontWeight.w700, color: AppColors.gold, letterSpacing: .5)),
              ),
          ],
        ),
      );

  Widget _iconMedallion(BenefitItem item) => Container(
        width: 46,
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.gold.withValues(alpha: .1),
          border: Border.all(color: AppColors.gold.withValues(alpha: .3)),
        ),
        child: Icon(item.iconData, size: 18, color: AppColors.gold),
      );
}

// ═════════════ Cheer Hub (tab) ═════════════
class CheerHubScreen extends ConsumerWidget {
  const CheerHubScreen({super.key});

  Future<void> _openPodcast(BuildContext context, Map<String, dynamic> copy) async {
    final url = (copy['podcast_link']?.toString() ?? '').trim();
    if (url.isEmpty) return;
    await launchUrlString(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final copy = ref.watch(screenCopyProvider).maybeWhen(data: (c) => c, orElse: () => const <String, dynamic>{});
    String cv(String k, String fallback) =>
        (copy[k] as String?)?.trim().isNotEmpty == true ? copy[k] as String : fallback;
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 84),
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(26, 14, 26, 0),
              child: ScreenHeader(eyebrow: 'WATCH. LISTEN. RELIVE', title: 'Media', titleSize: 30),
            ),
            const SizedBox(height: 22),
            Padding(
              padding: const EdgeInsets.fromLTRB(26, 0, 26, 0),
              child: Column(
                children: [
                  // ── Podcast card
                  _CheerCard(
                    image: cv('cheer_podcast_image',
                        'https://images.unsplash.com/photo-1478737270239-2f02b77fc618?w=600&q=80'),
                    tagIcon: _ytIcon(),
                    tag: 'OPENS ON YOUTUBE →',
                    tagColor: Colors.white,
                    title: cv('cheer_podcast_title', 'Podcast'),
                    sub: 'Tap to watch the latest episode on YouTube',
                    onTap: () => _openPodcast(context, copy),
                  ),
                  const SizedBox(height: 14),
                  // ── Event Gallery card
                  _CheerCard(
                    image: cv('cheer_gallery_image',
                        'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=600&q=80'),
                    tagIcon: _goldSquare(Icons.image_outlined),
                    tag: 'PICK AN EVENT, THEN DRIVE',
                    tagColor: AppColors.gold,
                    title: cv('cheer_gallery_title', 'Event Gallery'),
                    sub: 'Choose an event to find and download your photos',
                    onTap: () => context.push('/event-gallery-1'),
                  ),
                  const SizedBox(height: 14),
                  // ── Event Footage card
                  _CheerCard(
                    image: cv('cheer_footage_image',
                        'https://images.unsplash.com/photo-1492447166138-50c3889fccb1?w=600&q=80'),
                    tagIcon: _goldSquare(Icons.play_circle_outline),
                    tag: 'PICK AN EVENT, THEN DRIVE',
                    tagColor: AppColors.gold,
                    title: cv('cheer_footage_title', 'Event Footage'),
                    sub: 'Choose an event to open its films folder',
                    onTap: () => context.push('/event-footage-1'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _ytIcon() => Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: const Color(0xFFFF0000), borderRadius: BorderRadius.circular(8)),
        child: const Icon(Icons.play_arrow, size: 16, color: Colors.white),
      );

  static Widget _goldSquare(IconData icon) => Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
            color: AppColors.gold.withValues(alpha: .18), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 16, color: AppColors.gold),
      );
}

/// The big card used in the Cheer Hub (Podcast / Event Gallery / Event Footage).
/// Corner radius is applied via ClipRRect so ALL four corners clip properly —
/// including any network image overflow and InkWell splash boundaries.
class _CheerCard extends StatelessWidget {
  final String image;
  final Widget tagIcon;
  final String tag;
  final Color tagColor;
  final String title;
  final String sub;
  final VoidCallback? onTap;

  const _CheerCard({
    required this.image,
    required this.tagIcon,
    required this.tag,
    required this.tagColor,
    required this.title,
    required this.sub,
    this.onTap,
  });

  static const _radius = Radius.circular(18);
  static const _border = BorderRadius.all(_radius);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: _border,
      child: Material(
        color: AppColors.charcoal,
        child: InkWell(
          borderRadius: _border,
          onTap: onTap,
          child: Container(
            height: 118,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.line),
              borderRadius: _border,
            ),
            child: ClipRRect(
              borderRadius: _border,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Background photo (cached across launches)
                  CachedNetworkImage(
                    imageUrl: image,
                    fit: BoxFit.cover,
                    fadeInDuration: Duration.zero,
                    placeholder: (_, __) => Container(color: AppColors.charcoal),
                    errorWidget: (_, __, ___) => Container(color: AppColors.charcoal),
                  ),
                  // Dark gradient overlay (heavier on left so text pops)
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [Color(0xEB0A0A0B), Color(0x660A0A0B)],
                      ),
                    ),
                  ),
                  // Content
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Top: icon + tag label
                        Row(
                          children: [
                            tagIcon,
                            const SizedBox(width: 8),
                            Text(
                              tag,
                              style: AppTextStyles.inter(
                                  size: 9,
                                  weight: FontWeight.w600,
                                  color: tagColor,
                                  letterSpacing: 1.4),
                            ),
                          ],
                        ),
                        // Bottom: title + subtitle
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title,
                                style: AppTextStyles.serif(size: 22, color: Colors.white)),
                            const SizedBox(height: 2),
                            Text(sub,
                                style: AppTextStyles.inter(
                                    size: 10.5,
                                    weight: FontWeight.w300,
                                    color: const Color(0xFFBDB9B0))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


// ═════════════ Gallery / Footage — event picker ═════════════
class DrivePickerScreen extends ConsumerWidget {
  final bool footage;
  const DrivePickerScreen({super.key, this.footage = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only finished events appear here — an event joins the pickers the day
    // AFTER its (inclusive) end date.
    final all = ref.watch(allEventsProvider).maybeWhen(data: (e) => e, orElse: () => <ClubEvent>[]);
    final list = all.where((e) => e.isPast).toList();

    return Scaffold(
      backgroundColor: AppColors.ink,
      appBar: AppTopNav(title: footage ? 'Event Footage' : 'Event Gallery'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(26, 16, 26, 40),
        children: [
          Text(
            footage
                ? 'Pick an event to watch the films. Each event opens its own folder on Google Drive.'
                : 'Pick an event to find your photos. Each event opens its own folder on Google Drive.',
            style: AppTextStyles.inter(size: 11.5, weight: FontWeight.w300, color: AppColors.muted, height: 1.55),
          ),
          const SizedBox(height: 16),
          if (list.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text('No finished events yet. Albums appear here the day after an event ends.',
                  style: AppTextStyles.inter(size: 11.5, weight: FontWeight.w300, color: AppColors.muted)),
            ),
          ...list.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  onTap: () => context.push(footage ? '/event-footage-2' : '/event-gallery-2', extra: e),
                  borderRadius: BorderRadius.circular(20),
                  child: AppCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
                          child: CachedNetworkImage(fadeInDuration: Duration.zero, imageUrl: e.coverImageUrl ?? '',
                              fit: BoxFit.cover,
                              errorWidget: (a, b, c) => Container(color: AppColors.charcoal2)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(e.title, style: AppTextStyles.inter(size: 12.5, color: Colors.white)),
                              Text(e.dateLabel,
                                  style: AppTextStyles.inter(
                                      size: 10, weight: FontWeight.w300, color: AppColors.muted)),
                            ],
                          ),
                        ),
                        Text('›', style: AppTextStyles.inter(size: 16, color: AppColors.gold)),
                      ],
                    ),
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

// ═════════════ Gallery / Footage — Drive folder detail ═════════════
class DriveDetailScreen extends StatelessWidget {
  final bool footage;
  final ClubEvent? event;
  const DriveDetailScreen({super.key, this.footage = false, this.event});

  Future<void> _open(BuildContext context, String url) async {
    if (url.isEmpty || url == '#') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('The folder for this event has not been shared yet.')));
      return;
    }
    final ok = await launchUrlString(url, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Could not open the folder.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = event?.title ?? (footage ? 'The Rooftop Gala' : 'The Midnight Salon');
    final link = footage ? (event?.footageLink ?? '') : (event?.galleryLink ?? '');
    return Scaffold(
      backgroundColor: AppColors.ink,
      appBar: AppTopNav(title: title),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(26, 16, 26, 40),
        children: [
          Text(
            footage
                ? 'Highlight films from this event are stored on Google Drive. Tap below to open the folder and watch.'
                : 'All photos from this event are stored on Google Drive. Tap below to open the folder and download your own.',
            style: AppTextStyles.inter(
                size: 12.5, weight: FontWeight.w300, color: const Color(0xFFBDB9B0), height: 1.7),
          ),
          const SizedBox(height: 18),
          InkWell(
            onTap: () => _open(context, link),
            borderRadius: BorderRadius.circular(20),
            child: AppCard(
              padding: const EdgeInsets.all(16),
              borderColor: AppColors.gold.withValues(alpha: .4),
              child: Row(
                children: [
                  const Icon(Icons.folder_shared_outlined, size: 22, color: AppColors.gold),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Open in Google Drive', style: AppTextStyles.inter(size: 13, color: Colors.white)),
                        Text('Opens in a new tab',
                            style: AppTextStyles.inter(size: 10, weight: FontWeight.w300, color: AppColors.muted)),
                      ],
                    ),
                  ),
                  Text('→', style: AppTextStyles.inter(size: 18, color: AppColors.gold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════ Membership Tiers (selection) ═════════════
class MembershipTiersScreen extends ConsumerStatefulWidget {
  const MembershipTiersScreen({super.key});
  @override
  ConsumerState<MembershipTiersScreen> createState() => _MembershipTiersScreenState();
}

class _MembershipTiersScreenState extends ConsumerState<MembershipTiersScreen> {
  int _selected = 0;

  Color _tierColor(String id) => switch (id) {
        'gold' => AppColors.tierGold,
        'diamond' => AppColors.diamond,
        _ => AppColors.silver,
      };

  // Detailed "what's included" per tier. Prefers live backend benefit rows
  // (admin-editable via Manage Benefits) so edits reflect in the app; falls
  // back to the launch spec bundled in DemoData when rows are unavailable.
  ({String tagline, String inheritNote, List<String> includes}) _detail(
      String id, List<TierBenefitRow> rows) {
    // Build includes from benefit rows where this tier has the benefit
    // (value == yes/true, or a non-empty custom value like "6").
    final derived = <String>[];
    for (final r in rows) {
      final raw = r.values[id];
      if (raw == null) continue;
      final v = raw.toString().trim();
      final low = v.toLowerCase();
      if (low == 'no' || low == 'false' || v.isEmpty || v == '—' || v == '-') continue;
      if (low == 'yes' || low == 'true') {
        derived.add(r.label);
      } else {
        derived.add('${r.label}: $v');
      }
    }

    // Tagline / inherit note come from the demo spec (copy, not data).
    final d = DemoData.tierDetails.where((t) => t.id == id).toList();
    final tagline = d.isNotEmpty ? d.first.tagline : '';
    final inheritNote = d.isNotEmpty ? d.first.inheritNote : '';

    if (derived.isNotEmpty) {
      return (tagline: tagline, inheritNote: '', includes: derived);
    }
    // No real benefit rows configured for this tier yet (admin hasn't set
    // up Manage Benefits) — show an honest empty list rather than a
    // fabricated one. Only the tagline/inheritNote (static marketing copy,
    // not business data) still come from the launch spec.
    return (tagline: tagline, inheritNote: inheritNote, includes: const <String>[]);
  }

  @override
  Widget build(BuildContext context) {
    final tiersAsync = ref.watch(tiersProvider);
    final payload = tiersAsync.valueOrNull;
    // Only a payload with real data counts — an empty one (which our own
    // notifier would never actually return, but just in case) still needs
    // the loading branch below rather than silently falling to demo prices.
    if (payload == null || payload.tiers.isEmpty) {
      return const Scaffold(
        backgroundColor: AppColors.ink,
        body: Center(child: CircularProgressIndicator(color: AppColors.gold, strokeWidth: 2)),
      );
    }
    final tiers = payload.tiers;
    final selectedTier = tiers.isNotEmpty ? tiers[_selected.clamp(0, tiers.length - 1)] : null;
    // No demo fallback: if the admin hasn't configured tier benefit rows,
    // show none rather than inventing a comparison table of benefits the
    // club doesn't actually offer.
    final benefitRows = payload.rows;

    return Scaffold(
      backgroundColor: AppColors.ink,
      appBar: const AppTopNav(title: ''),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.only(bottom: 130),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(26, 6, 26, 0),
                child: Column(
                  children: [
                    Text('MEMBERSHIP', style: AppTextStyles.eyebrow),
                    const SizedBox(height: 6),
                    const HeroTitle(line1: 'Choose your', em: 'tier', size: 29),
                    const SizedBox(height: 10),
                    Text('Yearly. Every approved Silver member starts with a complimentary 6-month founding membership.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.inter(size: 12, weight: FontWeight.w300, color: AppColors.muted, height: 1.5)),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              ...List.generate(tiers.length, (i) {
                final t = tiers[i];
                final c = _tierColor(t.tierKey);
                final on = _selected == i;
                final detail = _detail(t.tierKey, benefitRows);
                return Padding(
                  padding: const EdgeInsets.fromLTRB(26, 0, 26, 12),
                  child: InkWell(
                    onTap: () => setState(() => _selected = i),
                    borderRadius: BorderRadius.circular(20),
                    child: AppCard(
                      padding: const EdgeInsets.all(16),
                      borderColor: on ? c : null,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.diamond_outlined, size: 22, color: c),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Row(
                                  children: [
                                    Flexible(
                                      child: Text(t.name,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTextStyles.serif(size: 19, color: Colors.white)),
                                    ),
                                    if (t.showTag && t.tag.isNotEmpty) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                            color: c, borderRadius: BorderRadius.circular(12)),
                                        child: Text(t.tag.toUpperCase(),
                                            style: AppTextStyles.inter(
                                                size: 8, weight: FontWeight.w600, color: AppColors.ink, letterSpacing: 1)),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Text('\$${t.price.toStringAsFixed(0)}',
                                  style: AppTextStyles.inter(size: 15, weight: FontWeight.w500, color: c)),
                              Text('/yr', style: AppTextStyles.inter(size: 10, color: AppColors.muted2)),
                            ],
                          ),
                          // Expanded details for the selected tier
                          if (on) ...[
                            const SizedBox(height: 12),
                            if (detail.tagline.isNotEmpty)
                              Text(detail.tagline,
                                  style: AppTextStyles.inter(
                                      size: 11.5, weight: FontWeight.w300, color: AppColors.muted, height: 1.5)),
                            if (detail.inheritNote.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(detail.inheritNote,
                                  style: AppTextStyles.inter(
                                      size: 11, weight: FontWeight.w600, color: c, letterSpacing: .3)),
                            ],
                            const SizedBox(height: 10),
                            ...detail.includes.map((line) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Icon(Icons.check, size: 13, color: c),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(line,
                                            style: AppTextStyles.inter(
                                                size: 11.5, weight: FontWeight.w300,
                                                color: const Color(0xFFE9E7E1), height: 1.45)),
                                      ),
                                    ],
                                  ),
                                )),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }),
              Padding(
                padding: const EdgeInsets.fromLTRB(26, 6, 26, 0),
                child: Text('Membership provides access, priority and community privileges. Event tickets are purchased separately.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.inter(size: 10, weight: FontWeight.w300, color: AppColors.muted2, height: 1.5)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(26, 14, 26, 0),
                child: Center(
                  child: InkWell(
                    onTap: () => context.push('/tier-comparison'),
                    child: Text('See full tier comparison',
                        style: AppTextStyles.inter(size: 11.5, color: AppColors.gold)
                            .copyWith(decoration: TextDecoration.underline)),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(26, 16, 26, 30),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0, .3],
                    colors: [Colors.transparent, AppColors.ink]),
              ),
              child: GoldButton(
                selectedTier != null
                    ? 'Get ${selectedTier.name} · \$${selectedTier.price.toStringAsFixed(0)}/yr'
                    : 'Choose a Tier',
                onTap: selectedTier == null
                    ? null
                    : () => context.push('/membership-checkout', extra: selectedTier),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════ Membership Checkout ═════════════
class MembershipCheckoutScreen extends ConsumerStatefulWidget {
  final TierInfo? tier;
  const MembershipCheckoutScreen({super.key, this.tier});

  @override
  ConsumerState<MembershipCheckoutScreen> createState() => _MembershipCheckoutScreenState();
}

class _MembershipCheckoutScreenState extends ConsumerState<MembershipCheckoutScreen> {
  bool _busy = false;

  Color _tierColor(String id) => switch (id) {
        'gold' => AppColors.tierGold,
        'diamond' => AppColors.diamond,
        _ => AppColors.silver,
      };

  int _tierRank(String key) => switch (key) {
        'gold' => 1,
        'diamond' => 2,
        _ => 0,
      };

  String _tierKeyOf(MemberTier t) => switch (t) {
        MemberTier.gold => 'gold',
        MemberTier.blackDiamond => 'diamond',
        _ => 'silver',
      };

  /// Determine purchase action + amount. Upgrade charges only the difference
  /// from the member's current tier price.
  ({String action, double amount, double currentPrice}) _plan(TierInfo tier) {
    final me = ref.read(currentMemberProvider);
    if (me == null || !me.hasActiveMembership) {
      // No active membership to renew or upgrade from — whatever tier they
      // pick, this is a first purchase. (An inactive member's raw tier
      // value defaults to the Silver enum case, which used to make
      // selecting Silver look like a renewal of a membership that was
      // never actually active.)
      return (action: 'new', amount: tier.price, currentPrice: 0);
    }
    final myKey = _tierKeyOf(me.tier);
    final tiers = ref.read(tiersProvider).maybeWhen(data: (p) => p.tiers, orElse: () => <TierInfo>[]);
    final myInfo = tiers.where((t) => t.tierKey == myKey).firstOrNull;
    final currentPrice = myInfo?.price ?? 0;
    if (myKey == tier.tierKey) {
      return (action: 'renew', amount: tier.price, currentPrice: currentPrice);
    }
    if (_tierRank(tier.tierKey) > _tierRank(myKey)) {
      final diff = tier.price - currentPrice;
      return (action: 'upgrade', amount: diff < 0 ? 0 : diff, currentPrice: currentPrice);
    }
    return (action: 'new', amount: tier.price, currentPrice: currentPrice);
  }

  Future<void> _confirm(TierInfo tier, String action) async {
    setState(() => _busy = true);
    final repo = ref.read(repoProvider);
    try {
      final plan = _plan(tier);
      String? paymentIntentId;

      if (plan.amount > 0) {
        final init = await ensureStripeInitialized(repo);
        if (!init.ready) {
          throw ApiException(switch (init.failure!) {
            StripeInitFailure.notSignedIn => 'Please sign in to your account to complete this purchase.',
            StripeInitFailure.serverNotConfigured => 'Payments are not set up yet. Please try again later.',
            StripeInitFailure.other =>
              init.error?.display ?? 'Something went wrong. Please try again.',
          });
        }

        final intent = await repo.createPaymentIntent(
          purpose: 'membership',
          tierKey: tier.tierKey,
          action: action,
        );

        if (!intent.freeNoPaymentNeeded) {
          if (intent.clientSecret == null) {
            throw ApiException('Could not start payment.');
          }
          final available = await isPlatformPayAvailable();
          if (!available) {
            throw ApiException(Platform.isIOS
                ? 'Apple Pay is not set up on this device.'
                : 'Google Pay is not set up on this device.');
          }
          String? payError;
          final paid = await payWithPlatformPay(
            clientSecret: intent.clientSecret!,
            amount: intent.amount,
            testEnv: stripeTestMode,
            onError: (m) => payError = m,
          );
          if (!paid) {
            // Null payError means the member simply cancelled the sheet —
            // no error to show, just stop quietly.
            if (payError != null) throw ApiException(payError!);
            setState(() => _busy = false);
            return;
          }
          paymentIntentId = intent.paymentIntentId;
        }
      }

      await repo.purchaseMembership(tierKey: tier.tierKey, action: action, paymentIntentId: paymentIntentId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e is ApiException ? e.message : 'Could not complete this purchase.')),
        );
      }
      if (mounted) setState(() => _busy = false);
      return;
    }
    if (!mounted) return;
    setState(() => _busy = false);
    context.push('/membership-confirmation', extra: {'tier': tier, 'action': action});
  }

  @override
  Widget build(BuildContext context) {
    final tier = widget.tier;
    if (tier == null) {
      return Scaffold(
        backgroundColor: AppColors.ink,
        appBar: const AppTopNav(title: 'Checkout'),
        body: Center(
          child: Text('No tier selected.',
              style: AppTextStyles.inter(size: 13, color: AppColors.muted)),
        ),
      );
    }
    final c = _tierColor(tier.tierKey);
    final plan = _plan(tier);
    final isUpgrade = plan.action == 'upgrade';
    final amount = plan.amount;
    final title = isUpgrade
        ? 'Upgrade to ${tier.name}'
        : (plan.action == 'renew' ? 'Renew ${tier.name}' : '${tier.name} Membership');
    return Scaffold(
      backgroundColor: AppColors.ink,
      appBar: const AppTopNav(title: 'Checkout'),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(26, 16, 26, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppCard(
                      padding: const EdgeInsets.all(16),
                      borderColor: c.withValues(alpha: .35),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: c.withValues(alpha: .12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: c.withValues(alpha: .5)),
                            ),
                            child: Icon(Icons.diamond_outlined, size: 24, color: c),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(title,
                                    style: AppTextStyles.inter(size: 13.5, color: Colors.white)),
                                Text('Billed once a year',
                                    style: AppTextStyles.inter(
                                        size: 10.5, weight: FontWeight.w300, color: AppColors.muted)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (isUpgrade) ...[
                      _MembershipCheckoutLine(
                          label: '${tier.name} tier (yearly)', value: '\$${tier.price.toStringAsFixed(2)}'),
                      _MembershipCheckoutLine(
                          label: 'Less current tier credit', value: '\u2212\$${plan.currentPrice.toStringAsFixed(2)}'),
                    ] else
                      _MembershipCheckoutLine(
                          label: '${tier.name} tier (yearly)', value: '\$${tier.price.toStringAsFixed(2)}'),
                    const _MembershipCheckoutLine(label: 'Tax', value: '\$0.00'),
                    Container(height: 1, color: AppColors.line, margin: const EdgeInsets.symmetric(vertical: 12)),
                    _MembershipCheckoutLine(label: 'Total', value: '\$${amount.toStringAsFixed(2)}', bold: true),
                    const SizedBox(height: 14),
                    Text(isUpgrade
                        ? 'You only pay the difference from your current tier. Your renewal date stays the same.'
                        : 'Your card is charged yearly. Cancel any time before your renewal date.',
                        style: AppTextStyles.inter(
                            size: 10.5, weight: FontWeight.w300, color: AppColors.muted2, height: 1.5)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (amount > 0)
              PlatformPayCheckoutButton(
                busy: _busy,
                ensureReady: () => ensureStripeInitialized(ref.read(repoProvider)),
                onPressed: () => _confirm(tier, plan.action),
              )
            else if (_busy)
              const Center(
                  child: SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(color: AppColors.gold, strokeWidth: 2)))
            else
              GoldButton('Activate ${tier.name}', onTap: () => _confirm(tier, plan.action)),
          ],
        ),
      ),
    );
  }
}

// ═════════════ Membership Confirmation ═════════════
class MembershipConfirmationScreen extends ConsumerStatefulWidget {
  final TierInfo? tier;
  final String action;
  const MembershipConfirmationScreen({super.key, this.tier, this.action = 'new'});

  @override
  ConsumerState<MembershipConfirmationScreen> createState() => _MembershipConfirmationScreenState();
}

class _MembershipConfirmationScreenState extends ConsumerState<MembershipConfirmationScreen> {
  @override
  void initState() {
    super.initState();
    // Reflect the newly purchased tier immediately in the logged-in member
    // state, and clear any scheduled cancellation. When a real membership
    // purchase endpoint exists, replace this with a /me refetch.
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyTier());
  }

  MemberTier _tierFromKey(String key) => switch (key) {
        'gold' => MemberTier.gold,
        'diamond' => MemberTier.blackDiamond,
        'amb' => MemberTier.ambassador,
        'admin' => MemberTier.admin,
        _ => MemberTier.silver,
      };

  void _applyTier() {
    final t = widget.tier;
    if (t == null) return;
    final notifier = ref.read(currentMemberProvider.notifier);
    // Refresh billing history so the new payment shows up.
    ContentCache.clear('billing');
    ref.invalidate(billingProvider);
    final current = ref.read(currentMemberProvider);
    if (current != null) {
      final now = DateTime.now();
      final rawExpiry = current.expiresAtRaw;
      DateTime? currentExpiry;
      if (rawExpiry != null && rawExpiry.trim().isNotEmpty) {
        currentExpiry = DateTime.tryParse(rawExpiry);
      }

      // Expiry rules mirror the backend:
      //  - upgrade : keep the current expiry (only the tier changes)
      //  - renew   : extend a year from the later of current expiry or today
      //  - new     : one year from today
      DateTime next;
      if (widget.action == 'upgrade' && currentExpiry != null) {
        next = currentExpiry;
      } else {
        final base = (widget.action == 'renew' &&
                currentExpiry != null &&
                currentExpiry.isAfter(now))
            ? currentExpiry
            : now;
        next = DateTime(base.year + 1, base.month, base.day);
      }

      final formatted = DateFormat('MMMM d, y').format(next);
      final iso = DateFormat('yyyy-MM-dd').format(next);
      notifier.state = current.copyWith(
        tier: _tierFromKey(t.tierKey),
        status: 'active',
        clearCancellation: true,
        hasActiveMembership: true,
        renewsAt: formatted,
        expiresAt: formatted,
        expiresAtRaw: iso,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.tier?.name ?? 'Membership';
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 34),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const GoldRingIcon(icon: Icons.check, size: 78),
                    const SizedBox(height: 24),
                    Text('WELCOME', style: AppTextStyles.eyebrow),
                    const SizedBox(height: 10),
                    HeroTitle(line1: 'You are now', em: name, size: 28),
                    const SizedBox(height: 14),
                    Text('Your $name membership is active. Explore your new access, priority benefits and community privileges.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.inter(
                            size: 12.5, weight: FontWeight.w300, color: AppColors.muted, height: 1.6)),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 26,
              right: 26,
              bottom: 44,
              child: GoldButton('Back to Membership',
                  onTap: () {
                    // Return to Membership & Tier, clearing the checkout/confirm
                    // stack so back doesn't re-open the purchase flow.
                    context.go('/explore');
                    context.push('/membership-tier-settings');
                  }),
            ),
          ],
        ),
      ),
    );
  }
}


class _MembershipCheckoutLine extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  const _MembershipCheckoutLine({required this.label, required this.value, this.bold = false});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(label,
                  style: AppTextStyles.inter(
                      size: 13,
                      weight: bold ? FontWeight.w600 : FontWeight.w300,
                      color: bold ? Colors.white : AppColors.muted)),
            ),
            Text(value,
                style: AppTextStyles.inter(
                    size: 13,
                    weight: bold ? FontWeight.w600 : FontWeight.w400,
                    color: bold ? AppColors.gold : const Color(0xFFE9E7E1))),
          ],
        ),
      );
}

// ═════════════ Tier Comparison ═════════════
class TierComparisonScreen extends ConsumerWidget {
  const TierComparisonScreen({super.key});

  static const _tierKeys = ['silver', 'gold', 'diamond'];

  Widget _cell(String raw, Color accent) {
    final v = raw.trim();
    final low = v.toLowerCase();
    if (low == 'yes' || low == 'true') {
      return Icon(Icons.check_rounded, size: 16, color: accent);
    }
    if (low == 'no' || low == 'false' || v.isEmpty || v == '\u2014' || v == '-') {
      return Text('\u2014',
          style: AppTextStyles.inter(size: 13, color: AppColors.muted2));
    }
    return Text(v,
        textAlign: TextAlign.center,
        style: AppTextStyles.inter(
            size: 10.5, weight: FontWeight.w400, color: const Color(0xFFE9E7E1), height: 1.25));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payload = ref.watch(tiersProvider).valueOrNull;
    if (payload == null || payload.tiers.isEmpty) {
      return const Scaffold(
        backgroundColor: AppColors.ink,
        body: Center(child: CircularProgressIndicator(color: AppColors.gold, strokeWidth: 2)),
      );
    }
    // Same as above: never substitute fabricated benefit rows.
    final rows = payload.rows;
    final tiers = payload.tiers;

    const tierColors = [AppColors.silver, AppColors.gold, AppColors.diamond];
    const tierShort = ['SILVER', 'GOLD', 'BLACK\nDIAMOND'];

    Widget headerCell(int i) => Expanded(
          flex: 2,
          child: Column(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: tierColors[i].withValues(alpha: .14),
                  shape: BoxShape.circle,
                  border: Border.all(color: tierColors[i].withValues(alpha: .5)),
                ),
                child: Icon(Icons.diamond_outlined, size: 14, color: tierColors[i]),
              ),
              const SizedBox(height: 6),
              Text(tierShort[i],
                  textAlign: TextAlign.center,
                  style: AppTextStyles.inter(
                      size: 8.5, weight: FontWeight.w600, color: tierColors[i], letterSpacing: .8, height: 1.2)),
            ],
          ),
        );

    return Scaffold(
      backgroundColor: AppColors.ink,
      appBar: const AppTopNav(title: ''),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(22, 6, 22, 40),
        children: [
          Text('COMPARE', style: AppTextStyles.eyebrow),
          const SizedBox(height: 6),
          Text('What each tier adds', style: AppTextStyles.serif(size: 27, color: Colors.white)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.only(bottom: 14),
            decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.line))),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Expanded(flex: 4, child: SizedBox()),
                headerCell(0),
                headerCell(1),
                headerCell(2),
              ],
            ),
          ),
          ...rows.map((b) => Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                        flex: 4,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: Text(b.label,
                              style: AppTextStyles.inter(
                                  size: 12.5, weight: FontWeight.w300, color: const Color(0xFFE9E7E1), height: 1.35)),
                        )),
                    for (int i = 0; i < 3; i++)
                      Expanded(
                          flex: 2,
                          child: Center(
                              child: _cell('${b.values[_tierKeys[i]] ?? '\u2014'}', tierColors[i]))),
                  ],
                ),
              )),
          const SizedBox(height: 22),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Column(
              children: [
                for (int i = 0; i < tiers.length; i++)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                        border: i == tiers.length - 1
                            ? null
                            : const Border(bottom: BorderSide(color: AppColors.line))),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.diamond_outlined,
                                size: 15,
                                color: i < tierColors.length ? tierColors[i] : AppColors.gold),
                            const SizedBox(width: 8),
                            Text(tiers[i].name,
                                style: AppTextStyles.inter(size: 12.5, color: const Color(0xFFE9E7E1))),
                          ],
                        ),
                        Text('\$${tiers[i].price.toStringAsFixed(0)} / year',
                            style: AppTextStyles.inter(
                                size: 12.5, weight: FontWeight.w500, color: AppColors.gold)),
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

// ═════════════ Ambassador Benefits ═════════════
class AmbassadorBenefitsScreen extends ConsumerWidget {
  const AmbassadorBenefitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final amb = ref.watch(benefitsProvider).valueOrNull?.ambassador ?? const <AmbassadorBenefit>[];
    return Scaffold(
      backgroundColor: AppColors.ink,
      appBar: const AppTopNav(title: ''),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(26, 6, 26, 40),
        children: [
          const ScreenHeader(
            eyebrow: 'Ambassador privileges',
            eyebrowColor: AppColors.ambassador,
            title: 'Benefits',
            titleSize: 30,
            subtitle: 'What you get as a verified Brand Ambassador of SM Royal Circle.',
          ),
          const SizedBox(height: 20),
          ...amb.map((b) => Padding(
                padding: const EdgeInsets.only(bottom: 11),
                child: AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, size: 18, color: AppColors.ambassador),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(b.title, style: AppTextStyles.inter(size: 13, color: Colors.white)),
                            Text(b.description,
                                style: AppTextStyles.inter(
                                    size: 10.5, weight: FontWeight.w300, color: AppColors.muted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.ambassador.withValues(alpha: .3)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text('STATUS GRANTED BY',
                    style: AppTextStyles.inter(
                        size: 9.5, weight: FontWeight.w600, color: AppColors.muted2, letterSpacing: 2)),
                const SizedBox(height: 5),
                Text('The Circle', style: AppTextStyles.serif(size: 17, color: AppColors.ambassador)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows the picked photo full-size with Send/Cancel before it actually
/// uploads and sends — previously tapping a photo in the gallery picker
/// sent it immediately with no way to back out of a wrong pick.
Future<bool?> _previewBeforeSend(BuildContext context, File file) {
  return showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: .92),
    builder: (ctx) => Dialog(
      backgroundColor: AppColors.charcoal,
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(file, fit: BoxFit.contain, height: 320),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: GoldButton('Cancel',
                      style: GoldBtnStyle.ghost, compact: true, onTap: () => Navigator.of(ctx).pop(false)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GoldButton('Send', compact: true, onTap: () => Navigator.of(ctx).pop(true)),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

/// Floating "jump to latest" button — just the arrow, no label. Shown
/// whenever the person has scrolled up from the bottom of a chat.
class _JumpToBottomButton extends StatelessWidget {
  final VoidCallback onTap;
  const _JumpToBottomButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.gold,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .35), blurRadius: 10, offset: const Offset(0, 3))],
          ),
          child: const Icon(Icons.keyboard_arrow_down, color: AppColors.ink, size: 24),
        ),
      ),
    );
  }
}
