import 'package:chucker_flutter_plus/chucker_flutter_plus.dart';
import 'package:dio/dio.dart';

import '../config/demo_config.dart';
import '../../data/datasources/posts_remote_data_source.dart';
import '../../data/repositories/posts_repository_impl.dart';
import '../../domain/repositories/posts_repository.dart';

final class DependencyInjection {
  const DependencyInjection._();

  static PostsRepository createPostsRepository() {
    final dio = Dio(
      BaseOptions(
        baseUrl: DemoConfig.apiBaseUrl,
        connectTimeout: DemoConfig.requestTimeout,
        receiveTimeout: DemoConfig.requestTimeout,
        headers: const {'Accept': 'application/json'},
      ),
    )..interceptors.add(ChuckerDioInterceptor());

    return PostsRepositoryImpl(PostsRemoteDataSource(dio));
  }
}
