import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/network/api_exception.dart';
import '../data/models/auth_models.dart';
import '../data/models/user_model.dart';
import '../data/social_auth_service.dart';
import '../roles/role.dart';
import 'providers.dart';

enum SessionStatus { booting, signedOut, signedIn }

class SessionState {
  const SessionState({this.status = SessionStatus.booting, this.user, this.notice});

  final SessionStatus status;
  final UserModel? user;

  /// One-off message for the sign-in screen, for example "Your session expired".
  final String? notice;

  bool get isSignedIn => status == SessionStatus.signedIn && user != null;
  Role get role => user?.role ?? Role.client;
}

final sessionProvider = NotifierProvider<SessionController, SessionState>(SessionController.new);

class SessionController extends Notifier<SessionState> {
  static const _kUser = 'ps_cached_user';

  @override
  SessionState build() {
    ref.read(apiClientProvider).onSessionExpired = _onExpired;
    return const SessionState();
  }

  /// Called once at start-up. Restores a saved session when there is one.
  Future<void> bootstrap() async {
    final stored = await ref.read(tokenStoreProvider).load();
    if (!stored.hasSession) {
      state = const SessionState(status: SessionStatus.signedOut);
      return;
    }
    final cached = await _readCachedUser();
    try {
      final me = await ref.read(profileRepositoryProvider).me();
      await _cacheUser(me);
      state = SessionState(status: SessionStatus.signedIn, user: me);
    } on ApiException catch (e) {
      if (e.isUnauthorized || e.isForbidden) {
        await _wipe();
        state = const SessionState(status: SessionStatus.signedOut);
      } else if (cached != null) {
        // Offline or the server is down: keep the person in, with what we last saw.
        state = SessionState(status: SessionStatus.signedIn, user: cached);
      } else {
        state = SessionState(status: SessionStatus.signedOut, notice: e.message);
      }
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    final tokens = await ref.read(authRepositoryProvider).signIn(email: email, password: password);
    await _complete(tokens);
  }

  /// Returns the sign-up result. When it carries tokens the user is signed in already,
  /// otherwise the caller should tell them to check their email.
  Future<SignUpResult> signUp({
    required String firstName,
    String? middleName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String password,
    String? username,
    String? country,
  }) async {
    final result = await ref.read(authRepositoryProvider).signUp(
          firstName: firstName,
          middleName: middleName,
          lastName: lastName,
          email: email,
          phoneNumber: phoneNumber,
          password: password,
          username: username,
          country: country,
        );
    if (result.tokens != null) await _complete(result.tokens!);
    return result;
  }

  /// Returns false when the person closed the Google or Facebook sheet.
  Future<bool> signInWithGoogle() async {
    if (SocialAuthService.usesCodeFlow) {
      final code = await SocialAuthService.googleAuthCode();
      if (code == null) return false;
      await _complete(await ref.read(authRepositoryProvider).googleCode(code, SocialAuthService.codeRedirectUri));
      return true;
    }
    final token = await SocialAuthService.googleIdToken();
    if (token == null) return false;
    await _complete(await ref.read(authRepositoryProvider).google(token));
    return true;
  }

  Future<bool> signInWithFacebook() async {
    if (SocialAuthService.usesCodeFlow) {
      final code = await SocialAuthService.facebookAuthCode();
      if (code == null) return false;
      await _complete(await ref.read(authRepositoryProvider).facebookCode(code, SocialAuthService.codeRedirectUri));
      return true;
    }
    final token = await SocialAuthService.facebookAccessToken();
    if (token == null) return false;
    await _complete(await ref.read(authRepositoryProvider).facebook(token));
    return true;
  }

  Future<bool> signInWithGithub() async {
    final code = await SocialAuthService.githubCode();
    if (code == null) return false;
    await _complete(await ref.read(authRepositoryProvider).github(code));
    return true;
  }

  Future<void> signOut() async {
    try {
      await ref.read(authRepositoryProvider).logout();
    } catch (_) {
      // Ending the session on the server is best effort; the device forgets it regardless.
    }
    await SocialAuthService.signOut();
    await _wipe();
    state = const SessionState(status: SessionStatus.signedOut);
  }

  Future<void> refreshUser() async {
    final me = await ref.read(profileRepositoryProvider).me();
    await _cacheUser(me);
    state = SessionState(status: SessionStatus.signedIn, user: me);
  }

  void setUser(UserModel user) {
    _cacheUser(user);
    state = SessionState(status: SessionStatus.signedIn, user: user);
  }

  void clearNotice() {
    if (state.notice != null) {
      state = SessionState(status: state.status, user: state.user);
    }
  }

  // ------------------------------------------------------------------ internals

  Future<void> _complete(AuthTokens t) async {
    final store = ref.read(tokenStoreProvider);
    await store.saveTokens(
      accessToken: t.accessToken,
      refreshToken: t.refreshToken,
      role: t.role,
      expiresInSeconds: t.expiresInSeconds,
      deviceToken: t.deviceToken,
    );
    try {
      final me = await ref.read(profileRepositoryProvider).me();
      await _cacheUser(me);
      state = SessionState(status: SessionStatus.signedIn, user: me);
    } catch (_) {
      await _wipe();
      rethrow;
    }
  }

  void _onExpired() {
    _forgetUser();
    state = const SessionState(
      status: SessionStatus.signedOut,
      notice: 'Your session ended. Please sign in again.',
    );
  }

  Future<void> _wipe() async {
    await ref.read(tokenStoreProvider).clearSession();
    await _forgetUser();
  }

  Future<void> _cacheUser(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kUser, jsonEncode(user.toJson()));
    } catch (_) {}
  }

  Future<UserModel?> _readCachedUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kUser);
      if (raw == null) return null;
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return UserModel.fromJson(decoded);
    } catch (_) {}
    return null;
  }

  Future<void> _forgetUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kUser);
    } catch (_) {}
  }
}
