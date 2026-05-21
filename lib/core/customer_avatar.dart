import 'package:flutter/material.dart';

import '../models/customer.dart';

/// Cari görselini yuvarlak avatar olarak gösterir.
/// Görsel yoksa marka renginde bir mağaza ikonu gösterilir.
class CustomerAvatar extends StatelessWidget {
  const CustomerAvatar({super.key, required this.customer, this.size = 40});

  final Customer? customer;
  final double size;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final url = customer?.imageUrl;

    if (url != null && url.isNotEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundColor: Colors.grey.shade100,
        backgroundImage: NetworkImage(url),
      );
    }

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: cs.primary.withValues(alpha: 0.10),
      child: Icon(Icons.storefront, size: size * 0.52, color: cs.primary),
    );
  }
}
