import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/brand.dart';
import '../../core/widgets/widgets.dart';

/// Opens a bottom sheet with a title and a form. The sheet rises above the keyboard.
Future<T?> showFormSheet<T>(
  BuildContext context, {
  required String title,
  String? subtitle,
  required Widget child,
}) {
  return showCenteredSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: context.surfaceColor,
    builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(20, 14, 12, 20 + MediaQuery.of(ctx).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(title, style: ctx.display(size: 19, weight: FontWeight.w800)),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => Navigator.of(ctx).maybePop(),
                      icon: Icon(Icons.close_rounded, size: 21, color: ctx.mutedColor),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      if (subtitle != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(subtitle, style: TextStyle(fontSize: 13.5, height: 1.4, color: ctx.mutedColor)),
                        ),
                      const SizedBox(height: 16),
                      child,
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// One colour for a status word from any of the services.
Color statusColor(String status) {
  switch (status.toUpperCase()) {
    case 'SUCCESS':
    case 'COMPLETED':
    case 'CONFIRMED':
    case 'ACTIVE':
    case 'APPROVED':
    case 'RECEIVED':
    case 'OCCUPIED':
    case 'RENEWED':
      return Brand.success;
    case 'PENDING':
    case 'IN_PROGRESS':
    case 'NEEDS_REVIEW':
    case 'RESERVED':
    case 'DRAFT':
      return Brand.warning;
    case 'FAILED':
    case 'CANCELLED':
    case 'REJECTED':
    case 'SUSPENDED':
    case 'REVOKED':
    case 'TERMINATED':
    case 'EVICTED':
    case 'EXPIRED':
      return Brand.danger;
    default:
      return Brand.info;
  }
}

/// A status word as a coloured pill: PENDING becomes "Pending".
class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    final label = status.isEmpty ? 'Unknown' : '${status[0].toUpperCase()}${status.substring(1).toLowerCase().replaceAll('_', ' ')}';
    return StatusPill(label, color: statusColor(status), dense: true);
  }
}

/// A line of label and value, used inside cards.
class KeyValueLine extends StatelessWidget {
  const KeyValueLine(this.label, this.value, {super.key, this.bold = false});

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(label, style: TextStyle(fontSize: 13, color: context.mutedColor))),
          Text(value, style: TextStyle(fontSize: 13.5, fontWeight: bold ? FontWeight.w800 : FontWeight.w600)),
        ],
      ),
    );
  }
}

/// Copies [text] and says so.
Future<void> copyText(BuildContext context, String text, {String done = 'Copied'}) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (context.mounted) showToast(context, done);
}

/// Reads a money amount typed by a person: "1,500.50" becomes 1500.5. Returns null when it is not a positive number.
double? parseAmount(String text) {
  final v = double.tryParse(text.trim().replaceAll(',', ''));
  if (v == null || v <= 0) return null;
  return v;
}

/// A short note under a screen that says which service it talks to, shown when it cannot be reached.
class ServiceDownHint extends StatelessWidget {
  const ServiceDownHint(this.service, this.address, {super.key});

  final String service;
  final String address;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 4),
      child: Text(
        '$service at $address',
        style: TextStyle(fontSize: 11.5, color: context.mutedColor),
      ),
    );
  }
}
