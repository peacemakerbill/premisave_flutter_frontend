import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/brand.dart';
import '../../core/theme/palette.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/country.dart';

/// Phone number box with a country code button. The user picks the country and types the number, and
/// [controller] receives the full international number, for example +254712345678, ready to send.
/// Pasting or typing a full number that starts with + or 00 switches the country by itself.
class PhoneField extends StatefulWidget {
  const PhoneField({
    super.key,
    required this.controller,
    this.label = 'Phone number',
    this.optional = false,
    this.countryCode,
    this.errorText,
    this.helper,
    this.validator,
    this.autofillHints,
    this.textInputAction = TextInputAction.next,
  });

  /// Holds the international number. Reading and writing it from outside works as with any text field.
  final TextEditingController controller;
  final String label;
  final bool optional;

  /// ISO country code used for the prefix while the user has not chosen one, for example the country picked
  /// elsewhere on the same form.
  final String? countryCode;
  final String? errorText;
  final String? helper;

  /// Receives the full international number, or an empty string.
  final String? Function(String?)? validator;
  final Iterable<String>? autofillHints;
  final TextInputAction textInputAction;

  /// A typical mobile number in each country, shown as the hint without the calling code.
  static const Map<String, String> examples = <String, String>{
    'KE': '712 345 678', 'US': '201 555 0123', 'CA': '506 234 5678', 'GB': '7400 123456', 'IE': '85 012 3456',
    'NG': '802 123 4567', 'GH': '23 123 4567', 'UG': '712 345 678', 'TZ': '621 234 567', 'RW': '720 123 456',
    'ET': '91 123 4567', 'ZA': '71 123 4567', 'EG': '100 123 4567', 'MA': '650 123456', 'SN': '70 123 45 67',
    'CI': '01 23 45 67 89', 'CM': '6 71 23 45 67', 'ZM': '97 1234567', 'ZW': '71 234 5678', 'MW': '991 23 45 67',
    'MZ': '82 123 4567', 'AO': '923 123 456', 'IN': '81234 56789', 'PK': '301 2345678', 'BD': '1812 345678',
    'LK': '71 234 5678', 'NP': '984 1234567', 'CN': '131 2345 6789', 'JP': '90 1234 5678', 'KR': '10 1234 5678',
    'SG': '8123 4567', 'MY': '12 345 6789', 'ID': '812 3456 7890', 'PH': '905 123 4567', 'TH': '81 234 5678',
    'VN': '91 234 56 78', 'AU': '412 345 678', 'NZ': '21 123 4567', 'AE': '50 123 4567', 'SA': '51 234 5678',
    'QA': '3312 3456', 'IL': '50 234 5678', 'TR': '501 234 56 78', 'DE': '1512 3456789', 'FR': '6 12 34 56 78',
    'ES': '612 34 56 78', 'IT': '312 345 6789', 'PT': '912 345 678', 'NL': '6 12345678', 'BE': '470 12 34 56',
    'CH': '78 123 45 67', 'AT': '664 123456', 'SE': '70 123 45 67', 'NO': '406 12 345', 'DK': '32 12 34 56',
    'FI': '41 2345678', 'PL': '512 345 678', 'GR': '691 234 5678', 'RU': '912 345 67 89', 'UA': '50 123 4567',
    'BR': '11 91234 5678', 'MX': '221 234 5678', 'AR': '11 2345 6789', 'CO': '321 1234567', 'CL': '9 6123 4567',
    'PE': '912 345 678',
  };

  @override
  State<PhoneField> createState() => _PhoneFieldState();
}

class _PhoneFieldState extends State<PhoneField> {
  final TextEditingController _national = TextEditingController();
  late Country _country;
  bool _chosen = false;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _country = _defaultCountry();
    _load(widget.controller.text);
    widget.controller.addListener(_onOutside);
  }

  @override
  void didUpdateWidget(PhoneField old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onOutside);
      widget.controller.addListener(_onOutside);
    }
    // Follow the country picked elsewhere on the form until the user chooses a prefix or types a number.
    if (widget.countryCode != old.countryCode && !_chosen && _national.text.trim().isEmpty) {
      final c = Country.byCode(widget.countryCode);
      if (c != null && c.dial.isNotEmpty) setState(() => _country = c);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onOutside);
    _national.dispose();
    super.dispose();
  }

  Country _defaultCountry() {
    final fromForm = Country.byCode(widget.countryCode);
    if (fromForm != null && fromForm.dial.isNotEmpty) return fromForm;
    final fromDevice = Country.byCode(WidgetsBinding.instance.platformDispatcher.locale.countryCode);
    if (fromDevice != null && fromDevice.dial.isNotEmpty) return fromDevice;
    return Country.byCode('US')!;
  }

  /// Shows [text] in the boxes: the country from its calling code and the rest as the number.
  void _load(String text) {
    final raw = text.trim();
    if (raw.isEmpty) {
      _national.text = '';
      return;
    }
    final parts = Country.splitInternational(raw);
    if (parts == null) {
      _national.text = raw;
      return;
    }
    var country = parts.country;
    final preferred = Country.byCode(widget.countryCode);
    if (preferred != null && preferred.dial == country.dial) country = preferred;
    _country = country;
    _national.text = parts.national;
  }

  String _compose() {
    var digits = _national.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return '';
    // A leading 0 is the local dialling prefix. It is dropped, except in Italy where it belongs to the number.
    if (_country.dial != '39') digits = digits.replaceFirst(RegExp(r'^0+'), '');
    return '+${_country.dial}$digits';
  }

  void _emit() {
    final value = _compose();
    if (widget.controller.text == value) return;
    _syncing = true;
    widget.controller.text = value;
    _syncing = false;
  }

  /// The number was changed from outside, for example cleared or filled from the saved profile.
  void _onOutside() {
    if (_syncing || !mounted) return;
    if (widget.controller.text == _compose()) return;
    setState(() => _load(widget.controller.text));
  }

  void _typed(String text) {
    final t = text.trimLeft();
    if (t.startsWith('+') || t.startsWith('00')) {
      final parts = Country.splitInternational(t);
      if (parts != null && parts.national.isNotEmpty) {
        _chosen = true;
        _country = parts.country;
        _national.value = TextEditingValue(
          text: parts.national,
          selection: TextSelection.collapsed(offset: parts.national.length),
        );
      }
    }
    _emit();
    setState(() {});
  }

  Future<void> _choose() async {
    final picked = await showCenteredSheet<Country>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _DialSheet(current: _country),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _country = picked;
      _chosen = true;
    });
    _emit();
  }

  /// The number as it will be saved, with a space after the calling code.
  String get _preview {
    final full = _compose();
    return full.isEmpty ? '' : '+${_country.dial} ${full.substring(_country.dial.length + 1)}';
  }

  @override
  Widget build(BuildContext context) {
    final preview = _preview;
    return PTextField(
      label: widget.label,
      controller: _national,
      optional: widget.optional,
      hint: PhoneField.examples[_country.code] ?? 'Phone number',
      keyboardType: TextInputType.phone,
      textInputAction: widget.textInputAction,
      autofillHints: widget.autofillHints,
      errorText: widget.errorText,
      helper: preview.isEmpty ? widget.helper : 'Saved as $preview',
      validator: (_) => widget.validator?.call(_compose()),
      inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s().\-]'))],
      onChanged: _typed,
      prefixWidget: _DialButton(country: _country, onTap: _choose),
    );
  }
}

class _DialButton extends StatelessWidget {
  const _DialButton({required this.country, required this.onTap});

  final Country country;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Semantics(
        button: true,
        label: 'Country code ${country.dialLabel}, ${country.name}. Tap to change.',
        child: InkWell(
          borderRadius: BorderRadius.circular(context.radius(Brand.radiusSmall)),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(country.flag, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 6),
                Text(country.dialLabel, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                Icon(Icons.expand_more_rounded, size: 18, color: context.mutedColor),
                const SizedBox(width: 6),
                Container(width: 1, height: 22, color: context.pal.line2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Searchable list of countries with their calling codes.
class _DialSheet extends StatefulWidget {
  const _DialSheet({required this.current});

  final Country current;

  @override
  State<_DialSheet> createState() => _DialSheetState();
}

class _DialSheetState extends State<_DialSheet> {
  late final List<Country> _all = <Country>[
    for (final c in Country.all)
      if (c.dial.isNotEmpty) c,
  ]..sort((a, b) => Country.fold(a.name).compareTo(Country.fold(b.name)));

  String _q = '';

  bool _matches(Country c, String q) {
    if (q.isEmpty) return true;
    if (Country.fold(c.name).contains(q) || c.code.toLowerCase() == q) return true;
    for (final a in c.aliases) {
      if (Country.fold(a).contains(q)) return true;
    }
    final digits = q.replaceAll('+', '');
    return digits.isNotEmpty && RegExp(r'^[0-9]+$').hasMatch(digits) && c.dial.startsWith(digits);
  }

  @override
  Widget build(BuildContext context) {
    final q = Country.fold(_q);
    final items = _all.where((c) => _matches(c, q)).toList();
    final pal = context.pal;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 8, 8),
              child: Row(
                children: <Widget>[
                  const Expanded(child: Text('Country code', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800))),
                  IconButton(tooltip: 'Close', icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.of(context).pop()),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: TextField(
                onChanged: (v) => setState(() => _q = v),
                decoration: InputDecoration(
                  hintText: 'Search a country or code, such as Kenya or 254',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  isDense: true,
                  filled: true,
                  fillColor: context.surfaceColor,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(context.radius(Brand.radiusSmall + 2)),
                    borderSide: BorderSide(color: pal.line2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(context.radius(Brand.radiusSmall + 2)),
                    borderSide: BorderSide(color: pal.line2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(context.radius(Brand.radiusSmall + 2)),
                    borderSide: BorderSide(color: pal.accent, width: 1.8),
                  ),
                ),
              ),
            ),
            Flexible(
              child: items.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text('No matching country', style: TextStyle(color: context.mutedColor)),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: items.length,
                      itemBuilder: (context, i) {
                        final c = items[i];
                        final selected = c.code == widget.current.code;
                        return ListTile(
                          leading: Text(c.flag, style: const TextStyle(fontSize: 24)),
                          title: Text(c.name, style: TextStyle(fontWeight: selected ? FontWeight.w800 : FontWeight.w500)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(c.dialLabel, style: TextStyle(fontWeight: FontWeight.w700, color: context.mutedColor)),
                              if (selected) ...<Widget>[
                                const SizedBox(width: 8),
                                Icon(Icons.check_rounded, color: pal.accent),
                              ],
                            ],
                          ),
                          onTap: () => Navigator.of(context).pop(c),
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
