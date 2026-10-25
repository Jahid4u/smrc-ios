import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/error_classifier.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/app_providers.dart';
import '../../widgets/ui_kit.dart';

/// Reached only via the "set your password" deep link
/// (smroyalcircle://set-password?token=...) sent when a staff member adds
/// someone directly in the admin panel. Sets the password entirely inside
/// the app — no browser, no separate web page — using the same
/// token-validated endpoint the web fallback page also calls.
class SetPasswordScreen extends ConsumerStatefulWidget {
  final String token;
  const SetPasswordScreen({super.key, required this.token});

  @override
  ConsumerState<SetPasswordScreen> createState() => _SetPasswordScreenState();
}

class _SetPasswordScreenState extends ConsumerState<SetPasswordScreen> {
  final _p1 = TextEditingController();
  final _p2 = TextEditingController();
  bool _busy = false;
  bool _done = false;
  String? _error;

  @override
  void dispose() {
    _p1.dispose();
    _p2.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_p1.text.length < 8) {
      setState(() => _error = 'Password must be at least 8 characters.');
      return;
    }
    if (_p1.text != _p2.text) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(repoProvider).setPasswordByToken(widget.token, _p1.text);
      if (mounted) setState(() => _done = true);
    } catch (e) {
      if (mounted) setState(() => _error = describeError(e).display);
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
          padding: const EdgeInsets.fromLTRB(26, 40, 26, 26),
          child: _done
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_outline, size: 46, color: AppColors.gold),
                    const SizedBox(height: 18),
                    Text('Password set', style: AppTextStyles.inter(size: 18, color: Colors.white)),
                    const SizedBox(height: 8),
                    Text('You can now sign in with your email and new password.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.inter(size: 12.5, weight: FontWeight.w300, color: AppColors.muted)),
                    const SizedBox(height: 26),
                    GoldButton('Go to Sign In', onTap: () => context.go('/sign-in')),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Set Your Password', style: AppTextStyles.inter(size: 20, color: Colors.white)),
                    const SizedBox(height: 8),
                    Text('Choose a password for your SM Royal Circle account.',
                        style: AppTextStyles.inter(size: 12.5, weight: FontWeight.w300, color: AppColors.muted)),
                    const SizedBox(height: 28),
                    _field('New password', _p1),
                    const SizedBox(height: 12),
                    _field('Confirm password', _p2),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!, style: AppTextStyles.inter(size: 11.5, color: const Color(0xFFE27272))),
                    ],
                    const SizedBox(height: 24),
                    _busy
                        ? const Center(
                            child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: AppColors.gold, strokeWidth: 2)))
                        : GoldButton('Set Password', onTap: _submit),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController c) {
    return TextField(
      controller: c,
      obscureText: true,
      autofillHints: const [],
      style: AppTextStyles.inter(size: 13, color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTextStyles.inter(size: 12, weight: FontWeight.w300, color: AppColors.muted),
        filled: true,
        fillColor: AppColors.charcoal2,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder:
            OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.line)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.gold.withValues(alpha: .55), width: 1.2)),
      ),
    );
  }
}
