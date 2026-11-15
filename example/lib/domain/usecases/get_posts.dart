import '../entities/post.dart';
import '../repositories/posts_repository.dart';

final class GetPosts {
  const GetPosts(this._repository);

  final PostsRepository _repository;

  Future<List<Post>> call({required int limit}) =>
      _repository.getPosts(limit: limit);
}
