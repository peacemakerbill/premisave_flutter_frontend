import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/branding/social_logos.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/brand.dart';
import '../../data/social_auth_service.dart';
import '../../state/session_controller.dart';

/// "Or continue with" row for sign in and sign up. All three providers are always shown; one
/// that cannot work on this device says why when it is tapped, instead of failing.
class SocialAuthButtons extends ConsumerStatefulWidget {
  const SocialAuthButtons({
    super.key,
    required this.onError,
    this.onNotice,
    this.disabled = false,
    this.onBusyChanged,
    this.onSignIn,
    this.only,
  });

  /// Handles the tap instead of signing in to the Premisave account. Used by the developer portal, which has its own
  /// accounts. Returns false when the person closed the sign in window.
  final Future<bool> Function(String provider)? onSignIn;

  /// Shows only these providers (google, facebook, github). Everything when null.
  final List<String>? only;

  /// Receives the message to show, or null to clear the previous one.
  final ValueChanged<String?> onError;

  /// Receives the explanation for a provider that cannot work on this device. It is information,
  /// not a failure, so a screen can show it more gently. Falls back to [onError] when not given.
  final ValueChanged<String?>? onNotice;
  final bool disabled;
  final ValueChanged<bool>? onBusyChanged;

  @override
  ConsumerState<SocialAuthButtons> createState() => _SocialAuthButtonsState();
}

class _SocialAuthButtonsState extends ConsumerState<SocialAuthButtons> {
  String? _active;

  Future<void> _run(String provider) async {
    // A screen with its own sign in (the developer portal) checks what it needs when it runs, using its own client ids.
    final reason = widget.onSignIn == null ? SocialAuthService.unavailableReason(provider) : null;
    if (reason != null) {
      (widget.onNotice ?? widget.onError)(reason);
      return;
    }
    setState(() => _active = provider);
    widget.onBusyChanged?.call(true);
    widget.onError(null);
    widget.onNotice?.call(null);
    try {
      final custom = widget.onSignIn;
      if (custom != null) {
        await custom(provider);
        return;
      }
      final session = ref.read(sessionProvider.notifier);
      switch (provider) {
        case 'google':
          await session.signInWithGoogle();
        case 'facebook':
          await session.signInWithFacebook();
        default:
          await session.signInWithGithub();
      }
      // The router moves a signed-in user on by itself.
    } catch (e) {
      widget.onError(ApiException.from(e).message);
    } finally {
      if (mounted) setState(() => _active = null);
      widget.onBusyChanged?.call(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = <_Provider>[
      const _Provider('google', 'Google', SocialLogo.google()),
      const _Provider('facebook', 'Facebook', SocialLogo.facebook()),
      _Provider('github', 'GitHub', SocialLogo.github(color: context.inkColor)),
    ].where((p) => widget.only == null || widget.only!.contains(p.id)).toList();
    if (items.isEmpty) return const SizedBox.shrink();

    final busy = widget.disabled || _active != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SizedBox(height: 22),
        Row(
          children: <Widget>[
            Expanded(child: Divider(color: context.borderColor)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('or continue with', style: TextStyle(fontSize: 12.5, color: context.mutedColor)),
            ),
            Expanded(child: Divider(color: context.borderColor)),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: <Widget>[
            for (var i = 0; i < items.length; i++) ...<Widget>[
              if (i > 0) const SizedBox(width: 10),
              Expanded(
                child: _SocialButton(
                  label: items[i].label,
                  glyph: items[i].glyph,
                  loading: _active == items[i].id,
                  onPressed: busy ? null : () => _run(items[i].id),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _Provider {
  const _Provider(this.id, this.label, this.glyph);

  final String id;
  final String label;
  final Widget glyph;
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({required this.label, required this.glyph, required this.loading, required this.onPressed});

  final String label;
  final Widget glyph;
  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: OutlinedButton(
        onPressed: loading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: context.borderColor, width: 1.4),
          backgroundColor: context.surfaceColor,
          foregroundColor: context.inkColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.radius(14))),
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
        child: loading
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  glyph,
                  const SizedBox(width: 9),
                  Flexible(
                    child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  ),
                ],
              ),
      ),
    );
  }
}
