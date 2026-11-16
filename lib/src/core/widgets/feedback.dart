import 'package:flutter/material.dart';

import '../network/api_exception.dart';
import '../theme/brand.dart';
import 'p_button.dart';
import 'p_text_field.dart';

void showToast(BuildContext context, String message, {bool error = false}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        backgroundColor: error ? Brand.danger : null,
        content: Row(
          children: <Widget>[
            Icon(error ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded, size: 20, color: error ? Colors.white : Brand.gold),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: TextStyle(color: error ? Colors.white : null))),
          ],
        ),
        duration: Duration(seconds: error ? 5 : 3),
      ),
    );
}

void showApiError(BuildContext context, Object error) =>
    showToast(context, ApiException.from(error).message, error: true);

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  bool danger = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: ctx.surfaceColor,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Brand.radiusLarge)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
      content: Text(message, style: TextStyle(height: 1.45, color: ctx.mutedColor)),
      actions: <Widget>[
        PButton(label: cancelLabel, kind: PButtonKind.text, small: true, onPressed: () => Navigator.of(ctx).pop(false)),
        PButton(
          label: confirmLabel,
          kind: danger ? PButtonKind.danger : PButtonKind.primary,
          small: true,
          onPressed: () => Navigator.of(ctx).pop(true),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Asks for a line of text (a reason, a note). Returns null when cancelled.
Future<String?> promptDialog(
  BuildContext context, {
  required String title,
  required String label,
  String? message,
  String confirmLabel = 'Save',
  bool required = false,
  bool multiline = true,
  bool obscure = false,
  String? initial,
}) {
  return showDialog<String>(
    context: context,
    builder: (ctx) => _PromptDialog(
      title: title,
      label: label,
      message: message,
      confirmLabel: confirmLabel,
      required: required,
      multiline: multiline,
      obscure: obscure,
      initial: initial,
    ),
  );
}

class _PromptDialog extends StatefulWidget {
  const _PromptDialog({
    required this.title,
    required this.label,
    required this.confirmLabel,
    required this.required,
    required this.multiline,
    required this.obscure,
    this.message,
    this.initial,
  });

  final String title;
  final String label;
  final String? message;
  final String confirmLabel;
  final bool required;
  final bool multiline;
  final bool obscure;
  final String? initial;

  @override
  State<_PromptDialog> createState() => _PromptDialogState();
}

class _PromptDialogState extends State<_PromptDialog> {
  late final TextEditingController _c = TextEditingController(text: widget.initial);
  String? _error;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _submit() {
    final v = _c.text.trim();
    if (widget.required && v.isEmpty) {
      setState(() => _error = '${widget.label} is required');
      return;
    }
    Navigator.of(context).pop(v);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: context.surfaceColor,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Brand.radiusLarge)),
      title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (widget.message != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Text(widget.message!, style: TextStyle(height: 1.45, color: context.mutedColor)),
              ),
            PTextField(
              label: widget.label,
              controller: _c,
              autofocus: true,
              obscure: widget.obscure,
              maxLines: widget.multiline ? 4 : 1,
              minLines: widget.multiline ? 2 : null,
              errorText: _error,
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              onSubmitted: widget.multiline ? null : (_) => _submit(),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        PButton(label: 'Cancel', kind: PButtonKind.text, small: true, onPressed: () => Navigator.of(context).pop()),
        PButton(label: widget.confirmLabel, small: true, onPressed: _submit),
      ],
    );
  }
}
