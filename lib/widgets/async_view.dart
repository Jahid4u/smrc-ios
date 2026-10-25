import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

/// Shimmering placeholder block — the neutral "content is on its way" shape
/// used while real data loads.
///
/// This exists because screens used to fall back to `DemoData` inside
/// `maybeWhen(..., orElse: ...)`, and `orElse` fires during the *loading*
/// state too — so every screen briefly rendered the bundled demo/reference
/// content (someone else's name, a placeholder event) before the member's
/// real data replaced it a moment later. Showing a neutral skeleton instead
/// means the member only ever sees content that's actually theirs.
class SkeletonBox extends StatefulWidget {
  final double? width;
  final double height;
  final double radius;
  final EdgeInsets margin;
  const SkeletonBox({
    super.key,
    this.width,
    this.height = 14,
    this.radius = 8,
    this.margin = EdgeInsets.zero,
  });

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        margin: widget.margin,
        decoration: BoxDecoration(
          color: Color.lerp(AppColors.charcoal2, AppColors.charcoal, _c.value),
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

/// Card-shaped skeleton matching the app's list-item proportions.
class SkeletonCard extends StatelessWidget {
  final double height;
  const SkeletonCard({super.key, this.height = 92});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.charcoal.withValues(alpha: .4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          const SkeletonBox(width: 46, height: 46, radius: 23),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                SkeletonBox(width: 140, height: 13),
                SizedBox(height: 8),
                SkeletonBox(width: 90, height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Consistent empty/error state with an optional retry.
class AsyncErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const AsyncErrorState({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 40),
      child: Column(
        children: [
          Icon(Icons.cloud_off_outlined, size: 28, color: AppColors.muted.withValues(alpha: .7)),
          const SizedBox(height: 12),
          Text(message,
              textAlign: TextAlign.center,
              style: AppTextStyles.inter(size: 12.5, weight: FontWeight.w300, color: AppColors.muted)),
          if (onRetry != null) ...[
            const SizedBox(height: 14),
            InkWell(
              onTap: onRetry,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.gold.withValues(alpha: .5)),
                ),
                child: Text('Try Again',
                    style: AppTextStyles.inter(size: 11.5, weight: FontWeight.w500, color: AppColors.gold)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A stack of [SkeletonCard]s — the standard loading state for any list.
class SkeletonList extends StatelessWidget {
  final int count;
  final double itemHeight;
  final EdgeInsets padding;
  const SkeletonList({
    super.key,
    this.count = 3,
    this.itemHeight = 92,
    this.padding = const EdgeInsets.symmetric(horizontal: 26),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        children: List.generate(count, (_) => SkeletonCard(height: itemHeight)),
      ),
    );
  }
}
