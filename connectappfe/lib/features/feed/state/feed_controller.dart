import '../../../core/models/models.dart';
import '../../../core/state/load_controller.dart';
import '../models/post.dart';
import '../services/feed_service.dart';

class FeedController extends LoadController<List<Post>> {
  FeedController(this._service);

  final FeedService _service;

  @override
  Future<List<Post>> fetch() => _service.getFeed();

  /// Prepends the new post locally so it appears instantly, rather than making
  /// the author wait for a full refetch to see their own words.
  /// Lets [ApiException] propagate so the composer can show the failure inline.
  Future<Post> createPost({required String content, PickedImage? photo}) async {
    final Post post = await _service.createPost(content: content, photo: photo);
    setData(<Post>[post, ...?data]);
    return post;
  }
}
