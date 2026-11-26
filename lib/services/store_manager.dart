import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Async wrapper around [SharedPreferences] for local key-value persistence.
class StorageManager {
  static Future<SharedPreferences> init() async {
    return SharedPreferences.getInstance();
  }

  static Future<bool> saveData(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is int) {
      return prefs.setInt(key, value);
    } else if (value is String) {
      return prefs.setString(key, value);
    } else if (value is bool) {
      return prefs.setBool(key, value);
    } else if (value is double) {
      return prefs.setDouble(key, value);
    } else if (value is List<String>) {
      return prefs.setStringList(key, value);
    } else {
      if (kDebugMode) {
        debugPrint('StorageManager: Unsupported value type ${value.runtimeType}');
      }
      return false;
    }
  }

  static Future<dynamic> readData(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.get(key);
  }

  static Future<Set<String>> getKeys() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getKeys();
  }

  static dynamic readDataFromPrefs(String key, SharedPreferences prefs) {
    return prefs.get(key);
  }

  static Future<bool> deleteData(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.remove(key);
  }
}
