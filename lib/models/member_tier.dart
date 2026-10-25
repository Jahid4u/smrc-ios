import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// Membership / role tiers. Mirrors the HTML's badge system:
/// Silver, Gold, Black Diamond membership tiers, plus the
/// Brand Ambassador and Admin roles (which render like tiers
/// but aren't purchasable memberships).
enum MemberTier { silver, gold, blackDiamond, ambassador, admin }

extension MemberTierX on MemberTier {
  String get label {
    switch (this) {
      case MemberTier.silver:
        return 'Silver';
      case MemberTier.gold:
        return 'Gold';
      case MemberTier.blackDiamond:
        return 'Black Diamond';
      case MemberTier.ambassador:
        return 'Brand Ambassador';
      case MemberTier.admin:
        return 'Admin';
    }
  }

  Color get ringColor {
    switch (this) {
      case MemberTier.silver:
        return AppColors.silver;
      case MemberTier.gold:
        return AppColors.tierGold;
      case MemberTier.blackDiamond:
        return AppColors.diamond;
      case MemberTier.ambassador:
        return AppColors.ambassador;
      case MemberTier.admin:
        return AppColors.admin;
    }
  }

  Color get bg {
    switch (this) {
      case MemberTier.silver:
        return AppColors.tSilverBg;
      case MemberTier.gold:
        return AppColors.tGoldBg;
      case MemberTier.blackDiamond:
        return Colors.transparent;
      case MemberTier.ambassador:
        return AppColors.tAmbBg;
      case MemberTier.admin:
        return AppColors.tAdminBg;
    }
  }

  Color get border {
    switch (this) {
      case MemberTier.silver:
        return AppColors.tSilverBorder;
      case MemberTier.gold:
        return AppColors.tGoldBorder;
      case MemberTier.blackDiamond:
        return AppColors.tDiamondBorder;
      case MemberTier.ambassador:
        return AppColors.tAmbBorder;
      case MemberTier.admin:
        return AppColors.tAdminBorder;
    }
  }

  Color get text {
    switch (this) {
      case MemberTier.silver:
        return AppColors.tSilverText;
      case MemberTier.gold:
        return AppColors.tGoldText;
      case MemberTier.blackDiamond:
        return AppColors.tDiamondText;
      case MemberTier.ambassador:
        return AppColors.tAmbText;
      case MemberTier.admin:
        return AppColors.tAdminText;
    }
  }

  bool get glows => this == MemberTier.blackDiamond;
}
