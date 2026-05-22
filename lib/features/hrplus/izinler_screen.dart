import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/hrplus_izin.dart';
import 'izin_repository.dart';

class IzinlerScreen extends ConsumerWidget {
  const IzinlerScreen({super.key});

  static String tarih(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.'
      '${d.month.toString().padLeft(2, '0')}.${d.year}';

  Color _durumColor(int durum) => switch (durum) {
        1 => Colors.orange,
        2 => Colors.green,
        4 => Colors.blue,
        0 || 3 => Colors.red,
        _ => Colors.grey,
      };

  String _altBilgi(IzinItem i) {
    final b = i.baslangicGunu, s = i.bitisGunu;
    if (i.saatlik && b != null) {
      final bs = (i.baslangicSaati ?? '').padRight(5).substring(0, 5);
      final es = (i.bitisSaati ?? '').padRight(5).substring(0, 5);
      return '${tarih(b)} · $bs-$es · ${i.sureMetni}';
    }
    final aralik = (b != null && s != null && b == s)
        ? tarih(b)
        : '${b != null ? tarih(b) : '?'} – ${s != null ? tarih(s) : '?'}';
    return '$aralik · ${i.sureMetni}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(izinlerProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('İzinlerim'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Yenile',
            onPressed: () => ref.invalidate(izinlerProvider),
          ),
        ],
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(error: e),
        data: (d) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(izinlerProvider),
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Card(
                color: cs.primary,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kalan Yıllık İzin Hakkı',
                        style: TextStyle(
                          color: cs.onPrimary.withValues(alpha: 0.85),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${d.kalanHak.toStringAsFixed(d.kalanHak == d.kalanHak.roundToDouble() ? 0 : 1)} gün',
                        style: TextStyle(
                          color: cs.onPrimary,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (d.izinler.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: Text('Henüz izin kaydınız yok.')),
                )
              else
                ...d.izinler.map((izin) => Card(
                      child: ListTile(
                        title: Text(izin.tipLabel),
                        subtitle: Text(_altBilgi(izin)),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _durumColor(izin.durum)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            izin.durumLabel,
                            style: TextStyle(
                                color: _durumColor(izin.durum), fontSize: 12),
                          ),
                        ),
                      ),
                    )),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error});
  final Object error;

  @override
  Widget build(BuildContext context) {
    final e = error;
    final msg = (e is DioException && e.response?.data is Map)
        ? ((e.response!.data as Map)['message']?.toString() ??
            'İzinler yüklenemedi.')
        : 'İzinler yüklenemedi.';
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(child: Text(msg, textAlign: TextAlign.center)),
    );
  }
}
