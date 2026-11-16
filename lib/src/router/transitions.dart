import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

/// Page transitions for the whole app. Three kinds, each with one job:
///
/// * [tabPage]: moving between the main sections (Home, People, Account). The old page fades
///   away while the new one fades in and settles up a few pixels, so nothing slides across
///   the screen.
/// * [detailPage]: opening something from a list. A short horizontal shared-axis move: the new
///   page glides in from the right as the old one drifts left and dims. iPhones keep their own
///   swipe-back push instead.
/// * [fadePage]: signed-out screens and the splash, a soft fade with a slight scale.
///
/// Motion is shortened to a plain fade when the device asks to reduce motion.

const Duration _forward = Duration(milliseconds: 320);
const Duration _back = Duration(milliseconds: 240);

bool _reduce(BuildContext context) => MediaQuery.of(context).disableAnimations;

Animation<double> _curve(Animation<double> a, double begin, double end, Curve curve) =>
    a.drive(CurveTween(curve: Interval(begin, end, curve: curve)));

Page<T> tabPage<T>(GoRouterState state, Widget child) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: _forward,
    reverseTransitionDuration: _back,
    transitionsBuilder: (context, animation, secondary, page) {
      final fadeIn = _curve(animation, 0.2, 1, Curves.easeOutCubic);
      final fadeOut = _curve(secondary, 0, 0.4, Curves.easeIn);
      Widget out = page;
      if (!_reduce(context)) {
        out = SlideTransition(
          position: fadeIn.drive(Tween<Offset>(begin: const Offset(0, 0.015), end: Offset.zero)),
          child: page,
        );
      }
      return FadeTransition(
        opacity: ReverseAnimation(fadeOut),
        child: FadeTransition(opacity: fadeIn, child: out),
      );
    },
  );
}

Page<T> detailPage<T>(GoRouterState state, Widget child) {
  final ios = !kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS);
  if (ios) return CupertinoPage<T>(key: state.pageKey, child: child);
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: _forward,
    reverseTransitionDuration: _back,
    transitionsBuilder: (context, animation, secondary, page) {
      final reduce = _reduce(context);
      final incoming = _curve(animation, 0, 1, Curves.easeOutCubic);
      final outgoing = _curve(secondary, 0, 1, Curves.easeInOutCubic);
      Widget result = FadeTransition(opacity: _curve(animation, 0, 0.7, Curves.easeOut), child: page);
      if (!reduce) {
        result = SlideTransition(
          position: incoming.drive(Tween<Offset>(begin: const Offset(0.08, 0), end: Offset.zero)),
          child: result,
        );
        result = SlideTransition(
          position: outgoing.drive(Tween<Offset>(begin: Offset.zero, end: const Offset(-0.04, 0))),
          child: result,
        );
      }
      return FadeTransition(opacity: ReverseAnimation(_curve(secondary, 0, 0.6, Curves.easeIn)), child: result);
    },
  );
}

Page<T> fadePage<T>(GoRouterState state, Widget child) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (context, animation, secondary, page) {
      final fade = _curve(animation, 0, 1, Curves.easeOutCubic);
      Widget result = FadeTransition(opacity: fade, child: page);
      if (!_reduce(context)) {
        result = ScaleTransition(scale: fade.drive(Tween<double>(begin: 0.985, end: 1)), child: result);
      }
      return FadeTransition(opacity: ReverseAnimation(_curve(secondary, 0, 0.5, Curves.easeIn)), child: result);
    },
  );
}
