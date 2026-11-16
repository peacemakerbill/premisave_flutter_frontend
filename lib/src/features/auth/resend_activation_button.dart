import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../core/widgets/widgets.dart';
import '../../state/providers.dart';

/// Sends a fresh activation email without leaving the page.
///
/// The server does not limit how often this can be called, so the button waits out a short
/// cooldown between sends. It starts cooling down straight away by default, because it is shown
/// right after an email has just gone out.
class ResendActivationButton extends ConsumerStatefulWidget {
  const ResendActivationButton({
    super.key,
    required this.email,
    this.label = 'Resend the email',
    this.cooldownSeconds = 60,
    this.startCooling = true,
  });

  final String email;
  final String label;
  final int cooldownSeconds;
  final bool startCooling;

  @override
  ConsumerState<ResendActivationButton> createState() => _ResendActivationButtonState();
}

class _ResendActivationButtonState extends ConsumerState<ResendActivationButton> {
  Timer? _timer;
  int _left = 0;
  bool _busy = false;
  String? _message;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.startCooling) _startCooldown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    _left = widget.cooldownSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _left--;
        if (_left <= 0) {
          _left = 0;
          t.cancel();
        }
      });
    });
  }

  Future<void> _send() async {
    setState(() {
      _busy = true;
      _error = null;
      _message = null;
    });
    try {
      final msg = await ref.read(authRepositoryProvider).resendActivation(widget.email);
      if (!mounted) return;
      setState(() => _message = msg);
      _startCooldown();
    } catch (e) {
      if (mounted) setState(() => _error = ApiException.from(e).message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cooling = _left > 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        PButton(
          label: cooling ? 'Send again in ${_left}s' : widget.label,
          kind: PButtonKind.outline,
          expand: true,
          loading: _busy,
          onPressed: (_busy || cooling) ? null : _send,
        ),
        if (_message != null) ...<Widget>[
          const SizedBox(height: 10),
          InlineMessage(_message!, kind: MessageKind.success),
        ],
        if (_error != null) ...<Widget>[
          const SizedBox(height: 10),
          InlineMessage(_error!, kind: MessageKind.error),
        ],
      ],
    );
  }
}
