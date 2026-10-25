import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../core/theme/app_colors.dart';
import 'app_logo.dart';
import '../core/theme/app_text_styles.dart';

/// .btn-fill / .btn-line / .btn-ghost — pill buttons, 16px pad, tracking 2
enum GoldBtnStyle { fill, line, ghost }

class GoldButton extends StatelessWidget {
  final String label;
  final GoldBtnStyle style;
  final VoidCallback? onTap;
  final bool compact;
  const GoldButton(this.label, {super.key, this.style = GoldBtnStyle.fill, this.onTap, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final Color bg = style == GoldBtnStyle.fill ? AppColors.accent : Colors.transparent;
    final Color border = switch (style) {
      GoldBtnStyle.fill => AppColors.accent,
      GoldBtnStyle.line => AppColors.accent,
      GoldBtnStyle.ghost => AppColors.line,
    };
    final Color fg = switch (style) {
      GoldBtnStyle.fill => AppColors.ink,
      GoldBtnStyle.line => AppColors.accent,
      GoldBtnStyle.ghost => const Color(0xFFCFCDC6),
    };
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(compact ? 24 : 30),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: compact ? 12 : 16),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(compact ? 24 : 30),
        ),
        child: Text(
          label.toUpperCase(),
          textAlign: TextAlign.center,
          style: AppTextStyles.inter(
              size: compact ? 11.5 : 12,
              weight: FontWeight.w500,
              color: fg,
              letterSpacing: compact ? 1.2 : 2),
        ),
      ),
    );
  }
}

/// .field — label + value box
/// Professional labelled text input — a small uppercase label above a single
/// clean bordered field. Replaces the older nested FieldBox+TextField pattern
/// that rendered a box-inside-a-box.
class LabeledField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final bool readOnly;
  final int maxLines;
  final TextInputType? keyboardType;
  final bool obscureText;
  final ValueChanged<String>? onSubmitted;
  final TextCapitalization textCapitalization;
  const LabeledField({
    super.key,
    required this.label,
    required this.controller,
    this.hint = '',
    this.readOnly = false,
    this.maxLines = 1,
    this.keyboardType,
    this.obscureText = false,
    this.onSubmitted,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  State<LabeledField> createState() => _LabeledFieldState();
}

class _LabeledFieldState extends State<LabeledField> {
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final focused = _focus.hasFocus;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label.isNotEmpty) ...[
          Text(widget.label.toUpperCase(), style: AppTextStyles.label),
          const SizedBox(height: 7),
        ],
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 3),
          decoration: BoxDecoration(
            color: widget.readOnly
                ? Colors.white.withValues(alpha: .015)
                : Colors.white.withValues(alpha: .03),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: focused ? AppColors.gold : AppColors.line,
              width: focused ? 1.4 : 1,
            ),
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focus,
            readOnly: widget.readOnly,
            maxLines: widget.obscureText ? 1 : widget.maxLines,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType,
            onSubmitted: widget.onSubmitted,
            textCapitalization: widget.textCapitalization,
            autofillHints: const [],
            style: AppTextStyles.value.copyWith(
                color: widget.readOnly ? AppColors.muted : const Color(0xFFECEAE4)),
            cursorColor: AppColors.gold,
            decoration: InputDecoration(
              isCollapsed: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 13),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              filled: false,
              hintText: widget.hint,
              hintStyle: AppTextStyles.inter(
                  size: 13, weight: FontWeight.w300, color: const Color(0xFF55555C)),
            ),
          ),
        ),
      ],
    );
  }
}

class FieldBox extends StatelessWidget {
  final String label;
  final String? value;
  final String? placeholder;
  final Widget? child;
  final double extraHeight;
  const FieldBox({super.key, required this.label, this.value, this.placeholder, this.child, this.extraHeight = 0});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(label.toUpperCase(), style: AppTextStyles.label),
          const SizedBox(height: 7),
        ],
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(14),
            color: Colors.white.withValues(alpha: .02),
          ),
          child: child ??
              Text(
                value ?? placeholder ?? '',
                style: value != null
                    ? AppTextStyles.value
                    : AppTextStyles.inter(size: 13, weight: FontWeight.w300, color: const Color(0xFF55555C)),
              ),
        ),
        if (extraHeight > 0) SizedBox(height: extraHeight),
      ],
    );
  }
}

/// .chip / .chip.on
class FilterChipPill extends StatelessWidget {
  final String label;
  final bool on;
  final VoidCallback? onTap;
  const FilterChipPill(this.label, {super.key, this.on = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
        decoration: BoxDecoration(
          color: on ? AppColors.accent : Colors.transparent,
          border: Border.all(color: on ? AppColors.accent : AppColors.line),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          label.toUpperCase(),
          style: AppTextStyles.inter(
            size: 9,
            weight: FontWeight.w500,
            color: on ? AppColors.ink : AppColors.muted,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}

/// .ey eyebrow + serif hero title header used at the top of tab screens
class ScreenHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String? titleEm; // italic gold part
  final String? subtitle;
  final Color eyebrowColor;
  final double titleSize;
  const ScreenHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    this.titleEm,
    this.subtitle,
    this.eyebrowColor = AppColors.accent,
    this.titleSize = 28,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(eyebrow.toUpperCase(),
            style: AppTextStyles.inter(size: 9.5, weight: FontWeight.w600, color: eyebrowColor, letterSpacing: 3)),
        const SizedBox(height: 6),
        RichText(
          text: TextSpan(
            style: AppTextStyles.serif(size: titleSize, color: Colors.white),
            children: [
              TextSpan(text: title),
              if (titleEm != null)
                TextSpan(
                  text: titleEm,
                  style: AppTextStyles.serif(
                      size: titleSize, color: AppColors.gold, style: FontStyle.italic),
                ),
            ],
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(subtitle!,
              style: AppTextStyles.inter(size: 11.5, weight: FontWeight.w300, color: AppColors.muted, height: 1.55)),
        ],
      ],
    );
  }
}

/// .h-hero centered variant with italic gold em part on 2nd line
class HeroTitle extends StatelessWidget {
  final String line1;
  final String em;
  final double size;
  final TextAlign align;
  final bool oneLine;
  const HeroTitle(
      {super.key,
      required this.line1,
      required this.em,
      this.size = 28,
      this.align = TextAlign.center,
      this.oneLine = false});

  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: align,
      text: TextSpan(
        style: AppTextStyles.serif(size: size, color: Colors.white, height: 1.06),
        children: [
          TextSpan(text: oneLine ? '$line1 ' : '$line1\n'),
          TextSpan(text: em, style: AppTextStyles.serif(size: size, color: AppColors.gold, style: FontStyle.italic, height: 1.06)),
        ],
      ),
    );
  }
}

/// Gold ring circle with an icon inside (.ring with inner ring)
class GoldRingIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color color;
  final bool doubleRing;
  const GoldRingIcon({super.key, required this.icon, this.size = 78, this.color = AppColors.gold, this.doubleRing = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color)),
      child: Container(
        margin: const EdgeInsets.all(7),
        alignment: Alignment.center,
        decoration: doubleRing
            ? BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color.withValues(alpha: .25)))
            : null,
        child: Icon(icon, color: color, size: size * .36),
      ),
    );
  }
}

/// Charcoal card, .card
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color? borderColor;
  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.charcoal,
        border: Border.all(color: borderColor ?? AppColors.line),
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }
}

/// Membership card (gold gradient card with logo + name + since/tier row)
class MembershipCard extends StatelessWidget {
  final String name;
  final String sinceLabel;
  final String tierLabel;
  final Color tierColor;
  final bool diamondGlow;
  const MembershipCard({
    super.key,
    required this.name,
    required this.sinceLabel,
    required this.tierLabel,
    this.tierColor = AppColors.gold,
    this.diamondGlow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1D1D21), Color(0xFF101012)],
        ),
        border: Border.all(color: tierColor.withValues(alpha: .4)),
        boxShadow: diamondGlow
            ? [BoxShadow(color: tierColor.withValues(alpha: .18), blurRadius: 24, spreadRadius: -6)]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const AppLogo(size: 34),
              Text('SM ROYAL CIRCLE',
                  style: AppTextStyles.inter(size: 9.5, weight: FontWeight.w600, color: tierColor, letterSpacing: 3)),
            ],
          ),
          const SizedBox(height: 30),
          Text(name, style: AppTextStyles.serif(size: 18, color: Colors.white, letterSpacing: 1)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(sinceLabel,
                  style: AppTextStyles.inter(size: 10, color: AppColors.muted, letterSpacing: 2)),
              Text(tierLabel,
                  style: AppTextStyles.inter(size: 10, color: tierColor, letterSpacing: 2)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Settings-style menu row list (.pad rows with 1px bottom line)
class MenuRows extends StatelessWidget {
  final List<(String, VoidCallback?)> items;
  final String? trailingMutedLabel; // e.g. "Log Out"
  final VoidCallback? onTrailingTap;
  const MenuRows({super.key, required this.items, this.trailingMutedLabel, this.onTrailingTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...items.map((e) => InkWell(
              onTap: e.$2,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 4),
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(e.$1, style: AppTextStyles.inter(size: 13, weight: FontWeight.w300, color: const Color(0xFFE9E7E1))),
                    Text('›', style: AppTextStyles.inter(size: 15, color: AppColors.muted2)),
                  ],
                ),
              ),
            )),
        if (trailingMutedLabel != null)
          InkWell(
            onTap: onTrailingTap,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 4),
              child: Text(trailingMutedLabel!,
                  style: AppTextStyles.inter(size: 13, weight: FontWeight.w300, color: AppColors.muted)),
            ),
          ),
      ],
    );
  }
}

/// Compact "Important Links" list — Privacy Policy, contact email, and
/// website. Used on the Concierge & Support screen.
class ImportantLinksCard extends StatelessWidget {
  const ImportantLinksCard({super.key});

  static const _privacyUrl = 'https://smroyalcircle.club/Privacy-Policy';
  static const _email = 'info@smroyalcircle.club';
  static const _website = 'smroyalcircle.club';

  Future<void> _open(String url) => launchUrlString(url, mode: LaunchMode.externalApplication);

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        children: [
          _row(Icons.privacy_tip_outlined, 'Privacy Policy', () => _open(_privacyUrl)),
          _row(Icons.mail_outline, _email, () => _open('mailto:$_email')),
          _row(Icons.language, _website, () => _open('https://$_website'), isLast: true),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, VoidCallback onTap, {bool isLast = false}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 10),
        decoration: BoxDecoration(
          border: isLast ? null : const Border(bottom: BorderSide(color: AppColors.line)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 15, color: AppColors.gold),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.inter(size: 12, weight: FontWeight.w300, color: const Color(0xFFE9E7E1))),
            ),
            Text('›', style: AppTextStyles.inter(size: 14, color: AppColors.muted2)),
          ],
        ),
      ),
    );
  }
}

/// One-line consent notice shown directly under a submit/continue action,
/// with "Privacy Policy" as an inline tappable link — the standard pattern
/// for telling someone what they're agreeing to at the moment they act.
///
/// Stateful purely so the tap recognizer can be disposed; a StatelessWidget
/// would leak one recognizer per rebuild.
class PrivacyConsentText extends StatefulWidget {
  /// What the person is about to do, e.g. 'submitting your application'.
  /// Rendered as: "By {action}, you agree to our Privacy Policy."
  final String action;
  const PrivacyConsentText({super.key, required this.action});

  @override
  State<PrivacyConsentText> createState() => _PrivacyConsentTextState();
}

class _PrivacyConsentTextState extends State<PrivacyConsentText> {
  late final TapGestureRecognizer _tap;

  @override
  void initState() {
    super.initState();
    _tap = TapGestureRecognizer()
      ..onTap = () => launchUrlString(
            'https://smroyalcircle.club/Privacy-Policy',
            mode: LaunchMode.externalApplication,
          );
  }

  @override
  void dispose() {
    _tap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = AppTextStyles.inter(
        size: 10.5, weight: FontWeight.w300, color: AppColors.muted, height: 1.5);
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: base,
        children: [
          TextSpan(text: 'By ${widget.action}, you agree to our '),
          TextSpan(
            text: 'Privacy Policy',
            recognizer: _tap,
            style: base.copyWith(
              color: AppColors.gold,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.gold,
            ),
          ),
          const TextSpan(text: '.'),
        ],
      ),
    );
  }
}
