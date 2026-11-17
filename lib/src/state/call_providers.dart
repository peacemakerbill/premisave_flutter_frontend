import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/call_models.dart';
import 'call_controller.dart';
import 'providers.dart';

/// The signed-in person's recent calls. Reloads when a call starts, ends, is missed or answered.
final callHistoryProvider = FutureProvider.autoDispose<List<CallInfo>>((ref) {
  ref.watch(callProvider.select((s) => s.revision));
  return ref.watch(callRepositoryProvider).history(limit: 60);
});

/// The call running in a chat, for the "Join" banner above its messages. Null when there is none.
final activeCallInChatProvider = FutureProvider.autoDispose.family<CallInfo?, String>((ref, chatId) {
  ref.watch(callProvider.select((s) => s.revision));
  return ref.watch(callRepositoryProvider).activeInChat(chatId);
});
