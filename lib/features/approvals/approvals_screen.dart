import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_menu.dart';
import '../../core/customer_avatar.dart';
import '../../core/formatters.dart';
import '../../core/paginated_list_view.dart';
import '../../core/refresh_providers.dart';
import '../../models/transaction.dart';
import 'approvals_repository.dart';

class ApprovalsScreen extends ConsumerStatefulWidget {
  const ApprovalsScreen({super.key});

  @override
  ConsumerState<ApprovalsScreen> createState() => _ApprovalsScreenState();
}

class _ApprovalsScreenState extends ConsumerState<ApprovalsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  static const _statuses = ['pending', 'approved', 'rejected'];
  static const _labels = ['Bekleyen', 'Onaylanan', 'İptal'];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _statuses.length, vsync: this);
    _tab.addListener(() {
      if (!_tab.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = _statuses[_tab.index];
    final refreshKey = ref.watch(approvalsRefreshProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Onaylar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Yenile',
            onPressed: () =>
                ref.read(approvalsRefreshProvider.notifier).bump(),
          ),
          const AppMenuButton(),
        ],
        bottom: TabBar(
          controller: _tab,
          tabs: List.generate(_statuses.length, (i) => Tab(text: _labels[i])),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('QR Tara'),
        onPressed: () => context.push('/scan'),
      ),
      body: PaginatedListView<TransactionItem>(
        cacheKey: '$status::$refreshKey',
        fetcher: (page, perPage) => ref.read(approvalsRepositoryProvider).list(
              status: status,
              page: page,
              perPage: perPage,
            ),
        emptyMessage: 'Kayıt yok.',
        itemBuilder: (context, t) => ListTile(
          leading: CustomerAvatar(customer: t.customer, size: 44),
          title: Text('${formatTl(t.amount)} • ${t.user?.name ?? '-'}'),
          subtitle: Text([
            t.customer?.name ?? '',
            t.code,
            if (t.description != null) t.description,
          ].where((s) => (s ?? '').isNotEmpty).join(' · ')),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/approvals/${t.id}'),
        ),
      ),
    );
  }
}
