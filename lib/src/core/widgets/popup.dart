import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/brand.dart';

/// Opens [builder] in a card in the middle of the screen, over a dimmed backdrop.
///
/// It takes the same arguments the app used with a bottom sheet, so every pop-up looks the same and sits in the centre.
/// The card is at most [maxWidth] wide, never taller than most of the screen, and moves up with the keyboard. Contents
/// that scroll keep scrolling inside the card. The sheet-only arguments (`isScrollControlled`, `showDragHandle`,
/// `enableDrag`) are accepted and ignored so older call sites keep working.
Future<T?> showCenteredSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  bool useSafeArea = true,
  bool showDragHandle = false,
  bool enableDrag = true,
  bool isDismissible = true,
  bool useRootNavigator = false,
  Color? backgroundColor,
  ShapeBorder? shape,
  BoxConstraints? constraints,
  double maxWidth = 560,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: isDismissible,
    useSafeArea: useSafeArea,
    useRootNavigator: useRootNavigator,
    builder: (ctx) {
      final size = MediaQuery.sizeOf(ctx);
      final width = math.min(constraints?.maxWidth.isFinite == true ? constraints!.maxWidth : maxWidth, size.width - 32);
      return Dialog(
        backgroundColor: backgroundColor ?? ctx.surfaceColor,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        clipBehavior: Clip.antiAlias,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: shape ?? RoundedRectangleBorder(borderRadius: BorderRadius.circular(ctx.radius(Brand.radiusLarge))),
        child: SizedBox(
          width: width,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: math.max(240, size.height * 0.86)),
            child: MediaQuery.removeViewInsets(context: ctx, removeBottom: true, child: Builder(builder: builder)),
          ),
        ),
      );
    },
  );
}
