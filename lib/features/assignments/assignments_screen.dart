import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../core/paginated_list_view.dart';
import '../../core/refresh_providers.dart';
import '../../models/assignment.dart';
import 'assignments_repository.dart';

class AssignmentsScreen extends ConsumerWidget {
  const AssignmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final refreshKey = ref.watch(assignmentsRefreshProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Atanan Krediler'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Yenile',
            onPressed: () =>
                ref.read(assignmentsRefreshProvider.notifier).bump(),
          ),
        ],
      ),
      body: PaginatedListView<Assignment>(
        cacheKey: refreshKey,
        fetcher: (page, perPage) => ref
            .read(assignmentsRepositoryProvider)
            .list(page: page, perPage: perPage),
        emptyMessage: 'Henüz atanmış kredi yok.',
        itemBuilder: (context, a) => ListTile(
          leading: const CircleAvatar(
            child: Icon(Icons.account_balance_wallet),
          ),
          title: Text(formatTl(a.amount),
              style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text([
            if (a.packageName != null) a.packageName,
            if (a.assignedByName != null) 'Atayan: ${a.assignedByName}',
            if (a.note != null && a.note!.isNotEmpty) a.note,
            if (a.assignedAt != null) formatDate(a.assignedAt!),
          ].whereType<String>().join(' · ')),
        ),
      ),
    );
  }
}
