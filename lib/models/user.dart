import 'balance.dart';

enum UserSide { company, customer, unknown }

class User {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final List<String> roles;
  final UserSide side;
  final Balance? balance;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatarUrl,
    required this.roles,
    required this.side,
    this.balance,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final sideStr = json['side'] as String?;
    final side = switch (sideStr) {
      'company' => UserSide.company,
      'customer' => UserSide.customer,
      _ => UserSide.unknown,
    };
    final balanceJson = json['balance'];
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      roles: List<String>.from(json['roles'] as List? ?? const []),
      side: side,
      balance: balanceJson is Map<String, dynamic>
          ? Balance.fromJson(balanceJson)
          : null,
    );
  }

  bool get isCompany => side == UserSide.company;
  bool get isCustomer => side == UserSide.customer;
}
