import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../models/hrplus_cagri.dart';

class CagriRepository {
  CagriRepository(this._dio);

  final Dio _dio;

  Future<List<CagriItem>> list() async {
    final res = await _dio.get('/hrplus/cagrilar');
    final data = res.data['data'] as List;
    return data
        .map((e) => CagriItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> create({
    required String baslik,
    required String icerik,
    required String aciliyet,
  }) async {
    await _dio.post('/hrplus/cagrilar', data: {
      'baslik': baslik,
      'icerik': icerik,
      'aciliyet': aciliyet,
    });
  }
}

final cagriRepositoryProvider = Provider<CagriRepository>((ref) {
  return CagriRepository(ref.watch(dioProvider));
});

final cagrilarProvider = FutureProvider.autoDispose<List<CagriItem>>((ref) {
  return ref.watch(cagriRepositoryProvider).list();
});
