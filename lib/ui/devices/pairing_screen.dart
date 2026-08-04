import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../security/pairing.dart';
import '../../sync/engine.dart';
import '../../theme/app_theme.dart';

/// Full-screen pairing QR with the 5-minute countdown (screen 11 detail).
/// Each visit mints a fresh single-use token (§6.1).
class PairingScreen extends ConsumerStatefulWidget {
  const PairingScreen({super.key});

  @override
  ConsumerState<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends ConsumerState<PairingScreen> {
  PairingQr? _qr;
  String? _error;
  Duration _remaining = const Duration(minutes: 5);
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _issue();
  }

  Future<void> _issue() async {
    _ticker?.cancel();
    setState(() {
      _qr = null;
      _error = null;
      _remaining = const Duration(minutes: 5);
    });
    final engine = ref.read(syncEngineProvider);
    await engine.ensureStarted();
    final pairing = engine.pairingService;
    if (pairing == null) {
      setState(() =>
          _error = 'Pairing is only available on the main business phone.');
      return;
    }
    final PairingQr qr;
    try {
      qr = await pairing.issueToken();
    } on NoLocalIpException {
      if (!mounted) return;
      setState(() => _error =
          'This phone has no Wi-Fi address to share. Make sure it is '
          'connected to a Wi-Fi network (or its own hotspot is on), then '
          'try again.');
      return;
    }
    if (!mounted) return;
    setState(() => _qr = qr);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _remaining -= const Duration(seconds: 1);
        if (_remaining.isNegative || _remaining == Duration.zero) {
          _ticker?.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expired = _remaining <= Duration.zero;
    final minutes = _remaining.inMinutes.clamp(0, 5);
    final seconds = (_remaining.inSeconds % 60).clamp(0, 59);

    return Scaffold(
      appBar: AppBar(title: const Text('Add device')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(Insets.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_error != null) ...[
                Icon(Icons.error_outline_rounded,
                    size: 64, color: theme.colorScheme.error),
                const SizedBox(height: Insets.lg),
                Text(_error!, textAlign: TextAlign.center),
              ] else if (_qr == null) ...[
                const CircularProgressIndicator(),
              ] else ...[
                Text(
                  'On the new phone, choose “Join an existing business” and scan this code.',
                  style: theme.textTheme.bodyMedium!
                      .copyWith(color: theme.colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: Insets.xxl),
                Container(
                  padding: const EdgeInsets.all(Insets.xl),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(Corners.xxl),
                    border: Border.all(
                        color: expired
                            ? theme.colorScheme.error
                            : theme.colorScheme.outlineVariant),
                  ),
                  child: Opacity(
                    opacity: expired ? 0.15 : 1,
                    child: QrImageView(
                      data: _qr!.encode(),
                      size: 260,
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: Insets.xl),
                if (expired)
                  Text('Code expired',
                      style: theme.textTheme.titleMedium!
                          .copyWith(color: theme.colorScheme.error))
                else
                  Text(
                    'Expires in $minutes:${seconds.toString().padLeft(2, '0')}',
                    style: theme.textTheme.titleMedium!.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontFeatures: tabularFigures,
                    ),
                  ),
                const SizedBox(height: Insets.sm),
                Text(
                  'Hub address: ${_qr!.ip}:${_qr!.port}',
                  style: theme.textTheme.bodySmall!.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontFeatures: tabularFigures,
                  ),
                ),
              ],
              const SizedBox(height: Insets.xxl),
              if (_qr != null || _error != null)
                OutlinedButton.icon(
                  onPressed: _issue,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('New code'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
