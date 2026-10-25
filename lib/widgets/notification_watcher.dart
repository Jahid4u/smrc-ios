import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/router/app_router.dart';
import '../providers/app_providers.dart';

/// Watches announcements, group chat and support chat in the background and
/// slides a small banner in from the top for ~2s when something new arrives.
/// Group-chat popups can be turned off in the Lounge settings sheet.
class NotificationWatcher extends ConsumerStatefulWidget {
  final Widget child;
  const NotificationWatcher({super.key, required this.child});

  static const prefGroupInApp = 'smrc_gc_inapp_popup';

  @override
  ConsumerState<NotificationWatcher> createState() => _NotificationWatcherState();
}

class _NotificationWatcherState extends ConsumerState<NotificationWatcher>
    with SingleTickerProviderStateMixin {
  Timer? _poll;
  late final AnimationController _anim;
  late final Animation<Offset> _slide;
  String _title = '';
  String _body = '';
  IconData _icon = Icons.notifications_none;
  String _route = '';
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 320));
    _slide = Tween<Offset>(begin: const Offset(0, -1.2), end: Offset.zero)
        .animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic));
    _poll = Timer.periodic(const Duration(seconds: 10), (_) => _check());
  }

  @override
  void dispose() {
    _poll?.cancel();
    _anim.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    if (!mounted || ref.read(currentMemberProvider) == null) return;
    final prefs = await SharedPreferences.getInstance();
    final repo = ref.read(repoProvider);

    // Announcements
    try {
      final anns = await repo.announcements();
      if (anns.isNotEmpty) {
        final latest = anns.map((a) => a.id).reduce((a, b) => a > b ? a : b);
        final seen = prefs.getInt('smrc_seen_ann') ?? -1;
        if (seen >= 0 && latest > seen) {
          _show('From the Circle', anns.firstWhere((a) => a.id == latest).title,
              Icons.campaign_outlined, '/announcements');
        }
        prefs.setInt('smrc_seen_ann', latest);
      }
    } catch (_) {}

    // Group chat (respects the Lounge in-app popup toggle)
    try {
      if (prefs.getBool(NotificationWatcher.prefGroupInApp) ?? true) {
        final payload = await repo.groupChat();
        final incoming = payload.messages.where((m) => !m.mine).toList();
        if (incoming.isNotEmpty) {
          final latest = incoming.map((m) => m.id).reduce((a, b) => a > b ? a : b);
          final seen = prefs.getInt('smrc_seen_group') ?? -1;
          if (seen >= 0 && latest > seen) {
            final m = incoming.firstWhere((x) => x.id == latest);
            _show('The Circle Lounge',
                '${m.senderName.split(' ').first}: ${m.message}', Icons.diamond_outlined,
                '/society-chat');
          }
          prefs.setInt('smrc_seen_group', latest);
        }
      }
    } catch (_) {}

    // Support chat (concierge replies)
    try {
      final t = await repo.supportThread();
      final fromConcierge = t.messages.where((m) => !m.fromMember).toList();
      if (fromConcierge.isNotEmpty) {
        final latest = fromConcierge.map((m) => m.id).reduce((a, b) => a > b ? a : b);
        final seen = prefs.getInt('smrc_seen_support') ?? -1;
        if (seen >= 0 && latest > seen) {
          _show('Concierge', fromConcierge.firstWhere((x) => x.id == latest).message,
              Icons.headset_mic_outlined, '/support-chat');
        }
        prefs.setInt('smrc_seen_support', latest);
      }
    } catch (_) {}

    // Benefit Offer — a gifted membership granted by admin while the member
    // is already using the app. Previously this only ever got checked once
    // at HomeShell launch, so a member already inside the app never saw it
    // until they force-closed and reopened.
    try {
      final offer = await repo.benefitOffer();
      if (offer != null && !offer.accepted) {
        final seenId = prefs.getInt('smrc_seen_offer_id') ?? -1;
        if (offer.id != seenId) {
          prefs.setInt('smrc_seen_offer_id', offer.id);
          _show('A gift for you', 'Tap to view your complimentary membership offer.',
              Icons.card_giftcard_outlined, '/founders-benefit');
        }
      }
    } catch (_) {}
  }

  Future<void> _show(String title, String body, IconData icon, String route) async {
    if (!mounted) return;
    setState(() {
      _title = title;
      _body = body;
      _icon = icon;
      _route = route;
      _visible = true;
    });
    await _anim.forward(from: 0);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      await _anim.reverse();
      if (mounted) setState(() => _visible = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          widget.child,
          if (_visible)
            Positioned(
              top: 0,
              left: 14,
              right: 14,
              child: SafeArea(
                child: SlideTransition(
                  position: _slide,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _route.isEmpty
                          ? null
                          : () {
                              setState(() => _visible = false);
                              _anim.value = 0;
                              appRouter.push(_route);
                            },
                      child: Container(
                      margin: const EdgeInsets.only(top: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xF21D1D21),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.gold.withValues(alpha: .45)),
                        boxShadow: const [
                          BoxShadow(color: Color(0x66000000), blurRadius: 18, offset: Offset(0, 6)),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle, border: Border.all(color: AppColors.gold)),
                            child: Icon(_icon, size: 15, color: AppColors.gold),
                          ),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_title.toUpperCase(),
                                    style: AppTextStyles.inter(
                                        size: 8.5,
                                        weight: FontWeight.w600,
                                        color: AppColors.gold,
                                        letterSpacing: 2)),
                                const SizedBox(height: 2),
                                Text(_body,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.inter(size: 12, color: Colors.white)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
