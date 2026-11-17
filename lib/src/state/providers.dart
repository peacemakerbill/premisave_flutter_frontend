import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../core/network/api_client.dart';
import '../core/storage/token_store.dart';
import '../data/repositories/admin_repository.dart';
import '../data/repositories/application_repository.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/call_repository.dart';
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
