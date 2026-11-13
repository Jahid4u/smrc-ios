import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/smrc_repository.dart';
import '../../core/error_classifier.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/app_providers.dart';
import '../../widgets/ui_kit.dart';

/// Step 1 — POST /forgot-password { email }
class ForgotPasswordEmailScreen extends ConsumerStatefulWidget {
  const ForgotPasswordEmailScreen({super.key});

  @override
  ConsumerState<ForgotPasswordEmailScreen> createState() => _ForgotPasswordEmailScreenState();
}

class _ForgotPasswordEmailScreenState extends ConsumerState<ForgotPasswordEmailScreen> {
  final _email = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final email = _email.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Enter the email on your membership.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(repoProvider).forgotPassword(email);
      if (mounted) context.push('/forgot-password-2', extra: email);
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 22),
                      Text('RESET PASSWORD', style: AppTextStyles.eyebrow),
                      const SizedBox(height: 10),
                      const HeroTitle(line1: 'Forgot your', em: 'password?', size: 28, align: TextAlign.left),
                      const SizedBox(height: 9),
                      Text('Enter your email and we will send a one-time code to verify it is you.',
                          style: AppTextStyles.inter(size: 12, weight: FontWeight.w300, color: AppColors.muted)),
                      const SizedBox(height: 22),
                      LabeledField(
                        label: 'Email',
                        controller: _email,
                        hint: 'you@example.com',
                        keyboardType: TextInputType.emailAddress,
                        onSubmitted: (_) => _send(),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(_error!, style: AppTextStyles.inter(size: 11.5, color: const Color(0xFFE68688))),
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
                  : GoldButton('Send Code', onTap: _send),
            ],
          ),
        ),
      ),
    );
  }
}

/// Step 2 — POST /verify-reset-otp { email, otp }
class ForgotPasswordOtpScreen extends ConsumerStatefulWidget {
  final String email;
  const ForgotPasswordOtpScreen({super.key, required this.email});

  @override
  ConsumerState<ForgotPasswordOtpScreen> createState() => _ForgotPasswordOtpScreenState();
}

class _ForgotPasswordOtpScreenState extends ConsumerState<ForgotPasswordOtpScreen> {
  static const _len = 6;
  final _controllers = List.generate(_len, (_) => TextEditingController());
  final _nodes = List.generate(_len, (_) => FocusNode());
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  String get _otp => _controllers.map((c) => c.text).join();

  Future<void> _verify() async {
    if (_otp.length < _len) {
      setState(() => _error = 'Enter the full 6-digit code.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(repoProvider).verifyResetOtp(widget.email, _otp);
      if (mounted) {
        context.push('/forgot-password-3', extra: {'email': widget.email, 'otp': _otp});
      }
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = describeError(e).display);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend() async {
    try {
      await ref.read(repoProvider).forgotPassword(widget.email);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('A new code has been sent.')));
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(describeError(e).display)));
      }
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 12),
                      const GoldRingIcon(icon: Icons.lock_outline, size: 74),
                      const SizedBox(height: 22),
                      Text('CHECK YOUR EMAIL', style: AppTextStyles.eyebrow),
                      const SizedBox(height: 10),
                      const HeroTitle(line1: 'Enter the', em: 'code we sent.', size: 27),
                      const SizedBox(height: 14),
                      Text('If an account exists for ${widget.email}, a 6-digit code has been sent. It expires in 15 minutes.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.inter(
                              size: 12.5, weight: FontWeight.w300, color: AppColors.muted, height: 1.6)),
                      const SizedBox(height: 22),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_len, (i) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3.5),
                            child: SizedBox(
                              width: 38,
                              height: 50,
                              child: TextField(
                                controller: _controllers[i],
                                focusNode: _nodes[i],
                                maxLength: 1,
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                style: AppTextStyles.serif(size: 18, color: Colors.white),
                                decoration: InputDecoration(
                                  counterText: '',
                                  contentPadding: EdgeInsets.zero,
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: AppColors.line),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: AppColors.gold),
                                  ),
                                ),
                                onChanged: (v) {
                                  if (v.isNotEmpty && i < _len - 1) _nodes[i + 1].requestFocus();
                                  if (v.isEmpty && i > 0) _nodes[i - 1].requestFocus();
                                  if (i == _len - 1 && v.isNotEmpty) _verify();
                                },
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: _resend,
                        child: RichText(
                          text: TextSpan(
                            style: AppTextStyles.inter(size: 11, color: AppColors.muted2),
                            children: [
                              const TextSpan(text: 'Did not get a code? '),
                              TextSpan(text: 'Resend', style: AppTextStyles.inter(size: 11, color: AppColors.gold)),
                            ],
                          ),
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(_error!, style: AppTextStyles.inter(size: 11.5, color: const Color(0xFFE68688))),
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
                  : GoldButton('Verify Code', onTap: _verify),
            ],
          ),
        ),
      ),
    );
  }
}

/// Step 3 — POST /reset-password { email, otp, new_password }
class ForgotPasswordResetScreen extends ConsumerStatefulWidget {
  final String email;
  final String otp;
  const ForgotPasswordResetScreen({super.key, required this.email, required this.otp});

  @override
  ConsumerState<ForgotPasswordResetScreen> createState() => _ForgotPasswordResetScreenState();
}

class _ForgotPasswordResetScreenState extends ConsumerState<ForgotPasswordResetScreen> {
  final _pass = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _pass.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _update() async {
    if (_pass.text.length < 8) {
      setState(() => _error = 'Password must be at least 8 characters.');
      return;
    }
    if (_pass.text != _confirm.text) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(repoProvider).resetPassword(widget.email, widget.otp, _pass.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password updated. Sign in with your new password.')));
        context.go('/sign-in');
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
                      const GoldRingIcon(icon: Icons.lock_open_outlined, size: 64, doubleRing: false),
                      const SizedBox(height: 18),
                      Text('CODE VERIFIED', style: AppTextStyles.eyebrow),
                      const SizedBox(height: 10),
                      const HeroTitle(line1: 'Set a new', em: 'password.', size: 26, oneLine: true),
                      const SizedBox(height: 22),
                      LabeledField(
                        label: 'New Password',
                        controller: _pass,
                        hint: '\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022',
                        obscureText: true,
                      ),
                      const SizedBox(height: 9),
                      LabeledField(
                        label: 'Confirm Password',
                        controller: _confirm,
                        hint: '\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022',
                        obscureText: true,
                        onSubmitted: (_) => _update(),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Use at least 8 characters. You will be signed out on all devices.',
                            style: AppTextStyles.inter(
                                size: 10.5, weight: FontWeight.w300, color: AppColors.muted2, height: 1.5)),
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
                  : GoldButton('Update Password', onTap: _update),
            ],
          ),
        ),
      ),
    );
  }
}
