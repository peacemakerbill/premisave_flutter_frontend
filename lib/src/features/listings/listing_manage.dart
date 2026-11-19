import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart' show ImagePicker;

import '../../core/network/api_exception.dart';
import '../../core/theme/brand.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/money.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/json_utils.dart';
import '../../data/repositories/listing_repository.dart';
import '../../data/repositories/messenger_repository.dart' show LocalFile;
import '../../state/providers.dart';
import '../../state/service_providers.dart';
import '../shared/hub.dart';
import '../shared/resource_form.dart';
import '../shared/resource_view.dart';
import 'bookings_screen.dart';
import 'listing_form.dart';
import 'promotion_form.dart';
import '../shared/service_widgets.dart';
import 'listing_widgets.dart';
import 'wishlists_screen.dart';

String _fileId(String url) {
  final clean = url.split('?').first;
  final parts = clean.split('/').where((p) => p.isNotEmpty).toList();
  return parts.isEmpty ? url : parts.last;
}

/// A scrolling page for a form that is shown as a whole screen instead of a sheet.
class _FormPage extends StatelessWidget {
  const _FormPage({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 640), child: child)),
    );
  }
}

/// The menu for a home owner's listings: every listing with edit, photos, calendar, promotion, archive and delete,
/// plus the bookings and leads that arrive on them.
class OwnerListingsHub extends StatelessWidget {
  const OwnerListingsHub({super.key});

  @override
  Widget build(BuildContext context) {
    return HubPage(
      title: 'Listings',
      tabs: <HubTab>[
        HubTab('My listings', Icons.home_work_outlined, (_) => const ManageListingsTab()),
        HubTab('Bookings', Icons.event_available_outlined, (_) => const BookingsScreen(asOwner: true)),
        HubTab('Leads', Icons.favorite_border_rounded, (_) => const WishlistsScreen(asOwner: true)),
        HubTab('Promotions', Icons.campaign_outlined, (_) => const PromotionsTab()),
        HubTab('Rates', Icons.currency_exchange_rounded, (_) => const CurrencyTab()),
      ],
    );
  }
}

/// The menu for a client's stays: bookings, saved listings and the rates behind the prices.
class ClientBookingsHub extends StatelessWidget {
  const ClientBookingsHub({super.key});

  @override
  Widget build(BuildContext context) {
    return HubPage(
      title: 'Bookings',
      tabs: <HubTab>[
        HubTab('My bookings', Icons.event_available_outlined, (_) => const BookingsScreen()),
        HubTab('Saved', Icons.favorite_border_rounded, (_) => const WishlistsScreen()),
        HubTab('Short stays', Icons.beach_access_outlined, (_) => const ShortStaysTab()),
        HubTab('Rates', Icons.currency_exchange_rounded, (_) => const CurrencyTab()),
      ],
    );
  }
}

/// Every listing of the signed in owner with all the things that can be done to it.
class ManageListingsTab extends ConsumerStatefulWidget {
  const ManageListingsTab({super.key});

  @override
  ConsumerState<ManageListingsTab> createState() => _ManageListingsTabState();
}

class _ManageListingsTabState extends ConsumerState<ManageListingsTab> {
  String? _status;
  int _bump = 0;

  ListingRepository get _repo => ref.read(listingRepositoryProvider);

  static const Map<String, String> _statuses = <String, String>{
    'PENDING': 'Waiting for review',
    'ACTIVE': 'Approved',
    'REJECTED': 'Rejected',
    'ARCHIVED': 'Archived',
  };

  void _changed() {
    ref.invalidate(myListingsProvider);
    setState(() => _bump++);
  }

  bool _isShort(Json m) => pick(m, <String>['category']) == 'SHORT_TERM_RENTAL';

  String _price(Json m) {
    final cur = pick(m, <String>['currency'], 'USD');
    final num? v = (m['pricePerNight'] ?? m['pricePerDay'] ?? m['price']) as num?;
    return v == null ? '' : formatMoney(v.toDouble(), cur);
  }

  @override
  Widget build(BuildContext context) {
    String id(Json m) => pick(m, <String>['id', 'listingId']);
    return Column(
      children: <Widget>[
        SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(label: const Text('All'), selected: _status == null, onSelected: (_) => setState(() => _status = null)),
              ),
              for (final e in _statuses.entries)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(label: Text(e.value), selected: _status == e.key, onSelected: (_) => setState(() => _status = e.key)),
                ),
            ],
          ),
        ),
        Expanded(
          child: ResourceSection(
            refreshKey: '$_status$_bump',
            load: () => _repo.myListingsRaw(status: _status),
            detail: (m) => _repo.listingRaw(id(m)),
            emptyTitle: 'No listings here',
            emptyMessage: 'Create a listing, then promote it to make it visible to clients.',
            emptyIcon: Icons.home_work_outlined,
            hidden: const <String>{'imageUrls', 'mainImageUrl', 'latitude', 'longitude'},
            row: RowView(
              icon: Icons.home_work_outlined,
              title: (m) => pick(m, <String>['title'], 'Untitled listing'),
              subtitle: (m) => <String>[categoryLabel(pick(m, <String>['category'])), pick(m, <String>['city'])].where((e) => e.isNotEmpty).join(' in '),
              status: (m) => pick(m, <String>['status']),
              trailing: _price,
              image: (m) => pick(m, <String>['mainImageUrl']),
            ),
            headerActions: <ItemAction>[
              ItemAction(
                'Create a listing',
                Icons.add_rounded,
                title: 'Create a listing',
                page: (_) => _FormPage(child: ListingFormSheet(key: UniqueKey())),
              ),
            ],
            itemActions: <ItemAction>[
              ItemAction(
                'Edit',
                Icons.edit_outlined,
                title: 'Edit listing',
                page: (m) => _FormPage(child: ListingFormSheet(existing: m)),
              ),
              ItemAction('Photos', Icons.photo_library_outlined, title: 'Photos', page: (m) => ListingPhotosPage(listingId: id(m))),
              ItemAction(
                'Calendar',
                Icons.calendar_month_outlined,
                title: 'Availability',
                visible: _isShort,
                page: (m) => ListingCalendarPage(listingId: id(m)),
              ),
              ItemAction(
                'Promote',
                Icons.campaign_outlined,
                title: 'Promote this listing',
                page: (m) => _FormPage(child: PromotionForm(listing: m)),
                visible: (m) => pick(m, <String>['status']) == 'ACTIVE',
              ),
              ItemAction(
                'Extend promotion',
                Icons.more_time_rounded,
                subtitle: 'Add days to a promotion that is running.',
                fields: const <FieldSpec>[FieldSpec('days', 'Days to add', kind: FieldKind.integer, required: true, initial: 7)],
                run: (m, v) async {
                  await _repo.extendPromotion(id(m), (v['days'] as num).toInt());
                },
                done: 'Promotion extended',
                visible: (m) => m['promoted'] == true || m['isPromoted'] == true,
              ),
              ItemAction(
                'Archive',
                Icons.archive_outlined,
                confirm: 'An archived listing is hidden from Explore until you restore it.',
                run: (m, _) async => _repo.archive(id(m)),
                done: 'Listing archived',
                visible: (m) => pick(m, <String>['status']) != 'ARCHIVED',
              ),
              ItemAction(
                'Restore',
                Icons.unarchive_outlined,
                run: (m, _) async => _repo.unarchive(id(m)),
                done: 'Listing restored',
                visible: (m) => pick(m, <String>['status']) == 'ARCHIVED',
              ),
              ItemAction(
                'Delete',
                Icons.delete_outline_rounded,
                danger: true,
                confirm: 'This deletes the listing for good. A listing with bookings cannot be deleted, archive it instead.',
                run: (m, _) async => _repo.deleteListing(id(m)),
                done: 'Listing deleted',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Photos of one listing: add, remove, choose the cover and change the order.
class ListingPhotosPage extends ConsumerStatefulWidget {
  const ListingPhotosPage({super.key, required this.listingId});

  final String listingId;

  @override
  ConsumerState<ListingPhotosPage> createState() => _ListingPhotosPageState();
}

class _ListingPhotosPageState extends ConsumerState<ListingPhotosPage> {
  late Future<Json> _future;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _future = ref.read(listingRepositoryProvider).listingRaw(widget.listingId);
  }

  void _reload() {
    setState(() {
      _future = ref.read(listingRepositoryProvider).listingRaw(widget.listingId);
    });
  }

  Future<void> _run(Future<void> Function() call, String done) async {
    setState(() => _busy = true);
    final ok = await attempt(context, call, done: done);
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      ref.invalidate(myListingsProvider);
      _reload();
    }
  }

  Future<void> _add() async {
    final picked = await ImagePicker().pickMultiImage(imageQuality: 88, maxWidth: 2400);
    if (picked.isEmpty) return;
    final files = <LocalFile>[];
    for (final x in picked) {
      final bytes = await x.readAsBytes();
      files.add(LocalFile(name: x.name, bytes: bytes, size: bytes.length));
    }
    await _run(() => ref.read(listingRepositoryProvider).addImages(widget.listingId, files), 'Photos added');
  }

  Future<void> _move(List<String> urls, int from, int to) async {
    final ids = urls.map(_fileId).toList();
    final moved = ids.removeAt(from);
    ids.insert(to, moved);
    await _run(() => ref.read(listingRepositoryProvider).reorderImages(widget.listingId, ids), 'Order saved');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Json>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) return const SkeletonList();
        if (snap.hasError) return ErrorState(error: snap.error!, onRetry: _reload);
        final data = snap.data ?? <String, dynamic>{};
        final urls = stringList(data['imageUrls']);
        final cover = pick(data, <String>['mainImageUrl']);
        return PageBody(
          maxWidth: 820,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: PButton(label: 'Add photos', icon: Icons.add_photo_alternate_outlined, small: true, loading: _busy, onPressed: _add),
              ),
            ),
            const SizedBox(height: 12),
            if (urls.isEmpty)
              const SizedBox(height: 260, child: EmptyState(icon: Icons.photo_library_outlined, title: 'No photos yet', message: 'Add photos so people can see the place.'))
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ResponsiveWrap(
                  minItemWidth: 220,
                  children: <Widget>[
                    for (var i = 0; i < urls.length; i++)
                      PCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            ClipRRect(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(context.radius(14))),
                              child: ListingPicture(urls[i]),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
                              child: Row(
                                children: <Widget>[
                                  if (urls[i] == cover || (cover.isEmpty && i == 0))
                                    const StatusChip('COVER')
                                  else
                                    TextButton(
                                      onPressed: _busy ? null : () => _run(() => ref.read(listingRepositoryProvider).setCoverImage(widget.listingId, _fileId(urls[i])), 'Cover changed'),
                                      child: const Text('Make cover'),
                                    ),
                                  const Spacer(),
                                  IconButton(
                                    tooltip: 'Move earlier',
                                    onPressed: _busy || i == 0 ? null : () => _move(urls, i, i - 1),
                                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                                  ),
                                  IconButton(
                                    tooltip: 'Move later',
                                    onPressed: _busy || i == urls.length - 1 ? null : () => _move(urls, i, i + 1),
                                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                                  ),
                                  IconButton(
                                    tooltip: 'Remove',
                                    onPressed: _busy
                                        ? null
                                        : () async {
                                            final yes = await confirmDialog(context, title: 'Remove photo', message: 'This photo is taken off the listing.', confirmLabel: 'Remove', danger: true);
                                            if (yes) await _run(() => ref.read(listingRepositoryProvider).removeImage(widget.listingId, _fileId(urls[i])), 'Photo removed');
                                          },
                                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Which nights of a short stay are taken, with a way to close dates and open them again.
class ListingCalendarPage extends ConsumerStatefulWidget {
  const ListingCalendarPage({super.key, required this.listingId});

  final String listingId;

  @override
  ConsumerState<ListingCalendarPage> createState() => _ListingCalendarPageState();
}

class _ListingCalendarPageState extends ConsumerState<ListingCalendarPage> {
  late Future<List<String>> _future;
  final List<String> _blockIds = <String>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final now = DateTime.now();
    final end = now.add(const Duration(days: 180));
    _future = ref.read(listingRepositoryProvider).unavailableDates(widget.listingId, from: isoDay(now), to: isoDay(end));
  }

  String isoDay(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _block() async {
    final today = DateTime.now();
    final ok = await showResourceForm(
      context,
      title: 'Close dates',
      subtitle: 'Guests cannot book these nights. The last date stays open, like a check out day.',
      fields: const <FieldSpec>[
        FieldSpec('from', 'First night closed', kind: FieldKind.date, required: true),
        FieldSpec('to', 'Open again on', kind: FieldKind.date, required: true),
      ],
      submitLabel: 'Close dates',
      onSubmit: (v) async {
        final from = DateTime.parse(v['from'] as String);
        final to = DateTime.parse(v['to'] as String);
        if (!to.isAfter(from)) throw ApiException('The reopening date must be after the first closed night.');
        if (to.isBefore(DateTime(today.year, today.month, today.day))) throw ApiException('Choose dates that are not in the past.');
        final id = await ref.read(listingRepositoryProvider).blockDates(widget.listingId, from: from, to: to);
        _blockIds.add(id);
      },
    );
    if (ok) setState(_load);
  }

  Future<void> _unblock([String? id]) async {
    String? blockId = id;
    if (blockId == null) {
      final ok = await showResourceForm(
        context,
        title: 'Open dates again',
        subtitle: 'The listing service gives a block code when dates are closed. Paste the code of the block to remove.',
        fields: const <FieldSpec>[FieldSpec('blockId', 'Block code', required: true)],
        submitLabel: 'Open dates',
        onSubmit: (v) async => blockId = v['blockId'] as String,
      );
      if (!ok || blockId == null) return;
    }
    final done = await attempt(context, () => ref.read(listingRepositoryProvider).unblockDates(widget.listingId, blockId!), done: 'Dates are open again');
    if (done && mounted) {
      setState(() {
        _blockIds.remove(blockId);
        _load();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageBody(
      maxWidth: 760,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              PButton(label: 'Close dates', icon: Icons.event_busy_outlined, small: true, onPressed: _block),
              PButton(label: 'Open dates again', icon: Icons.event_available_outlined, small: true, kind: PButtonKind.outline, onPressed: _unblock),
            ],
          ),
        ),
        if (_blockIds.isNotEmpty) ...<Widget>[
          const BlockTitle('Closed in this session'),
          for (final id in _blockIds)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: PCard(
                margin: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: <Widget>[
                    Expanded(child: SelectableText('Block $id', style: const TextStyle(fontSize: 13))),
                    TextButton(onPressed: () => _unblock(id), child: const Text('Open')),
                  ],
                ),
              ),
            ),
        ],
        const BlockTitle('Taken or closed in the next six months'),
        FutureBuilder<List<String>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) return const SkeletonList(count: 2, height: 60, shrink: true, padding: EdgeInsets.symmetric(horizontal: 16));
            if (snap.hasError) return ErrorState(error: snap.error!, onRetry: () => setState(_load));
            final days = snap.data ?? <String>[];
            if (days.isEmpty) return const EmptyState(icon: Icons.event_available_outlined, title: 'Every night is open', message: 'Nothing is booked or closed in the next six months.');
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  for (final d in days)
                    Chip(label: Text(displayValue(d)), visualDensity: VisualDensity.compact),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

/// The promotions of the signed in owner. A promotion is what makes a listing visible to clients.
class PromotionsTab extends ConsumerStatefulWidget {
  const PromotionsTab({super.key});

  @override
  ConsumerState<PromotionsTab> createState() => _PromotionsTabState();
}

class _PromotionsTabState extends ConsumerState<PromotionsTab> {
  int _bump = 0;

  String _until(Json m) {
    final d = DateTime.tryParse(pick(m, <String>['endDate', 'expiresAt', 'endsAt']));
    if (d == null) return '';
    final status = pick(m, <String>['status']);
    return status == 'EXPIRED' ? 'Ended ${formatDate(d)}' : 'Until ${formatDate(d)}';
  }

  @override
  Widget build(BuildContext context) {
    return ResourceSection(
      refreshKey: _bump,
      load: () => ref.read(listingRepositoryProvider).myPromotions(),
      intro: 'A listing is only shown to clients while it is promoted. Start a promotion, choose the photo it shows, and it appears first in Explore.',
      emptyTitle: 'No promotions yet',
      emptyMessage: 'Promote a listing to make it visible to clients.',
      emptyIcon: Icons.campaign_outlined,
      hidden: const <String>{'imageUrl', 'listingTitle', 'headline', 'listingId', 'status'},
      row: RowView(
        icon: Icons.campaign_outlined,
        title: (m) => pick(m, <String>['listingTitle', 'title'], 'Promotion'),
        subtitle: (m) {
          final headline = pick(m, <String>['headline']);
          return <String>[if (headline.isNotEmpty) headline, _until(m)].where((e) => e.isNotEmpty).join('\n');
        },
        status: (m) => pick(m, <String>['status']),
        trailing: (m) => m['totalAmount'] is num ? formatMoney((m['totalAmount'] as num).toDouble(), pick(m, <String>['currency'], 'USD')) : null,
        image: (m) => pick(m, <String>['imageUrl']),
      ),
      headerActions: <ItemAction>[
        ItemAction(
          'Promote a listing',
          Icons.add_rounded,
          title: 'Promote a listing',
          page: (_) => _FormPage(child: PromotionForm(key: UniqueKey())),
        ),
      ],
      itemActions: <ItemAction>[
        ItemAction(
          'Add days',
          Icons.more_time_rounded,
          title: 'Add days',
          subtitle: 'Extends this promotion. The days are paid from your wallet.',
          fields: const <FieldSpec>[FieldSpec('days', 'Days to add', kind: FieldKind.integer, required: true, initial: 7)],
          run: (m, v) async {
            await ref.read(listingRepositoryProvider).extendPromotion(pick(m, <String>['listingId']), (v['days'] as num).toInt());
            ref.invalidate(walletProvider);
          },
          done: 'Promotion extended',
          visible: (m) => pick(m, <String>['status']) == 'ACTIVE' || pick(m, <String>['status']) == 'EXPIRED',
        ),
      ],
    );
  }
}

/// Exchange rates behind the prices, with a converter.
class CurrencyTab extends ConsumerStatefulWidget {
  const CurrencyTab({super.key});

  @override
  ConsumerState<CurrencyTab> createState() => _CurrencyTabState();
}

class _CurrencyTabState extends ConsumerState<CurrencyTab> {
  late Future<({String base, Map<String, dynamic> rates})> _future;
  final _amount = TextEditingController(text: '100');
  String _to = 'KES';
  String? _result;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _future = ref.read(listingRepositoryProvider).currencyRates();
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _convert() async {
    final amount = parseAmount(_amount.text);
    if (amount == null) {
      setState(() => _result = 'Enter an amount above zero.');
      return;
    }
    setState(() => _busy = true);
    try {
      final res = await ref.read(listingRepositoryProvider).convertCurrency(amount, _to);
      final value = res['converted'] ?? res['result'] ?? res['amount'] ?? res['value'];
      setState(() => _result = value == null ? displayValue(res) : '${formatMoney(amount, 'USD')} is about ${displayValue(value)} $_to');
    } catch (e) {
      setState(() => _result = ApiException.from(e).message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageBody(
      maxWidth: 720,
      onRefresh: () async {
        setState(() {
          _future = ref.read(listingRepositoryProvider).currencyRates();
        });
      },
      children: <Widget>[
        FutureBuilder<({String base, Map<String, dynamic> rates})>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) return const SkeletonList(count: 3, height: 56, shrink: true);
            if (snap.hasError) return ErrorState(error: snap.error!, onRetry: () => setState(() {
              _future = ref.read(listingRepositoryProvider).currencyRates();
            }));
            final data = snap.data!;
            final codes = data.rates.keys.toList()..sort();
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  PCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('Convert from ${data.base}', style: const TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 12),
                        PTextField(label: 'Amount', controller: _amount, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                        const SizedBox(height: 12),
                        if (codes.isNotEmpty)
                          PSelectField<String>(
                            label: 'To',
                            value: codes.contains(_to) ? _to : codes.first,
                            searchable: true,
                            options: <PChoice<String>>[for (final c in codes) PChoice<String>(c, c)],
                            onChanged: (v) => setState(() => _to = v ?? _to),
                          ),
                        const SizedBox(height: 12),
                        PButton(label: 'Convert', icon: Icons.swap_horiz_rounded, loading: _busy, onPressed: _convert),
                        if (_result != null) ...<Widget>[const SizedBox(height: 10), Text(_result!, style: const TextStyle(fontWeight: FontWeight.w700))],
                      ],
                    ),
                  ),
                  const BlockTitle('Rates'),
                  PCard(
                    child: Column(
                      children: <Widget>[
                        for (final c in codes)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Row(children: <Widget>[Text(c, style: const TextStyle(fontWeight: FontWeight.w700)), const Spacer(), Text(displayValue(data.rates[c]))]),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Short stays anyone can browse, filtered by city.
class ShortStaysTab extends ConsumerStatefulWidget {
  const ShortStaysTab({super.key});

  @override
  ConsumerState<ShortStaysTab> createState() => _ShortStaysTabState();
}

class _ShortStaysTabState extends ConsumerState<ShortStaysTab> {
  final _city = TextEditingController();
  String? _applied;

  @override
  void dispose() {
    _city.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Row(
            children: <Widget>[
              Expanded(child: PTextField(label: 'City', controller: _city, optional: true, prefixIcon: Icons.location_city_outlined)),
              const SizedBox(width: 10),
              PButton(label: 'Search', small: true, onPressed: () => setState(() => _applied = _city.text.trim().isEmpty ? null : _city.text.trim())),
            ],
          ),
        ),
        Expanded(
          child: ResourceSection(
            refreshKey: _applied,
            load: () async => (await ref.read(listingRepositoryProvider).shortTerm(city: _applied)).map((l) => <String, dynamic>{
                  'id': l.id,
                  'title': l.title,
                  'city': l.city,
                  'price': priceLine(l),
                  'bedrooms': l.bedrooms,
                  'maxGuests': l.maxGuests,
                }).toList(),
            emptyTitle: 'No short stays found',
            emptyIcon: Icons.beach_access_outlined,
            row: RowView(
              icon: Icons.beach_access_outlined,
              title: (m) => pick(m, <String>['title']),
              subtitle: (m) => pick(m, <String>['city']),
              trailing: (m) => pick(m, <String>['price']),
            ),
          ),
        ),
      ],
    );
  }
}
