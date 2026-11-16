import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Switches theme with a circle that opens from the tap point, like the web console.
///
/// Put it above the navigator. Call [ThemeRevealState.run] with the change that swaps the theme.
/// It takes a picture of the old screen, applies the change, and wipes the picture away.
class ThemeReveal extends StatefulWidget {
  const ThemeReveal({super.key, required this.child});

  final Widget child;

  static ThemeRevealState? maybeOf(BuildContext context) => context.findAncestorStateOfType<ThemeRevealState>();

  @override
  State<ThemeReveal> createState() => ThemeRevealState();
}

class ThemeRevealState extends State<ThemeReveal> with SingleTickerProviderStateMixin {
  final GlobalKey _boundary = GlobalKey();
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
  late final Animation<double> _curve = CurvedAnimation(parent: _controller, curve: const Cubic(0.2, 0.7, 0.2, 1));
  ui.Image? _snapshot;
  Offset _origin = Offset.zero;

  @override
  void dispose() {
    _controller.dispose();
    _snapshot?.dispose();
    super.dispose();
  }

  /// Runs [change] and reveals the result from [origin] (screen centre when null).
  /// Falls back to an instant change when animations are off or a picture cannot be taken.
  Future<void> run(Offset? origin, VoidCallback change) async {
    final size = MediaQuery.of(context).size;
    final reduce = MediaQuery.of(context).disableAnimations;
    final boundary = _boundary.currentContext?.findRenderObject();
    if (reduce || _controller.isAnimating || boundary is! RenderRepaintBoundary) {
      change();
      return;
    }
    try {
      final ratio = MediaQuery.of(context).devicePixelRatio.clamp(1.0, 2.0);
      final image = await boundary.toImage(pixelRatio: ratio);
      if (!mounted) {
        image.dispose();
        return;
      }
      setState(() {
        _snapshot = image;
        _origin = origin ?? Offset(size.width / 2, size.height / 2);
      });
      change();
      await _controller.forward(from: 0);
    } catch (_) {
      change();
    } finally {
      if (mounted) {
        setState(() => _snapshot = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _snapshot;
    final size = MediaQuery.of(context).size;
    final far = (Offset(_origin.dx < size.width / 2 ? size.width : 0, _origin.dy < size.height / 2 ? size.height : 0) - _origin).distance;
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        RepaintBoundary(key: _boundary, child: widget.child),
        if (snapshot != null)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _curve,
                builder: (context, _) => ClipPath(
                  clipper: _HoleClipper(_origin, far * _curve.value),
                  child: RawImage(image: snapshot, fit: BoxFit.fill),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Everything except a growing circle.
class _HoleClipper extends CustomClipper<Path> {
  const _HoleClipper(this.center, this.radius);

  final Offset center;
  final double radius;

  @override
  Path getClip(Size size) => Path.combine(
        PathOperation.difference,
        Path()..addRect(Offset.zero & size),
        Path()..addOval(Rect.fromCircle(center: center, radius: radius)),
      );

  @override
  bool shouldReclip(_HoleClipper old) => old.radius != radius || old.center != center;
}
