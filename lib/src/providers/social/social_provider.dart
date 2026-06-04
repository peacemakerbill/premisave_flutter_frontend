import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../config/app_config.dart';
import '../auth/auth_provider.dart';

// ─── Models ───────────────────────────────────────────────────────────────────

class PublicUserProfile {
  final String id;
  final String username;
  final String firstName;
  final String lastName;
  final String? profilePictureUrl;
  final String role;
  final bool verified;

  const PublicUserProfile({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    this.profilePictureUrl,
    required this.role,
    required this.verified,
  });

  String get fullName => '$firstName $lastName'.trim();
  String get displayRole => role.replaceAll('_', ' ').toLowerCase();

  factory PublicUserProfile.fromJson(Map<String, dynamic> json) {
    return PublicUserProfile(
      id: json['id'] ?? '',
      username: json['username'] ?? json['displayUsername'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      profilePictureUrl: json['profilePictureUrl'],
      role: (json['role'] ?? 'CLIENT').toString(),
      verified: json['verified'] ?? false,
    );
  }
}

class UserStats {
  final int followerCount;
  final int followingCount;
  final int likeCount;
  final double averageRating;
  final int totalReviews;
  final int totalProfileViews;

  const UserStats({
    this.followerCount = 0,
    this.followingCount = 0,
    this.likeCount = 0,
    this.averageRating = 0.0,
    this.totalReviews = 0,
    this.totalProfileViews = 0,
  });

  factory UserStats.fromSocialAndViews(
      Map<String, dynamic> social,
      Map<String, dynamic> views,
      ) {
    return UserStats(
      followerCount: (social['followerCount'] ?? 0) as int,
      followingCount: (social['followingCount'] ?? 0) as int,
      likeCount: (social['likeCount'] ?? 0) as int,
      averageRating: (social['averageRating'] ?? 0.0).toDouble(),
      totalReviews: (social['totalReviews'] ?? 0) as int,
      totalProfileViews: (views['totalViews'] ?? 0) as int,
    );
  }
}

class ProfileViewEntry {
  final String viewerId;
  final String viewerName;
  final String? viewerProfilePicture;
  final DateTime? viewedAt;
  final String? deviceType;
  final String? source;

  const ProfileViewEntry({
    required this.viewerId,
    required this.viewerName,
    this.viewerProfilePicture,
    this.viewedAt,
    this.deviceType,
    this.source,
  });

  factory ProfileViewEntry.fromJson(Map<String, dynamic> json) {
    return ProfileViewEntry(
      viewerId: json['viewerId'] ?? '',
      viewerName: json['viewerName'] ?? '',
      viewerProfilePicture: json['viewerProfilePicture'],
      viewedAt: json['viewedAt'] != null
          ? DateTime.tryParse(json['viewedAt'].toString())
          : null,
      deviceType: json['deviceType'],
      source: json['source'],
    );
  }
}

// ─── State ────────────────────────────────────────────────────────────────────

class SocialState {
  final List<PublicUserProfile> users;
  final List<PublicUserProfile> searchResults;
  final bool isLoadingUsers;
  final bool isSearching;
  final String? error;
  final Set<String> likedUserIds;
  final Set<String> followingUserIds;

  const SocialState({
    this.users = const [],
    this.searchResults = const [],
    this.isLoadingUsers = false,
    this.isSearching = false,
    this.error,
    this.likedUserIds = const {},
    this.followingUserIds = const {},
  });

  SocialState copyWith({
    List<PublicUserProfile>? users,
    List<PublicUserProfile>? searchResults,
    bool? isLoadingUsers,
    bool? isSearching,
    String? error,
    Set<String>? likedUserIds,
    Set<String>? followingUserIds,
  }) {
    return SocialState(
      users: users ?? this.users,
      searchResults: searchResults ?? this.searchResults,
      isLoadingUsers: isLoadingUsers ?? this.isLoadingUsers,
      isSearching: isSearching ?? this.isSearching,
      error: error,
      likedUserIds: likedUserIds ?? this.likedUserIds,
      followingUserIds: followingUserIds ?? this.followingUserIds,
    );
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class SocialNotifier extends StateNotifier<SocialState> {
  final Ref _ref;
  late final Dio _dio;

  SocialNotifier(this._ref) : super(const SocialState()) {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ));
  }

  String? get _token => _ref.read(authProvider).token;
  Options get _auth => Options(headers: {'Authorization': 'Bearer $_token'});

  // ── All users ─────────────────────────────────────────────────────────────

  Future<void> loadAllUsers() async {
    state = state.copyWith(isLoadingUsers: true, error: null);
    try {
      final res = await _dio.get('/profile/all', options: _auth);
      final users = (res.data as List)
          .map((e) => PublicUserProfile.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(users: users, isLoadingUsers: false);
    } catch (e) {
      state = state.copyWith(isLoadingUsers: false, error: _err(e));
    }
  }

  // ── Search ────────────────────────────────────────────────────────────────

  Future<void> searchUsers(String query) async {
    if (query.trim().isEmpty) {
      state = state.copyWith(searchResults: [], isSearching: false);
      return;
    }
    state = state.copyWith(isSearching: true, error: null);
    try {
      final res = await _dio.get(
        '/profile/search',
        queryParameters: {'query': query.trim()},
        options: _auth,
      );
      final results = (res.data as List)
          .map((e) => PublicUserProfile.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(searchResults: results, isSearching: false);
    } catch (e) {
      state = state.copyWith(isSearching: false, error: _err(e));
    }
  }

  void clearSearch() => state = state.copyWith(searchResults: []);

  // ── Single profile ────────────────────────────────────────────────────────

  Future<PublicUserProfile?> getUserProfile(String userId) async {
    try {
      final res = await _dio.get('/profile/user/$userId', options: _auth);
      return PublicUserProfile.fromJson(res.data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  // ── Stats ─────────────────────────────────────────────────────────────────

  Future<UserStats> getUserStats(String userId) async {
    try {
      final results = await Future.wait([
        _dio.get('/social/stats/$userId', options: _auth),
        _dio.get(
          '/profile/views/stats',
          queryParameters: {'userId': userId},
          options: _auth,
        ),
      ]);
      return UserStats.fromSocialAndViews(
        results[0].data as Map<String, dynamic>,
        results[1].data as Map<String, dynamic>,
      );
    } catch (_) {
      return const UserStats();
    }
  }

  // ── Profile view recording ────────────────────────────────────────────────

  Future<void> recordProfileView(String targetId) async {
    try {
      await _dio.post('/profile/views/$targetId', options: _auth);
    } catch (_) {}
  }

  // ── Who viewed me ─────────────────────────────────────────────────────────

  Future<List<ProfileViewEntry>> getWhoViewedMe() async {
    try {
      final res = await _dio.get(
        '/profile/views/who-viewed-me',
        options: _auth,
      );
      return (res.data as List)
          .map((e) => ProfileViewEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ── Like / Unlike ─────────────────────────────────────────────────────────

  Future<void> toggleLike(String targetId) async {
    final isLiked = state.likedUserIds.contains(targetId);
    final updated = Set<String>.from(state.likedUserIds);
    isLiked ? updated.remove(targetId) : updated.add(targetId);
    state = state.copyWith(likedUserIds: updated);

    try {
      if (isLiked) {
        await _dio.delete('/social/unlike/$targetId', options: _auth);
      } else {
        await _dio.post(
          '/social/like',
          data: {'targetId': targetId},
          options: _auth,
        );
      }
    } catch (_) {
      // Rollback
      final rb = Set<String>.from(state.likedUserIds);
      isLiked ? rb.add(targetId) : rb.remove(targetId);
      state = state.copyWith(likedUserIds: rb);
    }
  }

  // ── Follow / Unfollow ─────────────────────────────────────────────────────

  Future<void> toggleFollow(String targetId) async {
    final isFollowing = state.followingUserIds.contains(targetId);
    final updated = Set<String>.from(state.followingUserIds);
    isFollowing ? updated.remove(targetId) : updated.add(targetId);
    state = state.copyWith(followingUserIds: updated);

    try {
      if (isFollowing) {
        await _dio.delete('/social/unfollow/$targetId', options: _auth);
      } else {
        await _dio.post(
          '/social/follow',
          data: {'targetId': targetId},
          options: _auth,
        );
      }
    } catch (_) {
      final rb = Set<String>.from(state.followingUserIds);
      isFollowing ? rb.add(targetId) : rb.remove(targetId);
      state = state.copyWith(followingUserIds: rb);
    }
  }

  // ── Error helper ──────────────────────────────────────────────────────────

  String _err(dynamic e) {
    if (e is DioException && e.response?.data != null) {
      final d = e.response!.data;
      if (d is Map<String, dynamic>) return d['message']?.toString() ?? 'Error';
      if (d is String) return d;
    }
    return 'An error occurred';
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final socialProvider =
StateNotifierProvider<SocialNotifier, SocialState>(
      (ref) => SocialNotifier(ref),
);