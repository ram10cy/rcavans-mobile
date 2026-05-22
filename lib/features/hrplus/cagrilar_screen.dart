import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters.dart';
import '../../models/hrplus_cagri.dart';
import 'cagri_repository.dart';

class CagrilarScreen extends ConsumerWidget {
  const CagrilarScreen({super.key});

  Color _durumColor(int durum) => switch (durum) {
        0 => Colors.orange,
        1 => Colors.blue,
        2 => Colors.green,
        5 => Colors.red,
        _ => Colors.grey,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cagrilar = ref.watch(cagrilarProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Destek Çağrılarım'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Yenile',
            onPressed: () => ref.invalidate(cagrilarProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Yeni Çağrı'),
        onPressed: () => context.push('/cagrilar/yeni'),
      ),
      body: cagrilar.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(error: e),
        data: (list) => list.isEmpty
            ? const Center(child: Text('Henüz çağrı kaydınız yok.'))
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(cagrilarProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final c = list[i];
                    return Card(
                      child: ListTile(
                        onTap: () => _showDetail(context, c),
                        title: Text(c.baslik,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text([
                          c.aciliyet,
                          if (c.acilmaTarihi != null)
                            formatDate(c.acilmaTarihi!),
                        ].join(' · ')),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _durumColor(c.durum).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(c.durumLabel,
                              style: TextStyle(
                                  color: _durumColor(c.durum), fontSize: 12)),
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }

  void _showDetail(BuildContext context, CagriItem c) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(c.baslik),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(c.icerik),
              const SizedBox(height: 12),
              Text('Durum: ${c.durumLabel}',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              Text('Aciliyet: ${c.aciliyet}'),
              if (c.kapatmaAciklama != null &&
                  c.kapatmaAciklama!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Kapatma notu: ${c.kapatmaAciklama}'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Kapat'),
          ),
        ],
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
            'Çağrılar yüklenemedi.')
        : 'Çağrılar yüklenemedi.';
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(child: Text(msg, textAlign: TextAlign.center)),
    );
  }
}
