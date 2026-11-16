import 'package:flutter/material.dart';

import '../../core/theme/brand.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/country.dart';
import 'place_widgets.dart';

/// Country box with suggestions. Start typing and pick from the list, or keep what you typed.
/// The text stays in [controller], so it saves exactly like a normal text field.
class CountryField extends StatefulWidget {
  const CountryField({
    super.key,
    required this.controller,
    this.label = 'Country',
    this.optional = false,
    this.errorText,
    this.helper,
    this.onCountry,
    this.textInputAction = TextInputAction.next,
  });

  final TextEditingController controller;
  final String label;
  final bool optional;
  final String? errorText;
  final String? helper;
  final TextInputAction textInputAction;

  /// Called when the text becomes a known country, and with null when it stops being one.
  final ValueChanged<Country?>? onCountry;

  @override
  State<CountryField> createState() => _CountryFieldState();
}

class _CountryFieldState extends State<CountryField> {
  final FocusNode _focus = FocusNode();
  List<Country> _matches = const <Country>[];
  Country? _known;
  bool _quiet = false;

  @override
  void initState() {
    super.initState();
    _known = Country.byName(widget.controller.text);
    widget.controller.addListener(_onText);
    _focus.addListener(_onFocus);
  }

  @override
  void didUpdateWidget(CountryField old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onText);
      widget.controller.addListener(_onText);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onText);
    _focus.dispose();
    super.dispose();
  }

  void _onFocus() {
    if (mounted) setState(() {});
  }

  void _onText() {
    if (_quiet || !mounted) return;
    final text = widget.controller.text;
    final known = Country.byName(text);
    if (known?.code != _known?.code) {
      _known = known;
      widget.onCountry?.call(known);
    }
    setState(() => _matches = Country.search(text));
  }

  bool get _listVisible {
    final text = widget.controller.text.trim();
    if (!_focus.hasFocus || text.isEmpty || _matches.isEmpty) return false;
    // Hide the list once the text is already one country and nothing else could be meant.
    return !(_matches.length == 1 && Country.byName(text) != null);
  }

  void _pick(Country c) {
    _quiet = true;
    widget.controller.value = TextEditingValue(text: c.name, selection: TextSelection.collapsed(offset: c.name.length));
    _quiet = false;
    setState(() {
      _matches = const <Country>[];
      _known = c;
    });
    widget.onCountry?.call(c);
    _focus.nextFocus();
  }

  void _clear() {
    widget.controller.clear();
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.controller.text.trim();
    final visible = _listVisible;
    final noMatch = _focus.hasFocus && text.isNotEmpty && _matches.isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        PTextField(
          label: widget.label,
          controller: widget.controller,
          focusNode: _focus,
          optional: widget.optional,
          hint: 'Start typing a country',
          prefixIcon: Icons.public_rounded,
          textCapitalization: TextCapitalization.words,
          textInputAction: widget.textInputAction,
          errorText: widget.errorText,
          helper: noMatch ? null : widget.helper,
          onSubmitted: (_) {
            if (visible && Country.byName(text) == null) _pick(_matches.first);
          },
          suffix: text.isEmpty
              ? null
              : IconButton(tooltip: 'Clear', icon: const Icon(Icons.close_rounded, size: 18), onPressed: _clear),
        ),
        if (visible)
          SuggestionPanel(
            maxHeight: 264,
            children: <Widget>[
              for (final c in _matches)
                SuggestionTile(
                  leading: Text(c.flag, style: const TextStyle(fontSize: 21)),
                  title: c.name,
                  onTap: () => _pick(c),
                ),
            ],
          )
        else if (noMatch)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 2),
            child: Text(
              'Not in the list. What you typed will be used as it is.',
              style: TextStyle(fontSize: 12, color: context.mutedColor),
            ),
          ),
      ],
    );
  }
}
