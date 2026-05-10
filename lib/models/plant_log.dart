import 'package:bloom/models/plant.dart';

class PlantLog {
  final String id;
  final String plantId;
  final DateTime date;
  PlantHealth health;
  bool watered;
  bool fertilized;
  bool repotted;
  String? notes;
  String? imagePath;

  PlantLog({
    required this.id,
    required this.plantId,
    required this.date,
    required this.health,
    this.watered = false,
    this.fertilized = false,
    this.repotted = false,
    this.notes,
    this.imagePath,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'plantId': plantId,
    'date': date.millisecondsSinceEpoch,
    'health': health.name,
    'watered': watered,
    'fertilized': fertilized,
    'repotted': repotted,
    'notes': notes,
    'imagePath': imagePath,
  };

  factory PlantLog.fromJson(Map<String, dynamic> j) => PlantLog(
    id: j['id'] as String,
    plantId: j['plantId'] as String,
    date: DateTime.fromMillisecondsSinceEpoch(j['date'] as int),
    health: PlantHealth.values.firstWhere(
      (e) => e.name == j['health'],
      orElse: () => PlantHealth.good,
    ),
    watered: j['watered'] as bool? ?? false,
    fertilized: j['fertilized'] as bool? ?? false,
    repotted: j['repotted'] as bool? ?? false,
    notes: j['notes'] as String?,
    imagePath: j['imagePath'] as String?,
  );
}
