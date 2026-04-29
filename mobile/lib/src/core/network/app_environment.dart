import 'package:flutter/foundation.dart';

const _configuredBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
const _appEnv = String.fromEnvironment('APP_ENV', defaultValue: 'dev');

String resolveApiBaseUrl() {
  if (_configuredBaseUrl.isNotEmpty) {
    return _configuredBaseUrl;
  }

  if (_appEnv == 'prod') {
    throw UnsupportedError(
      'API_BASE_URL must be provided when APP_ENV=prod',
    );
  }

  if (kIsWeb) {
    return 'http://localhost:8080';
  }

  if (defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:8080';
  }

  return 'http://localhost:8080';
}
