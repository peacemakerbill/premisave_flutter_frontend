import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/widgets.dart';
import '../../data/models/call_models.dart';
import '../../state/call_controller.dart';
import '../../state/messenger_controller.dart';
import 'call_screen.dart';
import 'call_widgets.dart';

/// The call screen's own Navigator, so the back button can close a sheet or dialog opened on it.
final GlobalKey<NavigatorState> callNavigatorKey = GlobalKey<NavigatorState>();

/// The system back button while a call fills the screen: close a sheet or dialog on the call screen first,
/// then shrink the call to its bar. Returns true when it handled the press.
Future<bool> handleCallBackButton(WidgetRef ref) async {
  final call = ref.read(callProvider);
  if (call.session == null || !call.expanded) return false;
  final nav = callNavigatorKey.currentState;
  if (nav != null && await nav.maybePop()) return true;
  ref.read(callProvider.notifier).setExpanded(false);
  return true;
}

/// Sits above the whole app, so a call can open over any screen, shrink to a bar while the app is used, and ring
/// whatever the person is looking at. Place it in the MaterialApp builder.
class CallHost extends ConsumerWidget {
  const CallHost({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final call = ref.watch(callProvider);
    ref.listen<int>(callProvider.select((s) => s.noticeSeq), (prev, next) {
      final msg = ref.read(callProvider).notice;
      if (msg != null && msg.isNotEmpty) showToast(context, msg);
    });

    final session = call.session;
    final minimised = session != null && !call.expanded;

    // The app keeps the same place in the tree whether or not the bar shows, so its state is never lost.
    final app = Column(
      children: <Widget>[
        if (session != null && minimised) MiniCallBar(key: const ValueKey<String>('call-bar'), session: session),
        Expanded(
          key: const ValueKey<String>('call-app'),
          child: MediaQuery.removePadding(context: context, removeTop: minimised, child: child),
        ),
      ],
    );

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        app,
        if (session != null && call.expanded)
          Positioned.fill(
            key: ValueKey<String>('call-${session.callId}'),
            child: _CallLayer(session: session),
          ),
        if (call.incoming.isNotEmpty)
          Positioned.fill(
            key: const ValueKey<String>('call-incoming'),
            child: IncomingCallOverlay(call: call.incoming.last, waiting: session != null, more: call.incoming.length - 1),
          ),
      ],
    );
  }
}

/// The call screen has its own small Navigator, so dialogs and sheets opened from it appear above it and not
/// behind it.
class _CallLayer extends StatelessWidget {
  const _CallLayer({required this.session});

  final CallSession session;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      builder: (context, t, child) => Opacity(opacity: t, child: Transform.scale(scale: 0.98 + 0.02 * t, child: child)),
      child: Navigator(
        key: callNavigatorKey,
        onGenerateRoute: (settings) => PageRouteBuilder<void>(
          settings: settings,
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          pageBuilder: (context, _, __) => CallScreen(session: session),
        ),
      ),
    );
  }
}

/// The green bar shown above the app while a call is minimised.
class MiniCallBar extends ConsumerWidget {
  const MiniCallBar({super.key, required this.session});

  final CallSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctl = ref.read(callProvider.notifier);
    return Material(
      color: const Color(0xFF1F6B4D),
      child: SafeArea(
        bottom: false,
        child: ListenableBuilder(
          listenable: session,
          builder: (context, _) {
            final started = session.call.startedAt ?? session.connectedAt;
            return InkWell(
              onTap: () => ctl.setExpanded(true),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
                child: Row(
                  children: <Widget>[
                    Icon(session.call.isVideo ? Icons.videocam_rounded : Icons.call_rounded, color: Colors.white, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text.rich(
                        TextSpan(children: <InlineSpan>[
                          TextSpan(text: session.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                          const TextSpan(text: '   '),
                          WidgetSpan(
                            alignment: PlaceholderAlignment.baseline,
                            baseline: TextBaseline.alphabetic,
                            child: session.isConnected && !session.ringingOut
                                ? CallTimerText(since: started, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600))
                                : Text(session.ringingOut ? 'Ringing' : 'Connecting', style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                          ),
                        ]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: Icon(session.micOn ? Icons.mic_rounded : Icons.mic_off_rounded, color: Colors.white, semanticLabel: session.micOn ? 'Mute' : 'Unmute'),
                      onPressed: session.toggleMic,
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.open_in_full_rounded, color: Colors.white, size: 20, semanticLabel: 'Back to call'),
                      onPressed: () => ctl.setExpanded(true),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.call_end_rounded, color: Color(0xFFFFB4B4), semanticLabel: 'Leave call'),
                      onPressed: ctl.leave,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Rings over everything. A full card when the person is free, a small banner when they are already on a call.
class IncomingCallOverlay extends ConsumerWidget {
  const IncomingCallOverlay({super.key, required this.call, required this.waiting, this.more = 0});

  final CallInfo call;
  final bool waiting;
  final int more;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctl = ref.read(callProvider.notifier);
    final me = ref.read(messengerProvider.notifier).meId;
    final busy = ref.watch(callProvider.select((s) => s.busy));
    final head = call.headPerson(me) ?? call.person(call.initiatorId);
    final caller = call.initiatorName.isNotEmpty ? call.initiatorName : (head?.name ?? 'Premisave member');
    final chat = call.chatId == null ? null : ref.watch(messengerProvider.select((s) => s.chatById(call.chatId!)));
    final group = call.kind == CallKind.group;
    final title = group ? (chat?.title ?? call.titleFor(me)) : caller;
    final what = '${call.isVideo ? 'Video' : 'Voice'} call${group ? ' from $caller' : ''}';
    final picture = group ? (chat?.photo ?? head?.picture) : (call.person(call.initiatorId)?.picture ?? head?.picture);

    if (waiting) {
      return SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Material(
              color: CallColors.control,
              elevation: 8,
              borderRadius: BorderRadius.circular(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                  child: Row(
                    children: <Widget>[
                      UserAvatar(initials: initialsOf(title), imageUrl: picture, size: 40),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: CallColors.text, fontWeight: FontWeight.w800)),
                            Text('$what, while you are on a call', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: CallColors.muted, fontSize: 12)),
                          ],
                        ),
                      ),
                      IconButton(icon: const Icon(Icons.call_end_rounded, color: CallColors.danger, semanticLabel: 'Decline'), onPressed: () => ctl.decline(call.id)),
                      IconButton(
                        icon: const Icon(Icons.call_rounded, color: CallColors.speaking, semanticLabel: 'Leave this call and answer'),
                        onPressed: busy ? null : () => ctl.answer(call.id),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    final wide = MediaQuery.of(context).size.width >= 700;
    final card = Material(
      color: CallColors.bg,
      elevation: 12,
      borderRadius: BorderRadius.circular(wide ? 22 : 0),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, wide ? 28 : 56, 24, wide ? 26 : 40),
          child: Column(
            mainAxisSize: wide ? MainAxisSize.min : MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(what, style: const TextStyle(color: CallColors.muted, fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 28),
                  _Pulse(child: UserAvatar(initials: initialsOf(title), imageUrl: picture, size: wide ? 96 : 132)),
                  const SizedBox(height: 22),
                  Text(title, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: CallColors.text, fontSize: 26, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(
                    call.people.length > 2 ? '${call.joined.length} in the call' : 'Premisave',
                    style: const TextStyle(color: CallColors.muted, fontSize: 14),
                  ),
                  if (more > 0) ...<Widget>[
                    const SizedBox(height: 10),
                    Text('$more more waiting', style: const TextStyle(color: CallColors.hand, fontSize: 13, fontWeight: FontWeight.w700)),
                  ],
                ],
              ),
              SizedBox(height: wide ? 36 : 0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  CallControl(icon: Icons.call_end_rounded, label: 'Decline', danger: true, size: 66, tooltip: false, onTap: () => ctl.decline(call.id)),
                  CallControl(
                    icon: call.isVideo ? Icons.videocam_rounded : Icons.call_rounded,
                    label: 'Answer',
                    size: 66,
                    tooltip: false,
                    enabled: !busy,
                    onTap: () => ctl.answer(call.id),
                  ).withAccent(CallColors.speaking),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (!wide) return card;
    return ColoredBox(
      color: Colors.black54,
      child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 400), child: card)),
    );
  }
}

extension on CallControl {
  /// An "Answer" button drawn in the call's green.
  Widget withAccent(Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Opacity(
          opacity: enabled ? 1 : 0.4,
          child: Material(
            color: color,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: enabled ? onTap : null,
              child: SizedBox(width: size, height: size, child: Icon(icon, color: CallColors.bg, size: size * 0.44)),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: CallColors.muted, fontSize: 11.5, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

/// A soft ring that breathes around the caller's picture.
class _Pulse extends StatefulWidget {
  const _Pulse({required this.child});

  final Widget child;

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: <Widget>[
            for (final phase in <double>[0, 0.5])
              Builder(builder: (context) {
                final t = (_c.value + phase) % 1.0;
                return Container(
                  width: 120 + 90 * t,
                  height: 120 + 90 * t,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: CallColors.speaking.withValues(alpha: (1 - t) * 0.45), width: 2),
                  ),
                );
              }),
            child!,
          ],
        );
      },
      child: widget.child,
    );
  }
}
