import 'package:connectappfe/core/services/api_exception.dart';
import 'package:flutter/foundation.dart';

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
  bool _isRefreshing = false;

  /// A silent refresh that failed while stale data stayed on screen. Distinct
  /// from [error] (which only applies when there's nothing else to show) so a
  /// screen can surface "the refresh failed" once, as a transient message,
  /// without it fighting the main error/empty states for the same slot.
  String? _silentError;

  /// Bumped on every `load()` call and captured at the start of each request.
  /// A response is only applied if it's still the most recent request in
  /// flight — otherwise two overlapping loads (e.g. tapping two filter chips
  /// quickly) could let the *first* response land after the second and
  /// silently overwrite newer data with stale data.
  int _requestId = 0;

  LoadStatus get status => _status;
  T? get data => _data;
  String? get error => _error;

  bool get isLoading => _status == LoadStatus.loading;
  bool get hasData => _data != null;

  /// True during a *silent* reload — the existing data is still on screen, so
  /// screens can show a subtle inline indicator instead of a full placeholder.
  bool get isRefreshing => _isRefreshing;

  /// Fetches the payload. Implementations should let [ApiException] propagate;
  /// [load] converts it into [error].
  Future<T> fetch();

  /// [silent] keeps existing data on screen while refetching, so a pull-to-
  /// refresh doesn't blank the list out and make the page jump.
  Future<void> load({bool silent = false}) async {
    final requestId = ++_requestId;

    if (silent) {
      _isRefreshing = true;
    } else {
      _status = LoadStatus.loading;
      _error = null;
    }
    notifyListeners();

    T? result;
    String? failureMessage;
    try {
      result = await fetch();
    } on ApiException catch (e) {
      failureMessage = e.message;
    } catch (_) {
      failureMessage = 'Something went wrong. Pull down to try again.';
    }

    // A newer load was issued while this one was in flight — its result (or
    // failure) is stale and must not clobber whatever the newer request wrote.
    if (requestId != _requestId) return;

    if (failureMessage == null) {
      _data = result;
      _error = null;
      _silentError = null;
      _status = LoadStatus.ready;
    } else {
      _error = failureMessage;
      _status = _data == null ? LoadStatus.error : LoadStatus.ready;
      // Data survived (this was a silent refresh) — the failure needs its own
      // surface, since AsyncView's error branch only renders when data==null.
      if (_data != null) _silentError = failureMessage;
    }
    _isRefreshing = false;
    notifyListeners();
  }

  /// Loads once; re-fires only if the previous attempt never produced data —
  /// i.e. it's still idle, or it errored with nothing to show. Once real data
  /// has landed (or a silent refresh kept stale data on screen), later calls
  /// are no-ops, so tab bodies don't refetch every time the tab is reselected.
  Future<void> loadOnce() async {
    final neverAttempted = _status == LoadStatus.idle;
    final failedWithNothingToShow =
        _status == LoadStatus.error && _data == null;
    if (!neverAttempted && !failedWithNothingToShow) return;
    await load();
  }

  /// One-shot read of a failed *silent* refresh's message — returns it once,
  /// then clears it, so a screen can show a snackbar exactly once per failure
  /// instead of on every rebuild.
  String? consumeSilentError() {
    final message = _silentError;
    _silentError = null;
    return message;
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
