import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/brand.dart';
import 'p_scaffold.dart';

/// Centres content and caps its width so wide screens do not stretch forms and lists.
class ContentWidth extends StatelessWidget {
  const ContentWidth({super.key, required this.child, this.maxWidth = 1080, this.padding});

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding ?? EdgeInsets.symmetric(horizontal: context.isCompact ? 16 : Brand.gutter + 4),
          child: child,
        ),
      ),
    );
  }
}

/// Lays children out in as many equal columns as fit, each at least [minItemWidth] wide.
class ResponsiveWrap extends StatelessWidget {
  const ResponsiveWrap({
    super.key,
    required this.children,
    this.minItemWidth = 220,
    this.spacing = 12,
    this.maxColumns = 6,
  });

  final List<Widget> children;
  final double minItemWidth;
  final double spacing;
  final int maxColumns;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite ? constraints.maxWidth : 600.0;
        final columns = math.max(1, math.min(maxColumns, ((width + spacing) / (minItemWidth + spacing)).floor()));
        final itemWidth = (width - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: <Widget>[for (final c in children) SizedBox(width: itemWidth, child: c)],
        );
      },
    );
  }
}

/// Scrollable page body with the usual padding and max width. Pull to refresh is optional.
class PageBody extends StatelessWidget {
  const PageBody({
    super.key,
    required this.children,
    this.onRefresh,
    this.maxWidth = 1080,
    this.bottomPadding = 32,
  });

  final List<Widget> children;
  final Future<void> Function()? onRefresh;
  final double maxWidth;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final list = ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(top: 12, bottom: bottomPadding),
      children: <Widget>[
        ContentWidth(
          maxWidth: maxWidth,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
        ),
      ],
    );
    if (onRefresh == null) return list;
    return RefreshIndicator(onRefresh: onRefresh!, child: list);
  }
}

/// Big page title for tab roots.
class PageTitle extends StatelessWidget {
  const PageTitle(this.title, {super.key, this.subtitle, this.trailing});

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: context.display(size: 26, weight: FontWeight.w800, spacing: -0.8, height: 1.15)),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(subtitle!, style: TextStyle(fontSize: 14, height: 1.4, color: context.mutedColor)),
                  ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Scaffold for screens opened from a tab: back arrow, title, optional actions.
class SubPage extends StatelessWidget {
  const SubPage({super.key, required this.title, required this.body, this.actions, this.fallbackRoute = '/home'});

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final String fallbackRoute;

  @override
  Widget build(BuildContext context) {
    return PScaffold(
      appBar: AppBar(
        leading: Navigator.of(context).canPop()
            ? null
            : IconButton(
                tooltip: 'Back',
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => context.go(fallbackRoute),
              ),
        title: Text(title, style: context.display(size: 18, weight: FontWeight.w800)),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        actions: actions,
      ),
      body: SafeArea(top: false, child: body),
    );
  }
}
