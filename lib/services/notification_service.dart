import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:bloom/models/plant.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(android: android, iOS: ios);

    await _plugin.initialize(settings);
    _initialized = true;
  }

  static Future<bool> requestPermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final granted = await ios.requestPermissions(alert: true, badge: true, sound: true);
      return granted ?? false;
    }
    return true;
  }

  static Future<void> scheduleForPlant(Plant plant) async {
    await cancelForPlant(plant.id);

    final config = plant.notificationConfig;
    if (!config.enabled || config.daysOfWeek.isEmpty) return;

    for (final day in config.daysOfWeek) {
      final id = _notifId(plant.id, day);
      final scheduledTime = _nextOccurrence(day, config.hour, config.minute);

      await _plugin.zonedSchedule(
        id,
        '🌱 Time to check on ${plant.displayName}!',
        'How is your ${plant.type == PlantType.indoor ? "indoor" : "outdoor"} plant doing today?',
        scheduledTime,
        _notifDetails(plant.id),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  static Future<void> cancelForPlant(String plantId) async {
    for (int day = 1; day <= 7; day++) {
      await _plugin.cancel(_notifId(plantId, day));
    }
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  static int _notifId(String plantId, int day) {
    return (plantId.hashCode.abs() % 100000) * 10 + day;
  }

  static tz.TZDateTime _nextOccurrence(int weekday, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var candidate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    // Advance to correct weekday (weekday: 1=Mon, 7=Sun in ISO)
    while (candidate.weekday != weekday || candidate.isBefore(now)) {
      candidate = candidate.add(const Duration(days: 1));
    }
    return candidate;
  }

  static NotificationDetails _notifDetails(String plantId) {
    const android = AndroidNotificationDetails(
      'bloom_plant_reminders',
      'Plant Reminders',
      channelDescription: 'Reminders to log your plant conditions',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const ios = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    return const NotificationDetails(android: android, iOS: ios);
  }
}
