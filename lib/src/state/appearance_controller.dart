import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme/appearance_options.dart';
import '../core/theme/palette.dart';

/// The user's look: a colour theme (or "auto" to follow the device), a font and a corner style.
class Appearance {
  const Appearance({this.themeId = auto, this.fontId = 'premisave', this.cornerId = 'standard'});

  /// Follow the device: Premisave in light mode, Premisave Night in dark mode.
  static const String auto = 'auto';

  final String themeId;
  final String fontId;
  final String cornerId;

  bool get isAuto => AppPalette.byId(themeId) == null;
  FontOption get font => FontOption.byId(fontId);
  CornerOption get corner => CornerOption.byId(cornerId);

  /// The chosen palette, or null while following the device.
  AppPalette? get palette => AppPalette.byId(themeId);

  Appearance copyWith({String? themeId, String? fontId, String? cornerId}) =>
      Appearance(themeId: themeId ?? this.themeId, fontId: fontId ?? this.fontId, cornerId: cornerId ?? this.cornerId);
}

final appearanceProvider = NotifierProvider<AppearanceController, Appearance>(AppearanceController.new);

class AppearanceController extends Notifier<Appearance> {
  static const _kTheme = 'ps_theme';
  static const _kFont = 'ps_font';
  static const _kCorner = 'ps_corner';
  static const _kOldMode = 'ps_theme_mode'; // light, dark or system, from the first version

  @override
  Appearance build() => const Appearance();

  /// Reads the saved look. Call once before the first frame so the app never flashes the wrong theme.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var theme = prefs.getString(_kTheme);
      if (theme == null) {
        switch (prefs.getString(_kOldMode)) {
          case 'light':
            theme = AppPalette.premisave.id;
          case 'dark':
            theme = AppPalette.premisaveNight.id;
        }
      }
      state = Appearance(
        themeId: AppPalette.byId(theme) == null ? Appearance.auto : theme!,
        fontId: FontOption.byId(prefs.getString(_kFont)).id,
        cornerId: CornerOption.byId(prefs.getString(_kCorner)).id,
      );
    } catch (_) {
      // Unreadable storage: keep the defaults.
    }
  }

  Future<void> setTheme(String id) async {
    state = state.copyWith(themeId: id);
    await _save(_kTheme, id);
  }

  Future<void> setFont(String id) async {
    state = state.copyWith(fontId: id);
    await _save(_kFont, id);
  }

  Future<void> setCorner(String id) async {
    state = state.copyWith(cornerId: id);
    await _save(_kCorner, id);
  }

  /// Steps through the themes, like the T key in the console. [step] is 1 or -1.
  Future<void> cycleTheme(int step) async {
    const all = AppPalette.all;
    final i = all.indexWhere((p) => p.id == state.themeId);
    final next = all[((i < 0 ? 0 : i) + step + all.length) % all.length];
    await setTheme(next.id);
  }

  Future<void> reset() async {
    state = const Appearance();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kTheme);
      await prefs.remove(_kFont);
      await prefs.remove(_kCorner);
    } catch (_) {}
  }

  Future<void> _save(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } catch (_) {}
  }
}
