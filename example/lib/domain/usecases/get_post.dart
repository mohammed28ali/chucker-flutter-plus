import '../entities/post.dart';
import '../repositories/posts_repository.dart';

final class GetPost {
  const GetPost(this._repository);

  final PostsRepository _repository;

  Future<Post> call(int id) => _repository.getPost(id);
}
