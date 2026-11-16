import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/brand.dart';
import '../utils/formatters.dart';

InputDecoration _decoration(
  BuildContext context, {
  String? hint,
  String? errorText,
  Widget? prefix,
  Widget? suffix,
  String? counter,
}) {
  OutlineInputBorder border(Color c, [double w = 1.2]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(context.radius(Brand.radiusSmall + 2)),
        borderSide: BorderSide(color: c, width: w),
      );
  return InputDecoration(
    hintText: hint,
    errorText: errorText,
    errorMaxLines: 3,
    counterText: counter,
    prefixIcon: prefix,
    suffixIcon: suffix,
    filled: true,
    fillColor: context.surfaceColor,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    hintStyle: TextStyle(color: context.mutedColor.op(0.8), fontWeight: FontWeight.w400),
    border: border(context.borderColor),
    enabledBorder: border(context.borderColor),
    disabledBorder: border(context.borderColor.op(0.6)),
    focusedBorder: border(context.scheme.primary, 1.8),
    errorBorder: border(Brand.danger),
    focusedErrorBorder: border(Brand.danger, 1.8),
  );
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label, {this.optional = false});

  final String label;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Text.rich(
        TextSpan(
          text: label,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.inkColor),
          children: <InlineSpan>[
            if (optional)
              TextSpan(
                text: '  optional',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: context.mutedColor),
              ),
          ],
        ),
      ),
    );
  }
}

/// Text field with its label above it. Set [obscure] for passwords and the eye toggle appears.
class PTextField extends StatefulWidget {
  const PTextField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.validator,
    this.obscure = false,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.onChanged,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.prefixIcon,
    this.suffix,
    this.enabled = true,
    this.readOnly = false,
    this.optional = false,
    this.autofillHints,
    this.focusNode,
    this.errorText,
    this.helper,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.autofocus = false,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final String? Function(String?)? validator;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final int maxLines;
  final int? minLines;
  final int? maxLength;
  final IconData? prefixIcon;
  final Widget? suffix;
  final bool enabled;
  final bool readOnly;
  final bool optional;
  final Iterable<String>? autofillHints;
  final FocusNode? focusNode;
  final String? errorText;
  final String? helper;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final bool autofocus;

  @override
  State<PTextField> createState() => _PTextFieldState();
}

class _PTextFieldState extends State<PTextField> {
  late bool _hidden = widget.obscure;

  @override
  Widget build(BuildContext context) {
    Widget? suffix = widget.suffix;
    if (widget.obscure) {
      suffix = IconButton(
        tooltip: _hidden ? 'Show password' : 'Hide password',
        icon: Icon(_hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20),
        onPressed: () => setState(() => _hidden = !_hidden),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _FieldLabel(widget.label, optional: widget.optional),
        TextFormField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          validator: widget.validator,
          obscureText: _hidden,
          enabled: widget.enabled,
          readOnly: widget.readOnly,
          autofocus: widget.autofocus,
          keyboardType: widget.keyboardType ?? (widget.maxLines > 1 ? TextInputType.multiline : null),
          textInputAction: widget.textInputAction,
          onFieldSubmitted: widget.onSubmitted,
          onChanged: widget.onChanged,
          maxLines: widget.obscure ? 1 : widget.maxLines,
          minLines: widget.minLines,
          maxLength: widget.maxLength,
          autofillHints: widget.autofillHints,
          textCapitalization: widget.textCapitalization,
          inputFormatters: widget.inputFormatters,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          decoration: _decoration(
            context,
            hint: widget.hint,
            errorText: widget.errorText,
            counter: widget.maxLength == null ? null : '',
            prefix: widget.prefixIcon == null ? null : Icon(widget.prefixIcon, size: 20),
            suffix: suffix,
          ),
        ),
        if (widget.helper != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 2),
            child: Text(widget.helper!, style: TextStyle(fontSize: 12, color: context.mutedColor)),
          ),
      ],
    );
  }
}

class PChoice<T> {
  const PChoice(this.value, this.label, {this.description});

  final T value;
  final String label;
  final String? description;
}

/// A field that opens a bottom sheet to pick one option. Used in place of a dropdown
/// so long lists (countries) can be searched and work well with a thumb.
class PSelectField<T> extends StatelessWidget {
  const PSelectField({
    super.key,
    required this.label,
    required this.options,
    required this.onChanged,
    this.value,
    this.hint = 'Select',
    this.errorText,
    this.enabled = true,
    this.optional = false,
    this.searchable = false,
  });

  final String label;
  final List<PChoice<T>> options;
  final T? value;
  final ValueChanged<T?> onChanged;
  final String hint;
  final String? errorText;
  final bool enabled;
  final bool optional;
  final bool searchable;

  @override
  Widget build(BuildContext context) {
    PChoice<T>? selected;
    for (final o in options) {
      if (o.value == value) selected = o;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _FieldLabel(label, optional: optional),
        InkWell(
          borderRadius: BorderRadius.circular(context.radius(Brand.radiusSmall + 2)),
          onTap: enabled ? () => _open(context) : null,
          child: InputDecorator(
            isEmpty: selected == null,
            decoration: _decoration(
              context,
              errorText: errorText,
              suffix: const Icon(Icons.expand_more_rounded),
            ),
            child: Text(
              selected?.label ?? hint,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: selected == null ? context.mutedColor.op(0.8) : context.inkColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _open(BuildContext context) async {
    final result = await showModalBottomSheet<_Picked<T>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => _PickerSheet<T>(
        title: label,
        options: options,
        value: value,
        searchable: searchable || options.length > 12,
        clearable: optional,
      ),
    );
    if (result != null) onChanged(result.value);
  }
}

class _Picked<T> {
  const _Picked(this.value);
  final T? value;
}

class _PickerSheet<T> extends StatefulWidget {
  const _PickerSheet({
    required this.title,
    required this.options,
    required this.value,
    required this.searchable,
    required this.clearable,
  });

  final String title;
  final List<PChoice<T>> options;
  final T? value;
  final bool searchable;
  final bool clearable;

  @override
  State<_PickerSheet<T>> createState() => _PickerSheetState<T>();
}

class _PickerSheetState<T> extends State<_PickerSheet<T>> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final items = widget.options
        .where((o) => _q.isEmpty || o.label.toLowerCase().contains(_q.toLowerCase()))
        .toList();
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 12, 8),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(widget.title,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                  ),
                  if (widget.clearable && widget.value != null)
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(_Picked<T>(null)),
                      child: const Text('Clear'),
                    ),
                ],
              ),
            ),
            if (widget.searchable)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: TextField(
                  autofocus: false,
                  onChanged: (v) => setState(() => _q = v),
                  decoration: _decoration(context, hint: 'Search', prefix: const Icon(Icons.search, size: 20)),
                ),
              ),
            Flexible(
              child: items.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text('No matches', style: TextStyle(color: context.mutedColor)),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: items.length,
                      itemBuilder: (ctx, i) {
                        final o = items[i];
                        final isSel = o.value == widget.value;
                        return ListTile(
                          title: Text(o.label, style: TextStyle(fontWeight: isSel ? FontWeight.w800 : FontWeight.w500)),
                          subtitle: o.description == null
                              ? null
                              : Text(o.description!, maxLines: 2, overflow: TextOverflow.ellipsis),
                          trailing: isSel ? Icon(Icons.check_rounded, color: context.scheme.primary) : null,
                          onTap: () => Navigator.of(context).pop(_Picked<T>(o.value)),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// A field that opens the date picker.
class PDateField extends StatelessWidget {
  const PDateField({
    super.key,
    required this.label,
    required this.onChanged,
    this.value,
    this.errorText,
    this.optional = false,
    this.firstDate,
    this.lastDate,
    this.initialDate,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final String? errorText;
  final bool optional;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final DateTime? initialDate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _FieldLabel(label, optional: optional),
        InkWell(
          borderRadius: BorderRadius.circular(context.radius(Brand.radiusSmall + 2)),
          onTap: () async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate: value ?? initialDate ?? DateTime(now.year - 30, now.month, now.day),
              firstDate: firstDate ?? DateTime(1900),
              lastDate: lastDate ?? DateTime(now.year + 30),
            );
            if (picked != null) onChanged(picked);
          },
          child: InputDecorator(
            isEmpty: value == null,
            decoration: _decoration(
              context,
              errorText: errorText,
              suffix: const Icon(Icons.calendar_today_outlined, size: 18),
            ),
            child: Text(
              value == null ? 'Select a date' : formatDate(value),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: value == null ? context.mutedColor.op(0.8) : context.inkColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
