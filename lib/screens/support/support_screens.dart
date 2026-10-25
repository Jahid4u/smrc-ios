import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/api_models.dart';
import '../../providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/error_classifier.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/async_view.dart';
import '../../widgets/app_top_nav.dart';
import '../../widgets/ui_kit.dart';

// ═════════════ Concierge & Support hub ═════════════
class ConciergeSupportScreen extends StatelessWidget {
  const ConciergeSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      appBar: const AppTopNav(title: ''),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(26, 6, 26, 40),
        children: [
          Text('AT YOUR SERVICE', style: AppTextStyles.eyebrow),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: AppTextStyles.serif(size: 29, color: Colors.white),
              children: [
                const TextSpan(text: 'Concierge '),
                TextSpan(
                    text: '& Support',
                    style: AppTextStyles.serif(size: 29, color: AppColors.gold, style: FontStyle.italic)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text('A private line to the Circle. Discreet, attentive, always on.',
              style: AppTextStyles.inter(size: 12.5, weight: FontWeight.w300, color: AppColors.muted, height: 1.6)),
          const SizedBox(height: 22),
          _row(context, Icons.help_outline, 'Ask a Question', 'General enquiries. Replies in minutes',
              '/ask-a-question'),
          const SizedBox(height: 12),
          _row(context, Icons.event_note_outlined, 'Support', 'Billing, tiers, events, tickets and requests',
              '/support-1'),
          const SizedBox(height: 12),
          _row(context, Icons.shield_outlined, 'Account & Legal', 'Privacy, contact details and account deletion',
              '/account-legal'),
          const SizedBox(height: 24),
          Container(height: 1, color: AppColors.gold.withValues(alpha: .35)),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                  width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle)),
              const SizedBox(width: 12),
              Text('Concierge is online now',
                  style: AppTextStyles.inter(size: 12, weight: FontWeight.w300, color: const Color(0xFFCFCDC6))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, IconData icon, String title, String sub, String route) {
    return InkWell(
      onTap: () => context.push(route),
      borderRadius: BorderRadius.circular(20),
      child: AppCard(
        padding: const EdgeInsets.all(17),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.gold)),
              child: Icon(icon, size: 19, color: AppColors.gold),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.inter(size: 14, color: Colors.white)),
                  Text(sub, style: AppTextStyles.inter(size: 11, weight: FontWeight.w300, color: AppColors.muted)),
                ],
              ),
            ),
            Text('›', style: AppTextStyles.inter(size: 18, color: AppColors.gold)),
          ],
        ),
      ),
    );
  }
}

// ═════════════ Account & Legal ═════════════
class AccountLegalScreen extends ConsumerStatefulWidget {
  const AccountLegalScreen({super.key});

  @override
  ConsumerState<AccountLegalScreen> createState() => _AccountLegalScreenState();
}

class _AccountLegalScreenState extends ConsumerState<AccountLegalScreen> {
  bool _deleting = false;

  Future<void> _confirmDeleteAccount() async {
    // Step 1 — plain-language warning of what's lost. Irreversible actions
    // get an explicit, spelled-out confirmation rather than a single tap.
    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.charcoal,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Delete your account?', style: AppTextStyles.serif(size: 21, color: Colors.white)),
        content: Text(
            'This permanently deletes your SM Society membership, profile, tickets, and messages. '
            'This cannot be undone.',
            style: AppTextStyles.inter(
                size: 12.5, weight: FontWeight.w300, color: AppColors.muted, height: 1.6)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('CANCEL',
                style: AppTextStyles.inter(size: 11, color: AppColors.gold, letterSpacing: 1.5)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('CONTINUE',
                style: AppTextStyles.inter(size: 11, color: const Color(0xFFE68688), letterSpacing: 1.5)),
          ),
        ],
      ),
    );
    if (proceed != true || !mounted) return;

    // Step 2 — final, unambiguous confirmation before the irreversible call.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.charcoal,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Are you absolutely sure?', style: AppTextStyles.serif(size: 20, color: Colors.white)),
        content: Text('Your account will be deleted immediately.',
            style: AppTextStyles.inter(
                size: 12.5, weight: FontWeight.w300, color: AppColors.muted, height: 1.6)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('KEEP MY ACCOUNT',
                style: AppTextStyles.inter(size: 11, color: AppColors.gold, letterSpacing: 1.5)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('DELETE PERMANENTLY',
                style: AppTextStyles.inter(size: 11, color: const Color(0xFFE68688), letterSpacing: 1.5)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      final repo = ref.read(repoProvider);
      final msg = await repo.deleteAccount();
      await repo.logout();
      ref.read(currentMemberProvider.notifier).state = null;
      if (mounted) {
        context.go('/welcome');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(describeError(e).display)));
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      appBar: const AppTopNav(title: 'Account & Legal'),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(26, 16, 26, 40),
            children: [
              Text('LEGAL & CONTACT', style: AppTextStyles.label),
              const SizedBox(height: 12),
              const ImportantLinksCard(),
              const SizedBox(height: 30),
              Text('ACCOUNT', style: AppTextStyles.label),
              const SizedBox(height: 12),
              InkWell(
                onTap: _deleting ? null : _confirmDeleteAccount,
                borderRadius: BorderRadius.circular(20),
                child: AppCard(
                  padding: const EdgeInsets.all(17),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle, border: Border.all(color: const Color(0xFFE68688))),
                        child: const Icon(Icons.delete_outline, size: 19, color: Color(0xFFE68688)),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Delete Account',
                                style: AppTextStyles.inter(size: 14, color: const Color(0xFFE68688))),
                            Text('Permanently remove your membership and data',
                                style: AppTextStyles.inter(
                                    size: 11, weight: FontWeight.w300, color: AppColors.muted)),
                          ],
                        ),
                      ),
                      Text('›', style: AppTextStyles.inter(size: 18, color: const Color(0xFFE68688))),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_deleting)
            Container(
              color: Colors.black54,
              child: const Center(
                  child: CircularProgressIndicator(color: AppColors.gold, strokeWidth: 2)),
            ),
        ],
      ),
    );
  }
}

// ═════════════ Ask a Question ═════════════
class AskAQuestionScreen extends ConsumerStatefulWidget {
  const AskAQuestionScreen({super.key});

  @override
  ConsumerState<AskAQuestionScreen> createState() => _AskAQuestionScreenState();
}

class _AskAQuestionScreenState extends ConsumerState<AskAQuestionScreen> {
  final _q = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _q.text.trim();
    if (text.isEmpty || _busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(repoProvider).askQuestion(text);
      _q.clear();
      ref.invalidate(questionsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sent to the concierge. You will be notified when answered.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not send. ${describeError(e).display}')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final questions = ref.watch(questionsProvider).maybeWhen(
          data: (q) => q,
          orElse: () => const <QuestionItem>[],
        );
    return Scaffold(
      backgroundColor: AppColors.ink,
      appBar: const AppTopNav(title: 'Ask a Question'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(26, 16, 26, 40),
        children: [
          LabeledField(
            label: 'New Question',
            controller: _q,
            maxLines: 4,
            hint: 'What would you like to know?',
          ),
          const SizedBox(height: 12),
          _busy
              ? const Center(
                  child: SizedBox(
                      width: 24, height: 24,
                      child: CircularProgressIndicator(color: AppColors.gold, strokeWidth: 2)))
              : GoldButton('Send to Concierge', onTap: _send),
          const SizedBox(height: 30),
          Text('YOUR QUESTIONS', style: AppTextStyles.label),
          const SizedBox(height: 10),
          if (questions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text('No questions yet. Ask anything above.',
                  style: AppTextStyles.inter(size: 11.5, weight: FontWeight.w300, color: AppColors.muted)),
            ),
          ...questions.map((q) => InkWell(
                onTap: () => context.push('/question-detail', extra: q),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(q.answered ? 'ANSWERED' : 'PENDING',
                              style: AppTextStyles.inter(
                                  size: 9,
                                  weight: FontWeight.w600,
                                  color: q.answered ? AppColors.success : AppColors.gold,
                                  letterSpacing: 2)),
                          Text(q.createdAt.split(' ').first,
                              style: AppTextStyles.inter(size: 10, color: AppColors.muted2)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Text(q.question,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.inter(size: 13, color: Colors.white)),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                              q.answered ? Icons.chevron_right : Icons.hourglass_empty,
                              size: 16,
                              color: q.answered ? AppColors.gold : AppColors.muted2),
                        ],
                      ),
                      if (q.answered) ...[
                        const SizedBox(height: 4),
                        Text('Tap to read reply',
                            style: AppTextStyles.inter(
                                size: 10.5, weight: FontWeight.w300, color: AppColors.muted)),
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

// ═════════════ Support — Ticket list ═════════════
class SupportListScreen extends ConsumerStatefulWidget {
  const SupportListScreen({super.key});

  @override
  ConsumerState<SupportListScreen> createState() => _SupportListScreenState();
}

class _SupportListScreenState extends ConsumerState<SupportListScreen> {
  bool _showOpen = true;

  Color _statusColor(String s) => s == 'open' ? AppColors.gold : AppColors.muted2;

  @override
  Widget build(BuildContext context) {
    final ticketsAsync = ref.watch(ticketsProvider);
    return Scaffold(
      backgroundColor: AppColors.ink,
      appBar: const AppTopNav(title: ''),
      body: RefreshIndicator(
        color: AppColors.gold,
        backgroundColor: AppColors.charcoal,
        onRefresh: () async => ref.invalidate(ticketsProvider),
        child: ticketsAsync.when(
          loading: () => const Center(
              child: SizedBox(
                  width: 24, height: 24,
                  child: CircularProgressIndicator(color: AppColors.gold, strokeWidth: 2))),
          error: (_, __) => ListView(
            padding: const EdgeInsets.fromLTRB(26, 60, 26, 40),
            children: [
              Center(
                  child: Text('Could not load your requests.',
                      style: AppTextStyles.inter(size: 12.5, color: AppColors.muted))),
              const SizedBox(height: 16),
              Center(
                child: SizedBox(
                    width: 140,
                    child: GoldButton('Retry',
                        style: GoldBtnStyle.line, onTap: () => ref.invalidate(ticketsProvider))),
              ),
            ],
          ),
          data: (all) {
            final open = all.where((t) => t.open).toList();
            final closed = all.where((t) => !t.open).toList();
            final list = _showOpen ? open : closed;
            return ListView(
              padding: const EdgeInsets.fromLTRB(26, 6, 26, 40),
              children: [
                Text('AT YOUR SERVICE', style: AppTextStyles.eyebrow),
                const SizedBox(height: 6),
                Text('Support', style: AppTextStyles.serif(size: 28, color: Colors.white)),
                const SizedBox(height: 18),
                Row(
                  children: [
                    FilterChipPill('Open. ${open.length}',
                        on: _showOpen, onTap: () => setState(() => _showOpen = true)),
                    const SizedBox(width: 8),
                    FilterChipPill('Closed. ${closed.length}',
                        on: !_showOpen, onTap: () => setState(() => _showOpen = false)),
                  ],
                ),
                const SizedBox(height: 16),
                if (list.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                        _showOpen
                            ? 'No open requests. The concierge is all caught up with you.'
                            : 'No closed requests yet.',
                        style: AppTextStyles.inter(
                            size: 11.5, weight: FontWeight.w300, color: AppColors.muted)),
                  ),
                ...list.map((t) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () => context.push('/support-3', extra: t),
                        borderRadius: BorderRadius.circular(20),
                        child: AppCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('${t.category.toUpperCase()} · ${t.refNo}',
                                      style: AppTextStyles.inter(
                                          size: 9,
                                          weight: FontWeight.w600,
                                          color: AppColors.muted2,
                                          letterSpacing: 2)),
                                  Text(t.status.toUpperCase(),
                                      style: AppTextStyles.inter(
                                          size: 9,
                                          weight: FontWeight.w600,
                                          color: _statusColor(t.status),
                                          letterSpacing: 2)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(t.subject, style: AppTextStyles.inter(size: 13.5, color: Colors.white)),
                              const SizedBox(height: 4),
                              Text(
                                  t.replies.isEmpty
                                      ? 'Awaiting concierge'
                                      : (t.replies.last.fromMember
                                          ? 'You replied'
                                          : 'Concierge replied'),
                                  style: AppTextStyles.inter(
                                      size: 10.5, weight: FontWeight.w300, color: AppColors.muted)),
                            ],
                          ),
                        ),
                      ),
                    )),
                const SizedBox(height: 6),
                GoldButton('New Request',
                    style: GoldBtnStyle.line, onTap: () => context.push('/support-2')),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ═════════════ Support — Create ticket ═════════════
class SupportCreateScreen extends ConsumerStatefulWidget {
  const SupportCreateScreen({super.key});
  @override
  ConsumerState<SupportCreateScreen> createState() => _SupportCreateScreenState();
}

class _SupportCreateScreenState extends ConsumerState<SupportCreateScreen> {
  int _cat = 0;
  static const _cats = ['Membership', 'Events', 'Payments', 'General', 'Other'];
  final _subject = TextEditingController();
  final _message = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_subject.text.trim().isEmpty || _message.text.trim().isEmpty) {
      setState(() => _error = 'Subject and message are required.');
      return;
    }
    setState(() { _busy = true; _error = null; });
    try {
      final ref_ = await ref.read(repoProvider).createTicket(
          category: _cats[_cat], subject: _subject.text.trim(), body: _message.text.trim());
      ref.invalidate(ticketsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Request $ref_ submitted to the concierge.')));
        context.pop();
      }
    } catch (e) {
      setState(() => _error = describeError(e).display);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      appBar: const AppTopNav(title: 'New Request'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(26, 16, 26, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('CATEGORY', style: AppTextStyles.eyebrow),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(
                  _cats.length,
                  (i) => FilterChipPill(_cats[i], on: _cat == i, onTap: () => setState(() => _cat = i))),
            ),
            const SizedBox(height: 18),
            LabeledField(
              label: 'Subject',
              controller: _subject,
              hint: 'Question about Gold tier upgrade',
            ),
            const SizedBox(height: 13),
            LabeledField(
              label: 'Message',
              controller: _message,
              maxLines: 3,
              hint: 'Tell the concierge how we can help.',
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: AppTextStyles.inter(size: 11.5, color: const Color(0xFFE68688))),
            ],
            const SizedBox(height: 18),
            _busy
                ? const Center(
                    child: SizedBox(
                        width: 24, height: 24,
                        child: CircularProgressIndicator(color: AppColors.gold, strokeWidth: 2)))
                : GoldButton('Submit Request', onTap: _submit),
          ],
        ),
      ),
    );
  }
}

// ═════════════ Support — Ticket thread ═════════════
class SupportThreadScreen extends ConsumerStatefulWidget {
  final TicketItem? ticket;
  const SupportThreadScreen({super.key, this.ticket});

  @override
  ConsumerState<SupportThreadScreen> createState() => _SupportThreadScreenState();
}

class _SupportThreadScreenState extends ConsumerState<SupportThreadScreen> {
  final _input = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _send(TicketItem t) async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await ref.read(repoProvider).replyTicket(t.id, text);
      _input.clear();
      ref.invalidate(ticketsProvider);
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
    // Watch the provider so concierge replies appear after invalidate.
    final live = ref.watch(ticketsProvider).maybeWhen(
          data: (all) => widget.ticket == null
              ? null
              : all.cast<TicketItem?>().firstWhere((t) => t!.id == widget.ticket!.id, orElse: () => null),
          orElse: () => null,
        );
    final t = live ?? widget.ticket;
    if (t == null) {
      return Scaffold(
        backgroundColor: AppColors.ink,
        appBar: const AppTopNav(title: 'Support'),
        body: Center(
            child: Text('Request not found.',
                style: AppTextStyles.inter(size: 12, color: AppColors.muted))),
      );
    }
    // A member sends one message, then waits for the concierge before
    // sending the next (backend edit #10).
    final awaitingConcierge = t.replies.isEmpty || t.replies.last.fromMember;
    return Scaffold(
      backgroundColor: AppColors.ink,
      appBar: AppTopNav(title: t.subject),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 16),
              children: [
                Center(
                    child: Text('${t.category.toUpperCase()} · ${t.refNo}',
                        style: AppTextStyles.inter(
                            size: 9, weight: FontWeight.w600, color: AppColors.muted2, letterSpacing: 2))),
                const SizedBox(height: 14),
                ChatBubble(fromMember: true, text: t.body),
                for (final r in t.replies) ...[
                  const SizedBox(height: 14),
                  ChatBubble(fromMember: r.fromMember, text: r.message),
                ],
              ],
            ),
          ),
          if (t.open && awaitingConcierge)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
              decoration: const BoxDecoration(
                color: Color(0xEB0A0A0B),
                border: Border(top: BorderSide(color: AppColors.line)),
              ),
              child: Text('Sent to the concierge. You can reply once they respond.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.inter(size: 11, weight: FontWeight.w300, color: AppColors.muted2)),
            )
          else if (t.open)
            Padding(
              padding: EdgeInsets.zero,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                decoration: const BoxDecoration(
                  color: Color(0xEB0A0A0B),
                  border: Border(top: BorderSide(color: AppColors.line)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                        decoration: BoxDecoration(
                          color: AppColors.charcoal2,
                          border: Border.all(color: AppColors.line),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: TextField(
                          autofillHints: const [],
                          controller: _input,
                          onSubmitted: (_) => _send(t),
                          style: AppTextStyles.inter(size: 12, color: Colors.white),
                          decoration: InputDecoration(
                            isCollapsed: true,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            hintText: 'Reply to concierge.',
                            hintStyle: AppTextStyles.inter(
                                size: 12, weight: FontWeight.w300, color: const Color(0xFF55555C)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    InkWell(
                      onTap: () => _send(t),
                      customBorder: const CircleBorder(),
                      child: _sending
                          ? const SizedBox(
                              width: 22, height: 22,
                              child: CircularProgressIndicator(color: AppColors.gold, strokeWidth: 2))
                          : const Icon(Icons.send_outlined, size: 22, color: AppColors.gold),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
              decoration: const BoxDecoration(
                color: Color(0xEB0A0A0B),
                border: Border(top: BorderSide(color: AppColors.line)),
              ),
              child: Text('This request is closed. Open a new one if you need anything else.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.inter(size: 11, weight: FontWeight.w300, color: AppColors.muted2)),
            ),
        ],
      ),
    );
  }
}

/// Chat bubble matching the HTML thread styles.
class ChatBubble extends StatelessWidget {
  final bool fromMember;
  final String text;
  final String? time;
  final String? senderName;
  final String? avatarUrl;
  final String? imageUrl;
  const ChatBubble(
      {super.key,
      required this.fromMember,
      required this.text,
      this.time,
      this.senderName,
      this.avatarUrl,
      this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final hasImage = (imageUrl ?? '').isNotEmpty;
    final hasText = text.isNotEmpty;
    final bubble = Container(
      constraints: const BoxConstraints(maxWidth: 240),
      padding: hasImage
          ? const EdgeInsets.all(4)
          : const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: fromMember ? AppColors.gold : AppColors.charcoal2,
        border: fromMember ? null : Border.all(color: AppColors.line),
        borderRadius: fromMember
            ? const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(4))
            : const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasImage)
            GestureDetector(
              onTap: () => showDialog(
                  context: context,
                  builder: (_) => Dialog(
                        backgroundColor: Colors.transparent,
                        insetPadding: const EdgeInsets.all(16),
                        child: InteractiveViewer(
                            child: CachedNetworkImage(imageUrl: imageUrl!, fit: BoxFit.contain)),
                      )),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                    imageUrl: imageUrl!,
                    fadeInDuration: Duration.zero,
                    width: 200,
                    height: 200,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(width: 200, height: 200, color: AppColors.charcoal),
                    errorWidget: (_, __, ___) =>
                        Container(width: 200, height: 200, color: AppColors.charcoal)),
              ),
            ),
          if (hasImage && hasText) const SizedBox(height: 8),
          if (hasText)
            Padding(
              padding: hasImage ? const EdgeInsets.symmetric(horizontal: 8, vertical: 2) : EdgeInsets.zero,
              child: Text(text,
                  style: AppTextStyles.inter(
                      size: 12.5,
                      weight: fromMember ? FontWeight.w400 : FontWeight.w300,
                      color: fromMember ? AppColors.ink : const Color(0xFFE9E7E1),
                      height: 1.5)),
            ),
        ],
      ),
    );

    if (fromMember) {
      return Align(alignment: Alignment.centerRight, child: bubble);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          width: 28,
          height: 28,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.line)),
          child: avatarUrl != null
              ? ClipOval(
                  child: CachedNetworkImage(fadeInDuration: Duration.zero, imageUrl: avatarUrl!,
                      fit: BoxFit.cover, errorWidget: (_, __, ___) => const SizedBox()))
              : const Icon(Icons.headset_mic_outlined, size: 13, color: AppColors.gold),
        ),
        const SizedBox(width: 9),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (senderName != null)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 3),
                child: Text(senderName!, style: AppTextStyles.inter(size: 9, color: AppColors.muted2)),
              ),
            bubble,
          ],
        ),
      ],
    );
  }
}

/// Bottom chat input bar (blurred dark bar with rounded input + send icon).
class ChatInputBar extends StatelessWidget {
  final String hint;
  final bool showPlus;
  const ChatInputBar({super.key, required this.hint, this.showPlus = false});

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
          if (showPlus) ...[
            const Icon(Icons.add_circle_outline, size: 22, color: AppColors.gold),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.charcoal2,
                border: Border.all(color: AppColors.line),
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                autofillHints: const [],
                style: AppTextStyles.inter(size: 12, color: Colors.white),
                decoration: InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  hintText: hint,
                  hintStyle: AppTextStyles.inter(size: 12, weight: FontWeight.w300, color: const Color(0xFF55555C)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Icon(Icons.send_outlined, size: 22, color: AppColors.gold),
        ],
      ),
    );
  }
}

// ═════════════ My Tickets & Wallet hub ═════════════
class TicketsWalletHubScreen extends StatelessWidget {
  const TicketsWalletHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      appBar: const AppTopNav(title: 'My Tickets & Wallet'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(26, 16, 26, 30),
        children: [
          InkWell(
            onTap: () => context.push('/ticket-wallet'),
            borderRadius: BorderRadius.circular(20),
            child: AppCard(
              padding: const EdgeInsets.all(17),
              borderColor: AppColors.gold.withValues(alpha: .35),
              child: _hubRow(Icons.credit_card_outlined, 'Active Passes', '2 upcoming, with QR access'),
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () => context.push('/past-tickets'),
            borderRadius: BorderRadius.circular(20),
            child: AppCard(
              padding: const EdgeInsets.all(17),
              child: _hubRow(Icons.schedule, 'Past Tickets', 'Your full event history'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hubRow(IconData icon, String title, String sub) => Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.gold)),
            child: Icon(icon, size: 19, color: AppColors.gold),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.inter(size: 14, color: Colors.white)),
                Text(sub, style: AppTextStyles.inter(size: 11, weight: FontWeight.w300, color: AppColors.muted)),
              ],
            ),
          ),
          Text('›', style: AppTextStyles.inter(size: 18, color: AppColors.gold)),
        ],
      );
}

// ═════════════ Past Tickets ═════════════
class PastTicketsScreen extends ConsumerWidget {
  const PastTicketsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketsAsync = ref.watch(eventTicketsProvider);
    final past = (ticketsAsync.valueOrNull ?? const <EventTicket>[])
        .where((t) => t.isPast)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.ink,
      appBar: const AppTopNav(title: ''),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(26, 6, 26, 40),
        children: [
          Text('YOUR FULL HISTORY', style: AppTextStyles.eyebrow),
          const SizedBox(height: 6),
          Text('Past Tickets', style: AppTextStyles.serif(size: 28, color: Colors.white)),
          const SizedBox(height: 18),
          if (ticketsAsync.isLoading && past.isEmpty)
            const SkeletonList(count: 3, padding: EdgeInsets.zero)
          else if (ticketsAsync.hasError && past.isEmpty)
            AsyncErrorState(
                message: "Couldn't load your tickets. ${describeError(ticketsAsync.error!).display}",
                onRetry: () => ref.invalidate(eventTicketsProvider))
          else if (past.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Center(
                child: Text('No past tickets yet.',
                    style: AppTextStyles.inter(size: 12.5, color: AppColors.muted)),
              ),
            )
          else
            ...past.map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
                          child: t.eventImage.isEmpty
                              ? Container(color: AppColors.charcoal2)
                              : CachedNetworkImage(
                                  fadeInDuration: Duration.zero,
                                  imageUrl: t.eventImage,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => Container(color: AppColors.charcoal2)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t.title,
                                  style: AppTextStyles.inter(size: 12.5, color: Colors.white)),
                              Text(t.dateLabel,
                                  style: AppTextStyles.inter(
                                      size: 10, weight: FontWeight.w300, color: AppColors.muted)),
                            ],
                          ),
                        ),
                        Text(t.ticketNo,
                            style: AppTextStyles.inter(size: 10, color: AppColors.muted2)),
                      ],
                    ),
                  ),
                )),
        ],
      ),
    );
  }
}

// ═════════════ Question Detail (answer view) ═════════════
class QuestionDetailScreen extends StatelessWidget {
  final QuestionItem question;
  const QuestionDetailScreen({super.key, required this.question});

  @override
  Widget build(BuildContext context) {
    final q = question;
    return Scaffold(
      backgroundColor: AppColors.ink,
      appBar: const AppTopNav(title: 'Your Question'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(26, 18, 26, 40),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: (q.answered ? AppColors.success : AppColors.gold).withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(q.answered ? 'ANSWERED' : 'PENDING',
                    style: AppTextStyles.inter(
                        size: 9,
                        weight: FontWeight.w600,
                        color: q.answered ? AppColors.success : AppColors.gold,
                        letterSpacing: 2)),
              ),
              Text(q.createdAt.split(' ').first,
                  style: AppTextStyles.inter(size: 11, color: AppColors.muted2)),
            ],
          ),
          const SizedBox(height: 20),
          Text('YOUR QUESTION', style: AppTextStyles.label),
          const SizedBox(height: 8),
          Text(q.question,
              style: AppTextStyles.serif(size: 20, color: Colors.white)),
          const SizedBox(height: 26),
          Text('CONCIERGE REPLY', style: AppTextStyles.label),
          const SizedBox(height: 10),
          if (q.answered && q.answer.isNotEmpty)
            AppCard(
              padding: const EdgeInsets.all(16),
              borderColor: AppColors.gold.withValues(alpha: .3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.verified_outlined, size: 15, color: AppColors.gold),
                      const SizedBox(width: 7),
                      Text('SM Royal Circle Concierge',
                          style: AppTextStyles.inter(
                              size: 11, weight: FontWeight.w500, color: AppColors.gold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(q.answer,
                      style: AppTextStyles.inter(
                          size: 13.5, weight: FontWeight.w300, color: const Color(0xFFE9E7E1), height: 1.6)),
                  if (q.answeredAt.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text('Replied ${q.answeredAt.split(' ').first}',
                        style: AppTextStyles.inter(size: 10, color: AppColors.muted2)),
                  ],
                ],
              ),
            )
          else
            AppCard(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  const Icon(Icons.schedule, size: 18, color: AppColors.muted),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Our concierge is preparing your reply. You\u2019ll be notified as soon as it\u2019s ready.',
                        style: AppTextStyles.inter(
                            size: 12.5, weight: FontWeight.w300, color: AppColors.muted, height: 1.5)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
