import 'package:flutter/material.dart';

import '../branding/premisave_logo.dart' show PremisaveColors;

/// Premisave brand tokens. Flat colour only: no gradients, no glows.
class Brand {
  Brand._();

  // Core palette (shared with the logo kit).
  static const Color green = PremisaveColors.green; // 0E3B2F
  static const Color gold = PremisaveColors.gold; // E3A72F
  static const Color cream = PremisaveColors.cream; // F6F1E7
  static const Color greenTonal = PremisaveColors.skyline; // 14493B

  // Text on light and dark surfaces.
  static const Color ink = Color(0xFF10231D);
  static const Color muted = Color(0xFF5E6F68);
  static const Color goldDeep = Color(0xFF9A6B0E); // gold text that stays readable on cream

  // Surfaces and lines.
  static const Color border = Color(0xFFE6DFD0);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color darkBackground = Color(0xFF0A1C17);
  static const Color darkSurface = Color(0xFF10302A);
  static const Color darkBorder = Color(0xFF1E4A40);

  // Feedback.
  static const Color success = Color(0xFF1E8E5A);
  static const Color danger = Color(0xFFC0392B);
  static const Color warning = Color(0xFFD98E04);
  static const Color info = Color(0xFF2B6CB0);

  // Shape and spacing.
  static const double radius = 16;
  static const double radiusLarge = 22;
  static const double radiusSmall = 10;
  static const double gutter = 20;

  static const String fontFamily = 'PlusJakartaSans';
}

extension BrandColorX on Color {
  /// Same colour with the given opacity (0 to 1). Avoids the deprecated withOpacity.
  Color op(double opacity) => withValues(alpha: opacity);
}

extension BrandContextX on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  ColorScheme get scheme => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
  Color get borderColor => isDark ? Brand.darkBorder : Brand.border;
  Color get surfaceColor => isDark ? Brand.darkSurface : Brand.surface;
  Color get mutedColor => isDark ? Brand.cream.op(0.65) : Brand.muted;
  Color get inkColor => isDark ? Brand.cream : Brand.ink;
  Size get screenSize => MediaQuery.of(this).size;
  bool get isWide => MediaQuery.of(this).size.width >= 900;
  bool get isCompact => MediaQuery.of(this).size.width < 600;
}
