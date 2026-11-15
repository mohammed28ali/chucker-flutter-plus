import '../../domain/entities/post.dart';
import '../../domain/repositories/posts_repository.dart';
import '../datasources/posts_remote_data_source.dart';

final class PostsRepositoryImpl implements PostsRepository {
  const PostsRepositoryImpl(this._remoteDataSource);

  final PostsRemoteDataSource _remoteDataSource;

  @override
  Future<List<Post>> getPosts({required int limit}) async =>
      _remoteDataSource.getPosts(limit: limit);

  @override
  Future<Post> getPost(int id) => _remoteDataSource.getPost(id);

  @override
  Future<Post> createPost({
    required String title,
    required String body,
    required int userId,
  }) => _remoteDataSource.createPost(title: title, body: body, userId: userId);

  @override
  Future<void> getMissingPost() => _remoteDataSource.getMissingPost();
}
