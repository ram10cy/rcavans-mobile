import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Counter-style notifiers used to invalidate paginated list caches after
/// mutations. Pass the value as `cacheKey` to a PaginatedListView; bumping the
/// counter triggers a reset + reload.

class _RefreshCounter extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

final transactionsRefreshProvider =
    NotifierProvider<_RefreshCounter, int>(_RefreshCounter.new);
final approvalsRefreshProvider =
    NotifierProvider<_RefreshCounter, int>(_RefreshCounter.new);
final assignmentsRefreshProvider =
    NotifierProvider<_RefreshCounter, int>(_RefreshCounter.new);
