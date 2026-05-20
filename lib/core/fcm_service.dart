import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';

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

    FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      _postToken(token);
    });

    FirebaseMessaging.onMessage.listen((message) {
      if (kDebugMode) {
        debugPrint('FCM foreground: ${message.notification?.title} / ${message.data}');
      }
    });
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
