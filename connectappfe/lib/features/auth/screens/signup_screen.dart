import 'package:connectappfe/core/router/app_routes.dart';
import 'package:connectappfe/core/services/api_exception.dart';
import 'package:connectappfe/core/theme/app_tokens.dart';
import 'package:connectappfe/core/utils/validators.dart';
import 'package:connectappfe/core/widgets/app_animated_size.dart';
import 'package:connectappfe/core/widgets/app_button.dart';
import 'package:connectappfe/core/widgets/app_text_field.dart';
import 'package:connectappfe/core/widgets/auth_shell.dart';
import 'package:connectappfe/core/widgets/fade_slide_in.dart';
import 'package:connectappfe/core/widgets/image_picker_field.dart';
import 'package:connectappfe/core/widgets/shake_on_change.dart';
import 'package:connectappfe/core/widgets/status_banner.dart';
import 'package:connectappfe/features/auth/models/auth_models.dart';
import 'package:connectappfe/features/auth/state/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Three-step signup wizard.
///
/// `POST /auth/signup` wants eleven fields including two images. Presenting
/// that as one scroll would be punishing, so it's split into Account →
/// Professional details → Verification, each validated before advancing. All
/// of it is still sent as a single multipart request at the end, because the
/// backend creates the user and profile in one transaction.
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  static const int _stepCount = 3;

  final PageController _pageController = PageController();
  final GlobalKey<FormState> _accountForm = GlobalKey<FormState>();
  final GlobalKey<FormState> _detailsForm = GlobalKey<FormState>();

  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirmPassword = TextEditingController();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _designation = TextEditingController();
  final TextEditingController _customService = TextEditingController();
  final TextEditingController _department = TextEditingController();
  final TextEditingController _stateOrCadre = TextEditingController();
  final TextEditingController _yearsInService = TextEditingController();
  final TextEditingController _bio = TextEditingController();

  String? _service;
  PickedImage? _idCardPhoto;
  PickedImage? _profilePhoto;

  int _step = 0;
  String? _error;
  int _errorTick = 0;
  AppButtonState _buttonState = AppButtonState.idle;

  bool get _busy => _buttonState != AppButtonState.idle;

  @override
  void dispose() {
    _pageController.dispose();
    for (final controller in <TextEditingController>[
      _email,
      _password,
      _confirmPassword,
      _name,
      _designation,
      _customService,
      _department,
      _stateOrCadre,
      _yearsInService,
      _bio,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _goToStep(int step) {
    setState(() => _step = step);
    if (!_pageController.hasClients) return;
    final duration = context.motion(AppMotion.slow);
    if (duration == Duration.zero) {
      _pageController.jumpToPage(step);
    } else {
      _pageController.animateToPage(
        step,
        duration: duration,
        curve: AppMotion.emphasized,
      );
    }
  }

  void _showError(String message) {
    setState(() {
      _error = message;
      _errorTick++;
    });
  }

  void _onPrimaryPressed() {
    FocusScope.of(context).unfocus();
    setState(() => _error = null);

    if (_step == 0) {
      if (_accountForm.currentState?.validate() ?? false) _goToStep(1);
    } else if (_step == 1) {
      if (_detailsForm.currentState?.validate() ?? false) _goToStep(2);
    } else {
      _submit();
    }
  }

  void _onBack() {
    if (_busy) return;
    if (_step == 0) {
      context.pop();
      return;
    }
    setState(() => _error = null);
    _goToStep(_step - 1);
  }

  Future<void> _submit() async {
    if (_idCardPhoto == null) {
      _showError('Attach a photo of your service ID to continue.');
      return;
    }

    setState(() => _buttonState = AppButtonState.loading);

    final draft = SignupDraft()
      ..email = _email.text
      ..password = _password.text
      ..name = _name.text
      ..designation = _designation.text
      ..service = _service == _otherService
          ? _customService.text
          : (_service ?? '')
      ..department = _department.text
      ..stateOrCadre = _stateOrCadre.text
      ..yearsInService = _yearsInService.text
      ..bio = _bio.text
      ..idCardPhoto = _idCardPhoto
      ..profilePhoto = _profilePhoto;

    try {
      await context.read<AuthController>().signup(draft);
      if (!mounted) return;
      setState(() => _buttonState = AppButtonState.success);
      await Future<void>.delayed(const Duration(milliseconds: 650));
      if (!mounted) return;
      context.go(AppRoutes.afterLogin);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _buttonState = AppButtonState.idle);
      _showError(error.message);
      _jumpToOffendingStep(error);
    } catch (_) {
      if (!mounted) return;
      setState(() => _buttonState = AppButtonState.idle);
      _showError('Unexpected error. Please try again.');
    }
  }

  /// Server-side validation can reject a field the user filled in two steps
  /// ago; sending them back to it beats showing an error next to inputs that
  /// aren't the problem.
  void _jumpToOffendingStep(ApiException error) {
    const fieldStep = <String, int>{
      'email': 0,
      'password': 0,
      'name': 1,
      'designation': 1,
      'service': 1,
      'department': 1,
      'stateOrCadre': 1,
      'yearsInService': 1,
      'bio': 1,
    };

    if (error.isConflict) {
      // 409 is always "email already registered".
      _goToStep(0);
      return;
    }

    final fields = error.fieldErrors;
    if (fields == null || fields.isEmpty) return;

    int? target;
    for (final field in fields.keys) {
      final step = fieldStep[field];
      if (step != null && (target == null || step < target)) target = step;
    }
    if (target != null && target != _step) _goToStep(target);
  }

  String get _primaryLabel => switch (_step) {
    0 => 'Continue',
    1 => 'Continue',
    _ => 'Create account',
  };

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Intercept back so it walks the wizard backwards instead of abandoning
      // a half-filled form.
      canPop: _step == 0 && !_busy,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !_busy) _onBack();
      },
      child: AuthShell(
        title: 'Create your account',
        subtitle: _stepSubtitle,
        onBack: _onBack,
        progress: (_step + 1) / _stepCount,
        child: Column(
          children: <Widget>[
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: <Widget>[
                  _AccountStep(
                    formKey: _accountForm,
                    email: _email,
                    password: _password,
                    confirmPassword: _confirmPassword,
                    enabled: !_busy,
                    error: _step == 0 ? _error : null,
                    errorTick: _errorTick,
                  ),
                  _DetailsStep(
                    formKey: _detailsForm,
                    name: _name,
                    designation: _designation,
                    department: _department,
                    stateOrCadre: _stateOrCadre,
                    yearsInService: _yearsInService,
                    bio: _bio,
                    customService: _customService,
                    service: _service,
                    onServiceChanged: (value) =>
                        setState(() => _service = value),
                    enabled: !_busy,
                    error: _step == 1 ? _error : null,
                    errorTick: _errorTick,
                  ),
                  _VerificationStep(
                    idCardPhoto: _idCardPhoto,
                    profilePhoto: _profilePhoto,
                    onIdCardChanged: (value) =>
                        setState(() => _idCardPhoto = value),
                    onProfilePhotoChanged: (value) =>
                        setState(() => _profilePhoto = value),
                    enabled: !_busy,
                    error: _step == 2 ? _error : null,
                    errorTick: _errorTick,
                  ),
                ],
              ),
            ),
            _Footer(
              step: _step,
              stepCount: _stepCount,
              label: _primaryLabel,
              buttonState: _buttonState,
              onPressed: _onPrimaryPressed,
            ),
          ],
        ),
      ),
    );
  }

  String get _stepSubtitle => switch (_step) {
    0 => 'Step 1 of 3 · Account credentials',
    1 => 'Step 2 of 3 · Your posting details',
    _ => 'Step 3 of 3 · Identity verification',
  };
}

const String _otherService = 'Other';

// ---------------------------------------------------------------- step one

class _AccountStep extends StatelessWidget {
  const _AccountStep({
    required this.formKey,
    required this.email,
    required this.password,
    required this.confirmPassword,
    required this.enabled,
    required this.error,
    required this.errorTick,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController email;
  final TextEditingController password;
  final TextEditingController confirmPassword;
  final bool enabled;
  final String? error;
  final int errorTick;

  @override
  Widget build(BuildContext context) {
    return _StepScroll(
      child: Form(
        key: formKey,
        child: ShakeOnChange(
          trigger: error == null ? null : errorTick,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              StatusBanner(message: error),
              FadeSlideIn(
                child: AppTextField(
                  label: 'Email',
                  hint: 'you@department.gov.in',
                  controller: email,
                  validator: Validators.email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  prefixIcon: Icons.alternate_email_rounded,
                  enabled: enabled,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FadeSlideIn(
                delay: AppMotion.stagger,
                child: AppTextField(
                  label: 'Password',
                  hint: 'At least 8 characters',
                  controller: password,
                  validator: Validators.password,
                  obscure: true,
                  textInputAction: TextInputAction.next,
                  prefixIcon: Icons.lock_outline_rounded,
                  enabled: enabled,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FadeSlideIn(
                delay: AppMotion.stagger * 2,
                child: AppTextField(
                  label: 'Confirm password',
                  hint: 'Re-enter your password',
                  controller: confirmPassword,
                  validator: Validators.confirmPassword(() => password.text),
                  obscure: true,
                  textInputAction: TextInputAction.done,
                  prefixIcon: Icons.lock_person_outlined,
                  enabled: enabled,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- step two

class _DetailsStep extends StatelessWidget {
  const _DetailsStep({
    required this.formKey,
    required this.name,
    required this.designation,
    required this.department,
    required this.stateOrCadre,
    required this.yearsInService,
    required this.bio,
    required this.customService,
    required this.service,
    required this.onServiceChanged,
    required this.enabled,
    required this.error,
    required this.errorTick,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController name;
  final TextEditingController designation;
  final TextEditingController department;
  final TextEditingController stateOrCadre;
  final TextEditingController yearsInService;
  final TextEditingController bio;
  final TextEditingController customService;
  final String? service;
  final ValueChanged<String?> onServiceChanged;
  final bool enabled;
  final String? error;
  final int errorTick;

  @override
  Widget build(BuildContext context) {
    return _StepScroll(
      child: Form(
        key: formKey,
        child: ShakeOnChange(
          trigger: error == null ? null : errorTick,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              StatusBanner(message: error),
              FadeSlideIn(
                child: AppTextField(
                  label: 'Full name',
                  hint: 'As it appears on official records',
                  controller: name,
                  validator: Validators.required('Full name'),
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  prefixIcon: Icons.person_outline_rounded,
                  enabled: enabled,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FadeSlideIn(
                delay: AppMotion.stagger,
                child: _ServiceSelector(
                  value: service,
                  customController: customService,
                  onChanged: onServiceChanged,
                  enabled: enabled,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FadeSlideIn(
                delay: AppMotion.stagger * 2,
                child: AppTextField(
                  label: 'Designation',
                  hint: 'e.g. District Magistrate',
                  controller: designation,
                  validator: Validators.required('Designation'),
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  prefixIcon: Icons.work_outline_rounded,
                  enabled: enabled,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FadeSlideIn(
                delay: AppMotion.stagger * 3,
                child: AppTextField(
                  label: 'Department',
                  hint: 'e.g. Revenue',
                  controller: department,
                  validator: Validators.required('Department'),
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  prefixIcon: Icons.account_balance_outlined,
                  enabled: enabled,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FadeSlideIn(
                delay: AppMotion.stagger * 4,
                child: AppTextField(
                  label: 'State / cadre',
                  hint: 'e.g. Karnataka',
                  controller: stateOrCadre,
                  validator: Validators.required('State / cadre'),
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  prefixIcon: Icons.map_outlined,
                  enabled: enabled,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FadeSlideIn(
                delay: AppMotion.stagger * 5,
                child: AppTextField(
                  label: 'Years in service',
                  hint: 'e.g. 8',
                  controller: yearsInService,
                  validator: Validators.yearsInService,
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  textInputAction: TextInputAction.next,
                  prefixIcon: Icons.timeline_rounded,
                  enabled: enabled,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FadeSlideIn(
                delay: AppMotion.stagger * 6,
                child: AppTextField(
                  label: 'Short bio (optional)',
                  hint: 'A line or two about your work',
                  controller: bio,
                  validator: Validators.maxLength(300),
                  maxLines: 4,
                  maxLength: 300,
                  textCapitalization: TextCapitalization.sentences,
                  enabled: enabled,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Chip picker for the common services, falling back to free text.
///
/// Implemented as a [FormField] so it participates in the step's validation
/// like any other input rather than needing bespoke checks at submit time.
class _ServiceSelector extends StatelessWidget {
  const _ServiceSelector({
    required this.value,
    required this.customController,
    required this.onChanged,
    required this.enabled,
  });

  static const List<String> _options = <String>[
    'IAS',
    'IPS',
    'IFS',
    'State Service',
    _otherService,
  ];

  final String? value;
  final TextEditingController customController;
  final ValueChanged<String?> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FormField<String>(
      initialValue: value,
      validator: (_) {
        if (value == null) return 'Select your service';
        if (value == _otherService && customController.text.trim().isEmpty) {
          return 'Enter your service';
        }
        return null;
      },
      builder: (field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Service', style: theme.textTheme.labelMedium),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: _options.map((option) {
                final selected = value == option;
                return ChoiceChip(
                  label: Text(option),
                  selected: selected,
                  onSelected: enabled
                      ? (_) {
                          onChanged(option);
                          field.didChange(option);
                          field.validate();
                        }
                      : null,
                  showCheckmark: false,
                  labelStyle: theme.textTheme.labelMedium?.copyWith(
                    color: selected
                        ? theme.colorScheme.onPrimary
                        : theme.textTheme.labelMedium?.color,
                  ),
                  selectedColor: theme.colorScheme.primary,
                  side: BorderSide(
                    color: selected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline,
                  ),
                );
              }).toList(),
            ),
            AppAnimatedSize(
              child: value == _otherService
                  ? Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: AppTextField(
                        label: 'Your service',
                        hint: 'e.g. Indian Revenue Service',
                        controller: customController,
                        enabled: enabled,
                        textCapitalization: TextCapitalization.words,
                        validator: Validators.required('Service'),
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
            if (field.hasError)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xxs),
                child: Text(
                  field.errorText!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// -------------------------------------------------------------- step three

class _VerificationStep extends StatelessWidget {
  const _VerificationStep({
    required this.idCardPhoto,
    required this.profilePhoto,
    required this.onIdCardChanged,
    required this.onProfilePhotoChanged,
    required this.enabled,
    required this.error,
    required this.errorTick,
  });

  final PickedImage? idCardPhoto;
  final PickedImage? profilePhoto;
  final ValueChanged<PickedImage?> onIdCardChanged;
  final ValueChanged<PickedImage?> onProfilePhotoChanged;
  final bool enabled;
  final String? error;
  final int errorTick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _StepScroll(
      child: ShakeOnChange(
        trigger: error == null ? null : errorTick,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            StatusBanner(message: error),
            FadeSlideIn(
              child: ImagePickerField(
                label: 'Service ID card',
                helper:
                    'Photograph your service ID, appointment letter, or other '
                    'official proof.',
                value: idCardPhoto,
                onChanged: onIdCardChanged,
                required: true,
                enabled: enabled,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Stored securely and used only to verify that you are a serving '
              'official. It is never shown on your profile.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.lg),
            FadeSlideIn(
              delay: AppMotion.stagger * 2,
              child: ImagePickerField(
                label: 'Profile photo (optional)',
                helper: 'A clear headshot helps peers recognise you.',
                value: profilePhoto,
                onChanged: onProfilePhotoChanged,
                aspectRatio: 1,
                icon: Icons.person_outline_rounded,
                enabled: enabled,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ shared

class _StepScroll extends StatelessWidget {
  const _StepScroll({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.lg,
        AppSpacing.gutter,
        AppSpacing.lg,
      ),
      child: child,
    );
  }
}

/// Pinned action bar: step dots on the left, primary action filling the rest.
class _Footer extends StatelessWidget {
  const _Footer({
    required this.step,
    required this.stepCount,
    required this.label,
    required this.buttonState,
    required this.onPressed,
  });

  final int step;
  final int stepCount;
  final String label;
  final AppButtonState buttonState;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.sm,
        AppSpacing.gutter,
        AppSpacing.md + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outline)),
      ),
      child: Row(
        children: <Widget>[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List<Widget>.generate(stepCount, (index) {
              final active = index <= step;
              return AnimatedContainer(
                duration: context.motion(AppMotion.base),
                curve: AppMotion.emphasized,
                margin: const EdgeInsets.only(right: 6),
                height: 7,
                width: index == step ? 20 : 7,
                decoration: BoxDecoration(
                  color: active
                      ? scheme.primary
                      : scheme.primary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              );
            }),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: AppButton(
              label: label,
              icon: step == stepCount - 1 ? null : Icons.arrow_forward_rounded,
              state: buttonState,
              onPressed: onPressed,
            ),
          ),
        ],
      ),
    );
  }
}
