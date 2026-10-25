import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/theme/app_text_styles.dart';
import '../models/member_tier.dart';
import '../models/member.dart' show Gender;

class TierBadge extends StatelessWidget {
  final MemberTier tier;
  const TierBadge({super.key, required this.tier});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: tier.bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tier.border),
        boxShadow: tier.glows
            ? [
                BoxShadow(color: tier.ringColor.withValues(alpha: .35), blurRadius: 14, spreadRadius: 1),
                BoxShadow(color: tier.ringColor.withValues(alpha: .2), blurRadius: 28, spreadRadius: 3),
              ]
            : null,
      ),
      child: Text(
        tier.label.toUpperCase(),
        style: AppTextStyles.inter(
          size: 8.5,
          weight: FontWeight.w600,
          color: tier.text,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

/// Avatar with a coloured ring matching the member's tier/role —
/// "user identity is shown by badge/ring, not by palette."
class RingAvatar extends StatelessWidget {
  final String? imageUrl;
  final MemberTier tier;
  final double size;
  /// When there's no uploaded photo, the fallback icon differs for Man vs
  /// Woman — a generic person icon, never a stock "face" photo (which would
  /// look like a random stranger's photo repeating across every member
  /// without one).
  final Gender? gender;
  const RingAvatar({super.key, this.imageUrl, required this.tier, this.size = 44, this.gender});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: tier.ringColor, width: 1.4),
        boxShadow: tier.glows
            ? [BoxShadow(color: tier.ringColor.withValues(alpha: .5), blurRadius: 12, spreadRadius: 1)]
            : null,
      ),
      child: ClipOval(
        child: (imageUrl != null && imageUrl!.isNotEmpty)
            ? CachedNetworkImage(fadeInDuration: Duration.zero, imageUrl: imageUrl!, fit: BoxFit.cover)
            : Container(
                color: const Color(0xFF1D1D21),
                alignment: Alignment.center,
                child: Icon(gender == Gender.woman ? Icons.woman : Icons.man,
                    size: size * 0.62, color: const Color(0xFF5E5E66)),
              ),
      ),
    );
  }
}
