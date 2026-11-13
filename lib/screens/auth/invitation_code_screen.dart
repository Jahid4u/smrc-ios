import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/smrc_repository.dart';
import '../../core/error_classifier.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/app_providers.dart';
import '../../widgets/ui_kit.dart';

/// Invitation Code — collects the code (e.g. SMRC-VIP-2025). The code is
/// validated server-side during signup; email and code must match.
class InvitationCodeScreen extends ConsumerStatefulWidget {
  const InvitationCodeScreen({super.key});

  @override
  ConsumerState<InvitationCodeScreen> createState() => _InvitationCodeScreenState();
}

class _InvitationCodeScreenState extends ConsumerState<InvitationCodeScreen> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final email = _email.text.trim();
    final code = _code.text.trim().toUpperCase();
    if (email.isEmpty) {
      setState(() => _error = 'Enter the email your invitation was sent to.');
      return;
    }
    if (code.isEmpty) {
      setState(() => _error = 'Enter the code from your invitation.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(repoProvider).checkInviteCode(email: email, inviteCode: code);
      if (mounted) {
        context.push('/application-form', extra: {'code': code, 'email': email});
      }
    } on ApiException catch (e) {
      setState(() => _error = e.message);
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 20, 26, 28),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 12),
                      const GoldRingIcon(icon: Icons.mail_outline, size: 76),
                      const SizedBox(height: 22),
                      Text('BY INVITATION', style: AppTextStyles.eyebrow),
                      const SizedBox(height: 10),
                      const HeroTitle(line1: 'Enter your', em: 'invitation code.', size: 28),
                      const SizedBox(height: 14),
                      Builder(builder: (context) {
                        final copy = ref.watch(screenCopyProvider).maybeWhen(data: (c) => c, orElse: () => const {});
                        final body = (copy['invite_body']?.toString() ?? '').isNotEmpty
                            ? copy['invite_body']?.toString() ?? ''
                            : 'A current member has invited you to SM Royal Circle. Enter your email and the code they shared. Both must match to skip review.';
                        return Text(
                          body,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.inter(
                              size: 12.5, weight: FontWeight.w300, color: AppColors.muted, height: 1.65),
                        );
                      }),
                      const SizedBox(height: 24),
                      LabeledField(
                        label: 'Email',
                        controller: _email,
                        hint: 'you@example.com',
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('INVITATION CODE', style: AppTextStyles.eyebrow),
                      ),
                      const SizedBox(height: 10),
                      CodeBoxesField(
                        controller: _code,
                        length: 6,
                        onCompleted: (_) => _continue(),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(_error!,
                              style: AppTextStyles.inter(size: 11.5, color: const Color(0xFFE68688))),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _busy
                  ? const Center(
                      child: SizedBox(
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(color: AppColors.gold, strokeWidth: 2)))
                  : GoldButton('Continue', onTap: _continue),
              const SizedBox(height: 10),
              const PrivacyConsentText(action: 'continuing'),
              const SizedBox(height: 12),
              InkWell(
                onTap: () => context.push('/membership-path'),
                child: Text('No code? Apply for membership',
                    style: AppTextStyles.inter(size: 11, color: AppColors.muted)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Segmented 6-box invitation-code input. Codes are 6 characters
/// (A–Z, 2–9 on the server). A single hidden field captures typing, paste and
/// backspace; the boxes mirror its value. A filled or the next active box shows
/// the gold border; empty boxes stay muted.
class CodeBoxesField extends StatefulWidget {
  final TextEditingController controller;
  final int length;
  final ValueChanged<String>? onCompleted;
  const CodeBoxesField({
    super.key,
    required this.controller,
    this.length = 6,
    this.onCompleted,
  });

  @override
  State<CodeBoxesField> createState() => _CodeBoxesFieldState();
}

class _CodeBoxesFieldState extends State<CodeBoxesField> {
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChange);
    _focus.addListener(() => setState(() {}));
  }

  void _onChange() {
    setState(() {});
    if (widget.controller.text.length == widget.length) {
      _focus.unfocus();
      widget.onCompleted?.call(widget.controller.text);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChange);
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.controller.text;
    final focused = _focus.hasFocus;
    return Stack(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(widget.length, (i) {
            final filled = i < text.length;
            final isNext = focused && i == text.length;
            final active = filled || isNext;
            return Container(
              width: 46,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.charcoal,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: active ? AppColors.gold : AppColors.line,
                  width: active ? 1.5 : 1,
                ),
              ),
              child: Text(
                filled ? text[i] : (active ? '' : '·'),
                style: AppTextStyles.serif(
                  size: 24,
                  color: filled ? Colors.white : AppColors.muted,
                ),
              ),
            );
          }),
        ),
        // Transparent field on top capturing input/paste; taps focus it.
        Positioned.fill(
          child: Opacity(
            opacity: 0,
            child: TextField(
              controller: widget.controller,
              focusNode: _focus,
              autofocus: false,
              showCursor: false,
              enableSuggestions: false,
              autocorrect: false,
              keyboardType: TextInputType.visiblePassword,
              textCapitalization: TextCapitalization.characters,
              maxLength: widget.length,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                _UpperCaseFormatter(),
                LengthLimitingTextInputFormatter(widget.length),
              ],
              decoration: const InputDecoration(counterText: '', border: InputBorder.none),
            ),
          ),
        ),
      ],
    );
  }
}

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
