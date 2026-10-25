import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/smrc_repository.dart';
import '../../core/error_classifier.dart';
import '../../core/push_helper.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/app_providers.dart';
import '../../widgets/ui_kit.dart';

/// Sign In — POST /login, save token, GET /me, then into the Circle.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final email = _email.text.trim();
    final pass = _password.text;
    if (email.isEmpty || pass.isEmpty) {
      setState(() => _error = 'Email and password are required.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final repo = ref.read(repoProvider);
      await repo.login(email, pass);
      final me = await repo.me();
      ref.read(currentMemberProvider.notifier).state = me;
      registerPushToken(repo); // fire-and-forget
      if (mounted) context.go(memberHomeRoute(me));
    } on ApiException catch (e) {
      if (e.code == 'application_rejected') {
        if (mounted) context.go('/not-approved', extra: e.data?['refNo'] as String?);
        return;
      }
      if (e.code == 'application_pending') {
        if (mounted) context.go('/pending-review', extra: e.data?['refNo'] as String?);
        return;
      }
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
                      Text('WELCOME BACK', style: AppTextStyles.eyebrow),
                      const SizedBox(height: 10),
                      const HeroTitle(line1: 'Step back', em: 'inside.', size: 30, align: TextAlign.left, oneLine: true),
                      const SizedBox(height: 26),
                      LabeledField(
                        label: 'Email',
                        controller: _email,
                        hint: 'you@example.com',
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 12),
                      LabeledField(
                        label: 'Password',
                        controller: _password,
                        hint: '\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022',
                        obscureText: true,
                        onSubmitted: (_) => _signIn(),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () => context.push('/forgot-password-1'),
                        child: Text('Forgot password?',
                            style: AppTextStyles.inter(size: 11, color: AppColors.gold)),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.admin.withValues(alpha: .5)),
                            borderRadius: BorderRadius.circular(12),
                          ),
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
                      child: Padding(
                        padding: EdgeInsets.all(14),
                        child: SizedBox(
                            width: 26,
                            height: 26,
                            child: CircularProgressIndicator(color: AppColors.gold, strokeWidth: 2)),
                      ),
                    )
                  : GoldButton('Sign In', onTap: _signIn),
            ],
          ),
        ),
      ),
    );
  }
}
