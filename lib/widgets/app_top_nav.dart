import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

/// Matches .topnav: dark bar that sits BELOW the status bar / notch
/// (SafeArea), with back chevron + title + optional trailing icon.
class AppTopNav extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? trailing;
  final bool showBack;

  const AppTopNav({super.key, required this.title, this.trailing, this.showBack = true});

  @override
  Size get preferredSize => const Size.fromHeight(58);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xE60A0A0B),
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: preferredSize.height,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                if (showBack)
                  IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.muted),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.inter(size: 14, weight: FontWeight.w500, color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Small circular icon button used in headers (notifications, menu, etc.)
class HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool showDot;
  const HeaderIconButton({super.key, required this.icon, this.onTap, this.showDot = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.line),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(icon, size: 16, color: const Color(0xFFCFCDC6)),
            if (showDot)
              Positioned(
                top: -1,
                right: -1,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(color: AppColors.admin, shape: BoxShape.circle),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
