import 'package:connectappfe/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';

/// Opens [imageUrl] full-screen, pan- and pinch-zoomable.
///
/// A thumbnail is enough to see that an ID card was uploaded, but not to read a
/// name, a service or an expiry date off it — and that reading is the decision
/// the admin is being asked to make. So the viewer is a genuine zoom surface
/// rather than a larger thumbnail.
Future<void> showIdCardViewer(
  BuildContext context, {
  required String imageUrl,
  required String title,
}) {
  return showDialog<void>(
    context: context,
    // Opaque black: an ID card photographed against a desk needs the
    // surrounding chrome out of the way to be read.
    barrierColor: Colors.black.withValues(alpha: 0.92),
    builder: (_) => _IdCardViewer(imageUrl: imageUrl, title: title),
  );
}

class _IdCardViewer extends StatelessWidget {
  const _IdCardViewer({required this.imageUrl, required this.title});

  final String imageUrl;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog.fullscreen(
      backgroundColor: Colors.transparent,
      child: SafeArea(
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: InteractiveViewer(
                maxScale: 6,
                child: Center(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      final expected = progress.expectedTotalBytes;
                      return Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                          value: expected == null
                              ? null
                              : progress.cumulativeBytesLoaded / expected,
                        ),
                      );
                    },
                    errorBuilder: (context, _, _) => Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const Icon(
                            Icons.broken_image_outlined,
                            color: Colors.white70,
                            size: 44,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            "Couldn't load the ID card image.",
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: AppSpacing.xs,
              left: AppSpacing.xs,
              right: AppSpacing.xs,
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        // The photo sits directly behind this row when zoomed
                        // out; a shadow keeps the label readable over a light
                        // ID card without adding a bar that eats vertical
                        // space on a small screen.
                        shadows: const <Shadow>[
                          Shadow(blurRadius: 12),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    color: Colors.white,
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: AppSpacing.md,
              child: Text(
                'Pinch or double-tap to zoom',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
