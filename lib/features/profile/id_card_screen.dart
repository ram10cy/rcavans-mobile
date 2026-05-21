import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../models/user.dart';
import '../auth/auth_notifier.dart';

const _red = Color(0xFFE30613);
const _redDark = Color(0xFFB8000F);
const _ink = Color(0xFF1B1B1B);

/// Personel kimlik kartı — web'deki kartın mobil karşılığı.
class IdCardScreen extends ConsumerWidget {
  const IdCardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Kimlik Kartım')),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _IdCard(user: user),
              ),
            ),
    );
  }
}

class _IdCard extends StatelessWidget {
  const _IdCard({required this.user});
  final User user;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 360,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- Başlık ---
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_red, _redDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Image.asset('img/rc-logo.png'),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'RAMADAN CEMİL',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const Text(
                  'PERSONEL\nKİMLİK KARTI',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          // --- Gövde: foto + bilgiler ---
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _photo(),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: _ink,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        (user.jobTitle?.isNotEmpty ?? false)
                            ? user.jobTitle!
                            : 'Personel',
                        style: const TextStyle(
                          color: _red,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      if (user.department?.isNotEmpty ?? false)
                        Text(
                          user.department!,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      const SizedBox(height: 12),
                      Text(
                        'KART NO',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        (user.cardNumber?.isNotEmpty ?? false)
                            ? user.cardNumber!
                            : '—',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _ink,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // --- QR ---
          if (user.cardVerifyUrl?.isNotEmpty ?? false)
            Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: QrImageView(
                      data: user.cardVerifyUrl!,
                      size: 112,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'DOĞRULA',
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey.shade500,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          // --- Alt şerit ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: const BoxDecoration(
              color: _ink,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'ramadancemil.com',
                  style: TextStyle(color: Colors.white, fontSize: 10),
                ),
                Text(
                  "Bu kart RC Corp.'a aittir.",
                  style: TextStyle(color: Colors.white, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _photo() {
    final url = user.avatarUrl;
    final hasPhoto = url != null && url.isNotEmpty;
    return Container(
      width: 86,
      height: 104,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _red, width: 3),
        color: Colors.grey.shade100,
        image: hasPhoto
            ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover)
            : null,
      ),
      child: hasPhoto
          ? null
          : Icon(Icons.person, size: 44, color: Colors.grey.shade400),
    );
  }
}
