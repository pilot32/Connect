import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/services/api_exception.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/auth_shell.dart';
import '../../../core/widgets/fade_slide_in.dart';
import '../../../core/widgets/shake_on_change.dart';
import '../../../core/widgets/status_banner.dart';
import '../state/auth_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();

  String? _error;

  /// Bumped on every failure so [ShakeOnChange] fires again even when the
  /// message text is identical to last time.
  int _errorTick = 0;

  AppButtonState _buttonState = AppButtonState.idle;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _error = null;
      _buttonState = AppButtonState.loading;
    });

    try {
      await context.read<AuthController>().login(
            email: _email.text,
            password: _password.text,
          );
      if (!mounted) return;
      setState(() => _buttonState = AppButtonState.success);
      // Let the checkmark land before handing over to the next screen.
      await Future<void>.delayed(const Duration(milliseconds: 550));
      if (!mounted) return;
      context.go(AppRoutes.afterLogin);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _errorTick++;
        _buttonState = AppButtonState.idle;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Unexpected error. Please try again.';
        _errorTick++;
        _buttonState = AppButtonState.idle;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool busy = _buttonState != AppButtonState.idle;

    return AuthShell(
      title: 'Welcome back',
      subtitle: 'Sign in to your verified professional network.',
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter,
          AppSpacing.xl,
          AppSpacing.gutter,
          AppSpacing.xl,
        ),
        child: Form(
          key: _formKey,
          child: ShakeOnChange(
            trigger: _errorTick == 0 ? null : _errorTick,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                StatusBanner(message: _error),
                FadeSlideIn(
                  delay: AppMotion.stagger,
                  child: AppTextField(
                    label: 'Email',
                    hint: 'you@department.gov.in',
                    controller: _email,
                    validator: Validators.email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    prefixIcon: Icons.alternate_email_rounded,
                    autofillHints: const <String>[AutofillHints.email],
                    enabled: !busy,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                FadeSlideIn(
                  delay: AppMotion.stagger * 2,
                  child: AppTextField(
                    label: 'Password',
                    hint: 'At least 8 characters',
                    controller: _password,
                    validator: Validators.password,
                    obscure: true,
                    textInputAction: TextInputAction.done,
                    prefixIcon: Icons.lock_outline_rounded,
                    autofillHints: const <String>[AutofillHints.password],
                    enabled: !busy,
                    onSubmitted: (_) => _submit(),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                FadeSlideIn(
                  delay: AppMotion.stagger * 3,
                  child: AppButton(
                    label: 'Sign in',
                    icon: Icons.arrow_forward_rounded,
                    state: _buttonState,
                    onPressed: _submit,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                FadeSlideIn(
                  delay: AppMotion.stagger * 4,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        'New here?',
                        style: theme.textTheme.bodyMedium,
                      ),
                      TextButton(
                        onPressed:
                            busy ? null : () => context.push(AppRoutes.signup),
                        child: const Text('Create an account'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
