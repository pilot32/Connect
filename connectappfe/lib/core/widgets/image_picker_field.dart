import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/picked_image.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

/// Tappable image slot that previews the chosen file before upload.
///
/// Reads the file into memory as bytes so the same code path serves mobile and
/// web, and so the preview and the multipart body share one source of truth.
class ImagePickerField extends StatefulWidget {
  const ImagePickerField({
    super.key,
    required this.label,
    required this.helper,
    required this.value,
    required this.onChanged,
    this.required = false,
    this.aspectRatio = 16 / 10,
    this.icon = Icons.badge_outlined,
    this.enabled = true,
  });

  final String label;
  final String helper;
  final PickedImage? value;
  final ValueChanged<PickedImage?> onChanged;
  final bool required;
  final double aspectRatio;
  final IconData icon;
  final bool enabled;

  @override
  State<ImagePickerField> createState() => _ImagePickerFieldState();
}

class _ImagePickerFieldState extends State<ImagePickerField> {
  final ImagePicker _picker = ImagePicker();
  bool _picking = false;

  Future<void> _pick(ImageSource source) async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        // Downscale before upload: an ID card photo doesn't need 12MP, and the
        // backend caps uploads at 5MB.
        maxWidth: 2000,
        imageQuality: 85,
      );
      if (file == null) return;
      final PickedImage picked = PickedImage(
        bytes: await file.readAsBytes(),
        filename: file.name,
      );
      if (!mounted) return;
      widget.onChanged(picked);
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _showSourceSheet() async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Take a photo'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from gallery'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
              const SizedBox(height: AppSpacing.xs),
            ],
          ),
        );
      },
    );
    if (source != null) await _pick(source);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final PickedImage? value = widget.value;
    final bool hasValue = value != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(widget.label, style: theme.textTheme.labelMedium),
            if (widget.required)
              Text(
                ' *',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.error,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        AspectRatio(
          aspectRatio: widget.aspectRatio,
          child: GestureDetector(
            onTap: widget.enabled ? _showSourceSheet : null,
            child: AnimatedContainer(
              duration: context.motion(AppMotion.base),
              curve: AppMotion.emphasized,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: hasValue
                    ? scheme.surface
                    : scheme.primary.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: hasValue
                      ? AppColors.success.withValues(alpha: 0.6)
                      : scheme.outline,
                  width: hasValue ? 1.6 : 1.2,
                ),
              ),
              child: AnimatedSwitcher(
                duration: context.motion(AppMotion.base),
                switchInCurve: AppMotion.enter,
                child: hasValue
                    ? _Preview(
                        key: ValueKey<String>(value.filename),
                        image: value,
                        onReplace: widget.enabled ? _showSourceSheet : null,
                        onRemove: widget.enabled
                            ? () => widget.onChanged(null)
                            : null,
                      )
                    : _Placeholder(
                        key: const ValueKey<String>('placeholder'),
                        icon: widget.icon,
                        helper: widget.helper,
                        busy: _picking,
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({
    super.key,
    required this.icon,
    required this.helper,
    required this.busy,
  });

  final IconData icon;
  final String helper;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Center(
      child: busy
          ? const CircularProgressIndicator(strokeWidth: 2.4)
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(icon, size: 30, color: theme.colorScheme.primary),
                const SizedBox(height: AppSpacing.xs),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Text(
                    helper,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({
    super.key,
    required this.image,
    this.onReplace,
    this.onRemove,
  });

  final PickedImage image;
  final VoidCallback? onReplace;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        Image.memory(image.bytes, fit: BoxFit.cover),
        // Scrim so the action buttons stay legible over any photo.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                Colors.black.withValues(alpha: 0.35),
                Colors.transparent,
                Colors.black.withValues(alpha: 0.15),
              ],
            ),
          ),
        ),
        Positioned(
          top: AppSpacing.xs,
          right: AppSpacing.xs,
          child: Row(
            children: <Widget>[
              _CircleAction(
                icon: Icons.sync_rounded,
                tooltip: 'Replace',
                onPressed: onReplace,
              ),
              const SizedBox(width: AppSpacing.xxs),
              _CircleAction(
                icon: Icons.close_rounded,
                tooltip: 'Remove',
                onPressed: onRemove,
              ),
            ],
          ),
        ),
        Positioned(
          left: AppSpacing.xs,
          bottom: AppSpacing.xs,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: AppColors.success,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(Icons.check_rounded, size: 14, color: Colors.white),
                SizedBox(width: 4),
                Text(
                  'Attached',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({
    required this.icon,
    required this.tooltip,
    this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 18, color: Colors.white),
        tooltip: tooltip,
        visualDensity: VisualDensity.compact,
        constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
        padding: EdgeInsets.zero,
      ),
    );
  }
}
