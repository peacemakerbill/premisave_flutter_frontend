import 'package:flutter/material.dart';

import 'brand.dart';

/// Light and dark themes. Component styling that changes between Flutter releases
/// (cards, dialogs, inputs, tabs) lives in the widgets under core/widgets instead.
class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;

    final scheme = ColorScheme(
      brightness: brightness,
      primary: dark ? Brand.gold : Brand.green,
      onPrimary: dark ? Brand.green : Brand.cream,
      secondary: dark ? Brand.cream : Brand.gold,
      onSecondary: Brand.green,
      tertiary: Brand.gold,
      onTertiary: Brand.green,
      error: Brand.danger,
      onError: Colors.white,
      surface: dark ? Brand.darkSurface : Brand.surface,
      onSurface: dark ? Brand.cream : Brand.ink,
      surfaceContainerHighest: dark ? Brand.greenTonal : const Color(0xFFEFE9DB),
      onSurfaceVariant: dark ? Brand.cream.op(0.7) : Brand.muted,
      outline: dark ? Brand.darkBorder : Brand.border,
      outlineVariant: dark ? Brand.darkBorder : Brand.border,
      primaryContainer: dark ? Brand.greenTonal : const Color(0xFFDCEBE4),
      onPrimaryContainer: dark ? Brand.cream : Brand.green,
      secondaryContainer: dark ? Brand.greenTonal : const Color(0xFFFBEBC8),
      onSecondaryContainer: dark ? Brand.gold : Brand.goldDeep,
    );

    final base = ThemeData(brightness: brightness, useMaterial3: true);
    final textTheme = base.textTheme.apply(
      fontFamily: Brand.fontFamily,
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: Brand.fontFamily,
      textTheme: textTheme,
      scaffoldBackgroundColor: dark ? Brand.darkBackground : Brand.cream,
      canvasColor: dark ? Brand.darkBackground : Brand.cream,
      splashFactory: InkRipple.splashFactory,
      visualDensity: VisualDensity.standard,
      dividerTheme: DividerThemeData(color: scheme.outline, thickness: 1, space: 1),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: dark ? Brand.cream : Brand.green,
        contentTextStyle: TextStyle(
          fontFamily: Brand.fontFamily,
          color: dark ? Brand.green : Brand.cream,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Brand.radiusSmall + 2)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(Brand.radiusLarge)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: dark ? Brand.greenTonal : Brand.green,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontFamily: Brand.fontFamily,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? (dark ? Brand.gold : Brand.cream) : scheme.onSurfaceVariant,
          );
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: dark ? Brand.greenTonal : Brand.green,
        selectedIconTheme: IconThemeData(color: dark ? Brand.gold : Brand.cream),
        unselectedIconTheme: IconThemeData(color: scheme.onSurfaceVariant),
        selectedLabelTextStyle: TextStyle(
          fontFamily: Brand.fontFamily,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
        unselectedLabelTextStyle: TextStyle(
          fontFamily: Brand.fontFamily,
          fontWeight: FontWeight.w500,
          color: scheme.onSurfaceVariant,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: scheme.primary),
      chipTheme: ChipThemeData(
        side: BorderSide(color: scheme.outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Brand.radiusSmall)),
        labelStyle: const TextStyle(fontFamily: Brand.fontFamily, fontWeight: FontWeight.w600),
      ),
    );
  }
}
