import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/models/models.dart';
import '../../../core/services/api_exception.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/image_picker_field.dart';
import '../../../core/widgets/shake_on_change.dart';
import '../../../core/widgets/status_banner.dart';
import '../state/profile_controller.dart';

/// Edits the signed-in user's profile via `PUT /profile/me`.
///
/// Only changed fields are sent: the endpoint does a partial update, so
/// transmitting untouched values would risk clobbering a change made elsewhere
/// and makes the request larger than it needs to be.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _designation;
  late final TextEditingController _service;
  late final TextEditingController _department;
  late final TextEditingController _stateOrCadre;
  late final TextEditingController _yearsInService;
  late final TextEditingController _bio;

  /// Snapshot of the values on entry, used to compute the diff at save time.
  late final Map<String, String> _initial;

  PickedImage? _photo;
  String? _error;
  int _errorTick = 0;
  AppButtonState _buttonState = AppButtonState.idle;

  bool get _busy => _buttonState != AppButtonState.idle;

  @override
  void initState() {
    super.initState();
    final UserProfile? p = context.read<ProfileController>().data?.profile;

    _name = TextEditingController(text: p?.name ?? '');
    _designation = TextEditingController(text: p?.designation ?? '');
    _service = TextEditingController(text: p?.service ?? '');
    _department = TextEditingController(text: p?.department ?? '');
    _stateOrCadre = TextEditingController(text: p?.stateOrCadre ?? '');
    _yearsInService =
        TextEditingController(text: p == null ? '' : '${p.yearsInService}');
    _bio = TextEditingController(text: p?.bio ?? '');

    _initial = <String, String>{
      'name': _name.text,
      'designation': _designation.text,
      'service': _service.text,
      'department': _department.text,
      'stateOrCadre': _stateOrCadre.text,
      'yearsInService': _yearsInService.text,
      'bio': _bio.text,
    };
  }

  @override
  void dispose() {
    for (final TextEditingController c in <TextEditingController>[
      _name,
      _designation,
      _service,
      _department,
      _stateOrCadre,
      _yearsInService,
      _bio,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Null when unchanged, so the service omits the field entirely.
  String? _changed(String key, TextEditingController controller) {
    final String current = controller.text.trim();
    return current == _initial[key]!.trim() ? null : current;
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final String? years = _changed('yearsInService', _yearsInService);
    final Map<String, String?> diff = <String, String?>{
      'name': _changed('name', _name),
      'designation': _changed('designation', _designation),
      'service': _changed('service', _service),
      'department': _changed('department', _department),
      'stateOrCadre': _changed('stateOrCadre', _stateOrCadre),
      'bio': _changed('bio', _bio),
    };

    final bool nothingChanged =
        diff.values.every((String? v) => v == null) && years == null && _photo == null;
    if (nothingChanged) {
      setState(() {
        _error = 'Nothing to save — no changes made.';
        _errorTick++;
      });
      return;
    }

    setState(() {
      _error = null;
      _buttonState = AppButtonState.loading;
    });

    try {
      await context.read<ProfileController>().update(
            name: diff['name'],
            designation: diff['designation'],
            service: diff['service'],
            department: diff['department'],
            stateOrCadre: diff['stateOrCadre'],
            yearsInService: years == null ? null : int.tryParse(years),
            bio: diff['bio'],
            photo: _photo,
          );
      if (!mounted) return;
      setState(() => _buttonState = AppButtonState.success);
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _errorTick++;
        _buttonState = AppButtonState.idle;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not save your changes. Please try again.';
        _errorTick++;
        _buttonState = AppButtonState.idle;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit profile'),
        titleSpacing: AppSpacing.gutter,
        leading: IconButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded),
          tooltip: 'Cancel',
        ),
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.gutter,
                  AppSpacing.md,
                  AppSpacing.gutter,
                  AppSpacing.lg,
                ),
                child: Form(
                  key: _formKey,
                  child: ShakeOnChange(
                    trigger: _error == null ? null : _errorTick,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        StatusBanner(message: _error),
                        ImagePickerField(
                          label: 'Profile photo',
                          helper: 'Tap to choose a new photo.',
                          value: _photo,
                          onChanged: (PickedImage? v) =>
                              setState(() => _photo = v),
                          aspectRatio: 1,
                          icon: Icons.person_outline_rounded,
                          enabled: !_busy,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Leaving this empty keeps your current photo.',
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        AppTextField(
                          label: 'Full name',
                          controller: _name,
                          validator: Validators.required('Full name'),
                          textCapitalization: TextCapitalization.words,
                          prefixIcon: Icons.person_outline_rounded,
                          enabled: !_busy,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          label: 'Designation',
                          controller: _designation,
                          validator: Validators.required('Designation'),
                          textCapitalization: TextCapitalization.words,
                          prefixIcon: Icons.work_outline_rounded,
                          enabled: !_busy,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          label: 'Service',
                          controller: _service,
                          validator: Validators.required('Service'),
                          textCapitalization: TextCapitalization.characters,
                          prefixIcon: Icons.shield_outlined,
                          enabled: !_busy,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          label: 'Department',
                          controller: _department,
                          validator: Validators.required('Department'),
                          textCapitalization: TextCapitalization.words,
                          prefixIcon: Icons.account_balance_outlined,
                          enabled: !_busy,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          label: 'State / cadre',
                          controller: _stateOrCadre,
                          validator: Validators.required('State / cadre'),
                          textCapitalization: TextCapitalization.words,
                          prefixIcon: Icons.map_outlined,
                          enabled: !_busy,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          label: 'Years in service',
                          controller: _yearsInService,
                          validator: Validators.yearsInService,
                          keyboardType: TextInputType.number,
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          prefixIcon: Icons.timeline_rounded,
                          enabled: !_busy,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          label: 'Short bio',
                          hint: 'A line or two about your work',
                          controller: _bio,
                          validator: Validators.maxLength(300),
                          maxLines: 4,
                          maxLength: 300,
                          textCapitalization: TextCapitalization.sentences,
                          enabled: !_busy,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                AppSpacing.sm,
                AppSpacing.gutter,
                AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  top: BorderSide(color: theme.colorScheme.outline),
                ),
              ),
              child: AppButton(
                label: 'Save changes',
                state: _buttonState,
                onPressed: _save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
