import '../entities/post.dart';

abstract interface class PostsRepository {
  Future<List<Post>> getPosts({required int limit});

  Future<Post> getPost(int id);

  Future<Post> createPost({
    required String title,
    required String body,
    required int userId,
  });

  Future<void> getMissingPost();
}
