import 'package:flutter/material.dart';

import '../../state/appearance_controller.dart';
import 'appearance_options.dart';
import 'brand.dart';
import 'palette.dart';

/// Builds the Flutter theme from a colour palette, a font and a corner style.
class AppTheme {
  AppTheme._();

  /// The theme for an explicit palette, or for the light or dark Premisave palette while following the device.
  static ThemeData forAppearance(Appearance a, {Brightness device = Brightness.light}) {
    final palette = a.palette ?? (device == Brightness.dark ? AppPalette.premisaveNight : AppPalette.premisave);
    return build(palette, font: a.font, corner: a.corner);
  }

  static ThemeData build(AppPalette p, {required FontOption font, required CornerOption corner}) {
    final dark = p.dark;
    final s = corner.scale;
    final brightness = dark ? Brightness.dark : Brightness.light;

    final scheme = ColorScheme(
      brightness: brightness,
      primary: p.accent,
      onPrimary: p.accentInk,
      secondary: p.accent,
      onSecondary: p.accentInk,
      tertiary: p.warn,
      onTertiary: p.accentInk,
      error: p.bad,
      onError: dark ? Colors.black : Colors.white,
      surface: p.panel,
      onSurface: p.ink,
      surfaceContainerHighest: p.panel2,
      onSurfaceVariant: p.ink3,
      outline: p.line2,
      outlineVariant: p.line,
      primaryContainer: p.accentSoft,
      onPrimaryContainer: p.ink,
      secondaryContainer: p.accentSoft,
      onSecondaryContainer: p.ink,
    );

    final base = ThemeData(brightness: brightness, useMaterial3: true).textTheme;
    var text = base.apply(fontFamily: font.sans, bodyColor: p.ink, displayColor: p.ink);
    final heading = font.display;
    if (heading != null) {
      TextStyle? h(TextStyle? t) => t?.copyWith(fontFamily: heading);
      text = text.copyWith(
        displayLarge: h(text.displayLarge),
        displayMedium: h(text.displayMedium),
        displaySmall: h(text.displaySmall),
        headlineLarge: h(text.headlineLarge),
        headlineMedium: h(text.headlineMedium),
        headlineSmall: h(text.headlineSmall),
        titleLarge: h(text.titleLarge),
      );
    }

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: font.sans,
      textTheme: text,
      scaffoldBackgroundColor: p.bg,
      canvasColor: p.panel,
      splashFactory: InkRipple.splashFactory,
      visualDensity: VisualDensity.standard,
      extensions: <ThemeExtension<dynamic>>[p, AppShape(scale: s)],
      dividerTheme: DividerThemeData(color: p.line, thickness: 1, space: 1),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: p.ink,
        contentTextStyle: TextStyle(color: p.bg, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12 * s)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.panel,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(Brand.radiusLarge * s))),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.panel,
        surfaceTintColor: Colors.transparent,
        indicatorColor: p.accent,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? p.ink : p.ink3,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(color: selected ? p.accentInk : p.ink3);
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: p.panel,
        indicatorColor: p.accent,
        selectedIconTheme: IconThemeData(color: p.accentInk),
        unselectedIconTheme: IconThemeData(color: p.ink3),
        selectedLabelTextStyle: TextStyle(fontWeight: FontWeight.w700, color: p.ink),
        unselectedLabelTextStyle: TextStyle(fontWeight: FontWeight.w500, color: p.ink3),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: p.accent),
      chipTheme: ChipThemeData(
        side: BorderSide(color: p.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Brand.radiusSmall * s)),
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}
