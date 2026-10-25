import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/app_providers.dart';
import '../../widgets/app_logo.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  static const fallbackImg =
      'https://images.unsplash.com/photo-1514933651103-005eec06c04b?w=900&q=80';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final copyAsync = ref.watch(screenCopyProvider);
    final copy = copyAsync.maybeWhen(data: (c) => c, orElse: () => const {});
    String cv(String k, String fb) { final v = copy[k]?.toString() ?? ''; return v.isNotEmpty ? v : fb; }
    // Only resolve a background once we actually know the admin's setting
    // (or that the request failed) — never show the fallback photo first and
    // then swap to the real one once it loads, which is the flash this
    // avoids entirely.
    final resolvedBg = copyAsync.isLoading ? null : cv('welcome_img', fallbackImg);
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Admin-set background (Screens & Copy → Welcome), or the built-in
          // fallback if nothing's configured — decided once, above. While
          // still loading, the screen simply stays on the plain ink
          // background (identical to the native splash), so there is never a
          // wrong photo shown first. memCacheWidth caps the decoded bitmap to
          // roughly phone width instead of decoding the source photo at full
          // resolution — this is the very first screen a user sees, so
          // decode cost here matters more than almost anywhere else in the app.
          if (resolvedBg != null)
            CachedNetworkImage(
              imageUrl: resolvedBg,
              fit: BoxFit.cover,
              memCacheWidth: 900,
              fadeInDuration: Duration.zero,
              fadeOutDuration: Duration.zero,
              placeholder: (_, __) => Container(color: AppColors.ink),
              errorWidget: (_, __, ___) => Container(color: AppColors.ink),
            ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xCC0A0A0B), Color(0xF20A0A0B)],
              ),
            ),
          ),
          SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 40, 28, 32),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const AppLogo(size: 92),
                        const SizedBox(height: 30),
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: AppTextStyles.heroTitle,
                            children: [
                              TextSpan(text: '${cv('welcome_line1_p1', 'A society built on')}\n'),
                              TextSpan(
                                text: cv('welcome_line1_p2', 'discretion'),
                                style: AppTextStyles.heroTitle.copyWith(color: AppColors.gold, fontStyle: FontStyle.italic),
                              ),
                              const TextSpan(text: '.'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          cv('welcome_body',
                              'SM Royal Circle is an invitation-only private members club. Membership is by application or sponsor invitation only.'),
                          textAlign: TextAlign.center,
                          style: AppTextStyles.body,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => context.push('/sign-in'),
                child: const Text('SIGN IN'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.push('/invitation-code'),
                child: const Text('I HAVE AN INVITATION CODE'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.push('/membership-path'),
                child: const Text('Apply for Membership'),
              ),
            ],
          ),
        ),
      ),
        ],
      ),
    );
  }
}
