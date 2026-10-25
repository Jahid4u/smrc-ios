import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Text styles mirroring the HTML simulator:
///  - Cormorant Garamond -> serif / hero / display headings
///  - Inter -> everything else (labels, body, buttons)
///
/// Both fonts are bundled locally (assets/fonts, declared in pubspec.yaml) as
/// variable fonts — NOT fetched from google_fonts at runtime. This removes
/// the network round-trip that used to block the first frame (the 3-4s
/// black-screen delay on launch): the exact typeface is available offline,
/// instantly, every time, regardless of network conditions.
class AppTextStyles {
  AppTextStyles._();

  static TextStyle serif({
    double size = 22,
    FontWeight weight = FontWeight.w500,
    Color color = Colors.white,
    FontStyle style = FontStyle.normal,
    double? height,
    double? letterSpacing,
  }) =>
      TextStyle(
        fontFamily: 'Cormorant Garamond',
        fontSize: size,
        fontWeight: weight,
        color: color,
        fontStyle: style,
        height: height,
        letterSpacing: letterSpacing,
      );

  static TextStyle inter({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color color = const Color(0xFFE8E6E0),
    double? height,
    double? letterSpacing,
  }) =>
      TextStyle(
        fontFamily: 'Inter',
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );

  // Common presets used across screens
  static TextStyle heroTitle = serif(size: 40, weight: FontWeight.w400, height: 1.06);
  static TextStyle screenTitle = serif(size: 26, weight: FontWeight.w500);
  static TextStyle sectionTitle = inter(
    size: 12,
    weight: FontWeight.w500,
    color: const Color(0xFFCFCDC6),
    letterSpacing: 2.5,
  );
  static TextStyle eyebrow = inter(
    size: 9.5,
    weight: FontWeight.w600,
    color: AppColors.accent,
    letterSpacing: 3,
  );
  static TextStyle body = inter(size: 13.5, weight: FontWeight.w300, color: AppColors.muted);
  static TextStyle label = inter(
    size: 9,
    weight: FontWeight.w500,
    color: AppColors.muted2,
    letterSpacing: 2,
  );
  static TextStyle value = inter(size: 13, weight: FontWeight.w300, color: const Color(0xFFE9E7E1));
  static TextStyle buttonLabel = inter(
    size: 12,
    weight: FontWeight.w500,
    color: Colors.white,
    letterSpacing: 2,
  );
}
