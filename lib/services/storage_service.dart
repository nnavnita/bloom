import 'dart:convert';
import 'package:bloom/models/plant.dart';
import 'package:bloom/models/plant_log.dart';
import 'package:hive_flutter/hive_flutter.dart';

class StorageService {
  static const _plantsBox = 'plants';
  static const _logsBox = 'logs';

  static Box get _plants => Hive.box(_plantsBox);
  static Box get _logs => Hive.box(_logsBox);

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_plantsBox);
    await Hive.openBox(_logsBox);
  }

  // Plants

  static List<Plant> getPlants() {
    return _plants.values
        .map((v) => Plant.fromJson(json.decode(v as String) as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
  }

  static Future<void> savePlant(Plant plant) async {
    await _plants.put(plant.id, json.encode(plant.toJson()));
  }

  static Future<void> deletePlant(String id) async {
    await _plants.delete(id);
    final logKeys = _logs.keys.where((k) {
      final v = _logs.get(k) as String?;
      if (v == null) return false;
      final m = json.decode(v) as Map<String, dynamic>;
      return m['plantId'] == id;
    }).toList();
    await _logs.deleteAll(logKeys);
  }

  // Logs

  static List<PlantLog> getLogsForPlant(String plantId) {
    return _logs.values
        .map((v) => PlantLog.fromJson(json.decode(v as String) as Map<String, dynamic>))
        .where((log) => log.plantId == plantId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  static List<PlantLog> getAllLogs() {
    return _logs.values
        .map((v) => PlantLog.fromJson(json.decode(v as String) as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  static Future<void> saveLog(PlantLog log) async {
    await _logs.put(log.id, json.encode(log.toJson()));
  }

  static Future<void> deleteLog(String id) async {
    await _logs.delete(id);
  }

  // Stats

  static int getLogStreak(String plantId) {
    final logs = getLogsForPlant(plantId);
    if (logs.isEmpty) return 0;

    final uniqueDays = <String>{};
    for (final log in logs) {
      uniqueDays.add('${log.date.year}-${log.date.month}-${log.date.day}');
    }

    final sortedDays = uniqueDays.toList()..sort((a, b) => b.compareTo(a));
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month}-${today.day}';
    final yesterday = today.subtract(const Duration(days: 1));
    final yestKey = '${yesterday.year}-${yesterday.month}-${yesterday.day}';

    if (sortedDays.first != todayKey && sortedDays.first != yestKey) return 0;

    int streak = 1;
    for (int i = 1; i < sortedDays.length; i++) {
      final prev = DateTime.parse(sortedDays[i - 1]);
      final curr = DateTime.parse(sortedDays[i]);
      if (prev.difference(curr).inDays == 1) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  static PlantHealth? getLatestHealth(String plantId) {
    final logs = getLogsForPlant(plantId);
    return logs.isEmpty ? null : logs.first.health;
  }

  static DateTime? getLastWatered(String plantId) {
    final logs = getLogsForPlant(plantId).where((l) => l.watered).toList();
    return logs.isEmpty ? null : logs.first.date;
  }
}
