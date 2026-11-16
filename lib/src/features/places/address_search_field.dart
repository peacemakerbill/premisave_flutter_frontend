import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/brand.dart';
import '../../core/theme/palette.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/country.dart';
import '../../data/models/place.dart';
import '../../state/providers.dart';
import 'map_picker_screen.dart';
import 'place_searcher.dart';
import 'place_widgets.dart';

/// Address box with live suggestions and a "pick on map" button. Type and choose a suggestion, which fills the
/// box and calls [onPlace] with the street, town, region, postcode, country and coordinates. Anything typed by hand
/// stays exactly as typed.
class AddressSearchField extends ConsumerStatefulWidget {
  const AddressSearchField({
    super.key,
    required this.controller,
    required this.onPlace,
    this.label = 'Address',
    this.hint = 'Start typing a street, building or area',
    this.optional = false,
    this.countryCode,
    this.errorText,
    this.helper,
    this.prefixIcon = Icons.home_outlined,
    this.mapTitle = 'Choose location',
    this.fill = AddressFill.street,
    this.textInputAction = TextInputAction.next,
  });

  final TextEditingController controller;

  /// Called after the user picks a suggestion or a point on the map.
  final ValueChanged<Place> onPlace;

  final String label;
  final String hint;
  final bool optional;

  /// Results in this country (ISO code, for example KE) are listed first.
  final String? countryCode;
  final String? errorText;
  final String? helper;
  final IconData prefixIcon;
  final String mapTitle;

  /// What goes into the box when a place is chosen.
  final AddressFill fill;
  final TextInputAction textInputAction;

  @override
  ConsumerState<AddressSearchField> createState() => _AddressSearchFieldState();
}

/// Which text a chosen place writes into the address box.
enum AddressFill {
  /// House number and street, or the place name when there is no street.
  street,

  /// One line with the place, town, region and country.
  summary,
}

class _AddressSearchFieldState extends ConsumerState<AddressSearchField> {
  final FocusNode _focus = FocusNode();
  late final PlaceSearcher _searcher;
  bool _quiet = false;
  bool _resolving = false;
  Place? _picked;

  @override
  void initState() {
    super.initState();
    _searcher = PlaceSearcher(ref.read(placeRepositoryProvider), countryCode: widget.countryCode);
    widget.controller.addListener(_onText);
    _focus.addListener(_onFocus);
  }

  @override
  void didUpdateWidget(AddressSearchField old) {
    super.didUpdateWidget(old);
    _searcher.countryCode = widget.countryCode;
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onText);
      widget.controller.addListener(_onText);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onText);
    _focus.dispose();
    _searcher.dispose();
    super.dispose();
  }

  void _onFocus() {
    if (mounted) setState(() {});
  }

  void _onText() {
    // Only react to typing. Text written by code, such as autofilling from a pick, must not start a search.
    if (_quiet || !_focus.hasFocus) return;
    _searcher.search(widget.controller.text);
  }

  /// The user chose a suggestion. Google suggestions need one more lookup for the coordinates.
  Future<void> _choose(PlaceSuggestion s) async {
    if (_resolving) return;
    final session = _searcher.session;
    setState(() => _resolving = true);
    try {
      final place = await ref.read(placeRepositoryProvider).resolve(s, sessionToken: session);
      if (!mounted) return;
      _searcher.endSession();
      _pick(place);
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _resolving = false);
    }
  }

  void _pick(Place p) {
    final text = widget.fill == AddressFill.summary ? p.summary : (p.streetLine.isNotEmpty ? p.streetLine : p.title);
    _quiet = true;
    widget.controller.value = TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
    _quiet = false;
    _searcher.clear();
    _picked = p;
    widget.onPlace(p);
    _focus.nextFocus();
  }

  Future<void> _openMap() async {
    final typed = widget.controller.text.trim();
    final place = await showMapPicker(
      context,
      title: widget.mapTitle,
      initial: _picked,
      centerOn: typed.length >= 3 ? typed : Country.byCode(widget.countryCode)?.name,
      countryCode: widget.countryCode,
    );
    if (place != null && mounted) _pick(place);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _searcher,
      builder: (context, _) {
        final text = widget.controller.text.trim();
        final open = _focus.hasFocus && text.length >= 3 && (_searcher.loading || _searcher.searched || _searcher.results.isNotEmpty);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            PTextField(
              label: widget.label,
              controller: widget.controller,
              focusNode: _focus,
              optional: widget.optional,
              hint: widget.hint,
              prefixIcon: widget.prefixIcon,
              textCapitalization: TextCapitalization.words,
              textInputAction: widget.textInputAction,
              errorText: widget.errorText,
              helper: widget.helper,
              suffix: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (_searcher.loading || _resolving) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  IconButton(tooltip: 'Pick on map', icon: const Icon(Icons.map_outlined, size: 21), onPressed: _openMap),
                ],
              ),
            ),
            if (open) _panel(context),
          ],
        );
      },
    );
  }

  Widget _panel(BuildContext context) {
    final results = _searcher.results;
    final children = <Widget>[
      if (results.isEmpty && _searcher.loading) const SuggestionNote('Searching', busy: true),
      if (results.isEmpty && !_searcher.loading && _searcher.failed)
        const SuggestionNote('Address search is not available right now. You can keep typing your address or pick it on the map.'),
      if (results.isEmpty && !_searcher.loading && !_searcher.failed)
        const SuggestionNote('No matching places. What you typed will be used as it is.'),
      for (final s in results)
        SuggestionTile(
          leading: Icon(Icons.place_outlined, size: 22, color: context.pal.accent),
          title: s.title,
          subtitle: s.subtitle,
          onTap: () => _choose(s),
        ),
      SuggestionTile(
        leading: Icon(Icons.map_outlined, size: 22, color: context.mutedColor),
        title: 'Choose on the map',
        onTap: _openMap,
      ),
    ];
    return SuggestionPanel(children: children);
  }
}
