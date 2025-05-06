import 'dart:convert';
import 'store_manager.dart';

class TaskService {
  static String _generateKeyForDate(DateTime date) {
    final formatted = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    return "tasks_$formatted";
  }

  static Future<List<Map<String, dynamic>>> loadTasks(DateTime date) async {
    final key = _generateKeyForDate(date);
    final data = await StorageManager.readData(key);
    if (data != null && data is String) {
      final decoded = jsonDecode(data) as List<dynamic>;
      return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return [];
  }

  static Future<void> saveTasks(DateTime date, List<Map<String, dynamic>> tasks) async {
    final key = _generateKeyForDate(date);
    final jsonString = jsonEncode(tasks);
    StorageManager.saveData(key, jsonString);
  }

  static Future<void> deleteTasks(DateTime date) async {
    final key = _generateKeyForDate(date);
    await StorageManager.deleteData(key);
  }
}
