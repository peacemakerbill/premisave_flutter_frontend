import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import 'service_widgets.dart';

/// The kinds of input a [FieldSpec] can ask for.
enum FieldKind {
  text,
  multiline,
  email,
  phone,
  password,

  /// A decimal number such as an amount. Sent as a number.
  number,

  /// A whole number. Sent as a number.
  integer,

  /// Sent as 2026-11-18.
  date,

  /// A date followed by a time. Sent as 2026-11-18T09:30:00.
  dateTime,

  /// One of [FieldSpec.options]. Sent as the option's key.
  select,

  /// A switch. Always sent.
  toggle,

  /// Any number of [FieldSpec.options]. Sent as a list of keys.
  multiSelect,
}

/// One input of a form. Forms are described as a list of these and turned into a request body by [showResourceForm],
/// so every create, edit and action in the app is built the same way.
///
/// [key] may be dotted: `address.city` becomes `{"address": {"city": ...}}`.
class FieldSpec {
  const FieldSpec(
    this.key,
    this.label, {
    this.kind = FieldKind.text,
    this.required = false,
    this.helper,
    this.hint,
    this.options = const <String, String>{},
    this.maxLength,
    this.clearable = false,
    this.initial,
  });

  final String key;
  final String label;
  final FieldKind kind;
  final bool required;
  final String? helper;
  final String? hint;

  /// For [FieldKind.select] and [FieldKind.multiSelect]: the value sent, and the words shown.
  final Map<String, String> options;
  final int? maxLength;

  /// An empty box sends an empty string when it held text before, so the server clears the field.
  final bool clearable;

  /// Used when the form is opened without a value for this key.
  final Object? initial;
}

/// Reads `a.b.c` out of nested maps.
Object? digValue(Map<String, dynamic> map, String key) {
  Object? current = map;
  for (final part in key.split('.')) {
    if (current is Map && current.containsKey(part)) {
      current = current[part];
    } else {
      return null;
    }
  }
  return current;
}

void _putValue(Map<String, dynamic> target, String key, Object? value) {
  final parts = key.split('.');
  var node = target;
  for (var i = 0; i < parts.length - 1; i++) {
    final next = node[parts[i]];
    if (next is Map<String, dynamic>) {
      node = next;
    } else {
      final created = <String, dynamic>{};
      node[parts[i]] = created;
      node = created;
    }
  }
  node[parts.last] = value;
}

String _dateOnly(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.year}-${two(d.month)}-${two(d.day)}';
}

String _dateTimeLocal(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${_dateOnly(d)}T${two(d.hour)}:${two(d.minute)}:00';
}

/// Opens a form in a bottom sheet. [onSubmit] gets the request body built from the fields and may throw; the message is
/// shown in the form. Returns true when the form was submitted without an error.
Future<bool> showResourceForm(
  BuildContext context, {
  required String title,
  String? subtitle,
  required List<FieldSpec> fields,
  Map<String, dynamic> initial = const <String, dynamic>{},
  String submitLabel = 'Save',
  bool danger = false,
  required Future<void> Function(Map<String, dynamic> body) onSubmit,
}) async {
  final result = await showFormSheet<bool>(
    context,
    title: title,
    subtitle: subtitle,
    child: ResourceForm(fields: fields, initial: initial, submitLabel: submitLabel, danger: danger, onSubmit: onSubmit),
  );
  return result ?? false;
}

class ResourceForm extends StatefulWidget {
  const ResourceForm({
    super.key,
    required this.fields,
    required this.onSubmit,
    this.initial = const <String, dynamic>{},
    this.submitLabel = 'Save',
    this.danger = false,
    this.popOnSuccess = true,
  });

  final List<FieldSpec> fields;
  final Map<String, dynamic> initial;
  final String submitLabel;
  final bool danger;
  final bool popOnSuccess;
  final Future<void> Function(Map<String, dynamic> body) onSubmit;

  @override
  State<ResourceForm> createState() => _ResourceFormState();
}

class _ResourceFormState extends State<ResourceForm> {
  final Map<String, TextEditingController> _text = <String, TextEditingController>{};
  final Map<String, Object?> _value = <String, Object?>{};
  final Map<String, String> _errors = <String, String>{};
  bool _busy = false;
  String? _error;

  static bool _isTyped(FieldKind k) =>
      k == FieldKind.text ||
      k == FieldKind.multiline ||
      k == FieldKind.email ||
      k == FieldKind.phone ||
      k == FieldKind.password ||
      k == FieldKind.number ||
      k == FieldKind.integer;

  @override
  void initState() {
    super.initState();
    for (final f in widget.fields) {
      final start = digValue(widget.initial, f.key) ?? f.initial;
      if (_isTyped(f.kind)) {
        _text[f.key] = TextEditingController(text: start == null ? '' : '$start');
      } else if (f.kind == FieldKind.date || f.kind == FieldKind.dateTime) {
        _value[f.key] = start == null ? null : DateTime.tryParse('$start');
      } else if (f.kind == FieldKind.toggle) {
        _value[f.key] = start == true || '$start'.toLowerCase() == 'true';
      } else if (f.kind == FieldKind.multiSelect) {
        _value[f.key] = start is List ? start.map((e) => '$e').toList() : <String>[];
      } else {
        _value[f.key] = start == null ? null : '$start';
      }
    }
  }

  @override
  void dispose() {
    for (final c in _text.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// Builds the body, or returns null after marking what is wrong.
  Map<String, dynamic>? _build() {
    _errors.clear();
    final body = <String, dynamic>{};
    for (final f in widget.fields) {
      switch (f.kind) {
        case FieldKind.text:
        case FieldKind.multiline:
        case FieldKind.email:
        case FieldKind.phone:
        case FieldKind.password:
          final raw = _text[f.key]!.text;
          final s = f.kind == FieldKind.password ? raw : raw.trim();
          if (s.isEmpty) {
            if (f.required) {
              _errors[f.key] = '${f.label} is required.';
            } else if (f.clearable && digValue(widget.initial, f.key) != null) {
              _putValue(body, f.key, '');
            }
          } else {
            if (f.kind == FieldKind.email && !s.contains('@')) _errors[f.key] = 'Enter a valid email address.';
            _putValue(body, f.key, s);
          }
        case FieldKind.number:
          final s = _text[f.key]!.text.trim().replaceAll(',', '');
          if (s.isEmpty) {
            if (f.required) _errors[f.key] = '${f.label} is required.';
          } else {
            final n = double.tryParse(s);
            if (n == null) {
              _errors[f.key] = 'Enter a number.';
            } else {
              _putValue(body, f.key, n);
            }
          }
        case FieldKind.integer:
          final s = _text[f.key]!.text.trim();
          if (s.isEmpty) {
            if (f.required) _errors[f.key] = '${f.label} is required.';
          } else {
            final n = int.tryParse(s);
            if (n == null) {
              _errors[f.key] = 'Enter a whole number.';
            } else {
              _putValue(body, f.key, n);
            }
          }
        case FieldKind.date:
          final d = _value[f.key] as DateTime?;
          if (d == null) {
            if (f.required) _errors[f.key] = 'Pick a date.';
          } else {
            _putValue(body, f.key, _dateOnly(d));
          }
        case FieldKind.dateTime:
          final d = _value[f.key] as DateTime?;
          if (d == null) {
            if (f.required) _errors[f.key] = 'Pick a date and time.';
          } else {
            _putValue(body, f.key, _dateTimeLocal(d));
          }
        case FieldKind.select:
          final v = _value[f.key] as String?;
          if (v == null || v.isEmpty) {
            if (f.required) _errors[f.key] = 'Choose one.';
          } else {
            _putValue(body, f.key, v);
          }
        case FieldKind.toggle:
          _putValue(body, f.key, _value[f.key] == true);
        case FieldKind.multiSelect:
          final list = (_value[f.key] as List<String>?) ?? <String>[];
          if (list.isEmpty) {
            if (f.required) _errors[f.key] = 'Choose at least one.';
          } else {
            _putValue(body, f.key, list);
          }
      }
    }
    return _errors.isEmpty ? body : null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final body = _build();
    if (body == null) {
      setState(() => _error = null);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onSubmit(body);
      if (mounted && widget.popOnSuccess) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _error = ApiException.from(e).message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  List<PChoice<String>> _choices(FieldSpec f) =>
      <PChoice<String>>[for (final e in f.options.entries) PChoice<String>(e.key, e.value)];

  Widget _input(FieldSpec f) {
    final optional = !f.required;
    switch (f.kind) {
      case FieldKind.text:
      case FieldKind.multiline:
      case FieldKind.email:
      case FieldKind.phone:
      case FieldKind.password:
      case FieldKind.number:
      case FieldKind.integer:
        final numeric = f.kind == FieldKind.number || f.kind == FieldKind.integer;
        return PTextField(
          label: f.label,
          controller: _text[f.key],
          optional: optional,
          helper: f.helper,
          hint: f.hint,
          maxLength: f.maxLength,
          errorText: _errors[f.key],
          obscure: f.kind == FieldKind.password,
          maxLines: f.kind == FieldKind.multiline ? 4 : 1,
          minLines: f.kind == FieldKind.multiline ? 3 : null,
          keyboardType: f.kind == FieldKind.email
              ? TextInputType.emailAddress
              : f.kind == FieldKind.phone
                  ? TextInputType.phone
                  : numeric
                      ? const TextInputType.numberWithOptions(decimal: true)
                      : f.kind == FieldKind.multiline
                          ? TextInputType.multiline
                          : null,
        );
      case FieldKind.date:
        return PDateField(
          label: f.label,
          optional: optional,
          value: _value[f.key] as DateTime?,
          errorText: _errors[f.key],
          firstDate: DateTime(2000),
          lastDate: DateTime(DateTime.now().year + 30),
          initialDate: DateTime.now(),
          onChanged: (d) => setState(() => _value[f.key] = d),
        );
      case FieldKind.dateTime:
        final picked = _value[f.key] as DateTime?;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            PDateField(
              label: f.label,
              optional: optional,
              value: picked,
              errorText: _errors[f.key],
              firstDate: DateTime(2000),
              lastDate: DateTime(DateTime.now().year + 30),
              initialDate: DateTime.now(),
              onChanged: (d) async {
                if (d == null) return;
                final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                if (!mounted) return;
                setState(() => _value[f.key] = DateTime(d.year, d.month, d.day, t?.hour ?? 0, t?.minute ?? 0));
              },
            ),
            if (picked != null)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 4),
                child: Text('At ${formatDateTime(picked).split(', ').last}', style: const TextStyle(fontSize: 12.5)),
              ),
          ],
        );
      case FieldKind.select:
        return PSelectField<String>(
          label: f.label,
          optional: optional,
          value: _value[f.key] as String?,
          options: _choices(f),
          errorText: _errors[f.key],
          searchable: f.options.length > 8,
          onChanged: (v) => setState(() => _value[f.key] = v),
        );
      case FieldKind.toggle:
        return SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text(f.label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          subtitle: f.helper == null ? null : Text(f.helper!),
          value: _value[f.key] == true,
          onChanged: (v) => setState(() => _value[f.key] = v),
        );
      case FieldKind.multiSelect:
        final picked = (_value[f.key] as List<String>?) ?? <String>[];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(f.label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: <Widget>[
                for (final e in f.options.entries)
                  FilterChip(
                    label: Text(e.value),
                    selected: picked.contains(e.key),
                    onSelected: (on) => setState(() {
                      final next = List<String>.of(picked);
                      if (on) {
                        next.add(e.key);
                      } else {
                        next.remove(e.key);
                      }
                      _value[f.key] = next;
                    }),
                  ),
              ],
            ),
            if (_errors[f.key] != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(_errors[f.key]!, style: const TextStyle(fontSize: 12, color: Colors.redAccent)),
              ),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (final f in widget.fields) ...<Widget>[
          _input(f),
          const SizedBox(height: 14),
        ],
        if (_error != null) ...<Widget>[InlineMessage(_error!, kind: MessageKind.error), const SizedBox(height: 14)],
        PButton(
          label: widget.submitLabel,
          kind: widget.danger ? PButtonKind.danger : PButtonKind.primary,
          expand: true,
          loading: _busy,
          onPressed: _submit,
        ),
      ],
    );
  }
}
