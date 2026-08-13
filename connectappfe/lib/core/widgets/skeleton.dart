import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

/// A shimmering placeholder block.
///
/// Skeletons beat a centred spinner here because the shape of the content is
/// known in advance: the user sees the page's structure immediately and the
/// list doesn't jump when data lands. Implemented with a sliding gradient
/// rather than a shimmer package — it's a dozen lines and avoids a dependency.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.height = 14,
    this.width,
    this.radius = AppRadius.sm,
    this.shape = BoxShape.rectangle,
  });

  const SkeletonBox.circle({super.key, required double size})
      : height = size,
        width = size,
        radius = 0,
        shape = BoxShape.circle;

  final double height;
  final double? width;
  final double radius;
  final BoxShape shape;

  @override
  Widget build(BuildContext context) {
    return _Shimmer(
      child: Container(
        height: height,
        width: width ?? double.infinity,
        decoration: BoxDecoration(
          color: AppColors.brand.withValues(alpha: 0.08),
          shape: shape,
          borderRadius:
              shape == BoxShape.circle ? null : BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

/// Drives the highlight sweep. One controller per skeleton block is fine at
/// these counts, and keeps each block self-contained.
class _Shimmer extends StatefulWidget {
  const _Shimmer({required this.child});

  final Widget child;

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // A looping shimmer is exactly the kind of motion reduce-motion users ask
    // to be spared; the static block still communicates "loading". Toggling
    // the setting mid-session (not just at launch) re-runs this, so also
    // stop an already-running loop rather than only ever starting one —
    // otherwise the Ticker keeps requesting frames forever behind a
    // now-static widget.
    if (context.animationsDisabled) {
      if (_controller.isAnimating) _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (context.animationsDisabled) return widget.child;

    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (Rect bounds) {
            // Sweeps from off-left to off-right across the block.
            final double t = _controller.value * 2 - 1;
            return LinearGradient(
              begin: Alignment(t - 0.35, 0),
              end: Alignment(t + 0.35, 0),
              colors: <Color>[
                Colors.transparent,
                Colors.white.withValues(alpha: 0.55),
                Colors.transparent,
              ],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Loading placeholder shaped like a [UserListTile].
class UserTileSkeleton extends StatelessWidget {
  const UserTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Row(
        children: <Widget>[
          const SkeletonBox.circle(size: 46),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const <Widget>[
                SkeletonBox(height: 13, width: 140),
                SizedBox(height: AppSpacing.xs),
                SkeletonBox(height: 11, width: 90),
                SizedBox(height: AppSpacing.xxs),
                SkeletonBox(height: 11, width: 170),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Loading placeholder shaped like a [PostCard].
class PostSkeleton extends StatelessWidget {
  const PostSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: const <Widget>[
              SkeletonBox.circle(size: 42),
              SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SkeletonBox(height: 13, width: 130),
                    SizedBox(height: AppSpacing.xs),
                    SkeletonBox(height: 11, width: 100),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const SkeletonBox(height: 12),
          const SizedBox(height: AppSpacing.xs),
          const SkeletonBox(height: 12),
          const SizedBox(height: AppSpacing.xs),
          const SkeletonBox(height: 12, width: 200),
        ],
      ),
    );
  }
}

/// A column of [count] skeletons, each fading in slightly after the last so the
/// placeholder itself arrives with the same rhythm as real content.
class SkeletonList extends StatelessWidget {
  const SkeletonList({
    super.key,
    required this.itemBuilder,
    this.count = 5,
    this.padding,
  });

  final WidgetBuilder itemBuilder;
  final int count;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: padding ??
          const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            AppSpacing.md,
            AppSpacing.gutter,
            AppSpacing.xxl,
          ),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
      itemBuilder: (BuildContext context, int index) => Opacity(
        // Fade the tail out so the list looks like it continues below the fold.
        opacity: 1 - (index / (count + 1)) * 0.7,
        child: itemBuilder(context),
      ),
    );
  }
}
