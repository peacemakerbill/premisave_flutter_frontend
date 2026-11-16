import 'package:flutter/material.dart';

import '../../../core/theme/palette.dart';

/// How a status or figure should feel on screen. Data classes choose a tone and the widgets turn it into a
/// colour from the current theme, so nothing on an overview hardcodes a colour.
enum OverviewTone {
  good,
  warn,
  bad,
  accent,
  neutral;

  Color color(AppPalette pal) {
    switch (this) {
      case OverviewTone.good:
        return pal.good;
      case OverviewTone.warn:
        return pal.warn;
      case OverviewTone.bad:
        return pal.bad;
      case OverviewTone.accent:
        return pal.accent;
      case OverviewTone.neutral:
        return pal.ink3;
    }
  }
}
