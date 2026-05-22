import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../models/hrplus_izin.dart';

class IzinRepository {
  IzinRepository(this._dio);

  final Dio _dio;

  Future<IzinlerData> list() async {
    final res = await _dio.get('/hrplus/izinler');
    final data = res.data as Map<String, dynamic>;
    return IzinlerData(
      kalanHak: (data['kalan_hak'] as num?)?.toDouble() ?? 0,
      izinler: (data['izinler'] as List)
          .map((e) => IzinItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

final izinRepositoryProvider = Provider<IzinRepository>((ref) {
  return IzinRepository(ref.watch(dioProvider));
});

final izinlerProvider = FutureProvider.autoDispose<IzinlerData>((ref) {
  return ref.watch(izinRepositoryProvider).list();
});
