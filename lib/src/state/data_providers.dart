import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/application_models.dart';
import '../data/models/location_model.dart';
import '../data/models/security_models.dart';
import '../data/models/social_models.dart';
import '../data/models/user_model.dart';
import 'providers.dart';
import 'session_controller.dart';

// All providers here are autoDispose, so leaving a screen drops its data and the next visit
// loads fresh. Screens call ref.invalidate(provider) after a change or on pull to refresh.

// ------------------------------------------------------------------- security

final sessionsProvider = FutureProvider.autoDispose<List<SessionView>>(
  (ref) => ref.watch(securityRepositoryProvider).sessions(),
);

final devicesProvider = FutureProvider.autoDispose<List<DeviceView>>(
  (ref) => ref.watch(securityRepositoryProvider).devices(),
);

final deviceDetailProvider = FutureProvider.autoDispose.family<DeviceDetail, String>(
  (ref, id) => ref.watch(securityRepositoryProvider).device(id),
);

final signInsProvider = FutureProvider.autoDispose<List<SignInView>>(
  (ref) => ref.watch(securityRepositoryProvider).signIns(),
);

final securityEventsProvider = FutureProvider.autoDispose<List<SecurityEventView>>(
  (ref) => ref.watch(securityRepositoryProvider).events(),
);

/// What the audit trail is filtered by. [from] is a moment, so "last 7 days" is turned into a date when picked.
class AuditFilter {
  const AuditFilter({
    this.type,
    this.userId,
    this.severity,
    this.outcome,
    this.ip,
    this.from,
    this.page = 0,
  });

  final String? type;
  final String? userId;
  final String? severity;
  final String? outcome;
  final String? ip;
  final DateTime? from;
  final int page;

  AuditFilter onPage(int p) => AuditFilter(
        type: type,
        userId: userId,
        severity: severity,
        outcome: outcome,
        ip: ip,
        from: from,
        page: p,
      );

  /// True when something other than the person is narrowing the list.
  bool get narrowed => type != null || severity != null || outcome != null || ip != null || from != null;

  @override
  bool operator ==(Object other) =>
      other is AuditFilter &&
      other.type == type &&
      other.userId == userId &&
      other.severity == severity &&
      other.outcome == outcome &&
      other.ip == ip &&
      other.from == from &&
      other.page == page;

  @override
  int get hashCode => Object.hash(type, userId, severity, outcome, ip, from, page);
}

const int auditPageSize = 50;

final auditEventsProvider = FutureProvider.autoDispose.family<List<SecurityEventView>, AuditFilter>(
  (ref, f) => ref.watch(securityRepositoryProvider).adminEvents(
        type: f.type,
        userId: f.userId,
        severity: f.severity,
        outcome: f.outcome,
        ip: f.ip,
        from: f.from,
        page: f.page,
        size: auditPageSize,
      ),
);

final auditEventProvider = FutureProvider.autoDispose.family<SecurityEventView, String>(
  (ref, id) => ref.watch(securityRepositoryProvider).adminEvent(id),
);

final auditSummaryProvider = FutureProvider.autoDispose.family<AuditSummary, int>(
  (ref, hours) => ref.watch(securityRepositoryProvider).adminSummary(hours: hours),
);

// --------------------------------------------------------------------- social

final myStatsProvider = FutureProvider.autoDispose<StatsModel>((ref) async {
  final id = ref.watch(sessionProvider.select((s) => s.user?.id));
  if (id == null) return StatsModel(<String, dynamic>{});
  return ref.watch(socialRepositoryProvider).stats(id);
});

final directoryProvider = FutureProvider.autoDispose<List<DirectoryEntry>>(
  (ref) => ref.watch(profileRepositoryProvider).directory(),
);

final followingProvider = FutureProvider.autoDispose<List<UserModel>>(
  (ref) => ref.watch(socialRepositoryProvider).myFollowing(),
);

final followersProvider = FutureProvider.autoDispose<List<UserModel>>(
  (ref) => ref.watch(socialRepositoryProvider).myFollowers(),
);

final myLikesProvider = FutureProvider.autoDispose<List<UserModel>>(
  (ref) => ref.watch(socialRepositoryProvider).myLikes(),
);

final myLikersProvider = FutureProvider.autoDispose<List<UserModel>>(
  (ref) => ref.watch(socialRepositoryProvider).myLikers(),
);

final reviewsAboutMeProvider = FutureProvider.autoDispose<List<ReviewModel>>(
  (ref) => ref.watch(socialRepositoryProvider).myReviews(),
);

final reviewsIWroteProvider = FutureProvider.autoDispose<List<ReviewModel>>(
  (ref) => ref.watch(socialRepositoryProvider).myWrittenReviews(),
);

final whoViewedMeProvider = FutureProvider.autoDispose<List<ProfileViewEntry>>(
  (ref) => ref.watch(profileRepositoryProvider).whoViewedMe(),
);

final whoIViewedProvider = FutureProvider.autoDispose<List<ProfileViewEntry>>(
  (ref) => ref.watch(profileRepositoryProvider).whoIViewed(),
);

final myViewStatsProvider = FutureProvider.autoDispose<StatsModel>(
  (ref) => ref.watch(profileRepositoryProvider).myViewStats(),
);

/// Everything the public profile screen needs, loaded together.
class PublicProfile {
  const PublicProfile({
    required this.user,
    required this.stats,
    required this.reviews,
    required this.liked,
    required this.following,
    required this.mutual,
    required this.reviewed,
  });

  final UserModel user;
  final StatsModel stats;
  final List<ReviewModel> reviews;
  final bool liked;
  final bool following;
  final bool mutual;
  final bool reviewed;
}

final publicProfileProvider = FutureProvider.autoDispose.family<PublicProfile, String>((ref, id) async {
  final profiles = ref.watch(profileRepositoryProvider);
  final social = ref.watch(socialRepositoryProvider);
  final myId = ref.watch(sessionProvider.select((s) => s.user?.id));
  final isMe = myId == id;

  final user = await profiles.user(id);

  // The counters and flags are nice to have: a failure in one must not hide the profile.
  Future<T> safe<T>(Future<T> Function() call, T fallback) async {
    try {
      return await call();
    } catch (_) {
      return fallback;
    }
  }

  if (!isMe) {
    // Counts as a profile view for the person being looked at. Failure is harmless.
    safe<void>(() => profiles.recordView(id), null);
  }

  final results = await Future.wait<Object>(<Future<Object>>[
    safe<Object>(() => social.stats(id), StatsModel(<String, dynamic>{})),
    safe<Object>(() => social.reviewsFor(id), <ReviewModel>[]),
    safe<Object>(() => isMe ? Future<bool>.value(false) : social.likeStatus(id), false),
    safe<Object>(() => isMe ? Future<bool>.value(false) : social.followStatus(id), false),
    safe<Object>(() => isMe ? Future<bool>.value(false) : social.mutualFollow(id), false),
    safe<Object>(() => isMe ? Future<bool>.value(false) : social.reviewStatus(id), false),
  ]);

  return PublicProfile(
    user: user,
    stats: results[0] as StatsModel,
    reviews: results[1] as List<ReviewModel>,
    liked: results[2] as bool,
    following: results[3] as bool,
    mutual: results[4] as bool,
    reviewed: results[5] as bool,
  );
});

// ------------------------------------------------------------------- location

final currentLocationProvider = FutureProvider.autoDispose<LocationModel?>(
  (ref) => ref.watch(profileRepositoryProvider).currentLocation(),
);

final locationHistoryProvider = FutureProvider.autoDispose<List<LocationModel>>(
  (ref) => ref.watch(profileRepositoryProvider).locationHistory(),
);

// --------------------------------------------------------------- applications

/// Dropdown options, countries and upload limits. Rarely change, so kept for the session.
final appMetaProvider = FutureProvider<AppMeta>(
  (ref) => ref.watch(applicationRepositoryProvider).meta(),
);

final eligibilityProvider = FutureProvider.autoDispose<Eligibility>(
  (ref) => ref.watch(applicationRepositoryProvider).eligibility(),
);

final myApplicationProvider = FutureProvider.autoDispose<ApplicationDetail?>(
  (ref) => ref.watch(applicationRepositoryProvider).mine(),
);

final staffStatsProvider = FutureProvider.autoDispose<StaffStats>(
  (ref) => ref.watch(applicationRepositoryProvider).staffStats(),
);

final staffApplicationProvider = FutureProvider.autoDispose.family<ApplicationDetail, String>(
  (ref, id) => ref.watch(applicationRepositoryProvider).staffGet(id),
);

final reviewersProvider = FutureProvider.autoDispose<List<StaffMember>>(
  (ref) => ref.watch(applicationRepositoryProvider).reviewers(),
);

// ----------------------------------------------------------------------- admin

final adminUsersProvider = FutureProvider.autoDispose<List<UserModel>>(
  (ref) => ref.watch(adminRepositoryProvider).all(),
);

final adminUserProvider = FutureProvider.autoDispose.family<UserModel, String>(
  (ref, id) => ref.watch(adminRepositoryProvider).byId(id),
);

final applicationProvider = FutureProvider.autoDispose.family<ApplicationDetail, String>(
  (ref, id) => ref.watch(applicationRepositoryProvider).get(id),
);

final myApplicationsProvider = FutureProvider.autoDispose<List<ApplicationSummary>>(
  (ref) => ref.watch(applicationRepositoryProvider).myApplications(),
);
