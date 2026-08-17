import 'package:connectappfe/core/models/models.dart';
import 'package:connectappfe/core/services/api_exception.dart'
    show ApiException;
import 'package:connectappfe/core/state/load_controller.dart';
import 'package:connectappfe/features/profile/services/profile_service.dart';

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
    final updated = await _service.updateMyProfile(
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
