import 'package:flutter/material.dart';

import '../theme/pattern_painter.dart';

/// A [Scaffold] that sits on the theme's page colour and background texture.
/// Use it instead of [Scaffold] for screens that should show the texture.
class PScaffold extends StatelessWidget {
  const PScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.animated = false,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;

  /// Let the texture drift slowly. Meant for calm screens such as sign in.
  final bool animated;

  @override
  Widget build(BuildContext context) {
    return AppBackdrop(
      animated: animated,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: appBar,
        body: body,
        bottomNavigationBar: bottomNavigationBar,
        floatingActionButton: floatingActionButton,
      ),
    );
  }
}
