class Balance {
  final double assigned;
  final double spent;
  final double pending;
  final double available;

  const Balance({
    required this.assigned,
    required this.spent,
    required this.pending,
    required this.available,
  });

  factory Balance.fromJson(Map<String, dynamic> json) => Balance(
        assigned: (json['assigned'] as num).toDouble(),
        spent: (json['spent'] as num).toDouble(),
        pending: (json['pending'] as num).toDouble(),
        available: (json['available'] as num).toDouble(),
      );
}
