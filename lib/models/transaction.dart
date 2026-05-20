import 'customer.dart';
import 'user.dart';

enum TxStatus { pending, approved, rejected, unknown }

TxStatus _parseStatus(String? s) => switch (s) {
      'pending' => TxStatus.pending,
      'approved' => TxStatus.approved,
      'rejected' => TxStatus.rejected,
      _ => TxStatus.unknown,
    };

class TransactionItem {
  final int id;
  final String code;
  final double amount;
  final String? description;
  final TxStatus status;
  final String statusLabel;
  final DateTime? approvedAt;
  final DateTime? rejectedAt;
  final String? rejectionReason;
  final DateTime? createdAt;
  final Customer? customer;
  final User? user;
  final User? approver;
  final User? rejecter;

  const TransactionItem({
    required this.id,
    required this.code,
    required this.amount,
    this.description,
    required this.status,
    required this.statusLabel,
    this.approvedAt,
    this.rejectedAt,
    this.rejectionReason,
    this.createdAt,
    this.customer,
    this.user,
    this.approver,
    this.rejecter,
  });

  factory TransactionItem.fromJson(Map<String, dynamic> json) {
    DateTime? parse(dynamic v) =>
        v is String ? DateTime.tryParse(v)?.toLocal() : null;
    User? userFrom(dynamic v) =>
        v is Map<String, dynamic> ? User.fromJson(v) : null;
    Customer? customerFrom(dynamic v) =>
        v is Map<String, dynamic> ? Customer.fromJson(v) : null;

    return TransactionItem(
      id: json['id'] as int,
      code: json['code'] as String,
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String?,
      status: _parseStatus(json['status'] as String?),
      statusLabel: json['status_label'] as String? ?? '',
      approvedAt: parse(json['approved_at']),
      rejectedAt: parse(json['rejected_at']),
      rejectionReason: json['rejection_reason'] as String?,
      createdAt: parse(json['created_at']),
      customer: customerFrom(json['customer']),
      user: userFrom(json['user']),
      approver: userFrom(json['approver']),
      rejecter: userFrom(json['rejecter']),
    );
  }
}
