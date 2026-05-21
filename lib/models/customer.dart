class Customer {
  final int id;
  final String name;
  final String? taxNumber;
  final String? taxOffice;
  final String? phone;
  final String? email;
  final String? imageUrl;

  const Customer({
    required this.id,
    required this.name,
    this.taxNumber,
    this.taxOffice,
    this.phone,
    this.email,
    this.imageUrl,
  });

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
        id: json['id'] as int,
        name: json['name'] as String,
        taxNumber: json['tax_number'] as String?,
        taxOffice: json['tax_office'] as String?,
        phone: json['phone'] as String?,
        email: json['email'] as String?,
        imageUrl: json['image_url'] as String?,
      );
}
