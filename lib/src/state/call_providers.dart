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

/// Everything the call details screen shows: the call, its recordings (when recording is on) and the call chat.
class CallDetails {
  const CallDetails({required this.call, this.recordings = const <CallRecording>[], this.messages = const <CallChatMsg>[], this.chatAllowed = true});

  final CallInfo call;
  final List<CallRecording> recordings;
  final List<CallChatMsg> messages;

  /// False when the server refused the chat because this person was not in the call.
  final bool chatAllowed;
}

/// One call with its recordings and chat. Reloads when a call event arrives, for example when a recording is finished.
final callDetailsProvider = FutureProvider.autoDispose.family<CallDetails, String>((ref, callId) async {
  ref.watch(callProvider.select((s) => s.revision));
  final repo = ref.watch(callRepositoryProvider);
  final call = await repo.get(callId);
  var recordings = const <CallRecording>[];
  if (call.recordingEnabled) {
    try {
      recordings = await repo.recordings(callId);
    } catch (_) {
      // The recordings list is optional: the rest of the page still shows.
    }
  }
  var messages = const <CallChatMsg>[];
  var allowed = true;
  try {
    messages = await repo.messages(callId, limit: 1000);
  } catch (_) {
    allowed = false;
  }
  return CallDetails(call: call, recordings: recordings, messages: messages, chatAllowed: allowed);
});

/// The call switches (recording on or off) and whether this person may change them.
final callSettingsProvider = FutureProvider.autoDispose<CallSettings>((ref) => ref.watch(callRepositoryProvider).settings());

