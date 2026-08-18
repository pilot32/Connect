import 'package:connectappfe/core/services/api_exception.dart';
import 'package:connectappfe/core/state/load_controller.dart';
import 'package:connectappfe/features/admin/models/applicant.dart';
import 'package:connectappfe/features/admin/services/admin_service.dart';

/// The review queue for one [ApplicantFilter] at a time.
class AdminController extends LoadController<List<Applicant>> {
  AdminController(this._service);

  final AdminService _service;

  ApplicantFilter _filter = ApplicantFilter.pending;
  ApplicantFilter get filter => _filter;

  /// Ids mid-decision, so a row can show progress and can't be double-tapped
  /// into two conflicting reviews.
  final Set<String> _busyIds = <String>{};

  bool isBusy(String id) => _busyIds.contains(id);

  List<Applicant> get applicants => data ?? <Applicant>[];

  @override
  Future<List<Applicant>> fetch() => _service.fetchApplicants(filter: _filter);

  /// Switches tab and refetches, blanking the list first — the previous tab's
  /// rows are not an answer to the new question, and leaving approved users
  /// visible under "Pending" for the length of a round trip reads as a bug.
  Future<void> setFilter(ApplicantFilter next) async {
    if (_filter == next) return;
    _filter = next;
    clearData();
    await load();
  }

  Future<String?> approve(String userId) =>
      _decide(userId, () => _service.approveApplicant(userId));

  Future<String?> reject(String userId, {String? reason}) =>
      _decide(userId, () => _service.rejectApplicant(userId, reason: reason));

  /// Returns null on success, or a message for the caller to surface.
  ///
  /// The decision is applied locally from the response rather than by
  /// refetching: the server hands back the updated applicant, so the row can
  /// leave the current tab the instant the request lands. A refetch here would
  /// cost a second round trip and make an approval feel slower than it is.
  Future<String?> _decide(
    String userId,
    Future<Applicant> Function() action,
  ) async {
    if (_busyIds.contains(userId)) return null;
    _busyIds.add(userId);
    notifyListeners();

    try {
      final updated = await action();
      _applyDecision(updated);
      return null;
    } on ApiException catch (error) {
      return error.message;
    } catch (_) {
      return 'Something went wrong. Please try again.';
    } finally {
      _busyIds.remove(userId);
      notifyListeners();
    }
  }

  void _applyDecision(Applicant updated) {
    final current = data;
    if (current == null) return;

    final next = <Applicant>[
      for (final applicant in current)
        if (applicant.id != updated.id)
          applicant
        // Keep the reviewed row visible when the active tab still covers it
        // (the "All" tab, or a re-reject while viewing rejected) so the list
        // doesn't appear to swallow the person who was just acted on.
        else if (_filter.matches(updated.status))
          updated,
    ];
    setData(next);
  }
}
