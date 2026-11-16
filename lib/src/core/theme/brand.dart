import 'package:flutter/material.dart';

import '../branding/premisave_logo.dart' show PremisaveColors;
import 'palette.dart';

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

/// Scales every corner radius in the shared components (Sharp, Standard, Soft).
@immutable
class AppShape extends ThemeExtension<AppShape> {
  const AppShape({this.scale = 1});

  final double scale;

  @override
  AppShape copyWith({double? scale}) => AppShape(scale: scale ?? this.scale);

  @override
  AppShape lerp(ThemeExtension<AppShape>? other, double t) {
    if (other is! AppShape) return this;
    return AppShape(scale: scale + (other.scale - scale) * t);
  }
}

extension BrandContextX on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  ColorScheme get scheme => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
  Color get borderColor => pal.line;
  Color get surfaceColor => pal.panel;
  Color get mutedColor => pal.ink3;
  Color get inkColor => pal.ink;
  Size get screenSize => MediaQuery.of(this).size;
  bool get isWide => MediaQuery.of(this).size.width >= 900;
  bool get isCompact => MediaQuery.of(this).size.width < 600;

  /// A corner radius that follows the chosen corner style.
  double radius(double base) => base * (Theme.of(this).extension<AppShape>()?.scale ?? 1);

  /// Heading style in the display font of the chosen font pairing.
  TextStyle display({double? size, FontWeight? weight, double? spacing, double? height, Color? color}) {
    final base = Theme.of(this).textTheme.headlineMedium ?? const TextStyle();
    return base.copyWith(fontSize: size, fontWeight: weight, letterSpacing: spacing, height: height, color: color);
  }
}
