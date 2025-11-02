import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io';

class FirebaseMessagingService {
  static final _localNotifications = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Configurações do plugin de notificações locais
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings();

    final settings = InitializationSettings(
      android: android,
      iOS: darwin,
      macOS: darwin,
    );
    await _localNotifications.initialize(settings);

    // Só executa no iOS e Android
    if (!Platform.isMacOS) {
      // Solicita permissão para notificações (necessário no iOS)
      await messaging.requestPermission();

      // Obtenha o token do dispositivo (use para testes no Firebase Console)
      String? token = await messaging.getToken();
      print('FCM Token: $token');
    }

    // Escute mensagens recebidas em foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Notificação recebida: ${message.notification?.title}');
      showNotification(
        message.notification?.title ?? '',
        message.notification?.body ?? '',
      );
    });
  }

  static void showNotification(String title, String body) {
    _localNotifications.show(
      0,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'channel_id',
          'channel_name',
          channelDescription: 'channel_desc',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
        macOS: DarwinNotificationDetails(),
      ),
    );
  }
}