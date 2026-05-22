import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/approvals/approval_detail_screen.dart';
import 'features/approvals/approvals_screen.dart';
import 'features/approvals/qr_scan_screen.dart';
import 'features/assignments/assignments_screen.dart';
import 'features/auth/auth_notifier.dart';
import 'features/auth/login_screen.dart';
import 'features/hrplus/cagri_ekle_screen.dart';
import 'features/hrplus/cagrilar_screen.dart';
import 'features/hrplus/izinler_screen.dart';
import 'features/profile/id_card_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/transactions/breakdown_screen.dart';
import 'features/transactions/customer_transactions_screen.dart';
import 'features/transactions/receipt_screen.dart';
import 'features/transactions/spend_screen.dart';
import 'features/transactions/transactions_screen.dart';
import 'models/user.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (ctx, state) {
      final auth = ref.read(authNotifierProvider);
      if (auth.isLoading) return null;

      final user = auth.value;
      final loc = state.matchedLocation;

      if (user == null) {
        return loc == '/login' ? null : '/login';
      }

      if (loc == '/login' || loc == '/') {
        return user.isCustomer ? '/approvals' : '/transactions';
      }

      // role guard
      if (user.isCustomer && loc.startsWith('/transactions')) {
        return '/approvals';
      }
      if (user.isCompany && loc.startsWith('/approvals')) {
        return '/transactions';
      }
      return null;
    },
    refreshListenable: _AuthListenable(ref),
    routes: [
      GoRoute(path: '/', builder: (_, __) => const _Splash()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(
          path: '/transactions',
          builder: (_, __) => const TransactionsScreen()),
      GoRoute(
          path: '/transactions/new', builder: (_, __) => const SpendScreen()),
      GoRoute(
          path: '/assignments',
          builder: (_, __) => const AssignmentsScreen()),
      GoRoute(
          path: '/breakdown/:status',
          builder: (_, s) =>
              BreakdownScreen(status: s.pathParameters['status']!)),
      GoRoute(
          path: '/breakdown/:status/customer/:customerId',
          builder: (_, s) => CustomerTransactionsScreen(
                status: s.pathParameters['status']!,
                customerId: int.parse(s.pathParameters['customerId']!),
              )),
      GoRoute(
          path: '/receipts/:id',
          builder: (_, s) =>
              ReceiptScreen(id: int.parse(s.pathParameters['id']!))),
      GoRoute(path: '/approvals', builder: (_, __) => const ApprovalsScreen()),
      GoRoute(
          path: '/approvals/:id',
          builder: (_, s) => ApprovalDetailScreen(
              id: int.parse(s.pathParameters['id']!))),
      GoRoute(path: '/scan', builder: (_, __) => const QrScanScreen()),
      GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
      GoRoute(path: '/id-card', builder: (_, __) => const IdCardScreen()),
      GoRoute(path: '/cagrilar', builder: (_, __) => const CagrilarScreen()),
      GoRoute(
          path: '/cagrilar/yeni',
          builder: (_, __) => const CagriEkleScreen()),
      GoRoute(path: '/izinler', builder: (_, __) => const IzinlerScreen()),
    ],
  );
});

class _Splash extends StatelessWidget {
  const _Splash();
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}

class _AuthListenable extends ChangeNotifier {
  _AuthListenable(this._ref) {
    _ref.listen<AsyncValue<User?>>(authNotifierProvider, (_, __) {
      notifyListeners();
    });
  }
  final Ref _ref;
}
