import 'package:connectappfe/core/models/models.dart';

/// A feed post from `GET /feed` / `POST /feed`.
class Post {
  const Post({
    required this.id,
    required this.content,
    required this.author,
    this.photoUrl,
    this.createdAt,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] as String? ?? '',
      content: json['content'] as String? ?? '',
      author: PublicUser.fromJson(
        (json['author'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{},
      ),
      photoUrl: json['photoUrl'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    );
  }

  final String id;
  final String content;
  final PublicUser author;
  final String? photoUrl;
  final DateTime? createdAt;
}
