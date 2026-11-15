import '../repositories/posts_repository.dart';

final class GetMissingPost {
  const GetMissingPost(this._repository);

  final PostsRepository _repository;

  Future<void> call() => _repository.getMissingPost();
}
