import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../models/user.dart';
import '../auth/auth_notifier.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  String _sideLabel(User user) => switch (user.side) {
        UserSide.company => 'Şirket hesabı',
        UserSide.customer => 'Müşteri hesabı',
        UserSide.unknown => 'Hesap',
      };

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Oturumu Kapat'),
        content: const Text(
          'Oturumunuz kapatılacak. Tekrar giriş yapana kadar '
          'bildirimler gelmeyecektir. Devam etmek istiyor musunuz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Oturumu Kapat'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authNotifierProvider.notifier).logout();
      // Oturum kapaninca router otomatik olarak /login'e yönlendirir.
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).value;
    final cs = Theme.of(context).colorScheme;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final initial =
        user.name.trim().isNotEmpty ? user.name.trim()[0].toUpperCase() : '?';

    return Scaffold(
      appBar: AppBar(title: const Text('Hesabım')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        children: [
          Center(
            child: CircleAvatar(
              radius: 40,
              backgroundColor: cs.primary,
              child: Text(
                initial,
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: Text(
              user.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              _sideLabel(user),
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 1,
            child: Column(
              children: [
                _InfoTile(
                  icon: Icons.email_outlined,
                  label: 'E-posta',
                  value: user.email,
                ),
                if (user.phone != null && user.phone!.isNotEmpty)
                  _InfoTile(
                    icon: Icons.phone_outlined,
                    label: 'Telefon',
                    value: user.phone!,
                  ),
                if (user.roles.isNotEmpty)
                  _InfoTile(
                    icon: Icons.badge_outlined,
                    label: 'Rol',
                    value: user.roles.join(', '),
                  ),
              ],
            ),
          ),
          if (user.balance != null) ...[
            const SizedBox(height: 12),
            Card(
              elevation: 1,
              child: Column(
                children: [
                  _InfoTile(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Kullanılabilir Bakiye',
                    value: formatTl(user.balance!.available),
                  ),
                  _InfoTile(
                    icon: Icons.savings_outlined,
                    label: 'Atanan',
                    value: formatTl(user.balance!.assigned),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 28),
          OutlinedButton.icon(
            onPressed: () => _confirmLogout(context, ref),
            icon: const Icon(Icons.logout),
            label: const Text('Oturumu Kapat'),
            style: OutlinedButton.styleFrom(
              foregroundColor: cs.primary,
              side: BorderSide(color: cs.primary),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Çıkış yapmadığınız sürece oturumunuz açık kalır ve '
            'bildirimleri almaya devam edersiniz.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(label, style: const TextStyle(fontSize: 12)),
      subtitle: Text(
        value,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }
}
