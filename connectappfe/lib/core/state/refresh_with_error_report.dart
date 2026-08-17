import 'package:connectappfe/core/state/load_controller.dart';
import 'package:flutter/material.dart';

/// Runs a silent refresh and, if it failed, surfaces it as a snackbar.
///
/// A silent `load()` deliberately keeps stale data on screen rather than
/// blanking it out — but that means a failure has nowhere to render itself
/// (`AsyncView`'s error state only shows when there's no data at all), so
/// without this the user would pull-to-refresh, watch the spinner retract,
/// and have no idea it didn't actually work.
Future<void> refreshWithErrorReport(
  BuildContext context,
  LoadController<dynamic> controller,
) async {
  await controller.load(silent: true);
  final message = controller.consumeSilentError();
  if (message == null || !context.mounted) return;

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
