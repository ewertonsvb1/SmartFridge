import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class TokenStorage {
  Future<String?> readToken();

  Future<void> writeToken(String token);

  Future<void> clearToken();
}

class HybridTokenStorage implements TokenStorage {
  HybridTokenStorage(this._secureStorage);

  static const _tokenKey = 'jwt_token';

  final FlutterSecureStorage _secureStorage;

  @override
  Future<String?> readToken() async {
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getString(_tokenKey);
      }

      return await _secureStorage.read(
        key: _tokenKey,
      );
    } catch (e) {
      debugPrint('Token read error: $e');
      return null;
    }
  }

  @override
  Future<void> writeToken(String token) async {
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, token);
        return;
      }

      await _secureStorage.write(
        key: _tokenKey,
        value: token,
      );
    } catch (e) {
      debugPrint('Token write error: $e');
    }
  }

  @override
  Future<void> clearToken() async {
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_tokenKey);
        return;
      }

      await _secureStorage.delete(
        key: _tokenKey,
      );
    } catch (e) {
      debugPrint('Token clear error: $e');
    }
  }
}

final tokenStorageProvider = Provider<TokenStorage>((_) {
  return HybridTokenStorage(const FlutterSecureStorage());
});
