import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/fcm_service.dart';
import 'router.dart';

const Color kBrandRed = Color(0xFFE30613);
const Color kBrandRedDark = Color(0xFFB8000F);
const Color kBrandBlack = Color(0xFF1B1B1B);
const Color kBrandSurface = Color(0xFFF7F7F9);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  final container = ProviderContainer();
  await container.read(fcmServiceProvider).init();
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const RcavansApp(),
    ),
  );
}

class RcavansApp extends ConsumerWidget {
  const RcavansApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: kBrandRed,
      primary: kBrandRed,
      onPrimary: Colors.white,
      secondary: kBrandBlack,
      onSecondary: Colors.white,
      surface: Colors.white,
      onSurface: kBrandBlack,
      brightness: Brightness.light,
    );

    return MaterialApp.router(
      title: 'RC ONE',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: kBrandSurface,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: kBrandBlack,
          elevation: 0,
          centerTitle: false,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: kBrandRed,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kBrandRed, width: 1.6),
          ),
          labelStyle: TextStyle(color: Colors.grey.shade700),
        ),
      ),
      routerConfig: router,
    );
  }
}
