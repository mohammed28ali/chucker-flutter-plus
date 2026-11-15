import '../../domain/entities/post.dart';

final class PostModel extends Post {
  const PostModel({
    required super.id,
    required super.userId,
    required super.title,
    required super.body,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) => PostModel(
    id: _readInt(json, 'id'),
    userId: _readInt(json, 'userId'),
    title: _readString(json, 'title'),
    body: _readString(json, 'body'),
  );

  static int _readInt(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is int) return value;
    throw FormatException('Expected "$key" to be an integer.');
  }

  static String _readString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is String) return value;
    throw FormatException('Expected "$key" to be a string.');
  }
}
