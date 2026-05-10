import 'package:bloom/models/plant_log.dart';
import 'package:bloom/services/storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LogsNotifier extends StateNotifier<List<PlantLog>> {
  final String plantId;

  LogsNotifier(this.plantId) : super(StorageService.getLogsForPlant(plantId));

  Future<void> addLog(PlantLog log) async {
    await StorageService.saveLog(log);
    state = StorageService.getLogsForPlant(plantId);
  }

  Future<void> deleteLog(String id) async {
    await StorageService.deleteLog(id);
    state = StorageService.getLogsForPlant(plantId);
  }

  void refresh() {
    state = StorageService.getLogsForPlant(plantId);
  }
}

final logsProvider = StateNotifierProvider.family<LogsNotifier, List<PlantLog>, String>(
  (_, plantId) => LogsNotifier(plantId),
);
