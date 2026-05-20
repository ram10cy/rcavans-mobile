import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const _channel = MethodChannel('com.ramadancemil.rcavans/app');

/// Uygulamayi arka plana atar (Android'de home tusuna basmak gibi).
///
/// Aktivite bitirilmez: oturum, FCM token ve uygulama state'i korunur,
/// push bildirimleri gelmeye devam eder. iOS'ta arka plana programatik
/// gecis desteklenmez; orada sessizce no-op olur.
Future<void> moveAppToBackground() async {
  if (defaultTargetPlatform != TargetPlatform.android) return;
  try {
    await _channel.invokeMethod('moveToBackground');
  } catch (_) {
    // Platform channel yoksa/desteklemiyorsa sessizce gec.
  }
}