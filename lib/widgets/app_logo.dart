import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/app_providers.dart';

/// The SM Royal Circle phoenix mark, used across the app.
///
/// The mark is admin-controlled: set it in the admin panel under
/// Screens & Copy → Splash → "Logo". That single logo is used everywhere
/// `AppLogo` appears (splash, welcome, approved, the Society, etc.).
///
/// The bundled gold mark is shown INSTANTLY as the placeholder, so the brand
/// moment never blanks out; if an admin logo URL is configured it loads over
/// the network with the asset as placeholder + error fallback and is cached
/// after the first fetch. Pass [url] to override the admin logo for one spot.
class AppLogo extends ConsumerWidget {
  final double size;
  final String? url;
  const AppLogo({super.key, this.size = 64, this.url});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asset = Image.asset(
      'assets/images/logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );

    // Explicit override wins; otherwise use the admin logo from Screens & Copy.
    var u = url?.trim() ?? '';
    if (u.isEmpty) {
      u = ref
          .watch(screenCopyProvider)
          .maybeWhen(
              data: (c) => (c['splash_logo']?.toString() ?? '').trim(),
              orElse: () => '');
    }
    if (u.isEmpty) return asset;

    return CachedNetworkImage(
      imageUrl: u,
      width: size,
      height: size,
      fit: BoxFit.contain,
      fadeInDuration: Duration.zero,
      placeholder: (_, __) => asset,
      errorWidget: (_, __, ___) => asset,
    );
  }
}
