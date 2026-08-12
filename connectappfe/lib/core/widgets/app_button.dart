import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

enum AppButtonState { idle, loading, success }

/// Primary call-to-action with three visual states and a press-scale response.
///
/// The state machine matters for perceived speed: signup uploads two images and
/// can take a few seconds, so the button has to *hold* the loading state and
/// then confirm, rather than leaving the user wondering whether the tap landed.
class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.state = AppButtonState.idle,
    this.icon,
    this.expand = true,
  });

  final String label;

  /// Null disables the button (also disabled while loading/succeeding).
  final VoidCallback? onPressed;
  final AppButtonState state;
  final IconData? icon;
  final bool expand;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _pressed = false;

  bool get _busy => widget.state != AppButtonState.idle;
  bool get _enabled => widget.onPressed != null && !_busy;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    final Color background = switch (widget.state) {
      AppButtonState.success => scheme.tertiary,
      _ => scheme.primary,
    };

    // A bare GestureDetector contributes no "this is a button" trait and no
    // enabled/disabled state to the accessibility tree, and the loading/
    // success children below carry no text at all — a screen-reader user
    // hears nothing while a multi-second upload runs. The outer Semantics
    // node keeps announcing `widget.label` plus `button`/`enabled` regardless
    // of which visual child is showing; ExcludeSemantics stops the descendant
    // Text/Icon from being announced a second time underneath it.
    final String semanticsValue = switch (widget.state) {
      AppButtonState.loading => 'Loading',
      AppButtonState.success => 'Done',
      AppButtonState.idle => '',
    };

    final Widget content = AnimatedSwitcher(
      duration: context.motion(AppMotion.base),
      switchInCurve: AppMotion.emphasized,
      switchOutCurve: AppMotion.exit,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.82, end: 1).animate(animation),
            child: child,
          ),
        );
      },
      child: switch (widget.state) {
        AppButtonState.loading => const SizedBox(
            key: ValueKey<String>('loading'),
            height: 22,
            width: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        AppButtonState.success => const Icon(
            Icons.check_rounded,
            key: ValueKey<String>('success'),
            color: Colors.white,
            size: 26,
          ),
        AppButtonState.idle => Row(
            key: const ValueKey<String>('idle'),
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(widget.label),
              if (widget.icon != null) ...<Widget>[
                const SizedBox(width: AppSpacing.xs),
                Icon(widget.icon, size: 19),
              ],
            ],
          ),
      },
    );

    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.label,
      value: semanticsValue,
      onTap: _enabled ? widget.onPressed : null,
      child: ExcludeSemantics(
        child: GestureDetector(
          onTapDown: _enabled ? (_) => setState(() => _pressed = true) : null,
          onTapUp: _enabled ? (_) => setState(() => _pressed = false) : null,
          onTapCancel: _enabled ? () => setState(() => _pressed = false) : null,
          onTap: _enabled ? widget.onPressed : null,
          child: AnimatedScale(
            scale: _pressed ? 0.97 : 1,
            duration: context.motion(AppMotion.instant),
            curve: AppMotion.emphasized,
            child: AnimatedContainer(
              duration: context.motion(AppMotion.base),
              curve: AppMotion.emphasized,
              height: 54,
              width: widget.expand ? double.infinity : null,
              padding: widget.expand
                  ? null
                  : const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              decoration: BoxDecoration(
                color: _enabled || _busy
                    ? background
                    : scheme.onSurface.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.md),
                boxShadow: _enabled && !_pressed
                    ? <BoxShadow>[
                        BoxShadow(
                          color: background.withValues(alpha: 0.32),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: DefaultTextStyle(
                  style: (theme.textTheme.labelLarge ?? const TextStyle()).copyWith(
                    color: _enabled || _busy
                        ? Colors.white
                        : scheme.onSurface.withValues(alpha: 0.4),
                  ),
                  child: content,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
