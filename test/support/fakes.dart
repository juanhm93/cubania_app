import 'dart:convert';
import 'dart:typed_data';

import 'package:cubania_app/core/network/api_exception.dart';
import 'package:cubania_app/features/auth/data/auth_repository.dart';
import 'package:cubania_app/features/auth/domain/student_identifier.dart';
import 'package:cubania_app/features/auth/domain/student_profile.dart';
import 'package:dio/dio.dart';

const sampleStudentJson = <String, dynamic>{
  'id': 42,
  'name': 'Ana María López',
  'email': 'ana@example.com',
  'dni': 'V-12345678',
  'phone': null,
  'birthday': '1995-03-14',
  'current_level': {
    'id': 3,
    'name': 'Básico 1',
    'slug': 'basico-1',
    'dance_type': {'id': 1, 'name': 'Salsa casino'},
  },
};

StudentProfile sampleStudent() => StudentProfile.fromJson(sampleStudentJson);

/// Answers Dio requests with canned JSON and records what was sent.
class FakeHttpAdapter implements HttpClientAdapter {
  FakeHttpAdapter(this._respond);

  final ({int status, Object? body}) Function(RequestOptions options) _respond;

  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final response = _respond(options);

    return ResponseBody.fromString(
      response.body == null ? '' : jsonEncode(response.body),
      response.status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// In-memory stand-in for [AuthRepository].
class FakeAuthRepository extends AuthRepository {
  FakeAuthRepository() : super(Dio());

  StudentProfile? meResult;
  ApiException? meError;
  ApiException? requestCodeError;
  int logoutCalls = 0;
  ApiException? logoutError;

  @override
  Future<LoginCodeRequest> requestCode(StudentIdentifier identifier) async {
    if (requestCodeError != null) throw requestCodeError!;

    return const LoginCodeRequest(
      message: 'ok',
      codeLength: 6,
      expiresInMinutes: 10,
    );
  }

  @override
  Future<StudentProfile> fetchMe() async {
    if (meError != null) throw meError!;
    return meResult ?? sampleStudent();
  }

  @override
  Future<void> logout() async {
    logoutCalls++;
    if (logoutError != null) throw logoutError!;
  }
}
