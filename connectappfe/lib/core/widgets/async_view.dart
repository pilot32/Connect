import 'package:connectappfe/core/state/load_controller.dart';
import 'package:connectappfe/core/theme/app_tokens.dart';
import 'package:connectappfe/core/widgets/empty_state.dart';
import 'package:flutter/material.dart';

/// Renders the four states of a [LoadController] consistently across features:
/// loading, error with retry, empty, and data.
///
/// Written as a widget rather than a mixin so screens stay declarative and
/// nobody has to remember to handle the error branch.
class AsyncView<T> extends StatelessWidget {
  const AsyncView({
    required this.controller,
    required this.builder,
    required this.isEmpty,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptyMessage,
    super.key,
    this.emptyActionLabel,
    this.onEmptyAction,
    this.loadingPlaceholder,
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

  /// Skeleton shaped like the real content. Falls back to a spinner when a
  /// screen has no meaningful shape to promise.
  final Widget? loadingPlaceholder;

  @override
  Widget build(BuildContext context) {
    final data = controller.data;

    final Widget child;
    // `idle` (before the screen's post-frame loadOnce() has even run) is
    // treated the same as `loading`: every screen calls loadOnce() one frame
    // after first build, so without this, frame 1 renders the *empty* state
    // (falling through the branches below) and frame 2 swaps in loading —
    // a flash of "no data" that briefly outranks the real loading UI on
    // every cold start.
    final showLoading =
        data == null &&
        (controller.status == LoadStatus.loading ||
            controller.status == LoadStatus.idle);
    if (showLoading) {
      child = KeyedSubtree(
        key: const ValueKey<String>('loading'),
        child:
            loadingPlaceholder ??
            const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.xxl),
                child: CircularProgressIndicator(strokeWidth: 2.6),
              ),
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
        onAction: controller.load,
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
      duration: context.motion(AppMotion.base),
      switchInCurve: AppMotion.enter,
      switchOutCurve: AppMotion.exit,
      // Default layout stacks children centred, which fights a full-height
      // list; keep them top-aligned and full-bleed instead.
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.topCenter,
        children: <Widget>[
          ...previous,
          if (current != null) Positioned.fill(child: current),
        ],
      ),
      child: child,
    );
  }
}
