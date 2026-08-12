import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Fades and lifts its child into place once, on first build.
///
/// Used to stagger form fields and headings so a screen assembles itself
/// instead of appearing all at once. Pass an increasing [delay] down a column
/// (`AppMotion.stagger * index`) to get the cascade.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = AppMotion.slow,
    this.offset = 20,
    this.curve = AppMotion.enter,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;

  /// Vertical travel in logical pixels. Negative values drop in from above.
  final double offset;
  final Curve curve;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future<void>.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Animation<double> eased =
        CurvedAnimation(parent: _controller, curve: widget.curve);

    return AnimatedBuilder(
      animation: eased,
      builder: (BuildContext context, Widget? child) {
        return Opacity(
          opacity: eased.value,
          child: Transform.translate(
            offset: Offset(0, widget.offset * (1 - eased.value)),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
