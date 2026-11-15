import 'package:dio/dio.dart';

import '../../core/config/demo_config.dart';
import '../models/post_model.dart';

final class PostsRemoteDataSource {
  const PostsRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<PostModel>> getPosts({required int limit}) async {
    final response = await _dio.get<List<dynamic>>(
      '/posts',
      queryParameters: {'_limit': limit},
    );
    return (response.data ?? const [])
        .map((json) => PostModel.fromJson(_asJson(json)))
        .toList(growable: false);
  }

  Future<PostModel> getPost(int id) async {
    final response = await _dio.get<Map<String, dynamic>>('/posts/$id');
    final data = response.data;
    if (data == null) {
      throw const FormatException('The post response was empty.');
    }
    return PostModel.fromJson(data);
  }

  Future<PostModel> createPost({
    required String title,
    required String body,
    required int userId,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/posts',
      data: {'title': title, 'body': body, 'userId': userId},
      options: Options(
        headers: {DemoConfig.clientHeaderName: DemoConfig.clientHeaderValue},
      ),
    );
    final data = response.data;
    if (data == null) {
      throw const FormatException('The created post response was empty.');
    }
    return PostModel.fromJson(data);
  }

  Future<void> getMissingPost() async {
    await _dio.get<void>('/posts/0');
  }

  Map<String, dynamic> _asJson(Object? value) {
    if (value is Map<String, dynamic>) return value;
    throw const FormatException('Expected a JSON object in the post list.');
  }
}
