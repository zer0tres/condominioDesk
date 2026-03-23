import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final _messaging = FirebaseMessaging.instance;
  static final _localNotifications = FlutterLocalNotificationsPlugin();

  static Future<void> salvarSalaId(String salaId) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('sala_id', salaId);
}

  static Future<void> init() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings),
    );

    const channel = AndroidNotificationChannel(
      'encomendas_channel',
      'Encomendas',
      description: 'Notificacoes de novas encomendas',
      importance: Importance.high,
    );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(channel);

    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification != null) {
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'encomendas_channel',
              'Encomendas',
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
        );
      }
    });
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      final prefs = await SharedPreferences.getInstance();
      final salaId = prefs.getString('sala_id');
      if (salaId != null) {
        await Supabase.instance.client
            .from('salas')
            .update({'fcm_token': newToken})
            .eq('id', salaId);
      }
    });
  }
  
  static Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  static Future<void> salvarTokenSala(String salaId) async {
    final token = await getToken();
    if (token == null) return;
    await Supabase.instance.client
        .from('salas')
        .update({'fcm_token': token})
        .eq('id', salaId);
  }
}
