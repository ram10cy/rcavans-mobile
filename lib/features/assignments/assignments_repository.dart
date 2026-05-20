import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/paginated.dart';
import '../../models/assignment.dart';

class AssignmentsRepository {
  AssignmentsRepository(this._dio);

  final Dio _dio;

  Future<PaginatedResult<Assignment>> list({
    int page = 1,
    int perPage = kDefaultPerPage,
  }) async {
    final res = await _dio.get('/assignments', queryParameters: {
      'page': page,
      'per_page': perPage,
    });
    return PaginatedResult.fromJson(
      res.data as Map<String, dynamic>,
      (j) => Assignment.fromJson(j),
    );
  }
}

final assignmentsRepositoryProvider = Provider<AssignmentsRepository>((ref) {
  return AssignmentsRepository(ref.watch(dioProvider));
});
