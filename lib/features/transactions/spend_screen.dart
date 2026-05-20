import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters.dart';
import '../../core/refresh_providers.dart';
import '../../models/customer.dart';
import '../auth/auth_notifier.dart';
import 'transactions_repository.dart';

class SpendScreen extends ConsumerStatefulWidget {
  const SpendScreen({super.key});

  @override
  ConsumerState<SpendScreen> createState() => _SpendScreenState();
}

class _SpendScreenState extends ConsumerState<SpendScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _description = TextEditingController();
  Customer? _customer;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_customer == null) {
      setState(() => _error = 'Cari seçiniz');
      return;
    }
    final amt = double.parse(_amount.text.replaceAll(',', '.'));
    final description = _description.text.trim();

    final confirmed = await _confirm(amt, description);
    if (confirmed != true) return;

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final tx = await ref.read(transactionsRepositoryProvider).create(
            customerId: _customer!.id,
            amount: amt,
            description: description,
          );
      ref.read(transactionsRefreshProvider.notifier).bump();
      await ref.read(authNotifierProvider.notifier).refreshMe();
      if (!mounted) return;
      context.pushReplacement('/receipts/${tx.id}');
    } on DioException catch (e) {
      if (!mounted) return;
      final data = e.response?.data;
      final available = data is Map ? (data['available'] as num?)?.toDouble() : null;
      if (e.response?.statusCode == 422 && available != null) {
        await _showInsufficientBalanceDialog(
          attempted: amt,
          available: available,
        );
        // refresh local balance so the form reflects server-side state
        await ref.read(authNotifierProvider.notifier).refreshMe();
      } else {
        setState(() => _error = _extractDioMessage(e));
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _extractDioMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] is String) return data['message'] as String;
    return 'Bağlantı hatası: ${e.message ?? e.type.name}';
  }

  Future<void> _showInsufficientBalanceDialog({
    required double attempted,
    required double available,
  }) {
    final deficit = attempted - available;
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return AlertDialog(
          icon: Icon(Icons.error_outline,
              color: theme.colorScheme.error, size: 48),
          title: const Text('Bakiye Yetersiz',
              textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Harcamak istediğiniz tutar kullanılabilir bakiyenizi aşıyor.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.5),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    _summaryRow('İstenen Tutar', attempted,
                        color: theme.colorScheme.onSurface),
                    const SizedBox(height: 8),
                    _summaryRow('Kullanılabilir', available,
                        color: theme.colorScheme.onSurface),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(height: 1),
                    ),
                    _summaryRow('Eksik Tutar', deficit,
                        color: theme.colorScheme.error, bold: true),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Lütfen daha düşük bir tutar girin veya yöneticinizden ek kredi atanmasını talep edin.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Tamam'),
            ),
          ],
        );
      },
    );
  }

  Widget _summaryRow(String label, double value,
      {required Color color, bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
              fontSize: bold ? 14 : 13,
              fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
              color: bold ? color : Colors.grey.shade700,
            )),
        Text(formatTl(value),
            style: TextStyle(
              fontSize: bold ? 17 : 14,
              fontWeight: bold ? FontWeight.bold : FontWeight.w500,
              color: color,
            )),
      ],
    );
  }

  Future<bool?> _confirm(double amount, String description) {
    final user = ref.read(authNotifierProvider).value;
    final available = user?.balance?.available;
    return showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Harcamayı Onayla'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _row('Cari', _customer!.name),
              _row('Tutar', formatTl(amount), bold: true),
              if (description.isNotEmpty) _row('Açıklama', description),
              if (available != null) ...[
                const Divider(height: 20),
                _row('Kullanılabilir', formatTl(available)),
                _row('İşlem Sonrası', formatTl(available - amount)),
              ],
              const SizedBox(height: 12),
              const Text(
                'Bu tutar onaya gönderilecek ve bakiyenizde blokede tutulacak.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Onayla ve Gönder'),
            ),
          ],
        );
      },
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                    fontSize: bold ? 16 : 14)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customers = ref.watch(customersListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Yeni Harcama')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              customers.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Cari listesi alınamadı: $e'),
                data: (list) => DropdownButtonFormField<Customer>(
                  initialValue: _customer,
                  decoration: const InputDecoration(
                    labelText: 'Cari',
                    border: OutlineInputBorder(),
                  ),
                  items: list
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c.name),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _customer = v),
                  validator: (v) => v == null ? 'Zorunlu' : null,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amount,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Tutar (₺)',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Zorunlu';
                  final n = double.tryParse(v.replaceAll(',', '.'));
                  if (n == null || n <= 0) return 'Geçerli bir tutar girin';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _description,
                maxLength: 255,
                decoration: const InputDecoration(
                  labelText: 'Açıklama (opsiyonel)',
                  border: OutlineInputBorder(),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Harcama Yap'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
