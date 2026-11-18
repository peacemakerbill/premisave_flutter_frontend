import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/application_models.dart';
import '../data/models/listing_models.dart';
import '../data/models/wallet_models.dart';
import 'providers.dart';

// Data for the role overviews. Each part has its own provider so it loads, fails and refreshes on its own.
// Client and home owner overviews reuse the providers in service_providers.dart (bookings, wishlists, listings,
// the owner dashboard, leases), so they are not repeated here.

/// Listings the public can see right now (promoted, not archived or rejected), newest first.
final liveListingsProvider = FutureProvider.autoDispose<List<ListingModel>>((ref) async {
  final list = await ref.watch(listingRepositoryProvider).search();
  final sorted = List<ListingModel>.of(list)
    ..sort((a, b) => (b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)).compareTo(a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)));
  return sorted;
});

/// Money movement for each of the last seven days, oldest first. The last entry is today.
final financeWeekProvider = FutureProvider.autoDispose<List<DailyFinance>>((ref) {
  final repo = ref.watch(walletRepositoryProvider);
  final now = DateTime.now();
  final days = <DateTime>[for (var i = 6; i >= 0; i--) DateTime(now.year, now.month, now.day - i)];
  return Future.wait(days.map(repo.financeDaily));
});

final balanceOverviewProvider =
    FutureProvider.autoDispose<BalanceOverview>((ref) => ref.watch(walletRepositoryProvider).balanceOverview());

final latestDepositsProvider =
    FutureProvider.autoDispose<List<AdminDeposit>>((ref) => ref.watch(walletRepositoryProvider).latestDeposits());

final bookingsNeedingReviewProvider = FutureProvider.autoDispose<({int total, List<BookingModel> items})>(
  (ref) => ref.watch(listingRepositoryProvider).bookingsNeedingReview(),
);

/// The applications that have waited longest, for the support overview.
final supportQueueProvider = FutureProvider.autoDispose<PagedApplications>(
  (ref) => ref.watch(applicationRepositoryProvider).staffSearch(size: 6),
);
