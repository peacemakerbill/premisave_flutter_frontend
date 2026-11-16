import 'package:flutter/material.dart';

import '../theme/brand.dart';
import '../theme/palette.dart';

enum PButtonKind { primary, accent, outline, text, danger }

/// Flat brand button with an optional icon and loading state.
class PButton extends StatelessWidget {
  const PButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.kind = PButtonKind.primary,
    this.loading = false,
    this.expand = false,
    this.small = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final PButtonKind kind;
  final bool loading;
  final bool expand;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final enabled = onPressed != null && !loading;

    late final Color bg;
    late final Color fg;
    Color? border;
    switch (kind) {
      case PButtonKind.primary:
        bg = pal.accent;
        fg = pal.accentInk;
        break;
      case PButtonKind.accent:
        bg = pal.accentSoft;
        fg = pal.dark ? pal.accent : pal.ink;
        border = pal.accent.op(0.5);
        break;
      case PButtonKind.danger:
        bg = pal.bad;
        fg = pal.dark ? Colors.black : Colors.white;
        break;
      case PButtonKind.outline:
        bg = Colors.transparent;
        fg = pal.ink;
        border = pal.line2;
        break;
      case PButtonKind.text:
        bg = Colors.transparent;
        fg = pal.accent;
        break;
    }

    final height = small ? 38.0 : 50.0;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(context.radius(small ? 10 : 14)),
      side: border == null ? BorderSide.none : BorderSide(color: border, width: 1.4),
    );
    final textStyle = TextStyle(
      fontSize: small ? 13 : 15,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.1,
    );

    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        if (loading)
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2.2, color: fg),
          )
        else if (icon != null)
          Icon(icon, size: small ? 16 : 19),
        if (loading || icon != null) SizedBox(width: small ? 6 : 9),
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    );

    final style = ButtonStyle(
      minimumSize: WidgetStatePropertyAll<Size>(Size(small ? 0 : 64, height)),
      padding: WidgetStatePropertyAll<EdgeInsetsGeometry>(
        EdgeInsets.symmetric(horizontal: small ? 14 : 22),
      ),
      shape: WidgetStatePropertyAll<OutlinedBorder>(shape),
      textStyle: WidgetStatePropertyAll<TextStyle>(textStyle),
      elevation: const WidgetStatePropertyAll<double>(0),
      backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.disabled) && !loading) {
          return kind == PButtonKind.outline || kind == PButtonKind.text ? Colors.transparent : bg.op(0.4);
        }
        return bg;
      }),
      foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.disabled) && !loading) return fg.op(0.6);
        return fg;
      }),
      overlayColor: WidgetStatePropertyAll<Color>(fg.op(0.1)),
    );

    final VoidCallback? handler = enabled ? onPressed : (loading ? () {} : null);
    final Widget button = (kind == PButtonKind.outline || kind == PButtonKind.text)
        ? TextButton(onPressed: handler, style: style, child: content)
        : FilledButton(onPressed: handler, style: style, child: content);

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}
