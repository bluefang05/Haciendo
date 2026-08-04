import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class ReminderService {
  ReminderService._();
  static final ReminderService instance = ReminderService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz_data.initializeTimeZones();
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _plugin.initialize(settings);
  }

  Future<void> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
  }

  Future<void> schedule({
    required int id,
    required DateTime dateTime,
    required String projectName,
  }) async {
    if (dateTime.isBefore(DateTime.now())) return;
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'project_reminders',
        'Recordatorios de proyectos',
        channelDescription: 'Avisos opcionales para registrar avances.',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
    );
    await _plugin.zonedSchedule(
      id,
      'Haciendo',
      '¿Quieres registrar cómo va “$projectName”?',
      tz.TZDateTime.from(dateTime, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> cancel(int id) => _plugin.cancel(id);
}
