import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// What we persist about the signed-in session.
class StoredSession {
  const StoredSession({
    this.accessToken,
    this.refreshToken,
    this.deviceToken,
    this.role,
    this.accessExpiresAt,
  });

  final String? accessToken;
  final String? refreshToken;

  /// Remembered-device token. Survives sign-out so the backend recognises this
  /// device next time and does not raise a "new device" alert.
  final String? deviceToken;
  final String? role;
  final DateTime? accessExpiresAt;

  bool get hasSession => (accessToken != null && accessToken!.isNotEmpty) ||
      (refreshToken != null && refreshToken!.isNotEmpty);

  /// True when the access token is missing or about to expire.
  bool expiresWithin(Duration margin) {
    if (accessToken == null || accessToken!.isEmpty) return true;
    final at = accessExpiresAt;
    if (at == null) return false;
    return DateTime.now().add(margin).isAfter(at);
  }
}

/// Secure, in-memory-cached storage for tokens.
class TokenStore {
  TokenStore([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
              webOptions: WebOptions(publicKey: 'premisave_auth'),
            );

  final FlutterSecureStorage _storage;

  static const _kAccess = 'ps_access_token';
  static const _kRefresh = 'ps_refresh_token';
  static const _kDevice = 'ps_device_token';
  static const _kRole = 'ps_role';
  static const _kExpiry = 'ps_access_expiry';

  StoredSession _cache = const StoredSession();
  bool _loaded = false;

  StoredSession get current => _cache;

  Future<StoredSession> load() async {
    if (_loaded) return _cache;
    try {
      final access = await _storage.read(key: _kAccess);
      final refresh = await _storage.read(key: _kRefresh);
      final device = await _storage.read(key: _kDevice);
      final role = await _storage.read(key: _kRole);
      final expiry = await _storage.read(key: _kExpiry);
      _cache = StoredSession(
        accessToken: access,
        refreshToken: refresh,
        deviceToken: device,
        role: role,
        accessExpiresAt: expiry == null ? null : DateTime.tryParse(expiry),
      );
    } catch (_) {
      // Corrupt or unreadable storage (can happen after a reinstall on Android).
      _cache = const StoredSession();
    }
    _loaded = true;
    return _cache;
  }

  /// Saves a fresh set of tokens from sign-in or refresh. Values that are null in
  /// the response keep their previous value (for example the device token).
  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
    String? role,
    int? expiresInSeconds,
    String? deviceToken,
  }) async {
    final expiresAt =
        expiresInSeconds == null ? null : DateTime.now().add(Duration(seconds: expiresInSeconds));
    _cache = StoredSession(
      accessToken: accessToken,
      refreshToken: refreshToken ?? _cache.refreshToken,
      deviceToken: deviceToken ?? _cache.deviceToken,
      role: role ?? _cache.role,
      accessExpiresAt: expiresAt,
    );
    _loaded = true;
    await _write(_kAccess, _cache.accessToken);
    await _write(_kRefresh, _cache.refreshToken);
    await _write(_kDevice, _cache.deviceToken);
    await _write(_kRole, _cache.role);
    await _write(_kExpiry, expiresAt?.toIso8601String());
  }

  /// Signs out locally. The device token is kept on purpose.
  Future<void> clearSession() async {
    _cache = StoredSession(deviceToken: _cache.deviceToken);
    _loaded = true;
    await _write(_kAccess, null);
    await _write(_kRefresh, null);
    await _write(_kRole, null);
    await _write(_kExpiry, null);
  }

  Future<void> _write(String key, String? value) async {
    try {
      if (value == null) {
        await _storage.delete(key: key);
      } else {
        await _storage.write(key: key, value: value);
      }
    } catch (_) {
      // Storage failures must never crash a sign-in; the in-memory copy still works.
    }
  }
}
