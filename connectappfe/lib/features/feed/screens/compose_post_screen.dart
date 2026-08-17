import 'package:connectappfe/core/models/models.dart';
import 'package:connectappfe/core/services/api_exception.dart';
import 'package:connectappfe/core/theme/app_tokens.dart';
import 'package:connectappfe/core/widgets/app_button.dart';
import 'package:connectappfe/core/widgets/image_picker_field.dart';
import 'package:connectappfe/core/widgets/shake_on_change.dart';
import 'package:connectappfe/core/widgets/status_banner.dart';
import 'package:connectappfe/features/feed/state/feed_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Post composer. Content is required (1–2000 chars); a photo is optional.
class ComposePostScreen extends StatefulWidget {
  const ComposePostScreen({super.key});

  @override
  State<ComposePostScreen> createState() => _ComposePostScreenState();
}

class _ComposePostScreenState extends State<ComposePostScreen> {
  static const int _maxLength = 2000;

  final TextEditingController _content = TextEditingController();
  PickedImage? _photo;
  String? _error;
  int _errorTick = 0;
  AppButtonState _buttonState = AppButtonState.idle;

  bool get _busy => _buttonState != AppButtonState.idle;
  bool get _canPost => _content.text.trim().isNotEmpty && !_busy;

  @override
  void initState() {
    super.initState();
    // Drives the live character counter and the post button's enabled state.
    _content.addListener(_onChanged);
  }

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    _content
      ..removeListener(_onChanged)
      ..dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final content = _content.text.trim();
    if (content.isEmpty) {
      setState(() {
        _error = 'Write something before posting.';
        _errorTick++;
      });
      return;
    }

    setState(() {
      _error = null;
      _buttonState = AppButtonState.loading;
    });

    try {
      await context.read<FeedController>().createPost(
        content: content,
        photo: _photo,
      );
      if (!mounted) return;
      setState(() => _buttonState = AppButtonState.success);
      await Future<void>.delayed(const Duration(milliseconds: 450));
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
        _error = 'Could not publish your post. Please try again.';
        _errorTick++;
        _buttonState = AppButtonState.idle;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remaining = _maxLength - _content.text.characters.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('New post'),
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
                child: ShakeOnChange(
                  trigger: _error == null ? null : _errorTick,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      StatusBanner(message: _error),
                      TextField(
                        controller: _content,
                        maxLines: null,
                        minLines: 5,
                        maxLength: _maxLength,
                        enabled: !_busy,
                        autofocus: true,
                        textCapitalization: TextCapitalization.sentences,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          height: 1.45,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Share an update with your network…',
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          counterText: '',
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      ImagePickerField(
                        label: 'Photo (optional)',
                        helper: 'Add an image to your post.',
                        value: _photo,
                        onChanged: (value) => setState(() => _photo = value),
                        icon: Icons.add_photo_alternate_outlined,
                        enabled: !_busy,
                      ),
                    ],
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
              child: Row(
                children: <Widget>[
                  // Only surfaces near the limit — a permanent counter is noise
                  // when you're 1800 characters away from it.
                  AnimatedOpacity(
                    opacity: remaining <= 200 ? 1 : 0,
                    duration: context.motion(AppMotion.fast),
                    child: Text(
                      '$remaining',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: remaining < 0
                            ? theme.colorScheme.error
                            : theme.textTheme.labelMedium?.color,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppButton(
                      label: 'Post',
                      icon: Icons.send_rounded,
                      state: _buttonState,
                      onPressed: _canPost ? _submit : null,
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
