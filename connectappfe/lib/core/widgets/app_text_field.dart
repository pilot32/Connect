import 'package:connectappfe/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Text input with an always-visible label and an animated focus treatment.
///
/// The label sits above the field rather than floating inside it: this form
/// asks for a lot (designation, cadre, department…), and static labels stay
/// readable while scanning a long column, where floating labels do not.
class AppTextField extends StatefulWidget {
  const AppTextField({
    required this.label,
    super.key,
    this.controller,
    this.hint,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.obscure = false,
    this.maxLines = 1,
    this.maxLength,
    this.prefixIcon,
    this.onSubmitted,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.autofillHints,
    this.enabled = true,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscure;
  final int maxLines;
  final int? maxLength;
  final IconData? prefixIcon;
  final ValueChanged<String>? onSubmitted;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final Iterable<String>? autofillHints;
  final bool enabled;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late final FocusNode _focusNode = FocusNode()..addListener(_onFocusChange);
  bool _focused = false;
  late bool _obscured = widget.obscure;

  void _onFocusChange() {
    if (!mounted) return;
    setState(() => _focused = _focusNode.hasFocus);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_onFocusChange)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        AnimatedDefaultTextStyle(
          duration: context.motion(AppMotion.fast),
          style: (theme.textTheme.labelMedium ?? const TextStyle()).copyWith(
            color: _focused
                ? scheme.primary
                : theme.textTheme.labelMedium?.color,
          ),
          child: Text(widget.label),
        ),
        const SizedBox(height: AppSpacing.xs),
        AnimatedContainer(
          duration: context.motion(AppMotion.base),
          curve: AppMotion.emphasized,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow: _focused
                ? <BoxShadow>[
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.14),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            validator: widget.validator,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            obscureText: _obscured,
            maxLines: widget.obscure ? 1 : widget.maxLines,
            maxLength: widget.maxLength,
            enabled: widget.enabled,
            textCapitalization: widget.textCapitalization,
            inputFormatters: widget.inputFormatters,
            autofillHints: widget.autofillHints,
            onFieldSubmitted: widget.onSubmitted,
            style: theme.textTheme.bodyLarge,
            decoration: InputDecoration(
              hintText: widget.hint,
              counterText: '',
              prefixIcon: widget.prefixIcon == null
                  ? null
                  : AnimatedSwitcher(
                      duration: context.motion(AppMotion.fast),
                      child: Icon(
                        widget.prefixIcon,
                        key: ValueKey<bool>(_focused),
                        size: 20,
                        color: _focused
                            ? scheme.primary
                            : theme.textTheme.bodySmall?.color,
                      ),
                    ),
              suffixIcon: widget.obscure
                  ? IconButton(
                      onPressed: () => setState(() => _obscured = !_obscured),
                      icon: Icon(
                        _obscured
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 20,
                      ),
                      tooltip: _obscured ? 'Show password' : 'Hide password',
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}
