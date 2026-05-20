import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/fcm_service.dart';
import '../../core/secure_storage.dart';
import '../../models/user.dart';

class AuthNotifier extends AsyncNotifier<User?> {
  @override
  Future<User?> build() async {
    final token = await ref.read(tokenStoreProvider).read();
    if (token == null || token.isEmpty) return null;
    try {
      final res = await ref.read(dioProvider).get('/me');
      final data = res.data['data'] as Map<String, dynamic>;
      final user = User.fromJson(data);
      unawaited(ref.read(fcmServiceProvider).syncToken());
      return user;
    } on DioException {
      await ref.read(tokenStoreProvider).clear();
      return null;
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final res = await ref.read(dioProvider).post('/login', data: {
        'email': email,
        'password': password,
        'device_name': 'flutter-mobile',
      });
      final token = res.data['token'] as String;
      await ref.read(tokenStoreProvider).write(token);
      final user = User.fromJson(res.data['user'] as Map<String, dynamic>);
      state = AsyncValue.data(user);
      unawaited(ref.read(fcmServiceProvider).syncToken());
    } on DioException catch (e, st) {
      final msg = _extractError(e);
      state = AsyncValue.error(msg, st);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> logout() async {
    try {
      await ref.read(dioProvider).post('/logout');
    } on DioException {
      // ignore — local logout still proceeds
    }
    await ref.read(fcmServiceProvider).clearToken();
    await ref.read(tokenStoreProvider).clear();
    state = const AsyncValue.data(null);
  }

  Future<void> refreshMe() async {
    try {
      final res = await ref.read(dioProvider).get('/me');
      final data = res.data['data'] as Map<String, dynamic>;
      state = AsyncValue.data(User.fromJson(data));
    } on DioException {
      // ignore
    }
  }

  String _extractError(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    if (data is Map && data['errors'] is Map) {
      final errors = data['errors'] as Map;
      final first = errors.values.first;
      if (first is List && first.isNotEmpty) return first.first.toString();
    }
    return 'Bağlantı hatası: ${e.message ?? e.type.name}';
  }
}

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, User?>(AuthNotifier.new);
