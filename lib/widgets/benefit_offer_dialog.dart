import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../models/api_models.dart';
import '../providers/app_providers.dart';
import '../core/error_classifier.dart';
import '../core/cache/content_cache.dart';
import 'ui_kit.dart';

/// Shows the complimentary benefit-offer popup. Accepting activates the gifted
/// membership for free. Dismissing keeps the offer — it returns on next launch.
Future<void> showBenefitOfferDialog(
    BuildContext context, WidgetRef ref, BenefitOffer offer) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: .82),
    builder: (ctx) => _BenefitOfferDialog(offer: offer),
  );
}

class _BenefitOfferDialog extends ConsumerStatefulWidget {
  final BenefitOffer offer;
  const _BenefitOfferDialog({required this.offer});

  @override
  ConsumerState<_BenefitOfferDialog> createState() => _BenefitOfferDialogState();
}

class _BenefitOfferDialogState extends ConsumerState<_BenefitOfferDialog> {
  bool _busy = false;

  Future<void> _accept() async {
    setState(() => _busy = true);
    try {
      await ref.read(repoProvider).acceptBenefitOffer();
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not accept this offer. ${describeError(e).display}')),
      );
      return; // Keep the dialog open — the offer was NOT confirmed as accepted.
    }
    // Refresh member + related data so the app unlocks immediately. Best
    // effort only: the offer itself is already accepted server-side at this
    // point, so a failure here just means the UI catches up on next load.
    try {
      final me = await ref.read(repoProvider).me();
      ref.read(currentMemberProvider.notifier).state = me;
    } catch (_) {}
    ref.invalidate(benefitOfferProvider);
    ref.invalidate(notificationsProvider);
    await ContentCache.clear('billing');
    ref.invalidate(billingProvider);
    if (!mounted) return;
    setState(() => _busy = false);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.offer;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 30),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        decoration: BoxDecoration(
          color: AppColors.charcoal,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.gold.withValues(alpha: .45)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold.withValues(alpha: .12),
                border: Border.all(color: AppColors.gold.withValues(alpha: .5)),
              ),
              child: const Icon(Icons.card_giftcard, size: 32, color: AppColors.gold),
            ),
            const SizedBox(height: 20),
            Text('A GIFT FOR YOU', style: AppTextStyles.eyebrow),
            const SizedBox(height: 10),
            Text('Complimentary ${o.tierName}',
                textAlign: TextAlign.center,
                style: AppTextStyles.serif(size: 24, color: Colors.white)),
            const SizedBox(height: 14),
            Text(o.message,
                textAlign: TextAlign.center,
                style: AppTextStyles.inter(
                    size: 12.5, weight: FontWeight.w300, color: AppColors.muted, height: 1.6)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .03),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.line),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.verified_outlined, size: 15, color: AppColors.gold),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                        o.durationDays > 0
                            ? 'Free for ${o.durationDays} days${o.endsAt.isNotEmpty ? ' · until ${o.endsAt}' : ''}'
                            : 'Complimentary membership',
                        style: AppTextStyles.inter(
                            size: 11, weight: FontWeight.w400, color: const Color(0xFFE9E7E1))),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            if (_busy)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: AppColors.gold, strokeWidth: 2)),
              )
            else ...[
              GoldButton('Accept — It\u2019s Free', onTap: _accept),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('MAYBE LATER',
                    style: AppTextStyles.inter(size: 10.5, color: AppColors.muted2, letterSpacing: 2)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
