import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_menu.dart';
import '../../core/customer_avatar.dart';
import '../../core/formatters.dart';
import '../../core/paginated_list_view.dart';
import '../../core/refresh_providers.dart';
import '../../models/transaction.dart';
import '../auth/auth_notifier.dart';
import 'transactions_repository.dart';

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

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
    final user = ref.watch(authNotifierProvider).value;
    final balance = user?.balance;
    final refreshKey = ref.watch(transactionsRefreshProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Harcamalarım'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Yenile',
            onPressed: () async {
              await ref.read(authNotifierProvider.notifier).refreshMe();
              ref.read(transactionsRefreshProvider.notifier).bump();
            },
          ),
          const AppMenuButton(),
        ],
      ),
      body: PaginatedListView<TransactionItem>(
        cacheKey: refreshKey,
        fetcher: (page, perPage) => ref
            .read(transactionsRepositoryProvider)
            .list(page: page, perPage: perPage),
        emptyMessage: 'Henüz harcama yok.',
        headerSliver: balance == null
            ? null
            : Card(
                margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                elevation: 3,
                color: Theme.of(context).colorScheme.primary,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kullanılabilir Bakiye',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimary
                              .withValues(alpha: 0.85),
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        formatTl(balance.available),
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onPrimary,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          _StatTile(
                            label: 'Atanan',
                            value: balance.assigned,
                            color: Colors.blueAccent.shade100,
                            onTap: () => context.push('/assignments'),
                          ),
                          const SizedBox(width: 8),
                          _StatTile(
                            label: 'Bekleyen',
                            value: balance.pending,
                            color: Colors.orange.shade200,
                            onTap: () => context.push('/breakdown/pending'),
                          ),
                          const SizedBox(width: 8),
                          _StatTile(
                            label: 'Harcanan',
                            value: balance.spent,
                            color: Colors.greenAccent.shade100,
                            onTap: () => context.push('/breakdown/approved'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
        itemBuilder: (context, t) => ListTile(
          onTap: () => context.push('/receipts/${t.id}'),
          leading: CustomerAvatar(customer: t.customer, size: 44),
          title:
              Text('${formatTl(t.amount)} • ${t.customer?.name ?? '-'}'),
          subtitle: Text([
            t.code,
            if (t.description != null) t.description,
            if (t.createdAt != null) formatDate(t.createdAt!),
          ].whereType<String>().join(' · ')),
          trailing: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Harcama'),
        onPressed: () => context.push('/transactions/new'),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
  });

  final String label;
  final double value;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                          color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimary
                              .withValues(alpha: 0.85),
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(Icons.chevron_right,
                        size: 14,
                        color: Theme.of(context)
                            .colorScheme
                            .onPrimary
                            .withValues(alpha: 0.7)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  formatTl(value),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
