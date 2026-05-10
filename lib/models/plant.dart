enum PlantType { indoor, outdoor }

enum PlantHealth { excellent, good, fair, poor, critical }

extension PlantHealthExt on PlantHealth {
  String get label => name[0].toUpperCase() + name.substring(1);
  String get emoji {
    switch (this) {
      case PlantHealth.excellent: return '🌟';
      case PlantHealth.good: return '😊';
      case PlantHealth.fair: return '😐';
      case PlantHealth.poor: return '😕';
      case PlantHealth.critical: return '🥀';
    }
  }
}

class NotificationConfig {
  final bool enabled;
  final int hour;
  final int minute;
  final List<int> daysOfWeek; // 1=Mon .. 7=Sun

  const NotificationConfig({
    required this.enabled,
    required this.hour,
    required this.minute,
    required this.daysOfWeek,
  });

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'hour': hour,
    'minute': minute,
    'daysOfWeek': daysOfWeek,
  };

  factory NotificationConfig.fromJson(Map<String, dynamic> j) => NotificationConfig(
    enabled: j['enabled'] as bool,
    hour: j['hour'] as int,
    minute: j['minute'] as int,
    daysOfWeek: List<int>.from(j['daysOfWeek'] as List),
  );

  static NotificationConfig get defaultConfig => const NotificationConfig(
    enabled: false,
    hour: 9,
    minute: 0,
    daysOfWeek: [1, 3, 5],
  );
}

class Plant {
  final String id;
  String name;
  String? nickname;
  PlantType type;
  String? species;
  String? imagePath;
  DateTime dateAdded;
  String? notes;
  int? perenualId;
  List<String> careTips;
  String? wateringFrequency;
  String? sunlight;
  String? difficulty;
  NotificationConfig notificationConfig;

  Plant({
    required this.id,
    required this.name,
    this.nickname,
    required this.type,
    this.species,
    this.imagePath,
    required this.dateAdded,
    this.notes,
    this.perenualId,
    List<String>? careTips,
    this.wateringFrequency,
    this.sunlight,
    this.difficulty,
    NotificationConfig? notificationConfig,
  })  : careTips = careTips ?? [],
        notificationConfig = notificationConfig ?? NotificationConfig.defaultConfig;

  String get displayName => nickname ?? name;

  String get typeEmoji => type == PlantType.indoor ? '🏠' : '☀️';

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'nickname': nickname,
    'type': type.name,
    'species': species,
    'imagePath': imagePath,
    'dateAdded': dateAdded.millisecondsSinceEpoch,
    'notes': notes,
    'perenualId': perenualId,
    'careTips': careTips,
    'wateringFrequency': wateringFrequency,
    'sunlight': sunlight,
    'difficulty': difficulty,
    'notificationConfig': notificationConfig.toJson(),
  };

  factory Plant.fromJson(Map<String, dynamic> j) => Plant(
    id: j['id'] as String,
    name: j['name'] as String,
    nickname: j['nickname'] as String?,
    type: PlantType.values.firstWhere((e) => e.name == j['type'], orElse: () => PlantType.indoor),
    species: j['species'] as String?,
    imagePath: j['imagePath'] as String?,
    dateAdded: DateTime.fromMillisecondsSinceEpoch(j['dateAdded'] as int),
    notes: j['notes'] as String?,
    perenualId: j['perenualId'] as int?,
    careTips: j['careTips'] != null ? List<String>.from(j['careTips'] as List) : [],
    wateringFrequency: j['wateringFrequency'] as String?,
    sunlight: j['sunlight'] as String?,
    difficulty: j['difficulty'] as String?,
    notificationConfig: j['notificationConfig'] != null
        ? NotificationConfig.fromJson(j['notificationConfig'] as Map<String, dynamic>)
        : NotificationConfig.defaultConfig,
  );

  Plant copyWith({
    String? name,
    String? nickname,
    PlantType? type,
    String? species,
    String? imagePath,
    String? notes,
    int? perenualId,
    List<String>? careTips,
    String? wateringFrequency,
    String? sunlight,
    String? difficulty,
    NotificationConfig? notificationConfig,
  }) => Plant(
    id: id,
    name: name ?? this.name,
    nickname: nickname ?? this.nickname,
    type: type ?? this.type,
    species: species ?? this.species,
    imagePath: imagePath ?? this.imagePath,
    dateAdded: dateAdded,
    notes: notes ?? this.notes,
    perenualId: perenualId ?? this.perenualId,
    careTips: careTips ?? this.careTips,
    wateringFrequency: wateringFrequency ?? this.wateringFrequency,
    sunlight: sunlight ?? this.sunlight,
    difficulty: difficulty ?? this.difficulty,
    notificationConfig: notificationConfig ?? this.notificationConfig,
  );
}
