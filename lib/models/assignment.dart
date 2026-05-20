class Assignment {
  final int id;
  final double amount;
  final String? note;
  final DateTime? assignedAt;
  final String? packageName;
  final String? assignedByName;

  const Assignment({
    required this.id,
    required this.amount,
    this.note,
    this.assignedAt,
    this.packageName,
    this.assignedByName,
  });

  factory Assignment.fromJson(Map<String, dynamic> json) {
    DateTime? parse(dynamic v) =>
        v is String ? DateTime.tryParse(v)?.toLocal() : null;
    final pkg = json['package'];
    final by = json['assigned_by'];
    return Assignment(
      id: json['id'] as int,
      amount: (json['amount'] as num).toDouble(),
      note: json['note'] as String?,
      assignedAt: parse(json['assigned_at']),
      packageName: pkg is Map<String, dynamic> ? pkg['name'] as String? : null,
      assignedByName: by is Map<String, dynamic> ? by['name'] as String? : null,
    );
  }
}
