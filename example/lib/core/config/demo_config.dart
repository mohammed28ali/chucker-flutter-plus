abstract final class DemoConfig {
  static const apiBaseUrl = 'https://jsonplaceholder.typicode.com';
  static const requestTimeout = Duration(seconds: 15);
  static const pageSize = 8;
  static const sampleUserId = 1;
  static const samplePostTitle = 'Hello Chucker';
  static const samplePostBody =
      'Inspect this request in the network inspector.';
  static const clientHeaderName = 'X-Demo-Client';
  static const clientHeaderValue = 'chucker-flutter-plus';
}
