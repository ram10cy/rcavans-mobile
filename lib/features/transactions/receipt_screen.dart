import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/customer_avatar.dart';
import '../../core/formatters.dart';
import '../../models/customer.dart';
import '../../models/transaction.dart';
import 'transactions_repository.dart';

class ReceiptScreen extends ConsumerWidget {
  const ReceiptScreen({super.key, required this.id});
  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tx = ref.watch(transactionDetailProvider(id));
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
              child: ReceiptCard(t: t),
            ),
          ),
        ),
      ),
    );
  }
}

class ReceiptCard extends StatelessWidget {
  const ReceiptCard({
    super.key,
    required this.t,
    this.isApproverView = false,
    this.footer,
  });

  final TransactionItem t;

  /// When true the card is rendered for the approving "cari" user:
  /// the QR section is hidden and the pending status copy is reframed.
  final bool isApproverView;

  /// Optional widget rendered at the bottom of the card (e.g. action buttons).
  final Widget? footer;

  Color _statusColor(BuildContext ctx) {
    final cs = Theme.of(ctx).colorScheme;
    return switch (t.status) {
      TxStatus.pending => Colors.orange.shade700,
      TxStatus.approved => Colors.green.shade700,
      TxStatus.rejected => cs.error,
      TxStatus.unknown => cs.outline,
    };
  }

  IconData _statusIcon() => switch (t.status) {
        TxStatus.pending => Icons.hourglass_top,
        TxStatus.approved => Icons.check_circle,
        TxStatus.rejected => Icons.replay,
        TxStatus.unknown => Icons.help_outline,
      };

  String _statusMessage() => switch (t.status) {
        TxStatus.pending => isApproverView
            ? 'Onayınız bekleniyor — tutar harcayanın bakiyesinde blokede.'
            : 'Cari onayı bekleniyor — tutar blokede.',
        TxStatus.approved =>
          '${t.approver?.name ?? 'Cari'} tarafından onaylandı'
              '${t.approvedAt != null ? ' (${formatDate(t.approvedAt!)})' : ''}.',
        TxStatus.rejected => isApproverView
            ? 'İşlem iptal edildi — tutar harcayanın bakiyesine iade edildi.'
                '${t.rejectionReason != null && t.rejectionReason!.isNotEmpty ? '\nSebep: ${t.rejectionReason}' : ''}'
            : 'Cari tarafından iptal edildi — tutar bakiyenize iade edildi.'
                '${t.rejectionReason != null && t.rejectionReason!.isNotEmpty ? '\nSebep: ${t.rejectionReason}' : ''}',
        TxStatus.unknown => '',
      };

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(context);
    const mono = TextStyle(fontFamily: 'monospace', fontSize: 14);
    final divider = Theme.of(context).dividerColor;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: divider),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text('Fiş: ${t.code}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(t.statusLabel,
                      style: TextStyle(color: statusColor, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Center(
              child: Column(
                children: [
                  Text('RC ONE',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          fontSize: 18)),
                  Text('Kredi Harcama Fişi',
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Divider(thickness: 1.2),
            _line('Tarih',
                t.createdAt != null ? formatDate(t.createdAt!) : '-',
                style: mono),
            _line('Kullanıcı', t.user?.name ?? '-', style: mono),
            _customerLine(t.customer, mono),
            _line('Açıklama',
                (t.description == null || t.description!.isEmpty)
                    ? '—'
                    : t.description!,
                style: mono),
            const Divider(thickness: 1.2),
            _line('TOPLAM', formatTl(t.amount),
                style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(_statusIcon(), color: statusColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_statusMessage(),
                        style: TextStyle(color: statusColor, fontSize: 13)),
                  ),
                ],
              ),
            ),
            if (!isApproverView && t.status == TxStatus.pending) ...[
              const SizedBox(height: 20),
              const Divider(thickness: 1.2),
              const SizedBox(height: 12),
              Center(
                child: Column(
                  children: [
                    Text('Cari Onay QR Kodu',
                        style: Theme.of(context).textTheme.labelMedium),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: QrImageView(
                        data: 'rcavans://tx/${t.id}',
                        version: QrVersions.auto,
                        size: 200,
                        backgroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Cari kullanıcı bu kodu telefonundan okuttuğunda\nharcama otomatik onaylanır.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
            if (footer != null) ...[
              const SizedBox(height: 20),
              const Divider(thickness: 1.2),
              const SizedBox(height: 12),
              footer!,
            ],
          ],
        ),
      ),
    );
  }

  Widget _customerLine(Customer? customer, TextStyle style) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text('Cari:', style: style.copyWith(color: Colors.grey)),
          ),
          CustomerAvatar(customer: customer, size: 30),
          const SizedBox(width: 8),
          Expanded(child: Text(customer?.name ?? '-', style: style)),
        ],
      ),
    );
  }

  Widget _line(String label, String value, {TextStyle? style}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text('$label:',
                style: (style ?? const TextStyle())
                    .copyWith(color: Colors.grey)),
          ),
          Expanded(child: Text(value, style: style)),
        ],
      ),
    );
  }
}
