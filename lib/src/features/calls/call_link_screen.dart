import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/brand.dart';
import '../../core/theme/palette.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/call_models.dart';
import '../../state/call_controller.dart';
import '../../state/providers.dart';

final _linkPreviewProvider = FutureProvider.autoDispose.family<CallLinkPreview, String>((ref, code) {
  return ref.watch(callRepositoryProvider).previewLink(code);
});

/// Where a call link lands: who is on the call, and a Join button.
class CallLinkScreen extends ConsumerWidget {
  const CallLinkScreen({super.key, required this.code});

  final String code;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preview = ref.watch(_linkPreviewProvider(code));
    final busy = ref.watch(callProvider.select((s) => s.busy));
    return SubPage(
      title: 'Call link',
      fallbackRoute: '/messages',
      body: preview.when(
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(error: e, onRetry: () => ref.invalidate(_linkPreviewProvider(code))),
        data: (p) {
          final blocked = p.locked ? 'The host has locked this call.' : (p.full ? 'This call is full.' : (!p.joinable ? 'This call has ended or the link has expired.' : null));
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    CircleAvatar(radius: 40, backgroundColor: context.pal.accentSoft, child: Icon(p.media == CallMedia.video ? Icons.videocam_rounded : Icons.call_rounded, size: 36, color: context.pal.accent)),
                    const SizedBox(height: 18),
                    Text((p.title ?? '').isNotEmpty ? p.title! : '${p.media == CallMedia.video ? 'Video' : 'Voice'} call', textAlign: TextAlign.center, style: context.display(size: 24, weight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text(
                      p.hostName.isEmpty ? 'Hosted on Premisave' : 'Hosted by ${p.hostName}',
                      style: TextStyle(color: context.mutedColor),
                    ),
                    const SizedBox(height: 4),
                    Text(p.participantCount == 0 ? 'Nobody is on the call yet' : (p.participantCount == 1 ? '1 person is on the call' : '${p.participantCount} people are on the call'), style: TextStyle(color: context.mutedColor)),
                    const SizedBox(height: 24),
                    if (blocked != null)
                      Text(blocked, textAlign: TextAlign.center, style: TextStyle(color: context.pal.bad, fontWeight: FontWeight.w700))
                    else
                      PButton(
                        label: 'Join call',
                        icon: Icons.call_rounded,
                        expand: true,
                        loading: busy,
                        onPressed: () async {
                          final ok = await ref.read(callProvider.notifier).joinLink(code);
                          if (ok && context.mounted) context.go('/messages');
                        },
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
