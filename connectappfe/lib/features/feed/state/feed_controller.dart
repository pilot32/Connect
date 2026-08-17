import 'package:connectappfe/core/models/models.dart';
import 'package:connectappfe/core/services/api_exception.dart'
    show ApiException;
import 'package:connectappfe/core/state/load_controller.dart';
import 'package:connectappfe/features/feed/models/post.dart';
import 'package:connectappfe/features/feed/services/feed_service.dart';

class FeedController extends LoadController<List<Post>> {
  FeedController(this._service);

  final FeedService _service;

  @override
  Future<List<Post>> fetch() => _service.getFeed();

  /// Prepends the new post locally so it appears instantly, rather than making
  /// the author wait for a full refetch to see their own words.
  /// Lets [ApiException] propagate so the composer can show the failure inline.
  Future<Post> createPost({required String content, PickedImage? photo}) async {
    final post = await _service.createPost(content: content, photo: photo);
    setData(<Post>[post, ...?data]);
    return post;
  }
}
