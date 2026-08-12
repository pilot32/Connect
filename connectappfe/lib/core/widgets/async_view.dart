import 'package:flutter/material.dart';

import '../state/load_controller.dart';
import '../theme/app_tokens.dart';
import 'empty_state.dart';

/// Renders the four states of a [LoadController] consistently across features:
/// initial spinner, error with retry, empty, and data.
///
/// Written as a widget rather than a mixin so screens stay declarative and
/// nobody has to remember to handle the error branch.
class AsyncView<T> extends StatelessWidget {
  const AsyncView({
    super.key,
    required this.controller,
    required this.builder,
    required this.isEmpty,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptyMessage,
    this.emptyActionLabel,
    this.onEmptyAction,
  });

  final LoadController<T> controller;
  final Widget Function(BuildContext context, T data) builder;

  /// Data can be present but empty (an empty list), which needs the empty
  /// state rather than a blank screen.
  final bool Function(T data) isEmpty;

  final IconData emptyIcon;
  final String emptyTitle;
  final String emptyMessage;
  final String? emptyActionLabel;
  final VoidCallback? onEmptyAction;

  @override
  Widget build(BuildContext context) {
    final T? data = controller.data;

    final Widget child;
    if (controller.status == LoadStatus.loading && data == null) {
      child = const Center(
        key: ValueKey<String>('loading'),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xxl),
          child: CircularProgressIndicator(strokeWidth: 2.6),
        ),
      );
    } else if (controller.status == LoadStatus.error && data == null) {
      child = EmptyState(
        key: const ValueKey<String>('error'),
        icon: Icons.cloud_off_rounded,
        title: "Couldn't load",
        message: controller.error ?? 'Please try again.',
        tone: EmptyStateTone.error,
        actionLabel: 'Retry',
        onAction: () => controller.load(),
      );
    } else if (data == null || isEmpty(data)) {
      child = EmptyState(
        key: const ValueKey<String>('empty'),
        icon: emptyIcon,
        title: emptyTitle,
        message: emptyMessage,
        actionLabel: emptyActionLabel,
        onAction: onEmptyAction,
      );
    } else {
      child = KeyedSubtree(
        key: const ValueKey<String>('data'),
        child: builder(context, data),
      );
    }

    return AnimatedSwitcher(
      duration: AppMotion.base,
      switchInCurve: AppMotion.enter,
      child: child,
    );
  }
}
