import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/brand.dart';
import '../../core/theme/palette.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/ids.dart';
import '../../core/utils/money.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/listing_models.dart';
import '../../state/providers.dart';
import '../../state/service_providers.dart';
import '../shared/service_widgets.dart';
import 'listing_widgets.dart';

const List<(String?, String)> _categories = <(String?, String)>[
  (null, 'All'),
  ('SHORT_TERM_RENTAL', 'Short stays'),
  ('LONG_TERM_RENTAL', 'Rentals'),
  ('LEASE', 'Leases'),
  ('HOUSE_SALE', 'Houses'),
  ('LAND_SALE', 'Land'),
];

/// Explore: public listings from the listing service, with search, categories, booking and interest.
class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final TextEditingController _search = TextEditingController();
  Timer? _debounce;
  ListingQuery _query = const ListingQuery();

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onText(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _query = ListingQuery(text: text, category: _query.category));
    });
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(listingSearchProvider(_query));
    return PageBody(
      onRefresh: () async => ref.invalidate(listingSearchProvider(_query)),
      children: <Widget>[
        const PageTitle('Explore', subtitle: 'Stays, rentals, leases and properties for sale.'),
        const SizedBox(height: 8),
        PTextField(
          label: 'Search',
          controller: _search,
          hint: 'City, title or keyword',
          prefixIcon: Icons.search_rounded,
          textInputAction: TextInputAction.search,
          onChanged: _onText,
          onSubmitted: (t) => setState(() => _query = ListingQuery(text: t, category: _query.category)),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: <Widget>[
              for (final (value, label) in _categories)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(label),
                    selected: _query.category == value,
                    onSelected: (_) => setState(() => _query = ListingQuery(text: _query.text, category: value)),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        results.when(
          loading: () => const SkeletonList(count: 3, height: 260, shrink: true, padding: EdgeInsets.zero),
          error: (e, _) => ErrorState(error: e, onRetry: () => ref.invalidate(listingSearchProvider(_query))),
          data: (items) {
            if (items.isEmpty) {
              return const SizedBox(
                height: 320,
                child: EmptyState(icon: Icons.travel_explore_rounded, title: 'Nothing found', message: 'Try another word or category.'),
              );
            }
            return ResponsiveWrap(
              minItemWidth: 280,
              children: <Widget>[
                for (final l in items)
                  ListingCard(
                    listing: l,
                    onTap: () => showFormSheet<void>(context, title: l.title, child: ListingDetail(listing: l)),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// The full listing inside a bottom sheet, with the one action that fits it: book a short stay, or show interest.
class ListingDetail extends ConsumerStatefulWidget {
  const ListingDetail({super.key, required this.listing, this.readOnly = false});

  final ListingModel listing;

  /// Hides the book and interest buttons, for an owner looking at their own listing.
  final bool readOnly;

  @override
  ConsumerState<ListingDetail> createState() => _ListingDetailState();
}

class _ListingDetailState extends ConsumerState<ListingDetail> {
  bool _busy = false;

  /// One key for one attempt. If the call fails or times out and the person tries the same dates again, the same
  /// key goes out, so the server returns the first booking instead of making a second. Other dates get a new key.
  String? _keyFor;
  String? _key;

  String _bookingKey(String signature) {
    if (_keyFor != signature || _key == null) {
      _keyFor = signature;
      _key = newIdempotencyKey();
    }
    return _key!;
  }

  ListingModel get l => widget.listing;

  Future<void> _book() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year, now.month, now.day).add(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
      helpText: 'Choose your dates',
    );
    if (range == null || !mounted) return;
    final nights = range.end.difference(range.start).inDays;
    if (nights < 1) {
      showToast(context, 'Pick at least one night.', error: true);
      return;
    }
    final rate = l.headlinePrice;
    final unit = l.pricePerNight != null || l.priceUnit == 'PER_NIGHT' ? 'PER_NIGHT' : 'PER_DAY';
    final estimate = rate == null ? null : rate * nights;
    final ok = await confirmDialog(
      context,
      title: 'Book ${plural(nights, 'night')}?',
      message: '${formatDate(range.start)} to ${formatDate(range.end)}.'
          '${estimate == null ? '' : ' About ${formatMoney(estimate, l.currency)}, held until check in.'}'
          ' The amount is taken from your wallet.',
      confirmLabel: 'Book and pay',
    );
    if (!ok) return;
    setState(() => _busy = true);
    try {
      final b = await ref.read(listingRepositoryProvider).book(
            listingId: l.id,
            checkIn: DateTime(range.start.year, range.start.month, range.start.day, 14),
            checkOut: DateTime(range.end.year, range.end.month, range.end.day, 11),
            priceUnit: unit,
            idempotencyKey: _bookingKey('${l.id}|${range.start.toIso8601String()}|${range.end.toIso8601String()}|$unit'),
          );
      _keyFor = null;
      _key = null;
      ref.invalidate(myBookingsProvider);
      ref.invalidate(walletProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      showToast(context, b.message ?? 'Booking ${sentence(b.status).toLowerCase()}', error: !b.status.startsWith('CONF') && b.status != 'PENDING');
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _interest() async {
    final note = await promptDialog(
      context,
      title: 'Tell the owner you are interested',
      label: 'Message (optional)',
      confirmLabel: 'Send',
    );
    if (note == null) return;
    setState(() => _busy = true);
    try {
      await ref.read(listingRepositoryProvider).expressInterest(l.id, message: note.trim().isEmpty ? null : note.trim());
      ref.invalidate(myInterestsProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      showToast(context, 'The owner has been told. It is saved in your wishlist.');
    } catch (e) {
      if (mounted) showApiError(context, ApiException.from(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ClipRRect(borderRadius: BorderRadius.circular(context.radius(16)), child: ListingPicture(l.cover)),
        const SizedBox(height: 14),
        Row(
          children: <Widget>[
            Expanded(child: Text(priceLine(l), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800))),
            StatusPill(categoryLabel(l.category), color: context.pal.accent, dense: true),
          ],
        ),
        if (l.place.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(<String?>[l.address, l.place].whereType<String>().join(', '), style: TextStyle(fontSize: 13.5, color: context.mutedColor)),
          ),
        if (l.isShortStay) ...<Widget>[
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: <Widget>[
              if (l.maxGuests != null) _Fact(Icons.group_outlined, '${l.maxGuests} guests'),
              if (l.bedrooms != null) _Fact(Icons.bed_outlined, '${l.bedrooms} bedrooms'),
              if (l.bathrooms != null) _Fact(Icons.bathtub_outlined, '${l.bathrooms} bathrooms'),
            ],
          ),
        ],
        if (l.description != null) ...<Widget>[
          const SizedBox(height: 14),
          Text(l.description!, style: const TextStyle(fontSize: 14.5, height: 1.5)),
        ],
        if (l.amenities.isNotEmpty) ...<Widget>[
          const SizedBox(height: 14),
          Wrap(spacing: 8, runSpacing: 8, children: <Widget>[for (final a in l.amenities) StatusPill(sentence(a), dense: true)]),
        ],
        if (l.cancellationPolicy != null) ...<Widget>[
          const SizedBox(height: 14),
          InlineMessage('Cancellation: ${sentence(l.cancellationPolicy)}.'),
        ],
        const SizedBox(height: 18),
        if (widget.readOnly)
          const SizedBox.shrink()
        else if (l.isShortStay)
          PButton(label: 'Choose dates and book', icon: Icons.event_available_outlined, expand: true, loading: _busy, onPressed: _book)
        else
          PButton(label: "I'm interested", icon: Icons.favorite_border_rounded, expand: true, loading: _busy, onPressed: _interest),
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 18, color: context.mutedColor),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
