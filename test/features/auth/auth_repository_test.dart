import 'package:cubania_app/core/network/api_client.dart';
import 'package:cubania_app/core/network/api_exception.dart';
import 'package:cubania_app/core/storage/token_storage.dart';
import 'package:cubania_app/features/auth/data/auth_repository.dart';
import 'package:cubania_app/features/auth/domain/student_identifier.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

void main() {
  late InMemoryTokenStorage tokenStorage;
  late FakeHttpAdapter adapter;
  late int unauthorizedCalls;
  late AuthRepository repository;

  void setUpWith(({int status, Object? body}) Function(String path) respond) {
    tokenStorage = InMemoryTokenStorage();
    unauthorizedCalls = 0;
    adapter = FakeHttpAdapter((options) => respond(options.path));

    final dio = buildApiClient(
      tokenStorage: tokenStorage,
      onUnauthorized: () => unauthorizedCalls++,
      baseUrl: 'https://api.test/api/v1',
    )..httpClientAdapter = adapter;

    repository = AuthRepository(dio);
  }

  test('requestCode sends the identifier and reads the code settings', () async {
    setUpWith(
      (_) => (
        status: 202,
        body: {
          'message': 'Enviado',
          'data': {'code_length': 6, 'expires_in_minutes': 10},
        },
      ),
    );

    final result = await repository.requestCode(
      const StudentIdentifier.dni('V-12345678'),
    );

    expect(result.codeLength, 6);
    expect(result.expiresInMinutes, 10);
    expect(adapter.requests.single.path, '/auth/request-code');
    expect(adapter.requests.single.data, {'dni': 'V-12345678'});
    expect(adapter.requests.single.headers['Accept'], 'application/json');
  });

  test('verifyCode returns the session with the student profile', () async {
    setUpWith(
      (_) => (
        status: 200,
        body: {
          'data': {
            'token': '12|secret',
            'token_type': 'Bearer',
            'expires_at': '2026-12-05T04:00:00+00:00',
            'student': sampleStudentJson,
          },
        },
      ),
    );

    final session = await repository.verifyCode(
      identifier: const StudentIdentifier.email('ana@example.com'),
      code: '482913',
      deviceName: 'Test phone',
    );

    expect(session.token, '12|secret');
    expect(session.student.name, 'Ana María López');
    expect(session.student.currentLevel?.danceType?.name, 'Salsa casino');
    expect(adapter.requests.single.data, {
      'email': 'ana@example.com',
      'code': '482913',
      'device_name': 'Test phone',
    });
  });

  test('verifyCode surfaces the code validation error', () async {
    setUpWith(
      (_) => (
        status: 422,
        body: {
          'message': 'El código no es válido o ya venció. Solicita uno nuevo.',
          'errors': {
            'code': ['El código no es válido o ya venció. Solicita uno nuevo.'],
          },
        },
      ),
    );

    await expectLater(
      repository.verifyCode(
        identifier: const StudentIdentifier.email('ana@example.com'),
        code: '000000',
        deviceName: 'Test phone',
      ),
      throwsA(
        isA<ApiException>().having(
          (exception) => exception.fieldErrors['code'],
          'code error',
          isNotNull,
        ),
      ),
    );
    expect(unauthorizedCalls, 0);
  });

  test('fetchMe sends the stored token as a Bearer header', () async {
    setUpWith((_) => (status: 200, body: {'data': sampleStudentJson}));
    await tokenStorage.write('12|secret');

    final student = await repository.fetchMe();

    expect(student.id, 42);
    expect(adapter.requests.single.headers['Authorization'], 'Bearer 12|secret');
  });

  test('a 401 on an authenticated request notifies the app', () async {
    setUpWith((_) => (status: 401, body: {'message': 'Unauthenticated.'}));
    await tokenStorage.write('12|expired');

    await expectLater(
      repository.fetchMe(),
      throwsA(
        isA<ApiException>().having(
          (exception) => exception.isUnauthenticated,
          'isUnauthenticated',
          isTrue,
        ),
      ),
    );
    expect(unauthorizedCalls, 1);
  });
}
