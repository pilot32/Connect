import 'dart:typed_data';

/// An image chosen by the user, held as bytes.
///
/// Bytes rather than a file path so the same object serves the on-screen
/// preview and the multipart upload, and so the code path is identical on web
/// (where there are no file paths) and on mobile.
///
/// Lives in `core` because both the picker widget and feature-level services
/// need it — putting it under a feature would make `core` depend on a feature.
class PickedImage {
  const PickedImage({required this.bytes, required this.filename});

  final Uint8List bytes;
  final String filename;
}
