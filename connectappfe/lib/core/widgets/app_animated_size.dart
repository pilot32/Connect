import 'package:connectappfe/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderAnimatedSize;

/// Drop-in replacement for [AnimatedSize] that safely degrades when
/// animations are disabled (e.g. reduce motion accessibility setting,
/// battery saver, or Android animator duration scale set to 0x / Off).
///
/// Flutter's [RenderAnimatedSize] throws
/// "A RenderAnimatedSize was mutated in its own performLayout implementation"
/// if given [Duration.zero] or mutated during layout with zero duration.
/// When animations are disabled, this widget bypasses [AnimatedSize] and
/// directly returns its [child].
class AppAnimatedSize extends StatelessWidget {
  const AppAnimatedSize({
    required this.child,
    super.key,
    this.duration = AppMotion.base,
    this.curve = AppMotion.emphasized,
    this.alignment = Alignment.topCenter,
    this.clipBehavior = Clip.hardEdge,
  });

  final Widget child;
  final Duration duration;
  final Curve curve;
  final AlignmentGeometry alignment;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final resolved = context.motion(duration);
    if (resolved == Duration.zero || context.animationsDisabled) {
      return child;
    }
    return AnimatedSize(
      duration: resolved,
      curve: curve,
      alignment: alignment,
      clipBehavior: clipBehavior,
      child: child,
    );
  }
}
