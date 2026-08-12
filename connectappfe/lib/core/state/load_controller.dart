import 'package:flutter/foundation.dart';

import '../services/api_exception.dart';

enum LoadStatus { idle, loading, ready, error }

/// Base for controllers that fetch one thing and expose load/error/data.
///
/// Every list screen in the app has the same lifecycle — load, show a spinner,
/// show an error with retry, refresh on pull-down. Centralising it keeps that
/// behaviour consistent and stops each feature from inventing its own flags.
abstract class LoadController<T> extends ChangeNotifier {
  LoadStatus _status = LoadStatus.idle;
  T? _data;
  String? _error;

  LoadStatus get status => _status;
  T? get data => _data;
  String? get error => _error;

  bool get isLoading => _status == LoadStatus.loading;
  bool get hasData => _data != null;

  /// Fetches the payload. Implementations should let [ApiException] propagate;
  /// [load] converts it into [error].
  Future<T> fetch();

  /// [silent] keeps existing data on screen while refetching, so a pull-to-
  /// refresh doesn't blank the list out and make the page jump.
  Future<void> load({bool silent = false}) async {
    if (!silent) {
      _status = LoadStatus.loading;
      _error = null;
      notifyListeners();
    }

    try {
      final T result = await fetch();
      _data = result;
      _error = null;
      _status = LoadStatus.ready;
    } on ApiException catch (e) {
      _error = e.message;
      _status = _data == null ? LoadStatus.error : LoadStatus.ready;
    } catch (_) {
      _error = 'Something went wrong. Pull down to try again.';
      _status = _data == null ? LoadStatus.error : LoadStatus.ready;
    }
    notifyListeners();
  }

  /// Loads once; later calls are no-ops. For tab bodies that shouldn't refetch
  /// every time the tab is re-selected.
  Future<void> loadOnce() async {
    if (_status != LoadStatus.idle) return;
    await load();
  }

  /// Replaces the payload locally — used for optimistic updates so the UI
  /// reacts immediately instead of waiting on a round trip.
  @protected
  void setData(T value) {
    _data = value;
    _status = LoadStatus.ready;
    notifyListeners();
  }

  @protected
  void setError(String message) {
    _error = message;
    notifyListeners();
  }
}
