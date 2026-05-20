import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/paginated.dart';
import '../../models/customer.dart';
import '../../models/customer_breakdown.dart';
import '../../models/transaction.dart';

class TransactionsRepository {
  TransactionsRepository(this._dio);

  final Dio _dio;

  Future<PaginatedResult<TransactionItem>> list({
    int page = 1,
    int perPage = kDefaultPerPage,
    String? status,
    int? customerId,
  }) async {
    final res = await _dio.get('/transactions', queryParameters: {
      'page': page,
      'per_page': perPage,
      if (status != null) 'status': status,
      if (customerId != null) 'customer_id': customerId,
    });
    return PaginatedResult.fromJson(
      res.data as Map<String, dynamic>,
      (j) => TransactionItem.fromJson(j),
    );
  }

  Future<List<CustomerBreakdown>> byCustomer(String status) async {
    final res = await _dio.get('/transactions/by-customer',
        queryParameters: {'status': status});
    final data = res.data['data'] as List;
    return data
        .map((e) => CustomerBreakdown.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Customer>> customers() async {
    final res = await _dio.get('/customers');
    final data = res.data['data'] as List;
    return data
        .map((e) => Customer.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<TransactionItem> show(int id) async {
    final res = await _dio.get('/transactions/$id');
    return TransactionItem.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<TransactionItem> create({
    required int customerId,
    required double amount,
    String? description,
  }) async {
    final res = await _dio.post('/transactions', data: {
      'customer_id': customerId,
      'amount': amount,
      if (description != null && description.isNotEmpty)
        'description': description,
    });
    return TransactionItem.fromJson(res.data['data'] as Map<String, dynamic>);
  }
}

final transactionsRepositoryProvider = Provider<TransactionsRepository>((ref) {
  return TransactionsRepository(ref.watch(dioProvider));
});

final customersListProvider =
    FutureProvider.autoDispose<List<Customer>>((ref) {
  return ref.watch(transactionsRepositoryProvider).customers();
});

final transactionDetailProvider =
    FutureProvider.autoDispose.family<TransactionItem, int>((ref, id) {
  return ref.watch(transactionsRepositoryProvider).show(id);
});

final breakdownProvider = FutureProvider.autoDispose
    .family<List<CustomerBreakdown>, String>((ref, status) {
  return ref.watch(transactionsRepositoryProvider).byCustomer(status);
});
