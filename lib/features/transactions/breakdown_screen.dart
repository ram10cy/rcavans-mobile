import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters.dart';
import 'transactions_repository.dart';

class BreakdownScreen extends ConsumerWidget {
  const BreakdownScreen({super.key, required this.status});

  final String status; // 'pending' | 'approved'

  String get _title => status == 'pending' ? 'Bekleyen' : 'Harcanan';
  Color _accent(BuildContext c) =>
      status == 'pending' ? Colors.orange : Colors.green;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(breakdownProvider(status));

    return Scaffold(
      appBar: AppBar(title: Text('$_title (Cari Bazında)')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(breakdownProvider(status));
          await ref.read(breakdownProvider(status).future);
        },
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(children: [
            Padding(padding: const EdgeInsets.all(24), child: Text('Hata: $e')),
          ]),
          data: (rows) {
            if (rows.isEmpty) {
              return ListView(children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Kayıt yok ($_title).'),
                ),
              ]);
            }
            final total = rows.fold<double>(0, (s, r) => s + r.total);
            return ListView.separated(
              itemCount: rows.length + 1,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                if (i == 0) {
                  return Container(
                    color: _accent(context).withValues(alpha: 0.12),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Toplam $_title',
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(formatTl(total),
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: _accent(context))),
                      ],
                    ),
                  );
                }
                final r = rows[i - 1];
                return ListTile(
                  onTap: () => context
                      .push('/breakdown/$status/customer/${r.customer.id}'),
                  leading: CircleAvatar(
                    backgroundColor: _accent(context).withValues(alpha: 0.15),
                    child: Icon(Icons.store, color: _accent(context)),
                  ),
                  title: Text(r.customer.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${r.count} işlem'),
                  trailing: Text(formatTl(r.total),
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _accent(context))),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
