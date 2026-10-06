import 'package:flutter/foundation.dart';

/// Runtime configuration for the app.
///
/// The API URL comes from `--dart-define=API_BASE_URL=...`. Without it, the app
/// points at a local `php artisan serve` (port 8000): `10.0.2.2` is how the
/// Android emulator reaches the host machine, `localhost` works on the iOS
/// simulator.
///
/// ```sh
/// flutter run --dart-define=API_BASE_URL=https://cubania.purphura.com/api/v1
/// ```
class AppConfig {
  const AppConfig._();

  static const String _apiBaseUrlFromEnvironment = String.fromEnvironment(
    'API_BASE_URL',
  );

  static String get apiBaseUrl {
    if (_apiBaseUrlFromEnvironment.isNotEmpty) {
      return _apiBaseUrlFromEnvironment;
    }

    final host = defaultTargetPlatform == TargetPlatform.android
        ? '10.0.2.2'
        : 'localhost';

    return 'http://$host:8000/api/v1';
  }

  /// Sent as `device_name` when signing in; the backend names the token after it.
  static String get deviceName => 'Cubanía app (${defaultTargetPlatform.name})';

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 20);
}
