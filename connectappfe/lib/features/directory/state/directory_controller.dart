import '../../../core/models/models.dart';
import '../../../core/state/load_controller.dart';
import '../services/directory_service.dart';

/// Directory search with three optional, AND-combined filters.
class DirectoryController extends LoadController<List<PublicUser>> {
  DirectoryController(this._service);

  final DirectoryService _service;

  String _service_ = '';
  String _department = '';
  String _state = '';

  String get serviceFilter => _service_;
  String get departmentFilter => _department;
  String get stateFilter => _state;

  bool get hasFilters =>
      _service_.isNotEmpty || _department.isNotEmpty || _state.isNotEmpty;

  int get activeFilterCount =>
      (_service_.isNotEmpty ? 1 : 0) +
      (_department.isNotEmpty ? 1 : 0) +
      (_state.isNotEmpty ? 1 : 0);

  @override
  Future<List<PublicUser>> fetch() => _service.search(
        service: _service_,
        department: _department,
        state: _state,
      );

  /// Applies filters and refetches. [silent] keeps the current results visible
  /// while the new ones load, so the list doesn't flash empty on each tweak.
  Future<void> applyFilters({
    String? service,
    String? department,
    String? state,
  }) async {
    _service_ = service ?? _service_;
    _department = department ?? _department;
    _state = state ?? _state;
    await load(silent: hasData);
  }

  Future<void> clearFilters() async {
    _service_ = '';
    _department = '';
    _state = '';
    await load(silent: hasData);
  }
}
