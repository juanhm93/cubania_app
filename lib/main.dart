import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/config/app_config.dart';

void main() {
  if (kDebugMode) {
    final host = AppConfig.apiHostHeader;
    debugPrint(
      'API: ${AppConfig.apiBaseUrl}${host.isEmpty ? '' : ' (Host: $host)'}',
    );
  }
  runApp(const ProviderScope(child: CubaniaApp()));
}
