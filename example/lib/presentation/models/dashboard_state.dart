import 'post.dart';

final class DashboardState {
  const DashboardState({
    this.posts = const [],
    this.isLoading = false,
    this.message,
  });

  final List<Post> posts;
  final bool isLoading;
  final String? message;

  DashboardState copyWith({
    List<Post>? posts,
    bool? isLoading,
    String? message,
    bool clearMessage = false,
  }) => DashboardState(
    posts: posts ?? this.posts,
    isLoading: isLoading ?? this.isLoading,
    message: clearMessage ? null : message ?? this.message,
  );
}
