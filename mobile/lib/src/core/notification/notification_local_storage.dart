import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartfridge_mobile/src/core/auth/token_storage.dart';

class NotificationLocalStorage {
  NotificationLocalStorage(this._tokenStorage);

  static const _afterIdPrefix = 'notification_after_id';
  static const _shownIdsPrefix = 'notification_shown_ids';
  static const _maxStoredShownIds = 200;

  final TokenStorage _tokenStorage;

  Future<int?> readAfterId() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _scopedKey(_afterIdPrefix);
    return prefs.getInt(key);
  }

  Future<void> writeAfterId(int afterId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _scopedKey(_afterIdPrefix);
    await prefs.setInt(key, afterId);
  }

  Future<Set<int>> readShownNotificationIds() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _scopedKey(_shownIdsPrefix);
    final rawIds = prefs.getStringList(key) ?? const <String>[];
    return rawIds.map(int.tryParse).whereType<int>().toSet();
  }

  Future<bool> hasShownNotification(int notificationId) async {
    final shownIds = await readShownNotificationIds();
    return shownIds.contains(notificationId);
  }

  Future<void> markNotificationAsShown(int notificationId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _scopedKey(_shownIdsPrefix);
    final shownIds = await readShownNotificationIds();
    shownIds.add(notificationId);

    final trimmed = shownIds.toList()..sort();
    if (trimmed.length > _maxStoredShownIds) {
      trimmed.removeRange(0, trimmed.length - _maxStoredShownIds);
    }

    await prefs.setStringList(
      key,
      trimmed.map((id) => id.toString()).toList(growable: false),
    );
  }

  Future<void> clearSessionState() async {
    final prefs = await SharedPreferences.getInstance();
    final afterIdKey = await _scopedKey(_afterIdPrefix);
    final shownIdsKey = await _scopedKey(_shownIdsPrefix);
    await prefs.remove(afterIdKey);
    await prefs.remove(shownIdsKey);
  }

  Future<String> _scopedKey(String prefix) async {
    final token = await _tokenStorage.readToken();
    final subject = _extractSubject(token);
    return '${prefix}_${_sanitizeKey(subject)}';
  }

  String _extractSubject(String? token) {
    if (token == null || token.isEmpty) {
      return 'anonymous';
    }

    final parts = token.split('.');
    if (parts.length < 2) {
      return 'anonymous';
    }

    try {
      final normalized = base64Url.normalize(parts[1]);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final payload = jsonDecode(decoded);
      if (payload is Map<String, dynamic>) {
        final subject = payload['sub'];
        if (subject is String && subject.isNotEmpty) {
          return subject;
        }
      }
    } catch (_) {
      return 'anonymous';
    }

    return 'anonymous';
  }

  String _sanitizeKey(String value) {
    return value.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
  }
}
