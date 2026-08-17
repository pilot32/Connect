import 'dart:math' as math;

import 'package:connectappfe/core/theme/app_colors.dart';
import 'package:connectappfe/core/theme/app_tokens.dart';
import 'package:connectappfe/core/widgets/app_animated_size.dart';
import 'package:connectappfe/core/widgets/brand_mark.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shared chrome for the login and signup screens.
///
/// A deep brand-gradient header carries the identity, and the form rides in a
/// rounded surface sheet below it. The header collapses when the keyboard opens
/// — which both keeps the form in view on small screens and avoids the layout
/// overflow a fixed-height header would cause.
class AuthShell extends StatefulWidget {
  const AuthShell({
    required this.title,
    required this.subtitle,
    required this.child,
    super.key,
    this.onBack,
    this.progress,
  });

  final String title;
  final String subtitle;

  /// Placed inside the sheet. Screens own their own scrolling so this can hold
  /// a `SingleChildScrollView`, a `PageView`, or anything else.
  final Widget child;

  final VoidCallback? onBack;

  /// 0..1 wizard progress. Null hides the bar.
  final double? progress;

  @override
  State<AuthShell> createState() => _AuthShellState();
}

class _AuthShellState extends State<AuthShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _aurora = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // This is the first screen of the app, and a 14s drifting background is
    // exactly the kind of motion "reduce motion" is meant to remove — and,
    // as a plain `repeat()`, it would otherwise never stop moving or let the
    // scheduler idle for as long as the screen is on. Every other looping
    // animation in the app (skeleton shimmer, empty-state float) gates the
    // same way; this one only got it after an audit caught the omission.
    if (context.animationsDisabled) {
      if (_aurora.isAnimating) _aurora.stop();
    } else if (!_aurora.isAnimating) {
      _aurora.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _aurora.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.brandInk,
        body: Stack(
          children: <Widget>[
            const Positioned.fill(child: _AuroraBase()),
            Positioned.fill(child: _AuroraBlobs(animation: _aurora)),
            SafeArea(
              bottom: false,
              child: Column(
                children: <Widget>[
                  AppAnimatedSize(
                    child: _Header(
                      title: widget.title,
                      subtitle: widget.subtitle,
                      onBack: widget.onBack,
                      compact: keyboardOpen,
                    ),
                  ),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(28),
                        ),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.28),
                            blurRadius: 32,
                            offset: const Offset(0, -8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: <Widget>[
                          if (widget.progress != null)
                            _WizardProgress(value: widget.progress!),
                          Expanded(child: widget.child),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.subtitle,
    required this.compact,
    this.onBack,
  });

  final String title;
  final String subtitle;
  final bool compact;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.xs,
        AppSpacing.gutter,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            height: 44,
            child: Row(
              children: <Widget>[
                if (onBack != null)
                  IconButton(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: Colors.white,
                    tooltip: 'Back',
                  ),
              ],
            ),
          ),
          if (!compact) ...<Widget>[
            const Row(
              children: <Widget>[
                BrandMark(size: 52),
                SizedBox(width: kBrandBlockGap),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    BrandWordmark(color: Colors.white),
                    SizedBox(height: 2),
                    BrandTagline(),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
          Text(
            title,
            style: theme.textTheme.headlineLarge?.copyWith(
              color: Colors.white,
              fontSize: compact ? 22 : null,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.72),
            ),
          ),
        ],
      ),
    );
  }
}

/// Static base gradient — cheap, painted once.
class _AuroraBase extends StatelessWidget {
  const _AuroraBase();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.authAurora,
          stops: <double>[0, 0.55, 1],
        ),
      ),
    );
  }
}

/// Two soft light pools drifting behind the header. Slow and low-contrast on
/// purpose: it should read as depth, not as an animation demanding attention.
class _AuroraBlobs extends StatelessWidget {
  const _AuroraBlobs({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          final t = animation.value;
          return Stack(
            children: <Widget>[
              Positioned(
                top: -80 + math.sin(t * math.pi) * 26,
                right: -70 + math.cos(t * math.pi) * 20,
                child: _Blob(
                  size: 260,
                  color: AppColors.brandBright.withValues(alpha: 0.42),
                ),
              ),
              Positioned(
                top: 90 + math.cos(t * math.pi) * 34,
                left: -110 + math.sin(t * math.pi) * 24,
                child: _Blob(
                  size: 220,
                  color: AppColors.accent.withValues(alpha: 0.20),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: <Color>[color, color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}

/// Thin animated progress rail pinned to the top edge of the sheet.
class _WizardProgress extends StatelessWidget {
  const _WizardProgress({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: SizedBox(
        height: 4,
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: ColoredBox(
                color: scheme.primary.withValues(alpha: 0.10),
              ),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                return AnimatedContainer(
                  duration: context.motion(AppMotion.slow),
                  curve: AppMotion.emphasized,
                  width: constraints.maxWidth * value.clamp(0.0, 1.0),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: <Color>[AppColors.brand, AppColors.brandBright],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
