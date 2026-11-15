import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/config/demo_config.dart';
import '../domain/entities/post.dart';
import '../domain/usecases/create_demo_post.dart';
import '../domain/usecases/get_missing_post.dart';
import '../domain/usecases/get_post.dart';
import '../domain/usecases/get_posts.dart';
import 'models/dashboard_state.dart';

final class DashboardViewModel extends ChangeNotifier {
  DashboardViewModel({
    required GetPosts getPosts,
    required GetPost getPost,
    required GetMissingPost getMissingPost,
    required CreateDemoPost createDemoPost,
  }) : _getPosts = getPosts,
       _getPost = getPost,
       _getMissingPost = getMissingPost,
       _createDemoPost = createDemoPost;

  final GetPosts _getPosts;
  final GetPost _getPost;
  final GetMissingPost _getMissingPost;
  final CreateDemoPost _createDemoPost;

  DashboardState _state = const DashboardState();
  DashboardState get state => _state;

  Future<void> fetchPosts() => _run(() async {
    final posts = await _getPosts(limit: DemoConfig.pageSize);
    _state = _state.copyWith(posts: posts);
  }, successMessage: 'Posts loaded · GET 200');

  Future<void> createPost() => _run(() async {
    await _createDemoPost(
      title: DemoConfig.samplePostTitle,
      body: DemoConfig.samplePostBody,
      userId: DemoConfig.sampleUserId,
    );
  }, successMessage: 'Post created · POST 201');

  Future<void> fetchMissingPost() => _run(() async {
    await _getMissingPost();
  });

  Future<Post?> fetchPost(int id) async {
    Post? post;
    await _run(() async => post = await _getPost(id));
    return post;
  }

  Future<void> _run(
    Future<void> Function() action, {
    String? successMessage,
  }) async {
    _state = _state.copyWith(isLoading: true, clearMessage: true);
    notifyListeners();
    try {
      await action();
      _state = _state.copyWith(message: successMessage);
    } on DioException catch (error) {
      _state = _state.copyWith(
        message:
            'Request captured · ${error.response?.statusCode ?? 'network error'}',
      );
    } catch (error) {
      _state = _state.copyWith(message: 'Request failed · $error');
    } finally {
      _state = _state.copyWith(isLoading: false);
      notifyListeners();
    }
  }
}
