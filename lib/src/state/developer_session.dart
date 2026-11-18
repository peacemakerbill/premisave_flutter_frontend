import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/network/api_exception.dart';
import '../data/models/developer_models.dart';
import '../data/social_auth_service.dart';
import 'providers.dart';

/// Keeps the developer service token in secure storage, apart from the auth-service tokens.
class DeveloperTokenStore {
  DeveloperTokenStore([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
              webOptions: WebOptions(publicKey: 'premisave_developer'),
            );

  final FlutterSecureStorage _storage;

  static const _kToken = 'ps_developer_token';

  String? _cache;
  bool _loaded = false;

  Future<String?> read() async {
    if (_loaded) return _cache;
    try {
      _cache = await _storage.read(key: _kToken);
    } catch (_) {
      _cache = null;
    }
    _loaded = true;
    return _cache;
  }

  Future<void> save(String token) async {
    _cache = token;
    _loaded = true;
    try {
      await _storage.write(key: _kToken, value: token);
    } catch (_) {
      // The token still works for this run if storage is unavailable.
    }
  }

  Future<void> clear() async {
    _cache = null;
    _loaded = true;
    try {
      await _storage.delete(key: _kToken);
    } catch (_) {}
  }
}

enum DeveloperStatus { loading, signedOut, signedIn }

class DeveloperSessionState {
  const DeveloperSessionState({this.status = DeveloperStatus.loading, this.account});

  final DeveloperStatus status;
  final DeveloperAccount? account;
}

final developerSessionProvider =
    NotifierProvider<DeveloperSession, DeveloperSessionState>(DeveloperSession.new);

/// The developer portal sign in. It is separate from the Premisave sign in, because the developer service keeps its
/// own accounts and issues its own token.
class DeveloperSession extends Notifier<DeveloperSessionState> {
  @override
  DeveloperSessionState build() {
    Future<void>.microtask(_restore);
    return const DeveloperSessionState();
  }

  Future<void> _restore() async {
    final store = ref.read(developerTokenStoreProvider);
    final token = await store.read();
    if (token == null || token.isEmpty) {
      state = const DeveloperSessionState(status: DeveloperStatus.signedOut);
      return;
    }
    try {
      final account = await ref.read(developerRepositoryProvider).me();
      state = DeveloperSessionState(status: DeveloperStatus.signedIn, account: account);
    } catch (e) {
      if (ApiException.from(e).isUnauthorized) await store.clear();
      state = const DeveloperSessionState(status: DeveloperStatus.signedOut);
    }
  }

  /// Throws an [ApiException] with a readable message when the sign in fails.
  Future<void> signIn({required String email, required String password}) async {
    final repo = ref.read(developerRepositoryProvider);
    final token = await repo.login(email: email, password: password);
    await ref.read(developerTokenStoreProvider).save(token);
    final account = await repo.me();
    state = DeveloperSessionState(status: DeveloperStatus.signedIn, account: account);
  }

  /// Signs in with a token the developer service already issued, such as the one from a social sign in.
  Future<void> signInWithToken(String token) async {
    await ref.read(developerTokenStoreProvider).save(token);
    final account = await ref.read(developerRepositoryProvider).me();
    state = DeveloperSessionState(status: DeveloperStatus.signedIn, account: account);
  }

  /// Signs in or up with Google, Facebook or GitHub. Returns false when the person closed the sign in window.
  Future<bool> signInSocial(String provider) async {
    final String? credential;
    switch (provider) {
      case 'google':
        credential = await SocialAuthService.googleIdToken();
      case 'facebook':
        credential = await SocialAuthService.facebookAccessToken();
      default:
        credential = await SocialAuthService.githubCode();
    }
    if (credential == null) return false;
    final token = await ref.read(developerRepositoryProvider).socialLogin(provider, credential);
    await signInWithToken(token);
    return true;
  }

  /// Reloads the account after the profile changed.
  Future<void> refresh() async {
    try {
      final account = await ref.read(developerRepositoryProvider).me();
      state = DeveloperSessionState(status: DeveloperStatus.signedIn, account: account);
    } catch (_) {}
  }

  Future<void> signOut() async {
    try {
      await ref.read(developerRepositoryProvider).logout();
    } catch (_) {
      // Signing out locally is enough when the server cannot be reached.
    }
    await ref.read(developerTokenStoreProvider).clear();
    state = const DeveloperSessionState(status: DeveloperStatus.signedOut);
  }

  /// The server rejected the token (expired or revoked).
  void expire() {
    ref.read(developerTokenStoreProvider).clear();
    if (state.status != DeveloperStatus.signedOut) {
      state = const DeveloperSessionState(status: DeveloperStatus.signedOut);
    }
  }
}
