import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../../models/recordatorio.dart';

int _notificationId(String prefix, String id) {
  return '$prefix-$id'.hashCode;
}

class NotificacionService {
  static final NotificacionService _instance = NotificacionService._();
  factory NotificacionService() => _instance;
  NotificacionService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool get _esCompatible => !kIsWeb;
  bool _inicializado = false;

  Future<void> initialize() async {
    if (!_esCompatible || _inicializado) return;
    _inicializado = true;

    tz_data.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(initSettings);
    await _solicitarPermisosAndroid();
    await _solicitarPermisosIOS();
  }

  Future<void> _solicitarPermisosAndroid() async {
    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }
  }

  Future<void> _solicitarPermisosIOS() async {
    final iosPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    if (iosPlugin != null) {
      await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  Future<void> programarRecordatorio(Recordatorio recordatorio) async {
    if (!_esCompatible) return;

    final scheduledDate = tz.TZDateTime.from(
      recordatorio.fechaHora,
      tz.local,
    );

    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) return;

    const androidDetails = AndroidNotificationDetails(
      'recordatorios',
      'Recordatorios',
      channelDescription: 'Notificaciones de recordatorios',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.zonedSchedule(
      _notificationId('recordatorio', recordatorio.id),
      recordatorio.titulo,
      recordatorio.descripcion.isNotEmpty
          ? recordatorio.descripcion
          : 'Tienes un recordatorio pendiente',
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelarRecordatorio(String id) async {
    if (!_esCompatible) return;
    await _plugin.cancel(_notificationId('recordatorio', id));
  }

  Future<void> programarTarea(
    String tareaId,
    String titulo,
    DateTime fechaVencimiento, {
    String descripcion = '',
  }) async {
    if (!_esCompatible) return;

    final scheduledDate = tz.TZDateTime.from(
      fechaVencimiento,
      tz.local,
    ).add(const Duration(hours: 6));

    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) return;

    const androidDetails = AndroidNotificationDetails(
      'tareas',
      'Tareas programadas',
      channelDescription: 'Notificaciones de tareas con fecha de vencimiento',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final body = descripcion.isNotEmpty
        ? descripcion
        : 'Tienes una tarea pendiente por completar';

    await _plugin.zonedSchedule(
      _notificationId('tarea', tareaId),
      'Tarea vence hoy: $titulo',
      body,
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelarTarea(String id) async {
    if (!_esCompatible) return;
    await _plugin.cancel(_notificationId('tarea', id));
  }

  Future<void> cancelarTodos() async {
    if (!_esCompatible) return;
    await _plugin.cancelAll();
  }
}
