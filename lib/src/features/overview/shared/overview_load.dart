import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/widgets.dart';

/// A part of an overview that loads on its own: a skeleton while it loads, a retry when it fails and the content when
/// it arrives. Giving each part its own provider means one service being down never hides the rest of the page.
class OverviewLoad<T> extends StatelessWidget {
  const OverviewLoad({super.key, required this.value, required this.builder, required this.onRetry, this.rows = 3});

  final AsyncValue<T> value;
  final Widget Function(T data) builder;
  final VoidCallback onRetry;

  /// How many placeholder rows to show while loading.
  final int rows;

  @override
  Widget build(BuildContext context) {
    return AsyncBody<T>(
      value: value,
      onRetry: onRetry,
      loading: SkeletonList(kind: SkeletonKind.row, count: rows, shrink: true, padding: const EdgeInsets.symmetric(vertical: 4)),
      builder: builder,
    );
  }
}

/// A figure for the hero: the value when it is loaded, "..." while it loads and a dash when it could not be read.
String overviewFigure<T>(AsyncValue<T> value, String Function(T data) pick) {
  if (value.hasValue) return pick(value.value as T);
  return value.hasError ? '-' : '...';
}

/// True while any of the parts has nothing to show yet, so a summary built from several of them can wait.
bool overviewWaiting(List<AsyncValue<Object?>> parts) => parts.any((v) => v.isLoading && !v.hasValue);
