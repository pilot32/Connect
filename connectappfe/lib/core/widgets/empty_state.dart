import 'dart:math' as math;

import 'package:connectappfe/core/theme/app_tokens.dart';
import 'package:connectappfe/core/widgets/app_button.dart';
import 'package:connectappfe/core/widgets/fade_slide_in.dart';
import 'package:flutter/material.dart';

/// Centred illustration-free empty/error placeholder.
///
/// Empty lists are the normal case early in this app's life — a brand-new
/// account has no connections and an empty feed — so these states are written
/// to explain the next action rather than just saying "nothing here".
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    super.key,
    this.actionLabel,
    this.onAction,
    this.tone = EmptyStateTone.neutral,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EmptyStateTone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = tone == EmptyStateTone.error
        ? theme.colorScheme.error
        : theme.colorScheme.primary;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          // Always scrollable so RefreshIndicator still works on an empty list.
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: FadeSlideIn(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      _FloatingIcon(icon: icon, accent: accent),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall,
                      ),
                      if (actionLabel != null && onAction != null) ...<Widget>[
                        const SizedBox(height: AppSpacing.lg),
                        SizedBox(
                          width: 220,
                          child: AppButton(
                            label: actionLabel!,
                            onPressed: onAction,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The icon breathes gently — just enough to keep an otherwise dead screen
/// feeling alive, slow enough not to nag.
class _FloatingIcon extends StatefulWidget {
  const _FloatingIcon({required this.icon, required this.accent});

  final IconData icon;
  final Color accent;

  @override
  State<_FloatingIcon> createState() => _FloatingIconState();
}

class _FloatingIconState extends State<_FloatingIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Also stop an already-running loop if reduce-motion is toggled on mid-
    // session — this can otherwise persist indefinitely on a static empty
    // feed/connections screen, unlike SkeletonBox which self-heals when its
    // data lands and the widget unmounts.
    if (context.animationsDisabled) {
      if (_controller.isAnimating) _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget disc = Container(
      height: 72,
      width: 72,
      decoration: BoxDecoration(
        color: widget.accent.withValues(alpha: 0.10),
        shape: BoxShape.circle,
      ),
      child: Icon(widget.icon, size: 31, color: widget.accent),
    );

    if (context.animationsDisabled) return disc;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_controller.value);
        return Transform.translate(
          offset: Offset(0, math.sin(t * math.pi) * -5),
          child: child,
        );
      },
      child: disc,
    );
  }
}

enum EmptyStateTone { neutral, error }
