import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/c2b_models.dart';
import '../data/models/developer_models.dart';
import '../data/models/listing_models.dart';
import '../data/models/property_models.dart';
import '../data/models/wallet_models.dart';
import 'providers.dart';

// Data for the wallet, listing, property, developer and C2B screens. Like the providers in data_providers.dart these
// are autoDispose: leaving a screen drops its data, and screens call ref.invalidate(provider) after a change.

// -------------------------------------------------------------------- wallet

final walletProvider = FutureProvider.autoDispose<WalletModel>((ref) => ref.watch(walletRepositoryProvider).wallet());

final walletTransactionsProvider =
    FutureProvider.autoDispose<List<WalletTransaction>>((ref) => ref.watch(walletRepositoryProvider).transactions());

final transferHistoryProvider =
    FutureProvider.autoDispose<List<TransferRecord>>((ref) => ref.watch(walletRepositoryProvider).transfers());

final depositHistoryProvider =
    FutureProvider.autoDispose<List<DepositRecord>>((ref) => ref.watch(walletRepositoryProvider).deposits());

final withdrawalHistoryProvider =
    FutureProvider.autoDispose<List<DisbursementRecord>>((ref) => ref.watch(walletRepositoryProvider).withdrawals());

// ------------------------------------------------------------------ listings

/// What the Explore screen searches for. Two queries with the same values are equal, so Riverpod reuses the result.
class ListingQuery {
  const ListingQuery({this.text = '', this.category});

  final String text;
  final String? category;

  @override
  bool operator ==(Object other) => other is ListingQuery && other.text == text && other.category == category;

  @override
  int get hashCode => Object.hash(text, category);
}

final listingSearchProvider = FutureProvider.autoDispose.family<List<ListingModel>, ListingQuery>((ref, q) {
  return ref.watch(listingRepositoryProvider).search(
        query: q.text.trim().isEmpty ? null : q.text.trim(),
        category: q.category,
      );
});

final myListingsProvider =
    FutureProvider.autoDispose<List<ListingModel>>((ref) => ref.watch(listingRepositoryProvider).myListings());

final myBookingsProvider =
    FutureProvider.autoDispose<List<BookingModel>>((ref) => ref.watch(listingRepositoryProvider).myBookings());

final receivedBookingsProvider =
    FutureProvider.autoDispose<List<BookingModel>>((ref) => ref.watch(listingRepositoryProvider).receivedBookings());

final myInterestsProvider =
    FutureProvider.autoDispose<List<InterestModel>>((ref) => ref.watch(listingRepositoryProvider).myInterests());

final receivedInterestsProvider =
    FutureProvider.autoDispose<List<InterestModel>>((ref) => ref.watch(listingRepositoryProvider).receivedInterests());

// ------------------------------------------------------- property management

final ownerDashboardProvider =
    FutureProvider.autoDispose<OwnerDashboard>((ref) => ref.watch(propertyRepositoryProvider).dashboard());

final myPropertiesProvider =
    FutureProvider.autoDispose<List<PropertyModel>>((ref) => ref.watch(propertyRepositoryProvider).myProperties());

final propertyUnitsProvider = FutureProvider.autoDispose.family<List<UnitModel>, String>(
  (ref, propertyId) => ref.watch(propertyRepositoryProvider).units(propertyId),
);

final ownerLeasesProvider =
    FutureProvider.autoDispose<List<LeaseModel>>((ref) => ref.watch(propertyRepositoryProvider).ownerLeases());

final pendingMaintenanceProvider = FutureProvider.autoDispose<List<MaintenanceModel>>(
  (ref) => ref.watch(propertyRepositoryProvider).maintenanceByStatus('PENDING'),
);

/// True when the person already has an owner profile on the property service.
final ownerProfileExistsProvider =
    FutureProvider.autoDispose<bool>((ref) => ref.watch(propertyRepositoryProvider).ownerExists());

/// Null when the person has not registered as a tenant yet.
final tenantProfileProvider =
    FutureProvider.autoDispose<TenantProfile?>((ref) => ref.watch(propertyRepositoryProvider).myTenantProfile());

final rentSummaryProvider =
    FutureProvider.autoDispose<RentSummary>((ref) => ref.watch(propertyRepositoryProvider).myRentSummary());

final tenantLeasesProvider = FutureProvider.autoDispose.family<List<LeaseModel>, String>(
  (ref, tenantId) => ref.watch(propertyRepositoryProvider).myLeases(tenantId),
);

final tenantMaintenanceProvider = FutureProvider.autoDispose.family<List<MaintenanceModel>, String>(
  (ref, tenantId) => ref.watch(propertyRepositoryProvider).myMaintenance(tenantId),
);

final tenantNoticesProvider = FutureProvider.autoDispose.family<List<NoticeModel>, String>(
  (ref, tenantId) => ref.watch(propertyRepositoryProvider).myNotices(tenantId),
);

// ----------------------------------------------------------------- developer

final developerAppsProvider =
    FutureProvider.autoDispose<List<DeveloperApp>>((ref) => ref.watch(developerRepositoryProvider).apps());

final developerKeysProvider = FutureProvider.autoDispose.family<List<ApiKeyModel>, String>(
  (ref, appId) => ref.watch(developerRepositoryProvider).keys(appId),
);

// ---------------------------------------------------------------------- C2B

final savedAccountsProvider =
    FutureProvider.autoDispose<List<SavedAccount>>((ref) => ref.watch(c2bRepositoryProvider).savedAccounts());

/// The title of a listing, for screens that only hold its id (a booking carries just the listing id).
final listingTitleProvider = FutureProvider.autoDispose.family<String, String>((ref, id) async {
  final l = await ref.watch(listingRepositoryProvider).listing(id);
  return l.title;
});
