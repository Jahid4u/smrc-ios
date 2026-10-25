import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

enum AppTab { explore, events, society, benefits, cheer }

extension AppTabX on AppTab {
  String get label {
    switch (this) {
      case AppTab.explore:
        return 'Explore';
      case AppTab.events:
        return 'Events';
      case AppTab.society:
        return 'SM Society';
      case AppTab.benefits:
        return 'Benefits';
      case AppTab.cheer:
        return 'Media';
    }
  }

  IconData get icon {
    switch (this) {
      case AppTab.explore:
        return Icons.diamond_outlined;
      case AppTab.events:
        return Icons.event_outlined;
      case AppTab.society:
        return Icons.groups_outlined;
      case AppTab.benefits:
        return Icons.card_giftcard_outlined;
      case AppTab.cheer:
        return Icons.celebration_outlined;
    }
  }

  String get path {
    switch (this) {
      case AppTab.explore:
        return '/explore';
      case AppTab.events:
        return '/events';
      case AppTab.society:
        return '/society';
      case AppTab.benefits:
        return '/benefits';
      case AppTab.cheer:
        return '/cheer';
    }
  }
}

/// 5-tab bottom bar. Height 84 + blur, matching .tabbar in the simulator.
class AppBottomNav extends StatelessWidget {
  final AppTab current;
  final ValueChanged<AppTab> onTap;
  const AppBottomNav({super.key, required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final barHeight = 62.0 + bottomPadding;
    return Container(
      height: barHeight,
      decoration: const BoxDecoration(
        color: Color(0xDD0A0A0B),
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: Row(
          children: AppTab.values.map((tab) {
            final on = tab == current;
            final color = on ? AppColors.accent : AppColors.muted2;
            return Expanded(
              child: InkWell(
                onTap: () => onTap(tab),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Icon(tab.icon, size: 21, color: color),
                    const SizedBox(height: 5),
                    Text(
                      tab.label.toUpperCase(),
                      style: AppTextStyles.inter(
                        size: 8,
                        weight: FontWeight.w500,
                        color: color,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
