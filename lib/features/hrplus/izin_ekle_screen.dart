import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/hrplus_izin.dart';
import 'izin_repository.dart';

class IzinEkleScreen extends ConsumerStatefulWidget {
  const IzinEkleScreen({super.key});

  @override
  ConsumerState<IzinEkleScreen> createState() => _IzinEkleScreenState();
}

class _IzinEkleScreenState extends ConsumerState<IzinEkleScreen> {
  IzinTuru? _tur;
  DateTime? _baslangic;
  DateTime? _bitis;
  TimeOfDay? _basSaat;
  TimeOfDay? _bitSaat;
  final _aciklama = TextEditingController();
  bool _saving = false;
  String? _error;

  bool get _saatlik => _tur?.saatlik ?? false;
  bool get _aciklamaZorunlu =>
      _tur != null && kAciklamaZorunluTipler.contains(_tur!.tip);

  @override
  void dispose() {
    _aciklama.dispose();
    super.dispose();
  }

  String _apiTarih(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  String _apiSaat(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}';

  String _gosterTarih(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.'
      '${d.month.toString().padLeft(2, '0')}.${d.year}';

  Future<void> _pickDate(bool baslangic) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (baslangic ? _baslangic : _bitis) ?? now,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      if (baslangic) {
        _baslangic = picked;
        if (_bitis != null && _bitis!.isBefore(picked)) _bitis = picked;
      } else {
        _bitis = picked;
      }
    });
  }

  Future<void> _pickTime(bool baslangic) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: (baslangic ? _basSaat : _bitSaat) ??
          const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked == null) return;
    setState(() {
      if (baslangic) {
        _basSaat = picked;
      } else {
        _bitSaat = picked;
      }
    });
  }

  Future<void> _submit() async {
    if (_tur == null) {
      setState(() => _error = 'Lütfen izin türü seçin.');
      return;
    }
    if (_baslangic == null) {
      setState(() => _error = 'Lütfen tarih seçin.');
      return;
    }
    if (!_saatlik && _bitis == null) {
      setState(() => _error = 'Lütfen bitiş tarihi seçin.');
      return;
    }
    if (_saatlik && (_basSaat == null || _bitSaat == null)) {
      setState(() => _error = 'Lütfen başlangıç ve bitiş saatini seçin.');
      return;
    }
    if (_aciklamaZorunlu && _aciklama.text.trim().isEmpty) {
      setState(() => _error = 'Bu izin türünde açıklama zorunludur.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await ref.read(izinRepositoryProvider).create(
            tip: _tur!.tip,
            baslangicGunu: _apiTarih(_baslangic!),
            bitisGunu: _apiTarih(_saatlik ? _baslangic! : _bitis!),
            baslangicSaati: _saatlik ? _apiSaat(_basSaat!) : null,
            bitisSaati: _saatlik ? _apiSaat(_bitSaat!) : null,
            aciklama: _aciklama.text.trim(),
          );
      ref.invalidate(izinlerProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İzin talebiniz oluşturuldu.')),
      );
      context.pop();
    } on DioException catch (e) {
      final data = e.response?.data;
      final msg = (data is Map && data['message'] is String)
          ? data['message'] as String
          : 'İzin talebi oluşturulamadı. Bağlantınızı kontrol edin.';
      setState(() {
        _saving = false;
        _error = msg;
      });
    } catch (_) {
      setState(() {
        _saving = false;
        _error = 'Beklenmeyen bir hata oluştu.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final turler = ref.watch(izinTurleriProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Yeni İzin Talebi')),
      body: turler.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text('İzin türleri yüklenemedi.')),
        ),
        data: (list) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_error!,
                    style: TextStyle(color: Colors.red.shade700)),
              ),
              const SizedBox(height: 16),
            ],
            DropdownButtonFormField<IzinTuru>(
              initialValue: _tur,
              decoration: const InputDecoration(labelText: 'İzin Türü'),
              items: list
                  .map((t) =>
                      DropdownMenuItem(value: t, child: Text(t.ad)))
                  .toList(),
              onChanged:
                  _saving ? null : (v) => setState(() => _tur = v),
            ),
            const SizedBox(height: 8),
            if (!_saatlik) ...[
              _dateTile('Başlangıç Tarihi', _baslangic, () => _pickDate(true)),
              _dateTile('Bitiş Tarihi', _bitis, () => _pickDate(false)),
            ] else ...[
              _dateTile('Tarih', _baslangic, () => _pickDate(true)),
              _timeTile('Başlangıç Saati', _basSaat, () => _pickTime(true)),
              _timeTile('Bitiş Saati', _bitSaat, () => _pickTime(false)),
            ],
            const SizedBox(height: 8),
            TextField(
              controller: _aciklama,
              decoration: InputDecoration(
                labelText: _aciklamaZorunlu
                    ? 'Açıklama (zorunlu)'
                    : 'Açıklama (opsiyonel)',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _saving ? null : _submit,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              label: Text(_saving ? 'Gönderiliyor…' : 'Talebi Gönder'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateTile(String label, DateTime? value, VoidCallback onTap) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.calendar_today_outlined),
        title: Text(label),
        subtitle:
            Text(value != null ? _gosterTarih(value) : 'Seçilmedi'),
        trailing: const Icon(Icons.chevron_right),
        onTap: _saving ? null : onTap,
      ),
    );
  }

  Widget _timeTile(String label, TimeOfDay? value, VoidCallback onTap) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.access_time),
        title: Text(label),
        subtitle:
            Text(value != null ? value.format(context) : 'Seçilmedi'),
        trailing: const Icon(Icons.chevron_right),
        onTap: _saving ? null : onTap,
      ),
    );
  }
}
