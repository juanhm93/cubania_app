import 'package:cubania_app/core/network/api_exception.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

DioException _withResponse(int status, Object? data) {
  final options = RequestOptions(path: '/auth/verify-code');

  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response<Object?>(
      requestOptions: options,
      statusCode: status,
      data: data,
    ),
  );
}

void main() {
  test('maps Laravel validation errors to field messages', () {
    final exception = ApiException.fromDioException(
      _withResponse(422, {
        'message': 'El código no es válido o ya venció. Solicita uno nuevo.',
        'errors': {
          'code': ['El código no es válido o ya venció. Solicita uno nuevo.'],
        },
      }),
    );

    expect(exception.statusCode, 422);
    expect(
      exception.fieldErrors['code'],
      'El código no es válido o ya venció. Solicita uno nuevo.',
    );
    expect(exception.message, startsWith('El código no es válido'));
  });

  test('treats a missing response as a connection error', () {
    final exception = ApiException.fromDioException(
      DioException(
        requestOptions: RequestOptions(path: '/me'),
        type: DioExceptionType.connectionError,
      ),
    );

    expect(exception.isConnectionError, isTrue);
    expect(exception.message, ApiException.connectionErrorMessage);
  });

  test('uses friendly messages for 401, 429 and 5xx', () {
    expect(
      ApiException.fromDioException(
        _withResponse(401, {'message': 'Unauthenticated.'}),
      ).isUnauthenticated,
      isTrue,
    );
    expect(
      ApiException.fromDioException(
        _withResponse(429, {'message': 'Too Many Attempts.'}),
      ).message,
      contains('Demasiados intentos'),
    );
    expect(
      ApiException.fromDioException(_withResponse(500, null)).message,
      contains('servidor'),
    );
  });
}
