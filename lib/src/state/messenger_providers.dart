import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/messenger_models.dart';
import 'messenger_controller.dart';
import 'providers.dart';

// Data providers for the messenger screens. Like the others they are autoDispose, so each visit loads fresh.
// Group and status providers also watch a revision counter that the live connection raises, so a screen that is
// open reloads the moment the server says something changed.

final groupDetailsProvider = FutureProvider.autoDispose.family<MGroup, String>((ref, groupId) {
  ref.watch(messengerProvider.select((s) => s.groupRevision));
  return ref.watch(messengerRepositoryProvider).group(groupId);
});

/// The group's working invite link, or null when it has none.
final groupInviteProvider = FutureProvider.autoDispose.family<MInvite?, String>(
  (ref, groupId) => ref.watch(messengerRepositoryProvider).currentInvite(groupId),
);

final invitePreviewProvider = FutureProvider.autoDispose.family<MInvitePreview, String>(
  (ref, code) => ref.watch(messengerRepositoryProvider).previewInvite(code),
);

final statusSettingsProvider = FutureProvider.autoDispose<StatusSettings>(
  (ref) => ref.watch(messengerRepositoryProvider).statusSettings(),
);

final statusFeedProvider = FutureProvider.autoDispose<List<StatusGroup>>((ref) {
  ref.watch(messengerProvider.select((s) => s.statusRevision));
  return ref.watch(messengerRepositoryProvider).statusFeed();
});

final myStatusesProvider = FutureProvider.autoDispose<List<StatusPost>>((ref) {
  ref.watch(messengerProvider.select((s) => s.statusRevision));
  return ref.watch(messengerRepositoryProvider).myStatuses();
});

final myPastStatusesProvider = FutureProvider.autoDispose<StatusPage>((ref) {
  ref.watch(messengerProvider.select((s) => s.statusRevision));
  return ref.watch(messengerRepositoryProvider).myPastStatuses();
});

final statusCommentsProvider = FutureProvider.autoDispose.family<List<StatusComment>, String>(
  (ref, statusId) => ref.watch(messengerRepositoryProvider).statusComments(statusId),
);

final statusInsightsProvider = FutureProvider.autoDispose.family<StatusInsights, String>((ref, statusId) {
  ref.watch(messengerProvider.select((s) => s.statusRevision));
  return ref.watch(messengerRepositoryProvider).statusInsights(statusId);
});

/// Another member's current statuses.
final userStatusesProvider = FutureProvider.autoDispose.family<List<StatusPost>, String>((ref, userId) {
  ref.watch(messengerProvider.select((s) => s.statusRevision));
  return ref.watch(messengerRepositoryProvider).statusesOf(userId);
});

/// How many hours a sender can still edit a message, as the server sets it. 0 means editing is off.
final editWindowProvider = FutureProvider.autoDispose<int>((ref) => ref.watch(messengerRepositoryProvider).editWindowHours());
