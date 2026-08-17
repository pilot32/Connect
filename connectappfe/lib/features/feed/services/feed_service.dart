import 'package:connectappfe/core/config/api_config.dart';
import 'package:connectappfe/core/models/models.dart';
import 'package:connectappfe/core/services/api_client.dart';
import 'package:connectappfe/features/feed/models/post.dart';
import 'package:dio/dio.dart';

/// `GET /feed` and `POST /feed`.
class FeedService {
  const FeedService(this._api);

  final ApiClient _api;

  /// Posts from the current user's accepted connections, plus their own,
  /// newest first. Server-ordered — the client does not re-sort.
  Future<List<Post>> getFeed() async {
    final dynamic data = await _api.get(ApiConfig.feed);
    if (data is! List) return <Post>[];
    return data
        .whereType<Map<dynamic, dynamic>>()
        .map((e) => Post.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  Future<Post> createPost({required String content, PickedImage? photo}) async {
    final fields = <String, dynamic>{
      'content': content.trim(),
    };
    if (photo != null) {
      fields['photo'] = ApiClient.imagePart(photo.bytes, photo.filename);
    }

    final dynamic data = await _api.post(
      ApiConfig.feed,
      data: FormData.fromMap(fields),
    );
    return Post.fromJson(
      data is Map ? data.cast<String, dynamic>() : <String, dynamic>{},
    );
  }
}
