import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/brand.dart';
import '../../core/theme/palette.dart';
import '../../core/utils/money.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/json_utils.dart';
import '../../state/providers.dart';
import '../../state/service_providers.dart';
import '../shared/resource_view.dart';
import '../shared/service_widgets.dart';

/// Starts a promotion: choose the listing, how many days, which of its photos to show and an optional headline. The price
/// is shown before anything is paid, and the money comes from the owner's wallet.
class PromotionForm extends ConsumerStatefulWidget {
  /// With [listing] the listing is fixed. Without it the owner picks one of the listings that can be promoted.
  const PromotionForm({super.key, this.listing});

  final Json? listing;

  @override
  ConsumerState<PromotionForm> createState() => _PromotionFormState();
}

class _PromotionFormState extends ConsumerState<PromotionForm> {
  static const List<int> _quickDays = <int>[3, 7, 14, 30];

  final TextEditingController _days = TextEditingController(text: '7');
  final TextEditingController _headline = TextEditingController();
  List<Json>? _listings;
  Json? _listing;
  String? _image;
  ({double dailyRate, String currency})? _rate;
  String? _error;
  String? _loadError;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _listing = widget.listing;
    _image = _cover(widget.listing);
    _days.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _days.dispose();
    _headline.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final repo = ref.read(listingRepositoryProvider);
    try {
      final rate = await repo.promotionRate();
      final list = widget.listing == null ? await repo.myListingsRaw(status: 'ACTIVE') : null;
      if (!mounted) return;
      setState(() {
        _rate = rate;
        _listings = list;
      });
    } catch (e) {
      if (mounted) setState(() => _loadError = ApiException.from(e).message);
    }
  }

  static String _id(Json m) => pick(m, <String>['id', 'listingId']);

  static String? _cover(Json? m) {
    if (m == null) return null;
    final cover = pick(m, <String>['mainImageUrl']);
    if (cover.isNotEmpty) return cover;
    final all = stringList(m['imageUrls']);
    return all.isEmpty ? null : all.first;
  }

  /// Every photo of the listing, the cover first, without repeats.
  static List<String> _photos(Json? m) {
    if (m == null) return const <String>[];
    final cover = pick(m, <String>['mainImageUrl']);
    final all = <String>[if (cover.isNotEmpty) cover, ...stringList(m['imageUrls'])];
    return <String>{...all}.toList();
  }

  int? get _dayCount {
    final n = int.tryParse(_days.text.trim());
    return n == null || n < 1 || n > 365 ? null : n;
  }

  Future<void> _submit() async {
    final listing = _listing;
    final days = _dayCount;
    if (listing == null) {
      setState(() => _error = 'Choose the listing to promote.');
      return;
    }
    if (days == null) {
      setState(() => _error = 'Enter a number of days between 1 and 365.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final res = await ref.read(listingRepositoryProvider).promote(
            _id(listing),
            days,
            imageUrl: _image,
            headline: _headline.text.trim().isEmpty ? null : _headline.text.trim(),
          );
      if (!mounted) return;
      if (res['success'] == false) {
        setState(() => _error = pick(res, <String>['message'], 'The payment did not go through.'));
        return;
      }
      ref.invalidate(myListingsProvider);
      ref.invalidate(walletProvider);
      showToast(context, 'Promotion started');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _error = ApiException.from(e).message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rate = _rate;
    final days = _dayCount;
    final photos = _photos(_listing);
    final fixed = widget.listing != null;
    final ready = rate != null && (fixed || _listings != null);
    if (_loadError != null) {
      return Padding(padding: const EdgeInsets.only(top: 8), child: InlineMessage(_loadError!, kind: MessageKind.error));
    }
    if (!ready) {
      return const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Center(child: CircularProgressIndicator()));
    }
    final list = _listings ?? const <Json>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'A promoted listing is shown first in Explore. Clients cannot see a listing until it is promoted.',
          style: TextStyle(fontSize: 13.5, height: 1.4, color: context.mutedColor),
        ),
        const SizedBox(height: 16),
        if (!fixed) ...<Widget>[
          if (list.isEmpty)
            const InlineMessage('You have no approved listings to promote yet. Create a listing first.', kind: MessageKind.info)
          else
            PSelectField<String>(
              label: 'Listing',
              searchable: list.length > 6,
              value: _listing == null ? null : _id(_listing!),
              options: <PChoice<String>>[
                for (final m in list)
                  PChoice<String>(
                    _id(m),
                    pick(m, <String>['title'], 'Untitled listing'),
                    description: pick(m, <String>['city']),
                  ),
              ],
              onChanged: (v) => setState(() {
                _listing = list.firstWhere((m) => _id(m) == v, orElse: () => <String, dynamic>{});
                if (_listing!.isEmpty) _listing = null;
                _image = _cover(_listing);
              }),
            ),
          const SizedBox(height: 16),
        ] else ...<Widget>[
          Text(pick(widget.listing!, <String>['title'], 'Listing'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 16),
        ],
        if (photos.isNotEmpty) ...<Widget>[
          Text('Promotion photo', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: context.mutedColor)),
          const SizedBox(height: 8),
          SizedBox(
            height: 82,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: photos.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) => _PhotoChoice(
                url: photos[i],
                selected: photos[i] == _image,
                onTap: () => setState(() => _image = photos[i]),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        PTextField(
          label: 'Headline',
          controller: _headline,
          optional: true,
          maxLength: 80,
          hint: 'For example: Sea view, ten minutes from the beach',
        ),
        const SizedBox(height: 14),
        Text('Days', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: context.mutedColor)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: <Widget>[
            for (final d in _quickDays)
              ChoiceChip(label: Text('$d days'), selected: _days.text.trim() == '$d', onSelected: (_) => _days.text = '$d'),
          ],
        ),
        const SizedBox(height: 10),
        PTextField(
          label: 'Number of days',
          controller: _days,
          keyboardType: TextInputType.number,
          errorText: _days.text.trim().isNotEmpty && days == null ? 'Enter a number between 1 and 365.' : null,
        ),
        const SizedBox(height: 16),
        PCard(
          child: Column(
            children: <Widget>[
              KeyValueLine('Price per day', formatMoney(rate.dailyRate, rate.currency)),
              KeyValueLine('Days', days == null ? '-' : '$days'),
              KeyValueLine('Total', days == null ? '-' : formatMoney(rate.dailyRate * days, rate.currency), bold: true),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Paid from your wallet.', style: TextStyle(fontSize: 12, color: context.mutedColor)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_error != null) ...<Widget>[InlineMessage(_error!, kind: MessageKind.error), const SizedBox(height: 14)],
        PButton(label: 'Pay and promote', icon: Icons.campaign_outlined, expand: true, loading: _busy, onPressed: _submit),
      ],
    );
  }
}

class _PhotoChoice extends StatelessWidget {
  const _PhotoChoice({required this.url, required this.selected, required this.onTap});

  final String url;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(context.radius(12));
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 110,
        decoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(color: selected ? context.pal.accent : context.borderColor, width: selected ? 2.5 : 1),
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported_outlined)),
              if (selected)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(color: context.pal.accent, shape: BoxShape.circle),
                    child: Icon(Icons.check_rounded, size: 14, color: context.pal.accentInk),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
