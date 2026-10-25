import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// An API error translated into something the UI can show.
class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
    this.fieldErrors = const {},
  });

  /// Builds an [ApiException] from any error thrown by Dio.
  ///
  /// The backend answers errors as `{ "message": "...", "errors": { field: [...] } }`.
  factory ApiException.fromDioException(DioException exception) {
    final response = exception.response;

    if (response == null) {
      if (kDebugMode) {
        debugPrint(
          'API sin respuesta: ${exception.type.name} '
          '${exception.requestOptions.uri} → ${exception.error}',
        );
      }
      return const ApiException(message: connectionErrorMessage);
    }

    final statusCode = response.statusCode;
    final data = response.data;
    final fieldErrors = <String, String>{};
    String? serverMessage;

    if (data is Map) {
      final message = data['message'];
      if (message is String && message.isNotEmpty) {
        serverMessage = message;
      }

      final errors = data['errors'];
      if (errors is Map) {
        errors.forEach((field, messages) {
          if (messages is List && messages.isNotEmpty) {
            fieldErrors[field.toString()] = messages.first.toString();
          }
        });
      }
    }

    return ApiException(
      message: _messageFor(statusCode, serverMessage),
      statusCode: statusCode,
      fieldErrors: fieldErrors,
    );
  }

  static const String connectionErrorMessage =
      'No pudimos conectar con Cubanía. Revisa tu conexión e intenta de nuevo.';

  final String message;
  final int? statusCode;

  /// First validation message per field (for example `code`, `email`).
  final Map<String, String> fieldErrors;

  bool get isUnauthenticated => statusCode == 401;

  bool get isForbidden => statusCode == 403;

  bool get isConnectionError => statusCode == null;

  static String _messageFor(int? statusCode, String? serverMessage) {
    switch (statusCode) {
      case 401:
        return 'Tu sesión venció. Vuelve a entrar.';
      case 429:
        return 'Demasiados intentos. Espera un minuto e intenta de nuevo.';
      case 422:
        return serverMessage ?? 'Revisa los datos e intenta de nuevo.';
    }

    if (statusCode != null && statusCode >= 500) {
      return 'Algo falló en el servidor. Intenta de nuevo en unos minutos.';
    }

    return serverMessage ?? 'Algo salió mal. Intenta de nuevo.';
  }

  @override
  String toString() => 'ApiException($statusCode): $message';
}
