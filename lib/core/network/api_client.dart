import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../storage/token_storage.dart';

/// Builds the Dio client used for every call to the Cubanía API.
///
/// - Always asks for JSON.
/// - Adds `Authorization: Bearer <token>` when a token is stored.
/// - Calls [onUnauthorized] when an authenticated request comes back 401
///   (expired or revoked token), so the app can return to the login screen.
Dio buildApiClient({
  required TokenStorage tokenStorage,
  required void Function() onUnauthorized,
  String? baseUrl,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl ?? AppConfig.apiBaseUrl,
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
      headers: {'Accept': 'application/json'},
      contentType: Headers.jsonContentType,
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await tokenStorage.read();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        final sentToken = error.requestOptions.headers.containsKey(
          'Authorization',
        );
        if (sentToken && error.response?.statusCode == 401) {
          onUnauthorized();
        }
        handler.next(error);
      },
    ),
  );

  return dio;
}
