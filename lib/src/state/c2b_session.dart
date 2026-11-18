import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/network/api_exception.dart';
import 'providers.dart';

class C2bSessionState {
  const C2bSessionState({this.token, this.expiresAt, this.shortcode});

  final String? token;
  final DateTime? expiresAt;

  /// The paybill shortcode the service is configured with. Only known after an automatic connection.
  final String? shortcode;

  bool get active => token != null && token!.isNotEmpty && (expiresAt == null || DateTime.now().isBefore(expiresAt!));
}

/// The service username and password, kept in the platform's secure storage only when the person asks for it
/// ("Remember on this device"). Nothing is saved otherwise. The web build never offers it, because the browser has
/// no secure store.
class C2bCredentialStore {
  C2bCredentialStore([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
            );

  final FlutterSecureStorage _storage;

  static const _kUser = 'ps_c2b_username';
  static const _kPass = 'ps_c2b_password';

  Future<(String, String)?> read() async {
    try {
      final user = await _storage.read(key: _kUser);
      final pass = await _storage.read(key: _kPass);
      if (user == null || user.isEmpty || pass == null || pass.isEmpty) return null;
      return (user, pass);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(String username, String password) async {
    try {
      await _storage.write(key: _kUser, value: username);
      await _storage.write(key: _kPass, value: password);
    } catch (_) {
      // Not saving is fine: the person types them again next time.
    }
  }

  Future<void> clear() async {
    try {
      await _storage.delete(key: _kUser);
      await _storage.delete(key: _kPass);
    } catch (_) {}
  }
}

final c2bCredentialStoreProvider = Provider<C2bCredentialStore>((ref) => C2bCredentialStore());

final c2bSessionProvider = NotifierProvider<C2bSession, C2bSessionState>(C2bSession.new);

/// The access token of the C2B Hakikisha service, kept in memory, and gone when the app closes. The credentials that
/// produced it are saved only when [connect] is called with `remember: true`.
class C2bSession extends Notifier<C2bSessionState> {
  @override
  C2bSessionState build() => const C2bSessionState();

  /// Throws an [ApiException] when the service rejects the credentials.
  Future<void> connect({required String username, required String password, bool remember = false}) async {
    final (token, seconds) = await ref.read(c2bRepositoryProvider).generateToken(username: username, password: password);
    final lifetime = seconds > 60 ? seconds - 30 : seconds;
    state = C2bSessionState(token: token, expiresAt: DateTime.now().add(Duration(seconds: lifetime)));
    final store = ref.read(c2bCredentialStoreProvider);
    if (remember) {
      await store.save(username, password);
    } else {
      await store.clear();
    }
  }

  /// Connects with the person's own Premisave sign in. The service holds the Hakikisha username and password in its
  /// configuration, so nothing is typed. Throws an [ApiException] when the service refuses, for example for a role that
  /// is not staff, or when it has no JWT_SECRET set.
  Future<void> connectAutomatically() async {
    final stored = await ref.read(tokenStoreProvider).load();
    final access = stored.accessToken;
    if (access == null || access.isEmpty) throw ApiException('Sign in to Premisave first.');
    final s = await ref.read(c2bRepositoryProvider).consoleSession(access);
    final lifetime = s.expiresIn > 60 ? s.expiresIn - 30 : s.expiresIn;
    state = C2bSessionState(token: s.token, expiresAt: DateTime.now().add(Duration(seconds: lifetime)), shortcode: s.shortcode.isEmpty ? null : s.shortcode);
  }

  void disconnect() => state = const C2bSessionState();

  /// Signs out and removes anything saved on this device.
  Future<void> forget() async {
    await ref.read(c2bCredentialStoreProvider).clear();
    state = const C2bSessionState();
  }
}
