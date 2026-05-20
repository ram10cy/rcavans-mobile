import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/refresh_providers.dart';
import 'approvals_repository.dart';

class QrScanScreen extends ConsumerStatefulWidget {
  const QrScanScreen({super.key});

  @override
  ConsumerState<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends ConsumerState<QrScanScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _busy = false;
  String? _status;
  bool _isError = false;
  _TerminalError? _terminal;

  int? _parseId(String? raw) {
    if (raw == null) return null;
    final uri = Uri.tryParse(raw);
    if (uri == null || uri.scheme != 'rcavans' || uri.host != 'tx') return null;
    if (uri.pathSegments.isEmpty) return null;
    return int.tryParse(uri.pathSegments.first);
  }

  Future<void> _onDetect(BarcodeCapture cap) async {
    if (_busy || _terminal != null) return;
    for (final code in cap.barcodes) {
      final id = _parseId(code.rawValue);
      if (id == null) continue;
      setState(() {
        _busy = true;
        _status = 'Onaylanıyor (tx #$id)...';
        _isError = false;
      });
      await _controller.stop();
      try {
        await ref.read(approvalsRepositoryProvider).approve(id);
        if (!mounted) return;
        ref.read(approvalsRefreshProvider.notifier).bump();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('İşlem #$id onaylandı.')),
        );
        context.pop();
      } catch (e) {
        if (!mounted) return;
        final terminal = _classifyTerminal(e);
        if (terminal != null) {
          setState(() {
            _busy = false;
            _terminal = terminal;
            _status = null;
          });
        } else {
          setState(() {
            _busy = false;
            _status = 'Hata: $e';
            _isError = true;
          });
          await _controller.start();
        }
      }
      return;
    }
  }

  _TerminalError? _classifyTerminal(Object e) {
    final s = e.toString();
    if (s.contains('403')) {
      return const _TerminalError(
        icon: Icons.block,
        title: 'Yetkiniz Yok',
        message:
            'Bu QR kodu sizin onayınıza sunulmamış. Lütfen kendi carinizin gönderdiği fişi okutun.',
      );
    }
    if (s.contains('422')) {
      return const _TerminalError(
        icon: Icons.task_alt,
        title: 'Karar Verilmiş',
        message: 'Bu işlem zaten onaylanmış veya iptal edilmiş.',
      );
    }
    if (s.contains('404')) {
      return const _TerminalError(
        icon: Icons.search_off,
        title: 'Bulunamadı',
        message: 'Bu QR koda ait işlem bulunamadı.',
      );
    }
    return null;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final terminal = _terminal;
    if (terminal != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('QR Tara')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(terminal.icon,
                    size: 72,
                    color: Theme.of(context).colorScheme.error),
                const SizedBox(height: 16),
                Text(terminal.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center),
                const SizedBox(height: 12),
                Text(terminal.message,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center),
                const SizedBox(height: 32),
                FilledButton.icon(
                  icon: const Icon(Icons.home),
                  label: const Text('Onaylara Dön'),
                  onPressed: () => context.go('/approvals'),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Tekrar Tara'),
                  onPressed: () async {
                    setState(() {
                      _terminal = null;
                      _status = null;
                      _isError = false;
                      _busy = false;
                    });
                    await _controller.start();
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Tara'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
            tooltip: 'Flaş',
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          Positioned(
            top: 24,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Fişteki QR kodunu kameraya tutun.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          if (_status != null)
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _isError ? Colors.red.shade700 : Colors.green.shade700,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(_isError ? Icons.error : Icons.check_circle,
                        color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_status!,
                          style: const TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TerminalError {
  const _TerminalError({
    required this.icon,
    required this.title,
    required this.message,
  });
  final IconData icon;
  final String title;
  final String message;
}
