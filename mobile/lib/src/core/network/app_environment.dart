import 'package:flutter/foundation.dart';

const _configuredBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
const _appEnv = String.fromEnvironment('APP_ENV', defaultValue: 'dev');

String resolveApiBaseUrl() {
  if (_configuredBaseUrl.isNotEmpty) {
    return _resolveConfiguredBaseUrl();
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

String _resolveConfiguredBaseUrl() {
  final normalizedBaseUrl = _configuredBaseUrl.trim().replaceFirst(RegExp(r'\/+$'), '');
  final uri = Uri.tryParse(normalizedBaseUrl);

  if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
    throw UnsupportedError(
      'API_BASE_URL must be an absolute http(s) URL',
    );
  }

  if (uri.scheme != 'http' && uri.scheme != 'https') {
    throw UnsupportedError(
      'API_BASE_URL must use http or https',
    );
  }

  if (_appEnv == 'prod' && _isLocalOnlyHost(uri.host)) {
    throw UnsupportedError(
      'API_BASE_URL must not target localhost or emulator hosts when APP_ENV=prod',
    );
  }

  return normalizedBaseUrl;
}

bool _isLocalOnlyHost(String host) {
  final normalizedHost = host.toLowerCase();
  return normalizedHost == 'localhost' ||
      normalizedHost == '127.0.0.1' ||
      normalizedHost == '10.0.2.2';
}
