import 'package:connectappfe/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';

/// Remembers which item ids have already played their [FadeSlideIn] entrance.
///
/// A `ListView` disposes and recreates item elements once they scroll out of
/// the cache extent, so a bare per-item `FadeSlideIn` replays its animation
/// every time a row is scrolled back into view — on a fast fling the recycled
/// rows are genuinely blank (opacity 0) for the delay/duration before they pop
/// in. Own one of these per list (a field on the screen's State, so it
/// survives rebuilds) and consult [consume] in the item builder: true means
/// "already shown once, skip the animation".
class PlayedOnceTracker {
  final Set<String> _played = <String>{};

  /// Returns whether [id] has already played. Marks it as played either way,
  /// so the *next* call for the same id returns true.
  bool consume(String id) => !_played.add(id);

  /// Forgets every id — for when the *meaning* of the list changed (e.g. a
  /// new filter was applied) and the new result set should visibly announce
  /// itself again, as opposed to a scroll position change recycling the same
  /// set.
  void reset() => _played.clear();
}

/// Fades and lifts its child into place once, on first build.
///
/// Used to stagger form fields and list rows so a screen assembles itself
/// instead of appearing all at once. Pass an increasing [delay] down a column
/// (`context.stagger(index)`) to get the cascade.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    required this.child,
    super.key,
    this.delay = Duration.zero,
    this.duration = AppMotion.slow,
    this.offset = 20,
    this.curve = AppMotion.enter,
    this.scaleFrom,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;

  /// Vertical travel in logical pixels. Negative values drop in from above.
  final double offset;
  final Curve curve;

  /// When set, the child also scales up from this factor — used for cards,
  /// where a little growth reads as "arriving" rather than "sliding past".
  final double? scaleFrom;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    // Reduce-motion: land in the final state without playing the entrance.
    if (context.animationsDisabled) {
      _controller.value = 1;
      return;
    }

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
    // `.drive(CurveTween(...))` rather than `CurvedAnimation(...)`: the latter
    // registers a status listener on its parent at construction and must be
    // disposed to remove it, which is easy to forget when it's built fresh
    // every `build()` call (as here). A driven animation is a stateless proxy
    // with nothing to leak.
    final eased = _controller.drive(CurveTween(curve: widget.curve));
    final scaleFrom = widget.scaleFrom;

    return AnimatedBuilder(
      animation: eased,
      builder: (context, child) {
        final t = eased.value;
        Widget result = Transform.translate(
          offset: Offset(0, widget.offset * (1 - t)),
          child: child,
        );
        if (scaleFrom != null) {
          result = Transform.scale(
            scale: scaleFrom + (1 - scaleFrom) * t,
            child: result,
          );
        }
        return Opacity(opacity: t.clamp(0.0, 1.0), child: result);
      },
      child: widget.child,
    );
  }
}
