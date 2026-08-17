import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Shakes its child horizontally whenever [trigger] changes to a new non-null
/// value.
///
/// Wrapped around auth forms so a rejected login gets a physical "no" instead
/// of only a colour change — the motion is what the eye actually catches.
class ShakeOnChange extends StatefulWidget {
  const ShakeOnChange({
    required this.trigger,
    required this.child,
    super.key,
    this.amplitude = 9,
    this.duration = const Duration(milliseconds: 420),
  });

  /// Any value that changes when a shake should happen — an error message,
  /// a counter, a timestamp.
  final Object? trigger;
  final Widget child;
  final double amplitude;
  final Duration duration;

  @override
  State<ShakeOnChange> createState() => _ShakeOnChangeState();
}

class _ShakeOnChangeState extends State<ShakeOnChange>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  @override
  void didUpdateWidget(covariant ShakeOnChange oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != oldWidget.trigger && widget.trigger != null) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Three decaying oscillations: sharp at first, settling to nothing.
        final decay = 1 - _controller.value;
        final dx =
            math.sin(_controller.value * math.pi * 6) *
            widget.amplitude *
            decay;
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: widget.child,
    );
  }
}
