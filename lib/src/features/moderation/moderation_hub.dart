import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/money.dart';
import '../../data/repositories/listing_repository.dart';
import '../../state/providers.dart';
import '../listings/listing_manage.dart';
import '../shared/hub.dart';
import '../shared/resource_view.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/brand.dart';
import '../../core/widgets/widgets.dart';

/// Staff menu for everything on the listing service: listings waiting for review, every listing in each state, and the
/// bookings whose payment or payout needs a person.
class ModerationHub extends StatelessWidget {
  const ModerationHub({super.key});

  @override
  Widget build(BuildContext context) {
    return HubPage(
      title: 'Moderation',
      tabs: <HubTab>[
        HubTab('Settings', Icons.tune_rounded, (_) => const _ReviewSettings()),
        HubTab('To review', Icons.pending_actions_outlined, (_) => const _AdminListings(status: 'PENDING', intro: 'Listings wait here only while review is switched on in Settings. Approve or reject each one.')),
        HubTab('Approved', Icons.check_circle_outline_rounded, (_) => const _AdminListings(status: 'ACTIVE')),
        HubTab('Rejected', Icons.block_outlined, (_) => const _AdminListings(status: 'REJECTED')),
        HubTab('Archived', Icons.archive_outlined, (_) => const _AdminListings(archived: true)),
        HubTab('Deleted', Icons.delete_outline_rounded, (_) => const _AdminListings(deleted: true, intro: 'Soft deleted listings can be restored or removed for good.')),
        HubTab('Bookings', Icons.fact_check_outlined, (_) => const _BookingsToReview()),
        HubTab('Rates', Icons.currency_exchange_rounded, (_) => const CurrencyTab()),
      ],
    );
  }
}

class _AdminListings extends ConsumerWidget {
  const _AdminListings({this.status, this.archived, this.deleted, this.intro});

  final String? status;
  final bool? archived;
  final bool? deleted;
  final String? intro;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ListingRepository repo = ref.read(listingRepositoryProvider);
    String id(Json m) => pick(m, <String>['id', 'listingId']);
    return ResourceSection(
      load: () => repo.adminListings(status: status, archived: archived, deleted: deleted),
      detail: (m) => repo.adminListing(id(m)),
      intro: intro,
      emptyTitle: 'Nothing here',
      emptyMessage: 'No listings in this state.',
      emptyIcon: Icons.home_work_outlined,
      hidden: const <String>{'imageUrls', 'mainImageUrl', 'latitude', 'longitude'},
      row: RowView(
        icon: Icons.home_work_outlined,
        title: (m) => pick(m, <String>['title'], 'Untitled listing'),
        subtitle: (m) => <String>[pick(m, <String>['category']), pick(m, <String>['city']), pick(m, <String>['ownerId'])].where((e) => e.isNotEmpty).join(' / '),
        status: (m) => m['deleted'] == true ? 'DELETED' : (m['archived'] == true ? 'ARCHIVED' : pick(m, <String>['status'])),
        trailing: (m) {
          final v = m['pricePerNight'] ?? m['pricePerDay'] ?? m['price'];
          return v is num ? formatMoney(v.toDouble(), pick(m, <String>['currency'], 'USD')) : null;
        },
      ),
      itemActions: <ItemAction>[
        ItemAction(
          'Approve',
          Icons.check_rounded,
          confirm: 'The listing is approved. The owner can then promote it, and clients see it while it is promoted.',
          run: (m, _) async => repo.approveListing(id(m)),
          done: 'Listing approved',
          visible: (m) => pick(m, <String>['status']) != 'ACTIVE' && m['deleted'] != true,
        ),
        ItemAction(
          'Reject',
          Icons.close_rounded,
          danger: true,
          confirm: 'The owner is told the listing was rejected.',
          run: (m, _) async => repo.rejectListing(id(m)),
          done: 'Listing rejected',
          visible: (m) => pick(m, <String>['status']) != 'REJECTED' && m['deleted'] != true,
        ),
        ItemAction(
          'Archive',
          Icons.archive_outlined,
          confirm: 'The listing is hidden from Explore.',
          run: (m, _) async => repo.adminArchive(id(m)),
          done: 'Listing archived',
          visible: (m) => m['archived'] != true && m['deleted'] != true,
        ),
        ItemAction(
          'Unarchive',
          Icons.unarchive_outlined,
          run: (m, _) async => repo.adminUnarchive(id(m)),
          done: 'Listing restored from the archive',
          visible: (m) => m['archived'] == true,
        ),
        ItemAction(
          'Delete',
          Icons.delete_outline_rounded,
          danger: true,
          confirm: 'The listing is soft deleted. It can be restored later.',
          run: (m, _) async => repo.adminSoftDelete(id(m)),
          done: 'Listing deleted',
          visible: (m) => m['deleted'] != true,
        ),
        ItemAction(
          'Restore',
          Icons.restore_from_trash_rounded,
          run: (m, _) async => repo.adminRestore(id(m)),
          done: 'Listing restored',
          visible: (m) => m['deleted'] == true,
        ),
        ItemAction(
          'Delete for good',
          Icons.delete_forever_outlined,
          danger: true,
          confirm: 'This removes the listing and its photos for good. It cannot be undone.',
          run: (m, _) async => repo.adminHardDelete(id(m)),
          done: 'Listing removed',
          visible: (m) => m['deleted'] == true,
        ),
      ],
    );
  }
}

class _BookingsToReview extends ConsumerWidget {
  const _BookingsToReview();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ListingRepository repo = ref.read(listingRepositoryProvider);
    String id(Json m) => pick(m, <String>['id', 'bookingId']);
    return ResourceSection(
      load: () => repo.bookingsNeedingReviewRaw(),
      intro: 'Bookings the automatic jobs gave up on: a payment that could not be confirmed, or a payout that failed.',
      emptyTitle: 'Nothing needs review',
      emptyMessage: 'Every booking is settled.',
      emptyIcon: Icons.fact_check_outlined,
      row: RowView(
        icon: Icons.event_note_outlined,
        title: (m) => 'Booking ${pick(m, <String>['id', 'bookingId'])}',
        subtitle: (m) => '${displayValue(m['checkIn'])} to ${displayValue(m['checkOut'])}',
        status: (m) => pick(m, <String>['status']),
        trailing: (m) {
          final v = m['totalAmount'];
          return v is num ? formatMoney(v.toDouble(), pick(m, <String>['currency'], 'USD')) : null;
        },
      ),
      itemActions: <ItemAction>[
        ItemAction(
          'Payment was received',
          Icons.check_rounded,
          confirm: 'Confirms the booking. Check the wallet history for the booking reference first.',
          run: (m, _) async => repo.resolvePayment(id(m), paid: true),
          done: 'Booking confirmed',
        ),
        ItemAction(
          'Payment failed',
          Icons.close_rounded,
          danger: true,
          confirm: 'Marks the booking failed and frees its dates.',
          run: (m, _) async => repo.resolvePayment(id(m), paid: false),
          done: 'Booking marked failed',
        ),
        ItemAction(
          'Retry payout',
          Icons.replay_rounded,
          confirm: 'Queues the owner payout again.',
          run: (m, _) async => repo.retryPayout(id(m)),
          done: 'Payout queued',
        ),
      ],
    );
  }
}

/// The switch that decides whether new listings need a person's review.
class _ReviewSettings extends ConsumerStatefulWidget {
  const _ReviewSettings();

  @override
  ConsumerState<_ReviewSettings> createState() => _ReviewSettingsState();
}

class _ReviewSettingsState extends ConsumerState<_ReviewSettings> {
  late Future<Json> _future;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _future = ref.read(listingRepositoryProvider).listingSettings();
  }

  Future<void> _set(bool on) async {
    setState(() => _busy = true);
    try {
      final res = await ref.read(listingRepositoryProvider).setListingReview(on);
      if (!mounted) return;
      setState(() => _future = Future<Json>.value(res));
      showToast(context, on ? 'Review is on' : 'Review is off');
    } catch (e) {
      if (mounted) showToast(context, ApiException.from(e).message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageBody(
      maxWidth: 640,
      children: <Widget>[
        FutureBuilder<Json>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()));
            }
            if (snap.hasError) {
              return ErrorState(error: snap.error!, onRetry: () => setState(() => _future = ref.read(listingRepositoryProvider).listingSettings()));
            }
            final on = snap.data?['reviewRequired'] == true;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: PCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Review new listings', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                      subtitle: Text(on ? 'On' : 'Off', style: TextStyle(color: context.mutedColor)),
                      value: on,
                      onChanged: _busy ? null : _set,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      on
                          ? 'A new listing waits in To review. An owner can promote it only after you approve it.'
                          : 'A new listing is approved the moment it is created. Nothing waits for review.',
                      style: TextStyle(fontSize: 13.5, height: 1.45, color: context.mutedColor),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Either way, clients only see a listing while it is promoted. The promotion is what makes it visible.',
                      style: TextStyle(fontSize: 13.5, height: 1.45, color: context.mutedColor),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
