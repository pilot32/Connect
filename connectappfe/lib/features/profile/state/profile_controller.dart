import '../../../core/models/models.dart';
import '../../../core/state/load_controller.dart';
import '../services/profile_service.dart';

/// The signed-in user's own profile.
class ProfileController extends LoadController<MyProfile> {
  ProfileController(this._service);

  final ProfileService _service;

  @override
  Future<MyProfile> fetch() => _service.getMyProfile();

  /// Lets [ApiException] propagate so the edit form can show field-level
  /// errors, rather than flattening it into the controller's error string.
  Future<void> update({
    String? name,
    String? designation,
    String? service,
    String? department,
    String? stateOrCadre,
    int? yearsInService,
    String? bio,
    PickedImage? photo,
  }) async {
    final MyProfile updated = await _service.updateMyProfile(
      name: name,
      designation: designation,
      service: service,
      department: department,
      stateOrCadre: stateOrCadre,
      yearsInService: yearsInService,
      bio: bio,
      photo: photo,
    );
    setData(updated);
  }
}
