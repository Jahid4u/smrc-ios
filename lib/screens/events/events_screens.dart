import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/api_models.dart';
import '../../providers/app_providers.dart';
import '../../core/api/smrc_repository.dart';
import '../../core/error_classifier.dart';
import '../../core/payment_helper.dart';
import '../../widgets/async_view.dart';
import '../../models/club_event.dart';
import '../../models/member.dart';
import '../../widgets/ui_kit.dart';
import '../../widgets/app_top_nav.dart';
import '../../widgets/platform_pay_checkout_button.dart';

// ═════════════ Events Listing (tab) ═════════════
class EventsListingScreen extends ConsumerStatefulWidget {
  const EventsListingScreen({super.key});
  @override
  ConsumerState<EventsListingScreen> createState() => _EventsListingScreenState();
}

class _EventsListingScreenState extends ConsumerState<EventsListingScreen> {
  EventType? _filter;

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(eventsProvider);
    // Deliberately NOT falling back to DemoData here: maybeWhen's orElse
    // fires during loading too, which is what made the reference/demo
    // content flash on screen before the member's real events replaced it.
    final upcoming = eventsAsync.valueOrNull ?? const <ClubEvent>[];
    final list = _filter == null ? upcoming : upcoming.where((e) => e.type == _filter).toList();

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
                  Text('Events', style: AppTextStyles.serif(size: 30, color: Colors.white)),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 9,
                    runSpacing: 9,
                    children: [
                      FilterChipPill('All', on: _filter == null, onTap: () => setState(() => _filter = null)),
                      FilterChipPill('Weekly',
                          on: _filter == EventType.weekly, onTap: () => setState(() => _filter = EventType.weekly)),
                      FilterChipPill('Big Events',
                          on: _filter == EventType.big, onTap: () => setState(() => _filter = EventType.big)),
                      FilterChipPill('Trips',
                          on: _filter == EventType.trip, onTap: () => setState(() => _filter = EventType.trip)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (eventsAsync.isLoading && upcoming.isEmpty)
              const SkeletonList(count: 3)
            else if (eventsAsync.hasError && upcoming.isEmpty)
              AsyncErrorState(
                  message: "Couldn't load events. ${describeError(eventsAsync.error!).display}",
                  onRetry: () => ref.invalidate(eventsProvider))
            else ...[
              ...list.map((e) => Padding(
                    padding: const EdgeInsets.fromLTRB(26, 0, 26, 18),
                    child: _EventCard(event: e),
                  )),
              if (list.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(40),
                  child: Center(
                      child: Text('No events in this category.',
                          style: AppTextStyles.inter(size: 12, color: AppColors.muted))),
                ),
            ],
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(26, 12, 26, 0),
              child: OutlinedButton.icon(
                onPressed: () => ref.read(homeShellTabRequestProvider.notifier).state = 0,
                icon: const Icon(Icons.diamond_outlined, size: 16),
                label: const Text('DISCOVER MORE ON HOME'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventCard extends ConsumerWidget {
  final ClubEvent event;
  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Member me = ref.watch(memberOrDemoProvider);
    final price = event.priceFor(me);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: InkWell(
          onTap: () => context.push('/event-detail', extra: event),
          borderRadius: BorderRadius.circular(19),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 130,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(fadeInDuration: Duration.zero, imageUrl: event.coverImageUrl ?? '',
                      fit: BoxFit.cover, errorWidget: (_, __, ___) => Container(color: AppColors.charcoal)),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x260A0A0B), Color(0xD90A0A0B)]),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0x990A0A0B),
                        border: Border.all(color: AppColors.gold.withValues(alpha: .5)),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(event.type.label.toUpperCase(),
                          style: AppTextStyles.inter(
                              size: 8.5, weight: FontWeight.w600, color: AppColors.goldSoft, letterSpacing: 1.6)),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              color: AppColors.charcoal,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(event.title, style: AppTextStyles.serif(size: 19, color: Colors.white)),
                        const SizedBox(height: 3),
                        Text(event.dateLabel,
                            style: AppTextStyles.inter(size: 10.5, weight: FontWeight.w300, color: AppColors.muted)),
                      ],
                    ),
                  ),
                  Text(price == 0 ? 'FREE' : '\$${price.toStringAsFixed(0)}',
                      style: AppTextStyles.inter(size: 13, weight: FontWeight.w600, color: AppColors.gold)),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}

// ═════════════ Event Detail (auto BUY vs RSVP by pricing rules) ═════════════
class EventDetailScreen extends ConsumerWidget {
  final ClubEvent? event;
  const EventDetailScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final event = this.event;
    if (event == null) return const _MissingEventScaffold(title: 'Event');
    final Member me = ref.watch(memberOrDemoProvider);
    final price = event.priceFor(me);
    final free = price == 0;
    final note = event.discountNoteFor(me);

    // Whether the current member already holds a (non-cancelled) ticket for
    // this event. When true, the CTA becomes "View My Pass" instead of a
    // buy/reserve action so a purchased event can never be bought again.
    final int eid = int.tryParse(event.id) ?? -1;
    final bool hasPass = ref.watch(eventTicketsProvider).maybeWhen(
          data: (tickets) => tickets.any(
            (t) => t.eventId == eid && t.status.toLowerCase() != 'cancelled',
          ),
          orElse: () => false,
        );

    return Scaffold(
      backgroundColor: AppColors.ink,
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.only(bottom: 150),
            children: [
              // Hero header
              SizedBox(
                height: 232,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(fadeInDuration: Duration.zero, imageUrl: event.coverImageUrl ?? '',
                        fit: BoxFit.cover, errorWidget: (_, __, ___) => Container(color: AppColors.charcoal)),
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0x400A0A0B), Color(0xF20A0A0B)]),
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: InkWell(
                            onTap: () => context.pop(),
                            customBorder: const CircleBorder(),
                            child: Container(
                              width: 34,
                              height: 34,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0x660A0A0B),
                                border: Border.all(color: AppColors.line),
                              ),
                              child: const Icon(Icons.arrow_back_ios_new, size: 15, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 26,
                      right: 26,
                      bottom: 18,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(event.type.label.toUpperCase(), style: AppTextStyles.eyebrow),
                          const SizedBox(height: 6),
                          Text(event.title, style: AppTextStyles.serif(size: 27, color: Colors.white)),
                          const SizedBox(height: 4),
                          Text(event.dateLabel,
                              style: AppTextStyles.inter(
                                  size: 11.5, weight: FontWeight.w300, color: const Color(0xFFBDB9B0))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(26, 18, 26, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(event.description,
                        style: AppTextStyles.inter(
                            size: 13, weight: FontWeight.w300, color: AppColors.muted, height: 1.65)),
                    const SizedBox(height: 18),
                    // Pricing / access card
                    AppCard(
                      padding: const EdgeInsets.all(16),
                      borderColor: AppColors.gold.withValues(alpha: .35),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(free ? 'Your access' : 'Member price',
                                  style: AppTextStyles.inter(size: 12.5, color: Colors.white)),
                              Text(
                                free
                                    ? (event.type == EventType.weekly
                                        ? 'Complimentary. Reserve your place'
                                        : 'Complimentary for ambassadors')
                                    : (note != null ? 'Member price. $note' : 'Per person'),
                                style:
                                    AppTextStyles.inter(size: 10.5, weight: FontWeight.w300, color: AppColors.muted),
                              ),
                            ],
                          ),
                          Text(free ? 'FREE' : '\$${price.toStringAsFixed(0)}',
                              style: AppTextStyles.inter(
                                  size: 20, weight: FontWeight.w600, color: AppColors.gold, letterSpacing: .3)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _detailRow(Icons.place_outlined, 'Location', event.location),
                    _detailRow(Icons.schedule, 'Date & Time', event.dateLabel),
                  ],
                ),
              ),
            ],
          ),
          // Sticky bottom CTA
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 30),
              decoration: const BoxDecoration(
                color: Color(0xE60A0A0B),
                border: Border(top: BorderSide(color: AppColors.line)),
              ),
              child: hasPass
                  ? GoldButton(
                      'View My Pass',
                      onTap: () => context.push('/ticket-wallet'),
                    )
                  : GoldButton(
                      free ? 'Reserve My Place' : 'Buy Ticket · \$${price.toStringAsFixed(0)}',
                      onTap: () => context.push('/ticket-purchase', extra: event),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: 16, color: AppColors.gold),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.toUpperCase(),
                    style: AppTextStyles.inter(
                        size: 9, weight: FontWeight.w600, color: AppColors.muted2, letterSpacing: 1.5)),
                const SizedBox(height: 2),
                Text(value,
                    style: AppTextStyles.inter(
                        size: 13, weight: FontWeight.w300, color: const Color(0xFFE9E7E1))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════ Ticket Purchase / Checkout ═════════════
class TicketPurchaseScreen extends ConsumerStatefulWidget {
  final ClubEvent? event;
  const TicketPurchaseScreen({super.key, this.event});

  @override
  ConsumerState<TicketPurchaseScreen> createState() => _TicketPurchaseScreenState();
}

class _TicketPurchaseScreenState extends ConsumerState<TicketPurchaseScreen> {
  bool _busy = false;

  Future<void> _purchase(ClubEvent ev) async {
    setState(() => _busy = true);
    final repo = ref.read(repoProvider);
    try {
      final me = ref.read(memberOrDemoProvider);
      final price = ev.priceFor(me);
      String? paymentIntentId;

      if (price > 0) {
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
          purpose: 'ticket',
          eventId: int.tryParse(ev.id) ?? 0,
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

      final ticketNo = await repo.purchaseTicket(int.tryParse(ev.id) ?? 0, paymentIntentId: paymentIntentId);
      ref.invalidate(eventTicketsProvider);
      if (mounted) {
        context.push('/confirmation', extra: {'event': ev, 'ticketNo': ticketNo});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(describeError(e).display)),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ev = widget.event;
    if (ev == null) return const _MissingEventScaffold(title: 'Checkout');
    final Member me = ref.watch(memberOrDemoProvider);
    final price = ev.priceFor(me);

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
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
                            child: CachedNetworkImage(fadeInDuration: Duration.zero, imageUrl: ev.coverImageUrl ?? '',
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => Container(color: AppColors.charcoal2)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(ev.title, style: AppTextStyles.inter(size: 13.5, color: Colors.white)),
                                Text(ev.dateLabel,
                                    style: AppTextStyles.inter(
                                        size: 10.5, weight: FontWeight.w300, color: AppColors.muted)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _CheckoutLine(label: 'Ticket', value: '\$${price.toStringAsFixed(2)}'),
                    const _CheckoutLine(label: 'Service', value: '\$0.00'),
                    Container(height: 1, color: AppColors.line, margin: const EdgeInsets.symmetric(vertical: 12)),
                    _CheckoutLine(label: 'Total', value: '\$${price.toStringAsFixed(2)}', bold: true),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (price > 0)
              PlatformPayCheckoutButton(
                busy: _busy,
                ensureReady: () => ensureStripeInitialized(ref.read(repoProvider)),
                onPressed: () => _purchase(ev),
              )
            else if (_busy)
              const Center(
                  child: SizedBox(
                      width: 26, height: 26,
                      child: CircularProgressIndicator(color: AppColors.gold, strokeWidth: 2)))
            else
              GoldButton('Confirm RSVP', onTap: () => _purchase(ev)),
          ],
        ),
      ),
    );
  }
}

// ═════════════ Confirmation ═════════════
class ConfirmationScreen extends StatelessWidget {
  final ClubEvent? event;
  final String ticketNo;
  const ConfirmationScreen({super.key, this.event, this.ticketNo = ''});

  @override
  Widget build(BuildContext context) {
    final ev = event;
    if (ev == null) return const _MissingEventScaffold(title: 'Confirmation');
    final displayNo = ticketNo.isNotEmpty ? ticketNo : 'SM-TKT-??????';
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
                    Text('CONFIRMED', style: AppTextStyles.eyebrow),
                    const SizedBox(height: 10),
                    const HeroTitle(line1: 'Your seat is', em: 'reserved.', size: 28),
                    const SizedBox(height: 14),
                    Text('${ev.title}. ${ev.dateLabel}. Your pass is ready in your wallet.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.inter(
                            size: 12.5, weight: FontWeight.w300, color: AppColors.muted, height: 1.6)),
                    const SizedBox(height: 22),
                    AppCard(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('PASS NO.',
                                  style: AppTextStyles.inter(
                                      size: 9.5, weight: FontWeight.w600, color: AppColors.muted2, letterSpacing: 3)),
                              const SizedBox(height: 3),
                              Text(displayNo,
                                  style: AppTextStyles.inter(size: 12, color: AppColors.gold)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('EVENT',
                                  style: AppTextStyles.inter(
                                      size: 9.5, weight: FontWeight.w600, color: AppColors.muted2, letterSpacing: 3)),
                              const SizedBox(height: 3),
                              Text(ev.type.label,
                                  style: AppTextStyles.inter(size: 12, color: const Color(0xFFE9E7E1))),
                            ],
                          ),
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
                  GoldButton('View My Pass', onTap: () => context.push('/ticket-wallet')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════ Ticket Wallet (QR passes) ═════════════
class TicketWalletScreen extends ConsumerStatefulWidget {
  const TicketWalletScreen({super.key});

  @override
  ConsumerState<TicketWalletScreen> createState() => _TicketWalletScreenState();
}

class _TicketWalletScreenState extends ConsumerState<TicketWalletScreen> {
  bool _showPast = false;

  @override
  Widget build(BuildContext context) {
    final ticketsAsync = ref.watch(eventTicketsProvider);
    return Scaffold(
      backgroundColor: AppColors.ink,
      appBar: const AppTopNav(title: ''),
      body: RefreshIndicator(
        color: AppColors.gold,
        backgroundColor: AppColors.charcoal,
        onRefresh: () async => ref.invalidate(eventTicketsProvider),
        child: ticketsAsync.when(
          loading: () => const Center(
              child: SizedBox(
                  width: 24, height: 24,
                  child: CircularProgressIndicator(color: AppColors.gold, strokeWidth: 2))),
          error: (_, __) => ListView(
            padding: const EdgeInsets.fromLTRB(26, 40, 26, 40),
            children: [
              Center(child: Text('Could not load your passes.',
                  style: AppTextStyles.inter(size: 12.5, color: AppColors.muted))),
              const SizedBox(height: 14),
              Center(child: SizedBox(width: 140,
                  child: GoldButton('Retry', style: GoldBtnStyle.line,
                      onTap: () => ref.invalidate(eventTicketsProvider)))),
            ],
          ),
          data: (all) {
            final upcoming = all.where((t) => !t.isPast).toList();
            final past = all.where((t) => t.isPast).toList();
            final list = _showPast ? past : upcoming;
            return ListView(
              padding: const EdgeInsets.fromLTRB(26, 6, 26, 40),
              children: [
                Text('YOUR PASSES', style: AppTextStyles.eyebrow),
                const SizedBox(height: 6),
                Text('Ticket Wallet', style: AppTextStyles.serif(size: 28, color: Colors.white)),
                const SizedBox(height: 16),
                Row(children: [
                  FilterChipPill('Upcoming. ${upcoming.length}',
                      on: !_showPast, onTap: () => setState(() => _showPast = false)),
                  const SizedBox(width: 8),
                  FilterChipPill('Past. ${past.length}',
                      on: _showPast, onTap: () => setState(() => _showPast = true)),
                ]),
                const SizedBox(height: 18),
                if (list.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: Text(
                        _showPast ? 'No past passes.' : 'No upcoming passes. The concierge will issue your pass after booking.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.inter(size: 12, weight: FontWeight.w300, color: AppColors.muted))),
                  ),
                ...list.map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _TicketCard(ticket: t),
                )),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final EventTicket ticket;
  const _TicketCard({required this.ticket});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1D1D21), Color(0xFF0F0F11)]),
          border: Border.all(color: AppColors.gold.withValues(alpha: .4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event image
            if (ticket.eventImage.isNotEmpty)
              SizedBox(
                height: 120,
                width: double.infinity,
                child: CachedNetworkImage(fadeInDuration: Duration.zero, imageUrl: 
                  ticket.eventImage,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(height: 120, color: AppColors.charcoal),
                ),
              ),
            // Event info
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ticket.eventType.toUpperCase(),
                      style: AppTextStyles.inter(size: 9, weight: FontWeight.w600,
                          color: AppColors.gold, letterSpacing: 2)),
                  const SizedBox(height: 4),
                  Text(ticket.title,
                      style: AppTextStyles.serif(size: 20, color: Colors.white)),
                  const SizedBox(height: 2),
                  Text(
                    [ticket.dateLabel, ticket.location]
                        .where((s) => s.isNotEmpty)
                        .join(' · '),
                    style: AppTextStyles.inter(
                        size: 11, weight: FontWeight.w300, color: AppColors.muted),
                  ),
                ],
              ),
            ),
            // Dashed divider
            CustomPaint(
              size: const Size(double.infinity, 1),
              painter: _DashPainter(),
            ),
            // QR strip
            Container(
              color: const Color(0x33000000),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                        color: Colors.white, borderRadius: BorderRadius.circular(10)),
                    child: QrImageView(
                      data: ticket.ticketNo,
                      version: QrVersions.auto,
                      backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square, color: Colors.black),
                      dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: Colors.black),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ACCESS PASS',
                            style: AppTextStyles.inter(
                                size: 9, weight: FontWeight.w600,
                                color: AppColors.muted2, letterSpacing: 2)),
                        const SizedBox(height: 4),
                        Text('Scan at the door',
                            style: AppTextStyles.inter(size: 13, color: Colors.white)),
                        const SizedBox(height: 6),
                        Text(ticket.ticketNo,
                            style: AppTextStyles.inter(
                                size: 11, weight: FontWeight.w600, color: AppColors.gold,
                                letterSpacing: 1)),
                        if (ticket.isPast)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                              decoration: BoxDecoration(
                                  color: AppColors.muted2.withValues(alpha: .15),
                                  borderRadius: BorderRadius.circular(8)),
                              child: Text('PAST EVENT',
                                  style: AppTextStyles.inter(
                                      size: 8.5, weight: FontWeight.w600,
                                      color: AppColors.muted2, letterSpacing: 1.5)),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


/// Simple price-row for the checkout screen.
class _CheckoutLine extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  const _CheckoutLine({required this.label, required this.value, this.bold = false});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: AppTextStyles.inter(
                    size: 13,
                    weight: bold ? FontWeight.w600 : FontWeight.w300,
                    color: bold ? Colors.white : AppColors.muted)),
            Text(value,
                style: AppTextStyles.inter(
                    size: 13,
                    weight: bold ? FontWeight.w600 : FontWeight.w400,
                    color: bold ? AppColors.gold : const Color(0xFFE9E7E1))),
          ],
        ),
      );
}

class _DashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.line
      ..strokeWidth = 1;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + 5, 0), paint);
      x += 9;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Shown when a screen that requires a ClubEvent is somehow reached without
/// one. Previously these screens fell back to DemoData.events[1] instead,
/// which silently presented a fabricated event ("The Rooftop Gala") that
/// could never actually be purchased — demo events carry non-numeric ids,
/// so checkout would send event_id=0 to the backend and always fail.
class _MissingEventScaffold extends StatelessWidget {
  final String title;
  const _MissingEventScaffold({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      appBar: AppTopNav(title: title),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.event_busy_outlined, size: 34, color: AppColors.muted2),
              const SizedBox(height: 14),
              Text('This event is no longer available.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.inter(size: 13, color: AppColors.muted)),
              const SizedBox(height: 6),
              Text('Please go back and choose an event again.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.inter(
                      size: 11.5, weight: FontWeight.w300, color: AppColors.muted2)),
            ],
          ),
        ),
      ),
    );
  }
}
