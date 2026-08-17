import 'package:connectappfe/core/theme/app_colors.dart';
import 'package:connectappfe/core/theme/app_tokens.dart';
import 'package:connectappfe/core/widgets/brand_mark.dart';
import 'package:connectappfe/features/auth/state/auth_controller.dart'
    show AuthController;
import 'package:flutter/material.dart';

/// Shown while [AuthController.bootstrap] reads the stored token.
///
/// Exists so a returning user never sees the login screen flash before being
/// dropped into the app. The emblem shares its Hero tag with the auth header,
/// so it flies into place rather than cutting.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.brandInk,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.authAurora,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const BrandMark(size: 78),
              const SizedBox(height: AppSpacing.lg),
              const BrandWordmark(color: Colors.white, fontSize: 30),
              const SizedBox(height: AppSpacing.xs),
              const BrandTagline(),
              const SizedBox(height: AppSpacing.xxl),
              SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
