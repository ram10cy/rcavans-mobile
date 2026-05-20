import 'customer.dart';

class CustomerBreakdown {
  final Customer customer;
  final int count;
  final double total;

  const CustomerBreakdown({
    required this.customer,
    required this.count,
    required this.total,
  });

  factory CustomerBreakdown.fromJson(Map<String, dynamic> json) {
    return CustomerBreakdown(
      customer: Customer.fromJson(json['customer'] as Map<String, dynamic>),
      count: json['count'] as int,
      total: (json['total'] as num).toDouble(),
    );
  }
}
