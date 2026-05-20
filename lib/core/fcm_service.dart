import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';

/// Foreground bildirimleri icin Android bildirim kanali.
const _androidChannel = AndroidNotificationChannel(
  'rcone_default',
  'Genel Bildirimler',
  description: 'Kredi atamalari ve diger uygulama bildirimleri',
  importance: Importance.high,
);

final _localNotifications = FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background mesajlar Android tarafından kendi tray notification'ı ile gösteriliyor;
  // burada ek iş yapmıyoruz. Firebase.initializeApp() entrypoint'te çağrılmalı.
  if (kDebugMode) {
    debugPrint('FCM background: ${message.messageId} ${message.data}');
  }
}

class FcmService {
  FcmService(this._dio);

  final Dio _dio;
  String? _lastSyncedToken;

  Future<void> init() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Uygulama on plandayken FCM Android'de otomatik bildirim gostermez;
    // local notifications ile koprulenir.
    await _initLocalNotifications();

    FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      _postToken(token);
    });

    FirebaseMessaging.onMessage.listen((message) {
      if (kDebugMode) {
        debugPrint(
            'FCM foreground: ${message.notification?.title} / ${message.data}');
      }
      _showForegroundNotification(message);
    });
  }

  Future<void> _initLocalNotifications() async {
    const androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _localNotifications.initialize(settings: initSettings);
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);
  }

  /// Gelen FCM mesajini sistem bildirim cubugunda gosterir.
  void _showForegroundNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: message.data['type'] as String?,
    );
  }

  Future<void> syncToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;
      await _postToken(token);
    } catch (e) {
      if (kDebugMode) debugPrint('FCM token al hatası: $e');
    }
  }

  Future<void> _postToken(String token) async {
    if (_lastSyncedToken == token) return;
    try {
      await _dio.post('/me/fcm-token', data: {
        'token': token,
        'platform': 'android',
      });
      _lastSyncedToken = token;
    } on DioException catch (e) {
      if (kDebugMode) debugPrint('FCM token POST hatası: ${e.message}');
    }
  }

  Future<void> clearToken() async {
    _lastSyncedToken = null;
    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {}
  }
}

final fcmServiceProvider = Provider<FcmService>((ref) {
  return FcmService(ref.watch(dioProvider));
});
