import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/auth_notifier.dart';
import 'app_control.dart';

/// AppBar'daki üç nokta menüsü — kişisel sayfalara kısayollar
/// ve uygulamadan çıkış.
class AppMenuButton extends ConsumerWidget {
  const AppMenuButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).value;
    final company = user?.isCompany ?? false;

    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      tooltip: 'Menü',
      onSelected: (value) => _handle(context, value),
      itemBuilder: (context) => [
        _item('profile', Icons.person_outline, 'Kişisel Bilgiler'),
        if (company) ...[
          _item('id-card', Icons.badge_outlined, 'Kimliğimi Göster'),
          _item('cagrilar', Icons.headset_mic_outlined, 'Destek Çağrılarım'),
          _item('izinler', Icons.event_available_outlined, 'İzinlerim'),
          _item('izin-onaylar', Icons.fact_check_outlined, 'İzin Onayları'),
        ],
        const PopupMenuDivider(),
        _item('exit', Icons.exit_to_app, 'Uygulamadan Çık'),
      ],
    );
  }

  PopupMenuItem<String> _item(String value, IconData icon, String label) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Text(label),
        ],
      ),
    );
  }

  void _handle(BuildContext context, String value) {
    switch (value) {
      case 'profile':
        context.push('/profile');
        break;
      case 'id-card':
        context.push('/id-card');
        break;
      case 'cagrilar':
        context.push('/cagrilar');
        break;
      case 'izinler':
        context.push('/izinler');
        break;
      case 'izin-onaylar':
        context.push('/izin-onaylar');
        break;
      case 'exit':
        moveAppToBackground();
        break;
    }
  }
}
