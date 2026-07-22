import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  String? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR')),
      body: MobileScanner(
        onDetect: (capture) {
          final code = capture.barcodes.firstOrNull?.rawValue;
          if (code == null) return;
          final objectId = _extractId(code);
          if (objectId == null) {
            setState(() => error = 'Unsupported QR format');
            return;
          }
          if (!mounted) return;
          context.go('/scan_result/$objectId');
        },
      ),
    );
  }

  int? _extractId(String value) {
    final urls = [
      RegExp(r'/objects/(\d+)'),
      RegExp(r'/object/(\d+)'),
      RegExp(r'/scan_result/(\d+)'),
    ];
    for (final reg in urls) {
      final m = reg.firstMatch(value);
      if (m != null) return int.tryParse(m.group(1)!);
    }
    final raw = int.tryParse(value);
    return raw;
  }
}
