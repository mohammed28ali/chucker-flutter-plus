import '../entities/post.dart';
import '../repositories/posts_repository.dart';

final class CreateDemoPost {
  const CreateDemoPost(this._repository);

  final PostsRepository _repository;

  Future<Post> call({
    required String title,
    required String body,
    required int userId,
  }) => _repository.createPost(title: title, body: body, userId: userId);
}
