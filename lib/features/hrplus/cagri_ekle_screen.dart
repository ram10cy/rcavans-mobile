import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/hrplus_cagri.dart';
import 'cagri_repository.dart';

class CagriEkleScreen extends ConsumerStatefulWidget {
  const CagriEkleScreen({super.key});

  @override
  ConsumerState<CagriEkleScreen> createState() => _CagriEkleScreenState();
}

class _CagriEkleScreenState extends ConsumerState<CagriEkleScreen> {
  final _baslik = TextEditingController();
  final _icerik = TextEditingController();
  String _aciliyet = kCagriAciliyetleri[1]; // Orta Seviye
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _baslik.dispose();
    _icerik.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final baslik = _baslik.text.trim();
    final icerik = _icerik.text.trim();

    if (baslik.isEmpty) {
      setState(() => _error = 'Lütfen bir başlık girin.');
      return;
    }
    if (icerik.length < 10) {
      setState(() => _error = 'Açıklama en az 10 karakter olmalı.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await ref.read(cagriRepositoryProvider).create(
            baslik: baslik,
            icerik: icerik,
            aciliyet: _aciliyet,
          );
      ref.invalidate(cagrilarProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Çağrınız oluşturuldu.')),
      );
      context.pop();
    } on DioException catch (e) {
      final data = e.response?.data;
      final msg = (data is Map && data['message'] is String)
          ? data['message'] as String
          : 'Çağrı oluşturulamadı. Bağlantınızı kontrol edin.';
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
    return Scaffold(
      appBar: AppBar(title: const Text('Yeni Destek Çağrısı')),
      body: ListView(
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
          TextField(
            controller: _baslik,
            decoration: const InputDecoration(labelText: 'Başlık'),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _aciliyet,
            decoration: const InputDecoration(labelText: 'Aciliyet'),
            items: kCagriAciliyetleri
                .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                .toList(),
            onChanged: _saving
                ? null
                : (v) => setState(() => _aciliyet = v ?? _aciliyet),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _icerik,
            decoration: const InputDecoration(
              labelText: 'Açıklama',
              hintText: 'Sorununuzu açıklayın (en az 10 karakter)',
              alignLabelWithHint: true,
            ),
            maxLines: 5,
            maxLength: 200,
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _saving ? null : _submit,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            label: Text(_saving ? 'Gönderiliyor…' : 'Çağrı Oluştur'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}
