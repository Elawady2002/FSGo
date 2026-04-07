import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../coordinator/presentation/providers/driver_duty_provider.dart';
import 'providers/scanner_provider.dart';

const _kBg = Color(0xFF1A1A1A);
const _kLime = Color(0xFF1A1A1A);
const _kText = Colors.white;
const _kSubText = Color(0xFF9E9E9E);

/// Full-screen QR scanner for driver boarding verification.
///
/// Usage:
/// ```dart
/// Navigator.push(context, CupertinoPageRoute(
///   builder: (_) => ScannerScreen(manifestKey: key),
/// ));
/// ```
class ScannerScreen extends ConsumerStatefulWidget {
  final ManifestKey manifestKey;
  const ScannerScreen({super.key, required this.manifestKey});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  late final MobileScannerController _cameraController;
  bool _torchOn = false;

  @override
  void initState() {
    super.initState();
    _cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scanState = ref.watch(scannerProvider(widget.manifestKey));

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        title: Text(
          'مسح تذكرة الراكب',
          style: GoogleFonts.cairo(
            color: _kText,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: _kText),
        actions: [
          IconButton(
            icon: Icon(
              _torchOn ? CupertinoIcons.bolt_fill : CupertinoIcons.bolt,
              color: _torchOn ? _kLime : _kText,
            ),
            onPressed: () {
              _cameraController.toggleTorch();
              setState(() => _torchOn = !_torchOn);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Camera viewport
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(24)),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  MobileScanner(
                    controller: _cameraController,
                    onDetect: (capture) {
                      final barcodes = capture.barcodes;
                      if (barcodes.isEmpty) return;
                      final raw = barcodes.first.rawValue;
                      if (raw == null) return;
                      ref
                          .read(scannerProvider(widget.manifestKey).notifier)
                          .processQr(raw);
                    },
                  ),
                  // Scan frame overlay
                  _ScanFrame(isActive: !scanState.isProcessing),
                ],
              ),
            ),
          ),
          // Result banner
          Expanded(
            flex: 1,
            child: _ResultBanner(state: scanState),
          ),
        ],
      ),
    );
  }
}

// ── Scan Frame Overlay ─────────────────────────────────────────

class _ScanFrame extends StatelessWidget {
  final bool isActive;
  const _ScanFrame({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        border: Border.all(
          color: isActive ? _kLime : Colors.white38,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

// ── Result Banner ──────────────────────────────────────────────

class _ResultBanner extends StatelessWidget {
  final ScanState state;
  const _ResultBanner({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.result == ScanResult.idle) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(CupertinoIcons.qrcode, color: _kSubText, size: 36),
            const SizedBox(height: 10),
            Text(
              'وجّه الكاميرا نحو QR الراكب',
              style: GoogleFonts.cairo(color: _kSubText, fontSize: 15),
            ),
          ],
        ),
      );
    }

    if (state.isProcessing) {
      return const Center(
        child: CircularProgressIndicator(color: _kLime),
      );
    }

    final isSuccess = state.result == ScanResult.success;
    final icon = isSuccess
        ? CupertinoIcons.checkmark_circle_fill
        : CupertinoIcons.xmark_circle_fill;
    final color = isSuccess ? _kLime : Colors.redAccent;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 48),
          const SizedBox(height: 8),
          Text(
            state.message ?? '',
            style: GoogleFonts.cairo(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
