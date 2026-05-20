import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters.dart';
import '../../core/paginated_list_view.dart';
import '../../core/refresh_providers.dart';
import '../../models/transaction.dart';
import 'transactions_repository.dart';

class CustomerTransactionsScreen extends ConsumerWidget {
  const CustomerTransactionsScreen({
    super.key,
    required this.status,
    required this.customerId,
  });

  final String status;
  final int customerId;

  String get _title => status == 'pending' ? 'Bekleyen' : 'Harcanan';

  Color _statusColor(BuildContext context, TxStatus s) {
    final cs = Theme.of(context).colorScheme;
    return switch (s) {
      TxStatus.pending => Colors.orange,
      TxStatus.approved => Colors.green,
      TxStatus.rejected => cs.error,
      TxStatus.unknown => cs.outline,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final refreshKey = ref.watch(transactionsRefreshProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('$_title İşlemler'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Yenile',
            onPressed: () =>
                ref.read(transactionsRefreshProvider.notifier).bump(),
          ),
        ],
      ),
      body: PaginatedListView<TransactionItem>(
        cacheKey: '$status::$customerId::$refreshKey',
        fetcher: (page, perPage) =>
            ref.read(transactionsRepositoryProvider).list(
                  page: page,
                  perPage: perPage,
                  status: status,
                  customerId: customerId,
                ),
        emptyMessage: 'Kayıt yok.',
        itemBuilder: (context, t) => ListTile(
          onTap: () => context.push('/receipts/${t.id}'),
          title: Text(formatTl(t.amount),
              style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text([
            t.customer?.name ?? '',
            t.code,
            if (t.description != null) t.description,
            if (t.createdAt != null) formatDate(t.createdAt!),
          ].where((s) => (s ?? '').isNotEmpty).join(' · ')),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color:
                  _statusColor(context, t.status).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              t.statusLabel,
              style: TextStyle(
                  color: _statusColor(context, t.status), fontSize: 12),
            ),
          ),
        ),
      ),
    );
  }
}
