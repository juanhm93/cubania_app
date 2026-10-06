import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../domain/student_identifier.dart';
import '../domain/student_profile.dart';

/// Result of asking the backend to email a login code.
class LoginCodeRequest {
  const LoginCodeRequest({
    required this.message,
    required this.codeLength,
    required this.expiresInMinutes,
  });

  final String message;
  final int codeLength;
  final int expiresInMinutes;
}

/// A token plus the profile it belongs to.
class AuthSession {
  const AuthSession({
    required this.token,
    required this.expiresAt,
    required this.student,
  });

  final String token;
  final DateTime expiresAt;
  final StudentProfile student;
}

/// Calls to the auth and profile endpoints of the API v1.
///
/// Every method throws [ApiException] on failure.
class AuthRepository {
  AuthRepository(this._dio);

  final Dio _dio;

  Future<LoginCodeRequest> requestCode(StudentIdentifier identifier) async {
    final body = await _post('/auth/request-code', identifier.toJson());
    final data = body['data'] as Map<String, dynamic>;

    return LoginCodeRequest(
      message: body['message'] as String,
      codeLength: data['code_length'] as int,
      expiresInMinutes: data['expires_in_minutes'] as int,
    );
  }

  Future<AuthSession> verifyCode({
    required StudentIdentifier identifier,
    required String code,
    required String deviceName,
  }) async {
    final body = await _post('/auth/verify-code', {
      ...identifier.toJson(),
      'code': code,
      'device_name': deviceName,
    });
    final data = body['data'] as Map<String, dynamic>;

    return AuthSession(
      token: data['token'] as String,
      expiresAt: DateTime.parse(data['expires_at'] as String),
      student: StudentProfile.fromJson(data['student'] as Map<String, dynamic>),
    );
  }

  Future<StudentProfile> fetchMe() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/me');
      final data = response.data!['data'] as Map<String, dynamic>;

      return StudentProfile.fromJson(data);
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post<void>('/auth/logout');
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        path,
        data: payload,
      );

      return response.data!;
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }
}
