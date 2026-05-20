import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/refresh_providers.dart';
import '../../models/transaction.dart';
import '../transactions/receipt_screen.dart';
import 'approvals_repository.dart';

final _detailProvider =
    FutureProvider.autoDispose.family<TransactionItem, int>((ref, id) {
  return ref.watch(approvalsRepositoryProvider).show(id);
});

class ApprovalDetailScreen extends ConsumerStatefulWidget {
  const ApprovalDetailScreen({super.key, required this.id});
  final int id;

  @override
  ConsumerState<ApprovalDetailScreen> createState() =>
      _ApprovalDetailScreenState();
}

class _ApprovalDetailScreenState extends ConsumerState<ApprovalDetailScreen> {
  bool _busy = false;

  Future<void> _approve() async {
    setState(() => _busy = true);
    try {
      await ref.read(approvalsRepositoryProvider).approve(widget.id);
      _invalidateLists();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İşlem onaylandı.')),
      );
      context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reject() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final c = TextEditingController();
        return AlertDialog(
          title: const Text('İptal Sebebi'),
          content: TextField(
            controller: c,
            maxLength: 500,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Opsiyonel açıklama',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Vazgeç')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, c.text),
                child: const Text('İptal Et')),
          ],
        );
      },
    );
    if (reason == null) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(approvalsRepositoryProvider)
          .reject(widget.id, reason: reason);
      _invalidateLists();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İşlem iptal edildi.')),
      );
      context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _invalidateLists() {
    ref.read(approvalsRefreshProvider.notifier).bump();
  }

  @override
  Widget build(BuildContext context) {
    final tx = ref.watch(_detailProvider(widget.id));

    return Scaffold(
      appBar: AppBar(title: const Text('Fiş')),
      body: tx.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Padding(padding: const EdgeInsets.all(24), child: Text('Hata: $e')),
        data: (t) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: ReceiptCard(
                t: t,
                isApproverView: true,
                footer: t.status == TxStatus.pending
                    ? Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _busy ? null : _reject,
                              style: OutlinedButton.styleFrom(
                                  foregroundColor:
                                      Theme.of(context).colorScheme.error),
                              child: const Text('İptal Et'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: _busy ? null : _approve,
                              child: _busy
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2))
                                  : const Text('Onayla'),
                            ),
                          ),
                        ],
                      )
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
