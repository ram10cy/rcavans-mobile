import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/paginated.dart';
import '../../models/transaction.dart';

class ApprovalsCounts {
  final int pending;
  final int approved;
  final int rejected;
  const ApprovalsCounts({
    required this.pending,
    required this.approved,
    required this.rejected,
  });

  static const empty = ApprovalsCounts(pending: 0, approved: 0, rejected: 0);
}

class ApprovalsRepository {
  ApprovalsRepository(this._dio);

  final Dio _dio;

  ApprovalsCounts _lastCounts = ApprovalsCounts.empty;
  ApprovalsCounts get lastCounts => _lastCounts;

  Future<PaginatedResult<TransactionItem>> list({
    String status = 'pending',
    int page = 1,
    int perPage = kDefaultPerPage,
  }) async {
    final res = await _dio.get('/approvals', queryParameters: {
      'status': status,
      'page': page,
      'per_page': perPage,
    });

    final body = res.data as Map<String, dynamic>;
    final counts =
        (body['meta']?['counts'] as Map?)?.cast<String, dynamic>() ?? const {};
    _lastCounts = ApprovalsCounts(
      pending: (counts['pending'] as int?) ?? _lastCounts.pending,
      approved: (counts['approved'] as int?) ?? _lastCounts.approved,
      rejected: (counts['rejected'] as int?) ?? _lastCounts.rejected,
    );

    return PaginatedResult.fromJson(
      body,
      (j) => TransactionItem.fromJson(j),
    );
  }

  Future<TransactionItem> show(int id) async {
    final res = await _dio.get('/approvals/$id');
    return TransactionItem.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<TransactionItem> approve(int id) async {
    final res = await _dio.post('/approvals/$id/approve');
    return TransactionItem.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<TransactionItem> reject(int id, {String? reason}) async {
    final res = await _dio.post('/approvals/$id/reject', data: {
      if (reason != null && reason.isNotEmpty) 'rejection_reason': reason,
    });
    return TransactionItem.fromJson(res.data['data'] as Map<String, dynamic>);
  }
}

final approvalsRepositoryProvider = Provider<ApprovalsRepository>((ref) {
  return ApprovalsRepository(ref.watch(dioProvider));
});
