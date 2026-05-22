import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/hrplus_izin.dart';
import 'izin_repository.dart';
import 'izinler_screen.dart';

/// Amirin onayını bekleyen izin talepleri.
class IzinOnaylarScreen extends ConsumerWidget {
  const IzinOnaylarScreen({super.key});

  String _bilgi(IzinItem i) {
    final b = i.baslangicGunu, s = i.bitisGunu;
    if (i.saatlik && b != null) {
      final bs = (i.baslangicSaati ?? '').padRight(5).substring(0, 5);
      final es = (i.bitisSaati ?? '').padRight(5).substring(0, 5);
      return '${i.tipLabel} · ${IzinlerScreen.tarih(b)} $bs-$es · ${i.sureMetni}';
    }
    final aralik = (b != null && s != null && b == s)
        ? IzinlerScreen.tarih(b)
        : '${b != null ? IzinlerScreen.tarih(b) : '?'} – '
            '${s != null ? IzinlerScreen.tarih(s) : '?'}';
    return '${i.tipLabel} · $aralik · ${i.sureMetni}';
  }

  Future<void> _karar(
    BuildContext context,
    WidgetRef ref,
    IzinItem izin,
    bool onayla,
  ) async {
    final onaylandi = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(onayla ? 'İzni Onayla' : 'İzni Reddet'),
        content: Text(
          '${izin.personelAdi ?? 'Personel'} — ${izin.tipLabel}\n'
          '${onayla ? 'Onaylamak' : 'Reddetmek'} istediğinize emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(onayla ? 'Onayla' : 'Reddet'),
          ),
        ],
      ),
    );
    if (onaylandi != true) return;

    try {
      await ref.read(izinRepositoryProvider).karar(
            izinId: izin.id,
            karar: onayla ? 'onayla' : 'reddet',
          );
      ref.invalidate(izinOnaylarProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(onayla ? 'İzin onaylandı.' : 'İzin reddedildi.')),
        );
      }
    } on DioException catch (e) {
      final data = e.response?.data;
      final msg = (data is Map && data['message'] is String)
          ? data['message'] as String
          : 'İşlem başarısız oldu.';
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onaylar = ref.watch(izinOnaylarProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('İzin Onayları'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Yenile',
            onPressed: () => ref.invalidate(izinOnaylarProvider),
          ),
        ],
      ),
      body: onaylar.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              (e is DioException && e.response?.data is Map)
                  ? ((e.response!.data as Map)['message']?.toString() ??
                      'Onaylar yüklenemedi.')
                  : 'Onaylar yüklenemedi.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (list) => list.isEmpty
            ? const Center(child: Text('Onayınızı bekleyen izin yok.'))
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(izinOnaylarProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final izin = list[i];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              izin.personelAdi ?? 'Personel',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 15),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _bilgi(izin),
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 13),
                            ),
                            if (izin.aciklama != null &&
                                izin.aciklama!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(izin.aciklama!,
                                  style: const TextStyle(fontSize: 13)),
                            ],
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () =>
                                        _karar(context, ref, izin, false),
                                    icon: const Icon(Icons.close, size: 18),
                                    label: const Text('Reddet'),
                                    style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: FilledButton.icon(
                                    onPressed: () =>
                                        _karar(context, ref, izin, true),
                                    icon: const Icon(Icons.check, size: 18),
                                    label: const Text('Onayla'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}
