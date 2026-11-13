import 'package:flutter/material.dart';

/// Colour system extracted 1:1 from the SM Royal Circle HTML simulator
/// (:root CSS variables). One theme for everyone — identity is shown via
/// badge/ring colour, not by changing the base palette.
class AppColors {
  AppColors._();

  static const Color ink = Color(0xFF0A0A0B);
  static const Color charcoal = Color(0xFF161619);
  static const Color charcoal2 = Color(0xFF1D1D21);
  static const Color line = Color(0xFF2A2A30);

  static const Color gold = Color(0xFFC8A24A);
  static const Color goldSoft = Color(0xFFD9BE7E);
  static const Color paper = Color(0xFFF1EDE4);
  static const Color muted = Color(0xFF8A8A92);
  static const Color muted2 = Color(0xFF5E5E66);

  static const Color accent = gold;

  // Tier / role ring + badge colours
  static const Color silver = Color(0xFF9DA3AC);
  static const Color tierGold = Color(0xFFC8A24A);
  static const Color diamond = Color(0xFFF1F4F8);
  static const Color ambassador = Color(0xFFE8B4C4);
  static const Color admin = Color(0xFFD0494B);

  static const Color success = Color(0xFF4CAF7D);
  static const Color successSoft = Color(0xFF7FD3A6);

  // Tier badge fills/borders/text (t-silver / t-gold / t-diamond / t-amb / t-admin)
  static const Color tSilverBg = Color(0x21C9CCD2);
  static const Color tSilverBorder = Color(0x80C9CCD2);
  static const Color tSilverText = Color(0xFFC9CCD2);

  static const Color tGoldBg = Color(0x24C8A24A);
  static const Color tGoldBorder = Color(0x8CC8A24A);
  static const Color tGoldText = Color(0xFFD9BE7E);

  static const Color tDiamondBorder = Color(0x99F1F4F8);
  static const Color tDiamondText = Color(0xFFF1F4F8);

  static const Color tAmbBg = Color(0x21E8B4C4);
  static const Color tAmbBorder = Color(0x8CE8B4C4);
  static const Color tAmbText = Color(0xFFF0C8D4);

  static const Color tAdminBg = Color(0x28D0494B);
  static const Color tAdminBorder = Color(0x99D0494B);
  static const Color tAdminText = Color(0xFFE68688);
}
