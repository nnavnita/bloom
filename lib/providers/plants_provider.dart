import 'package:bloom/models/plant.dart';
import 'package:bloom/services/notification_service.dart';
import 'package:bloom/services/storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PlantsNotifier extends StateNotifier<List<Plant>> {
  PlantsNotifier() : super(StorageService.getPlants());

  Future<void> addPlant(Plant plant) async {
    await StorageService.savePlant(plant);
    if (plant.notificationConfig.enabled) {
      await NotificationService.scheduleForPlant(plant);
    }
    state = StorageService.getPlants();
  }

  Future<void> updatePlant(Plant plant) async {
    await StorageService.savePlant(plant);
    await NotificationService.cancelForPlant(plant.id);
    if (plant.notificationConfig.enabled) {
      await NotificationService.scheduleForPlant(plant);
    }
    state = StorageService.getPlants();
  }

  Future<void> deletePlant(String id) async {
    await NotificationService.cancelForPlant(id);
    await StorageService.deletePlant(id);
    state = StorageService.getPlants();
  }

  void refresh() {
    state = StorageService.getPlants();
  }
}

final plantsProvider = StateNotifierProvider<PlantsNotifier, List<Plant>>(
  (_) => PlantsNotifier(),
);

final indoorPlantsProvider = Provider<List<Plant>>((ref) {
  return ref.watch(plantsProvider).where((p) => p.type == PlantType.indoor).toList();
});

final outdoorPlantsProvider = Provider<List<Plant>>((ref) {
  return ref.watch(plantsProvider).where((p) => p.type == PlantType.outdoor).toList();
});
