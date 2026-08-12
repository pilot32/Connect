import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../state/connections_controller.dart';

/// Compact action reflecting the current relationship with someone.
///
/// Shows Connect / Pending / Connected / Respond depending on
/// [ConnectionsController.statusFor], so the directory never offers an action
/// the server would reject with a 409.
class ConnectButton extends StatelessWidget {
  const ConnectButton({
    super.key,
    required this.userId,
    required this.controller,
    this.onError,
  });

  final String userId;
  final ConnectionsController controller;
  final ValueChanged<String>? onError;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final LinkStatus state = controller.statusFor(userId);
    final String? actionId = controller.actionableIdFor(userId);
    final bool busy =
        controller.isBusy(userId) || (actionId != null && controller.isBusy(actionId));

    Future<void> send() async {
      final String? failure = await controller.sendRequest(userId);
      if (failure != null) onError?.call(failure);
    }

    final Widget child = switch (state) {
      LinkStatus.none => _Pill(
          key: const ValueKey<String>('connect'),
          label: 'Connect',
          icon: Icons.person_add_alt_1_rounded,
          filled: true,
          busy: busy,
          onTap: send,
        ),
      LinkStatus.outgoing => _Pill(
          key: const ValueKey<String>('pending'),
          label: 'Pending',
          icon: Icons.schedule_rounded,
          filled: false,
          busy: busy,
          // Tapping a pending request cancels it — the only way to re-request
          // later, since any surviving row blocks a new one.
          onTap: actionId == null
              ? null
              : () async {
                  final String? failure = await controller.remove(actionId);
                  if (failure != null) onError?.call(failure);
                },
        ),
      LinkStatus.incoming => _Pill(
          key: const ValueKey<String>('respond'),
          label: 'Respond',
          icon: Icons.mark_email_unread_outlined,
          filled: true,
          busy: busy,
          onTap: null,
        ),
      LinkStatus.connected => _Pill(
          key: const ValueKey<String>('connected'),
          label: 'Connected',
          icon: Icons.check_circle_rounded,
          filled: false,
          tint: AppColors.success,
          busy: busy,
          onTap: null,
        ),
    };

    return AnimatedSwitcher(
      duration: AppMotion.base,
      switchInCurve: AppMotion.emphasized,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.85, end: 1).animate(animation),
            child: child,
          ),
        );
      },
      child: DefaultTextStyle(
        style: theme.textTheme.labelMedium ?? const TextStyle(),
        child: child,
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    super.key,
    required this.label,
    required this.icon,
    required this.filled,
    required this.busy,
    this.onTap,
    this.tint,
  });

  final String label;
  final IconData icon;
  final bool filled;
  final bool busy;
  final VoidCallback? onTap;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color accent = tint ?? theme.colorScheme.primary;

    return Material(
      color: filled ? accent : accent.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(AppRadius.pill),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: busy ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox(
                height: 15,
                width: 15,
                child: busy
                    ? CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          filled ? Colors.white : accent,
                        ),
                      )
                    : Icon(
                        icon,
                        size: 15,
                        color: filled ? Colors.white : accent,
                      ),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: filled ? Colors.white : accent,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
