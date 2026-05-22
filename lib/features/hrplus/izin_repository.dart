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

  Future<List<IzinTuru>> turler() async {
    final res = await _dio.get('/hrplus/izin-turleri');
    return (res.data['data'] as List)
        .map((e) => IzinTuru.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> create({
    required int tip,
    required String baslangicGunu,
    required String bitisGunu,
    String? baslangicSaati,
    String? bitisSaati,
    String? aciklama,
  }) async {
    await _dio.post('/hrplus/izinler', data: {
      'tip': tip,
      'baslangic_gunu': baslangicGunu,
      'bitis_gunu': bitisGunu,
      if (baslangicSaati != null) 'baslangic_saati': baslangicSaati,
      if (bitisSaati != null) 'bitis_saati': bitisSaati,
      if (aciklama != null && aciklama.isNotEmpty) 'aciklama': aciklama,
    });
  }
}

final izinRepositoryProvider = Provider<IzinRepository>((ref) {
  return IzinRepository(ref.watch(dioProvider));
});

final izinlerProvider = FutureProvider.autoDispose<IzinlerData>((ref) {
  return ref.watch(izinRepositoryProvider).list();
});

final izinTurleriProvider = FutureProvider.autoDispose<List<IzinTuru>>((ref) {
  return ref.watch(izinRepositoryProvider).turler();
});
