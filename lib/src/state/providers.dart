import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../core/network/api_client.dart';
import '../core/storage/token_store.dart';
import '../data/repositories/admin_repository.dart';
import '../data/repositories/application_repository.dart';
import '../core/network/service_client.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/c2b_repository.dart';
import '../data/repositories/call_repository.dart';
import '../data/repositories/developer_repository.dart';
import '../data/repositories/listing_repository.dart';
import '../data/repositories/property_repository.dart';
import '../data/repositories/wallet_repository.dart';
import 'c2b_session.dart';
import 'developer_session.dart';
import '../data/repositories/storage_repository.dart';
import '../data/repositories/contact_repository.dart';
import '../data/repositories/messenger_repository.dart';
import '../data/repositories/place_repository.dart';
import '../data/repositories/profile_repository.dart';
import '../data/repositories/security_repository.dart';
import '../data/repositories/social_repository.dart';

final tokenStoreProvider = Provider<TokenStore>((ref) => TokenStore());

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient(ref.watch(tokenStoreProvider)));

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository(ref.watch(apiClientProvider)));

final contactRepositoryProvider = Provider<ContactRepository>((ref) => ContactRepository(ref.watch(apiClientProvider)));

final profileRepositoryProvider =
    Provider<ProfileRepository>((ref) => ProfileRepository(ref.watch(apiClientProvider)));

final placeRepositoryProvider = Provider<PlaceRepository>((ref) => PlaceRepository(ref.watch(apiClientProvider)));

final socialRepositoryProvider = Provider<SocialRepository>((ref) => SocialRepository(ref.watch(apiClientProvider)));

final securityRepositoryProvider =
    Provider<SecurityRepository>((ref) => SecurityRepository(ref.watch(apiClientProvider)));

final adminRepositoryProvider = Provider<AdminRepository>((ref) => AdminRepository(ref.watch(apiClientProvider)));

final applicationRepositoryProvider =
    Provider<ApplicationRepository>((ref) => ApplicationRepository(ref.watch(apiClientProvider)));

/// The messenger service has its own address. It shares the saved sign-in, and token refreshes go through the
/// auth-service client, so both services always hold the same tokens.
final messengerApiClientProvider = Provider<ApiClient>((ref) {
  final auth = ref.watch(apiClientProvider);
  final client = ApiClient(ref.watch(tokenStoreProvider), baseUrl: AppConfig.messengerUrl, authClient: auth);
  client.onSessionExpired = () => auth.onSessionExpired?.call();
  return client;
});

final messengerRepositoryProvider =
    Provider<MessengerRepository>((ref) => MessengerRepository(ref.watch(messengerApiClientProvider)));

final callRepositoryProvider = Provider<CallRepository>((ref) => CallRepository(ref.watch(messengerApiClientProvider)));

final storageRepositoryProvider = Provider<StorageRepository>((ref) => StorageRepository(ref.watch(messengerApiClientProvider)));

final documentStorageRepositoryProvider =
    Provider<DocumentStorageRepository>((ref) => DocumentStorageRepository(ref.watch(apiClientProvider)));

/// The wallet, listing and property services take the same sign in as the auth-service. Each has its own address,
/// shares the saved tokens, and hands token refreshes to the auth-service client, like the messenger does.
ApiClient _sharedSessionClient(Ref ref, String baseUrl) {
  final auth = ref.watch(apiClientProvider);
  final client = ApiClient(ref.watch(tokenStoreProvider), baseUrl: baseUrl, authClient: auth);
  client.onSessionExpired = () => auth.onSessionExpired?.call();
  return client;
}

final walletApiClientProvider = Provider<ApiClient>((ref) => _sharedSessionClient(ref, AppConfig.walletUrl));

final listingApiClientProvider = Provider<ApiClient>((ref) => _sharedSessionClient(ref, AppConfig.listingUrl));

final propertyApiClientProvider = Provider<ApiClient>((ref) => _sharedSessionClient(ref, AppConfig.propertyUrl));

final walletRepositoryProvider =
    Provider<WalletRepository>((ref) => WalletRepository(ref.watch(walletApiClientProvider)));

final listingRepositoryProvider =
    Provider<ListingRepository>((ref) => ListingRepository(ref.watch(listingApiClientProvider)));

final propertyRepositoryProvider =
    Provider<PropertyRepository>((ref) => PropertyRepository(ref.watch(propertyApiClientProvider)));

/// The developer service has its own accounts. Its token lives in its own secure storage key.
final developerTokenStoreProvider = Provider<DeveloperTokenStore>((ref) => DeveloperTokenStore());

final developerClientProvider = Provider<ServiceClient>((ref) {
  final store = ref.watch(developerTokenStoreProvider);
  return ServiceClient(
    AppConfig.developerUrl,
    tokenProvider: store.read,
    onUnauthorized: () => ref.read(developerSessionProvider.notifier).expire(),
  );
});

final developerRepositoryProvider =
    Provider<DeveloperRepository>((ref) => DeveloperRepository(ref.watch(developerClientProvider)));

/// The C2B Hakikisha service has its own client credentials. The token it hands out is kept in memory only.
final c2bClientProvider = Provider<ServiceClient>((ref) {
  return ServiceClient(
    AppConfig.c2bUrl,
    tokenProvider: () async {
      final s = ref.read(c2bSessionProvider);
      return s.active ? s.token : null;
    },
    onUnauthorized: () => ref.read(c2bSessionProvider.notifier).disconnect(),
  );
});

final c2bRepositoryProvider = Provider<C2bRepository>((ref) => C2bRepository(ref.watch(c2bClientProvider)));
