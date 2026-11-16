import 'package:flutter/material.dart';

import '../theme/brand.dart';

enum MessageKind { info, success, warning, error }

/// A tinted banner for form errors, notices and confirmations.
class InlineMessage extends StatelessWidget {
  const InlineMessage(this.text, {super.key, this.kind = MessageKind.info, this.actionLabel, this.onAction});

  final String text;
  final MessageKind kind;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    late final Color c;
    late final IconData icon;
    switch (kind) {
      case MessageKind.info:
        c = Brand.info;
        icon = Icons.info_outline_rounded;
        break;
      case MessageKind.success:
        c = Brand.success;
        icon = Icons.check_circle_outline_rounded;
        break;
      case MessageKind.warning:
        c = Brand.warning;
        icon = Icons.warning_amber_rounded;
        break;
      case MessageKind.error:
        c = Brand.danger;
        icon = Icons.error_outline_rounded;
        break;
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: c.op(0.09),
        borderRadius: BorderRadius.circular(Brand.radiusSmall + 2),
        border: Border.all(color: c.op(0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 19, color: c),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(text, style: TextStyle(fontSize: 13.5, height: 1.4, fontWeight: FontWeight.w600, color: context.inkColor)),
                if (actionLabel != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: GestureDetector(
                      onTap: onAction,
                      child: Text(
                        actionLabel!,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: c, decoration: TextDecoration.underline),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
