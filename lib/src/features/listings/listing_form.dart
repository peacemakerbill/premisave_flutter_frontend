import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart' show ImagePicker;

import '../../core/network/api_exception.dart';
import '../../core/theme/brand.dart';
import '../../core/theme/palette.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/country.dart';
import '../../data/models/place.dart';
import '../../data/repositories/messenger_repository.dart' show LocalFile;
import '../../state/providers.dart';
import '../../state/service_providers.dart';
import '../places/address_search_field.dart';
import '../places/country_field.dart';
import '../shared/service_widgets.dart';

/// The most photos a listing can have, and the most the listing service accepts in one request.
const int maxListingPhotos = 20;
const int _maxPhotoBytes = 10 * 1024 * 1024;
const int _maxTotalBytes = 40 * 1024 * 1024;

const List<PChoice<String>> _categories = <PChoice<String>>[
  PChoice<String>('SHORT_TERM_RENTAL', 'Short stay', description: 'Booked by the night, like a holiday home'),
  PChoice<String>('LONG_TERM_RENTAL', 'Long term rental', description: 'Rented to a tenant by the month'),
  PChoice<String>('HOUSE_SALE', 'House for sale', description: 'One time sale price'),
  PChoice<String>('LAND_SALE', 'Land for sale', description: 'One time sale price'),
  PChoice<String>('LEASE', 'Lease', description: 'A fixed term lease with a deposit'),
];

const List<PChoice<String>> _policies = <PChoice<String>>[
  PChoice<String>('FLEXIBLE', 'Flexible', description: 'Full refund close to check in'),
  PChoice<String>('MODERATE', 'Moderate', description: 'Partial refund close to check in'),
  PChoice<String>('STRICT', 'Strict', description: 'Little or no refund close to check in'),
];

/// Create a listing for the listing service: its category, price, place, the details that category needs and photos.
/// A new listing is reviewed by Premisave before the public can see it.
class ListingFormSheet extends ConsumerStatefulWidget {
  /// [existing] is the listing as the service sent it. When given, the form edits that listing instead of creating one.
  const ListingFormSheet({super.key, this.existing});

  final Map<String, dynamic>? existing;

  @override
  ConsumerState<ListingFormSheet> createState() => _ListingFormSheetState();
}

class _ListingFormSheetState extends ConsumerState<ListingFormSheet> {
  final Map<String, TextEditingController> _c = <String, TextEditingController>{};
  final List<LocalFile> _photos = <LocalFile>[];
  final Map<String, bool> _flags = <String, bool>{};
  String _category = 'SHORT_TERM_RENTAL';
  String? _policy;
  bool _busy = false;
  String? _error;

  /// Where the address search put the listing on the map. Sent with the listing so it can be found by area.
  double? _lat;
  double? _lng;
  String? _countryCode;

  bool get _editing => widget.existing != null;

  String get _listingId => (widget.existing?['id'] ?? widget.existing?['listingId'] ?? '').toString();

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e == null) return;
    _category = (e['category'] ?? _category).toString();
    for (final key in const <String>[
      'title', 'description', 'city', 'country', 'address', 'pricePerNight', 'pricePerDay', 'price', 'maxGuests', 'bedrooms',
      'bathrooms', 'minLeaseMonths', 'tenantRequirements', 'propertyType', 'floors', 'plotSize', 'sizeInAcres', 'landUseType',
      'depositAmount', 'leaseDurationMonths', 'leaseTerms',
    ]) {
      final v = e[key];
      if (v != null) _ctl(key).text = _plain(v);
    }
    final lat = e['latitude'];
    final lng = e['longitude'];
    if (lat is num && lng is num) {
      _lat = lat.toDouble();
      _lng = lng.toDouble();
    }
    _countryCode = Country.byName(_val('country'))?.code;
    final amenities = e['amenities'];
    if (amenities is List) _ctl('amenities').text = amenities.join(', ');
    for (final key in const <String>['hasWifi', 'hasKitchen', 'furnished', 'hasGarage', 'hasTitleDeed', 'renewable']) {
      if (e[key] is bool) _flags[key] = e[key] as bool;
    }
    final policy = e['cancellationPolicy']?.toString();
    if (policy != null && _policies.any((p) => p.value == policy)) _policy = policy;
  }

  /// 120.0 reads as 120 in a text box.
  String _plain(Object v) {
    if (v is double && v == v.roundToDouble()) return v.toInt().toString();
    return v.toString();
  }

  TextEditingController _ctl(String key) => _c.putIfAbsent(key, TextEditingController.new);

  String _val(String key) => (_c[key]?.text ?? '').trim();

  bool _flag(String key) => _flags[key] ?? false;

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// A place was chosen in the address box: fill the city and country from it and keep its map position.
  void _placeChosen(Place p) {
    final line = p.streetLine.isNotEmpty ? p.streetLine : (p.isBare ? '' : p.title);
    if (line.isNotEmpty) _ctl('address').text = line;
    final town = p.city ?? p.district;
    if (town != null && town.isNotEmpty) _ctl('city').text = town;
    final country = p.country;
    if (country != null && country.isNotEmpty) _ctl('country').text = country;
    setState(() {
      _lat = p.latitude;
      _lng = p.longitude;
      _countryCode = p.countryCode ?? _countryCode;
    });
  }

  Widget _field(String key, String label, {TextInputType? keyboard, String? hint, bool optional = false, int maxLines = 1, IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: PTextField(
        label: label,
        controller: _ctl(key),
        keyboardType: keyboard,
        hint: hint,
        optional: optional,
        maxLines: maxLines,
        minLines: maxLines > 1 ? 3 : null,
        prefixIcon: icon,
        textCapitalization: maxLines > 1 || keyboard == null ? TextCapitalization.sentences : TextCapitalization.none,
      ),
    );
  }

  Widget _number(String key, String label, {bool optional = true, bool decimal = false, String? hint, IconData? icon}) {
    return _field(key, label, keyboard: TextInputType.numberWithOptions(decimal: decimal), optional: optional, hint: hint, icon: icon);
  }

  Widget _switch(String key, String label) {
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(label, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)),
      value: _flag(key),
      onChanged: _busy ? null : (v) => setState(() => _flags[key] = v),
    );
  }

  Future<void> _pickPhotos() async {
    try {
      final picked = await ImagePicker().pickMultiImage(imageQuality: 88, maxWidth: 2400);
      if (picked.isEmpty) return;
      final added = <LocalFile>[];
      var skipped = 0;
      for (final x in picked) {
        if (_photos.length + added.length >= maxListingPhotos) {
          skipped++;
          continue;
        }
        final bytes = await x.readAsBytes();
        if (bytes.length > _maxPhotoBytes) {
          skipped++;
          continue;
        }
        added.add(LocalFile(name: x.name, bytes: bytes, size: bytes.length));
      }
      if (!mounted) return;
      setState(() {
        _photos.addAll(added);
        _error = skipped == 0 ? null : '$skipped ${skipped == 1 ? 'photo was' : 'photos were'} skipped. Each photo must be under 10 MB and a listing can have at most $maxListingPhotos.';
      });
    } catch (e) {
      if (mounted) setState(() => _error = ApiException.from(e).message);
    }
  }

  /// The details the listing service expects as JSON, or an error sentence when something is missing.
  ({Map<String, dynamic>? details, String? error}) _collect() {
    String? bad;
    double? money(String key, String label, {bool required = true}) {
      final raw = _val(key);
      if (raw.isEmpty) {
        if (required) bad ??= 'Enter the $label.';
        return null;
      }
      final v = parseAmount(raw);
      if (v == null) bad ??= 'The $label must be a number above zero.';
      return v;
    }

    int? whole(String key, String label) {
      final raw = _val(key);
      if (raw.isEmpty) return null;
      final v = int.tryParse(raw);
      if (v == null || v < 0) bad ??= 'The $label must be a whole number.';
      return v;
    }

    double? decimal(String key, String label) {
      final raw = _val(key);
      if (raw.isEmpty) return null;
      final v = double.tryParse(raw);
      if (v == null || v <= 0) bad ??= 'The $label must be a number above zero.';
      return v;
    }

    if (_val('title').isEmpty) return (details: null, error: 'Give the listing a title.');
    if (_val('description').isEmpty) return (details: null, error: 'Add a description.');

    final d = <String, dynamic>{
      'title': _val('title'),
      'description': _val('description'),
      'category': _category,
      'city': _val('city'),
      'country': _val('country'),
      'address': _val('address'),
      if (_lat != null && _lng != null) 'latitude': _lat,
      if (_lat != null && _lng != null) 'longitude': _lng,
    };

    switch (_category) {
      case 'SHORT_TERM_RENTAL':
        final night = money('pricePerNight', 'price per night', required: false);
        final day = money('pricePerDay', 'price per day', required: false);
        if (night == null && day == null && bad == null) bad = 'Enter a price per night or a price per day.';
        d['pricePerNight'] = night;
        d['pricePerDay'] = day;
        d['maxGuests'] = whole('maxGuests', 'number of guests');
        d['bedrooms'] = whole('bedrooms', 'number of bedrooms');
        d['bathrooms'] = whole('bathrooms', 'number of bathrooms');
        d['hasWifi'] = _flag('hasWifi');
        d['hasKitchen'] = _flag('hasKitchen');
        d['amenities'] = _val('amenities').split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
        d['cancellationPolicy'] = _policy;
        break;
      case 'LONG_TERM_RENTAL':
        d['price'] = money('price', 'monthly rent');
        d['priceUnit'] = 'PER_MONTH';
        d['bedrooms'] = whole('bedrooms', 'number of bedrooms');
        d['bathrooms'] = whole('bathrooms', 'number of bathrooms');
        d['minLeaseMonths'] = whole('minLeaseMonths', 'minimum lease in months');
        d['furnished'] = _flag('furnished');
        d['tenantRequirements'] = _val('tenantRequirements');
        break;
      case 'HOUSE_SALE':
        d['price'] = money('price', 'sale price');
        d['priceUnit'] = 'TOTAL';
        d['bedrooms'] = whole('bedrooms', 'number of bedrooms');
        d['bathrooms'] = whole('bathrooms', 'number of bathrooms');
        d['floors'] = whole('floors', 'number of floors');
        d['plotSize'] = decimal('plotSize', 'plot size');
        d['hasGarage'] = _flag('hasGarage');
        d['propertyType'] = _val('propertyType');
        break;
      case 'LAND_SALE':
        d['price'] = money('price', 'sale price');
        d['priceUnit'] = 'TOTAL';
        d['sizeInAcres'] = decimal('sizeInAcres', 'size in acres');
        d['landUseType'] = _val('landUseType');
        d['hasTitleDeed'] = _flag('hasTitleDeed');
        break;
      case 'LEASE':
        d['price'] = money('price', 'monthly price');
        d['priceUnit'] = 'PER_MONTH';
        d['leaseDurationMonths'] = whole('leaseDurationMonths', 'lease length in months');
        d['depositAmount'] = money('depositAmount', 'deposit', required: false);
        d['renewable'] = _flag('renewable');
        d['leaseTerms'] = _val('leaseTerms');
        break;
    }
    if (bad != null) return (details: null, error: bad);
    // Leave out what was not filled in, so the service applies its own defaults.
    d.removeWhere((k, v) => v == null || (v is String && v.isEmpty) || (v is List && v.isEmpty));
    return (details: d, error: null);
  }

  Future<void> _submit() async {
    final result = _collect();
    if (result.error != null) {
      setState(() => _error = result.error);
      return;
    }
    final total = _photos.fold<int>(0, (s, p) => s + p.size);
    if (total > _maxTotalBytes) {
      setState(() => _error = 'The photos add up to ${formatBytes(total)}. Keep them under ${formatBytes(_maxTotalBytes)} in all.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final repo = ref.read(listingRepositoryProvider);
      final String message;
      if (_editing) {
        final changes = Map<String, dynamic>.of(result.details!)..remove('category');
        final text = await repo.updateListing(_listingId, changes, photos: _photos);
        message = text.isEmpty ? 'Listing updated' : text;
      } else {
        message = (await repo.createListing(result.details!, _photos)).message;
      }
      ref.invalidate(myListingsProvider);
      if (!mounted) return;
      Navigator.of(context).pop(true);
      showToast(context, message);
    } catch (e) {
      if (mounted) setState(() => _error = ApiException.from(e).message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  List<Widget> _details() {
    switch (_category) {
      case 'SHORT_TERM_RENTAL':
        return <Widget>[
          _number('pricePerNight', 'Price per night (USD)', decimal: true, hint: 'Fill this or the price per day', icon: Icons.payments_outlined),
          _number('pricePerDay', 'Price per day (USD)', decimal: true),
          _number('maxGuests', 'Most guests'),
          _number('bedrooms', 'Bedrooms'),
          _number('bathrooms', 'Bathrooms'),
          _switch('hasWifi', 'Wi-Fi'),
          _switch('hasKitchen', 'Kitchen'),
          const SizedBox(height: 8),
          _field('amenities', 'Other amenities', optional: true, hint: 'Pool, parking, garden', icon: Icons.checklist_rounded),
          PSelectField<String>(
            label: 'Cancellation policy',
            options: _policies,
            value: _policy,
            optional: true,
            hint: 'Use the default policy',
            onChanged: (v) => setState(() => _policy = v),
          ),
          const SizedBox(height: 14),
        ];
      case 'LONG_TERM_RENTAL':
        return <Widget>[
          _number('price', 'Rent per month (USD)', optional: false, decimal: true, icon: Icons.payments_outlined),
          _number('bedrooms', 'Bedrooms'),
          _number('bathrooms', 'Bathrooms'),
          _number('minLeaseMonths', 'Shortest lease (months)'),
          _switch('furnished', 'Furnished'),
          const SizedBox(height: 8),
          _field('tenantRequirements', 'What you need from a tenant', optional: true, maxLines: 3),
        ];
      case 'HOUSE_SALE':
        return <Widget>[
          _number('price', 'Sale price (USD)', optional: false, decimal: true, icon: Icons.payments_outlined),
          _field('propertyType', 'Type of house', optional: true, hint: 'Bungalow, maisonette, villa'),
          _number('bedrooms', 'Bedrooms'),
          _number('bathrooms', 'Bathrooms'),
          _number('floors', 'Floors'),
          _number('plotSize', 'Plot size', decimal: true),
          _switch('hasGarage', 'Garage'),
          const SizedBox(height: 8),
        ];
      case 'LAND_SALE':
        return <Widget>[
          _number('price', 'Sale price (USD)', optional: false, decimal: true, icon: Icons.payments_outlined),
          _number('sizeInAcres', 'Size in acres', decimal: true),
          _field('landUseType', 'Land use', optional: true, hint: 'Residential, farming, commercial'),
          _switch('hasTitleDeed', 'Has a title deed'),
          const SizedBox(height: 8),
        ];
      default:
        return <Widget>[
          _number('price', 'Price per month (USD)', optional: false, decimal: true, icon: Icons.payments_outlined),
          _number('depositAmount', 'Deposit (USD)', decimal: true),
          _number('leaseDurationMonths', 'Lease length (months)'),
          _switch('renewable', 'Can be renewed'),
          const SizedBox(height: 8),
          _field('leaseTerms', 'Lease terms', optional: true, maxLines: 3),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (_editing)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: InlineMessage(
              'This is a ${_categories.firstWhere((c) => c.value == _category, orElse: () => _categories.first).label.toLowerCase()} listing. The kind of listing cannot be changed once it is created.',
              kind: MessageKind.info,
            ),
          )
        else ...<Widget>[
          PSelectField<String>(
            label: 'What are you listing?',
            options: _categories,
            value: _category,
            onChanged: (v) => setState(() {
              if (v != null) _category = v;
            }),
          ),
          const SizedBox(height: 14),
        ],
        _field('title', 'Title', hint: 'Sunny two bedroom apartment in Kilimani', icon: Icons.title_rounded),
        _field('description', 'Description', maxLines: 5),
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: CountryField(controller: _ctl('country'), optional: true, onCountry: (c) => setState(() => _countryCode = c?.code)),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: AddressSearchField(
            label: 'Address',
            controller: _ctl('address'),
            optional: true,
            countryCode: _countryCode,
            mapTitle: 'Choose the location of the listing',
            onPlace: _placeChosen,
          ),
        ),
        _field('city', 'City or town', optional: true, icon: Icons.location_city_outlined),
        ..._details(),
        Text(_editing ? 'Add photos' : 'Photos', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: context.mutedColor)),
        const SizedBox(height: 8),
        _Photos(
          photos: _photos,
          busy: _busy,
          onAdd: _pickPhotos,
          onRemove: (i) => setState(() => _photos.removeAt(i)),
        ),
        const SizedBox(height: 6),
        Text(
          _editing
              ? 'Photos added here join the ones already on the listing. Use Photos in the listing menu to remove, reorder or choose the cover.'
              : 'Up to $maxListingPhotos photos. The first one is the cover. Once it is approved, promote it so clients can find it.',
          style: TextStyle(fontSize: 12.5, height: 1.45, color: pal.ink3),
        ),
        if (_error != null) ...<Widget>[const SizedBox(height: 14), InlineMessage(_error!, kind: MessageKind.error)],
        const SizedBox(height: 18),
        PButton(label: _editing ? 'Save changes' : 'Create listing', icon: _editing ? Icons.save_outlined : Icons.publish_rounded, expand: true, loading: _busy, onPressed: _submit),
      ],
    );
  }
}

class _Photos extends StatelessWidget {
  const _Photos({required this.photos, required this.busy, required this.onAdd, required this.onRemove});

  final List<LocalFile> photos;
  final bool busy;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: <Widget>[
        for (var i = 0; i < photos.length; i++)
          SizedBox(
            width: 84,
            height: 84,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                ClipRRect(
                  borderRadius: BorderRadius.circular(context.radius(10)),
                  child: Image.memory(photos[i].bytes!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: pal.accentSoft)),
                ),
                Positioned(
                  top: 2,
                  right: 2,
                  child: InkWell(
                    onTap: busy ? null : () => onRemove(i),
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                      child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (photos.length < maxListingPhotos)
          InkWell(
            onTap: busy ? null : onAdd,
            borderRadius: BorderRadius.circular(context.radius(10)),
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: pal.accentSoft,
                border: Border.all(color: pal.accent.op(0.35)),
                borderRadius: BorderRadius.circular(context.radius(10)),
              ),
              child: Icon(Icons.add_photo_alternate_outlined, color: pal.accent),
            ),
          ),
      ],
    );
  }
}
