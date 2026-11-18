import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/brand.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/money.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/listing_models.dart';
import '../../state/providers.dart';
import '../../state/service_providers.dart';
import '../shared/service_widgets.dart';

/// Bookings of short stays. [asOwner] switches from the stays the person booked to the stays booked on their listings.
class BookingsScreen extends ConsumerWidget {
  const BookingsScreen({super.key, this.asOwner = false});

  final bool asOwner;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = asOwner ? receivedBookingsProvider : myBookingsProvider;
    return AsyncBody<List<BookingModel>>(
      value: ref.watch(provider),
      onRetry: () => ref.invalidate(provider),
      builder: (items) => PageBody(
        maxWidth: 760,
        onRefresh: () async => ref.invalidate(provider),
        children: items.isEmpty
            ? <Widget>[
                SizedBox(
                  height: 340,
                  child: EmptyState(
                    icon: Icons.event_available_outlined,
                    title: asOwner ? 'No bookings on your listings yet' : 'No bookings yet',
                    message: asOwner ? 'Stays booked on your listings appear here.' : 'Book a short stay from Explore and it appears here.',
                  ),
                ),
              ]
            : <Widget>[for (final b in items) BookingCard(booking: b, asOwner: asOwner)],
      ),
    );
  }
}

class BookingCard extends ConsumerStatefulWidget {
  const BookingCard({super.key, required this.booking, required this.asOwner});

  final BookingModel booking;
  final bool asOwner;

  @override
  ConsumerState<BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends ConsumerState<BookingCard> {
  bool _busy = false;

  Future<void> _cancel() async {
    final b = widget.booking;
    setState(() => _busy = true);
    try {
      final repo = ref.read(listingRepositoryProvider);
      final quote = await repo.cancellationQuote(b.id);
      if (!mounted) return;
      final ok = await confirmDialog(
        context,
        title: 'Cancel this booking?',
        message: quote.message ??
            'You get back ${formatMoney(quote.refundAmount, quote.currency)} (${quote.refundPercent}%) under the cancellation policy.',
        confirmLabel: 'Cancel booking',
        cancelLabel: 'Keep it',
        danger: true,
      );
      if (!ok) return;
      await repo.cancelBooking(b.id);
      ref.invalidate(myBookingsProvider);
      ref.invalidate(receivedBookingsProvider);
      ref.invalidate(walletProvider);
      if (mounted) showToast(context, 'Booking cancelled');
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    final title = ref.watch(listingTitleProvider(b.listingId));
    final who = widget.asOwner ? b.tenantName : b.ownerName;
    return PCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  title.maybeWhen(data: (t) => t, orElse: () => 'Booking'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
              StatusChip(b.status),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Icon(Icons.event_outlined, size: 16, color: context.mutedColor),
              const SizedBox(width: 6),
              Text('${formatDate(b.checkIn)} to ${formatDate(b.checkOut)}', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
            ],
          ),
          if (who != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(widget.asOwner ? 'Guest: $who' : 'Host: $who', style: TextStyle(fontSize: 12.5, color: context.mutedColor)),
            ),
          const SizedBox(height: 8),
          KeyValueLine('Total', formatMoney(b.totalAmount, b.currency), bold: true),
          if (b.escrowStatus != null) KeyValueLine('Payment', sentence(b.escrowStatus)),
          if (b.refundAmount != null && b.status == 'CANCELLED') KeyValueLine('Refunded', formatMoney(b.refundAmount, b.currency)),
          if (b.status == 'NEEDS_REVIEW')
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: InlineMessage('The payment result could not be confirmed. Staff are checking it.', kind: MessageKind.warning),
            ),
          if (b.cancellable) ...<Widget>[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: PButton(label: 'Cancel booking', kind: PButtonKind.outline, small: true, loading: _busy, onPressed: _cancel),
            ),
          ],
        ],
      ),
    );
  }
}
