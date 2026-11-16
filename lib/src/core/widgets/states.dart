import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../branding/premisave_logo.dart';
import '../network/api_exception.dart';
import '../theme/brand.dart';
import '../theme/palette.dart';
import 'p_button.dart';

class LoadingState extends StatelessWidget {
  const LoadingState({super.key, this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          PremisaveLoader(size: 56, onDark: context.isDark, ink: context.isDark ? null : context.pal.accent),
          if (label != null) ...<Widget>[
            const SizedBox(height: 14),
            Text(label!, style: TextStyle(color: context.mutedColor, fontWeight: FontWeight.w600)),
          ],
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: context.pal.accent.op(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: context.pal.accent),
              ),
              const SizedBox(height: 18),
              Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              if (message != null) ...<Widget>[
                const SizedBox(height: 6),
                Text(message!,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, height: 1.45, color: context.mutedColor)),
              ],
              if (actionLabel != null) ...<Widget>[
                const SizedBox(height: 20),
                PButton(label: actionLabel!, onPressed: onAction, small: true),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.error, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final e = ApiException.from(error);
    return EmptyState(
      icon: e.isNetwork ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
      title: e.isNetwork ? 'You seem to be offline' : 'Something went wrong',
      message: e.message,
      actionLabel: onRetry == null ? null : 'Try again',
      onAction: onRetry,
    );
  }
}

enum SkeletonKind {
  /// A rounded block per item, for lists of cards.
  card,

  /// An avatar and two lines per item, for lists of rows.
  row,
}

/// Grey animated placeholders shown while a list loads. Use it instead of a spinner so the page keeps its shape.
/// Set [shrink] when it sits inside a column or a sliver.
class SkeletonList extends StatelessWidget {
  const SkeletonList({
    super.key,
    this.count = 4,
    this.height,
    this.padding,
    this.kind = SkeletonKind.card,
    this.shrink = false,
  });

  final int count;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final SkeletonKind kind;
  final bool shrink;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final rows = kind == SkeletonKind.row;
    final h = height ?? (rows ? 56.0 : 86.0);
    return Shimmer.fromColors(
      baseColor: rows ? pal.line : pal.panel2,
      highlightColor: rows ? pal.panel2 : pal.line,
      child: ListView.separated(
        shrinkWrap: shrink,
        physics: const NeverScrollableScrollPhysics(),
        padding: padding ?? const EdgeInsets.all(20),
        itemCount: count,
        separatorBuilder: (_, __) => SizedBox(height: rows ? 18 : 12),
        itemBuilder: (_, __) => rows
            ? _SkeletonRow(height: h)
            : Container(
                height: h,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(context.radius(Brand.radius))),
              ),
      ),
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow({required this.height});

  final double height;

  Widget _bar(double factor, double barHeight) => FractionallySizedBox(
        widthFactor: factor,
        alignment: Alignment.centerLeft,
        child: Container(
          height: barHeight,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Row(
        children: <Widget>[
          Container(width: 42, height: 42, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[_bar(0.55, 13), const SizedBox(height: 9), _bar(0.35, 11)],
            ),
          ),
        ],
      ),
    );
  }
}

/// Renders an [AsyncValue] with a skeleton while loading and a retry on failure.
class AsyncBody<T> extends StatelessWidget {
  const AsyncBody({
    super.key,
    required this.value,
    required this.builder,
    this.onRetry,
    this.loading,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) builder;
  final VoidCallback? onRetry;
  final Widget? loading;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: builder,
      loading: () => loading ?? const SkeletonList(),
      error: (e, _) => ErrorState(error: e, onRetry: onRetry),
    );
  }
}
