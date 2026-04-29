import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartfridge_mobile/src/core/auth/token_storage.dart';

class AuthSession extends ChangeNotifier {
  AuthSession({required TokenStorage tokenStorage}) : _tokenStorage = tokenStorage;

  final TokenStorage _tokenStorage;

  bool _initialized = false;
  bool _authenticated = false;

  bool get initialized => _initialized;

  bool get authenticated => _authenticated;

  Future<void> restore() async {
    final token = await _tokenStorage.readToken();
    _authenticated = token != null && token.isNotEmpty;
    _initialized = true;
    notifyListeners();
  }

  void setAuthenticated(bool value) {
    _authenticated = value;
    _initialized = true;
    notifyListeners();
  }
}

final authSessionProvider = Provider<AuthSession>((ref) {
  final session = AuthSession(tokenStorage: ref.watch(tokenStorageProvider));
  unawaited(session.restore());
  ref.onDispose(session.dispose);
  return session;
});
