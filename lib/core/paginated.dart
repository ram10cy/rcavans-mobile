class PaginatedResult<T> {
  final List<T> items;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  const PaginatedResult({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  bool get hasPrev => currentPage > 1;
  bool get hasNext => currentPage < lastPage;

  /// Parse from a Laravel-style paginated response that has `data`, plus
  /// pagination info either in a top-level `meta` (custom) or inline
  /// (`current_page`, `last_page`, `per_page`, `total`).
  factory PaginatedResult.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) parse,
  ) {
    final raw = (json['data'] as List).cast<Map<String, dynamic>>();
    final items = raw.map(parse).toList();

    final meta = (json['meta'] as Map?)?.cast<String, dynamic>();
    int read(String key, int fallback) {
      final v = meta?[key] ?? json[key];
      if (v is int) return v;
      if (v is num) return v.toInt();
      return fallback;
    }

    return PaginatedResult(
      items: items,
      currentPage: read('current_page', 1),
      lastPage: read('last_page', 1),
      perPage: read('per_page', items.length),
      total: read('total', items.length),
    );
  }
}

const kPerPageOptions = [10, 25, 50, 100];
const kDefaultPerPage = 10;
