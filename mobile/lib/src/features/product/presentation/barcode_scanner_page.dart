import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

@visibleForTesting
const supportedBarcodeFormats = <BarcodeFormat>{
  BarcodeFormat.ean13,
  BarcodeFormat.ean8,
  BarcodeFormat.upcA,
  BarcodeFormat.upcE,
};

@visibleForTesting
class BarcodeScanCandidate {
  const BarcodeScanCandidate({
    required this.format,
    required this.rawValue,
  });

  final BarcodeFormat format;
  final String? rawValue;
}

@visibleForTesting
String? findFirstSupportedBarcodeValue(
  Iterable<BarcodeScanCandidate> candidates,
) {
  for (final candidate in candidates) {
    if (!supportedBarcodeFormats.contains(candidate.format)) {
      continue;
    }

    final rawValue = candidate.rawValue?.trim();
    if (rawValue == null || rawValue.isEmpty) {
      continue;
    }

    return rawValue;
  }

  return null;
}

@visibleForTesting
class BarcodeDetectionCoordinator {
  bool _handledDetection = false;

  bool get handledDetection => _handledDetection;

  Future<String?> handleDetection({
    required Iterable<BarcodeScanCandidate> candidates,
    required Future<void> Function() stopScanner,
  }) async {
    if (_handledDetection) {
      return null;
    }

    final rawValue = findFirstSupportedBarcodeValue(candidates);
    if (rawValue == null) {
      return null;
    }

    _handledDetection = true;
    await stopScanner();
    return rawValue;
  }
}

class BarcodeScannerPage extends StatefulWidget {
  const BarcodeScannerPage({super.key});

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: supportedBarcodeFormats.toList(),
  );

  final BarcodeDetectionCoordinator _detectionCoordinator =
      BarcodeDetectionCoordinator();

  Future<void> _onDetect(BarcodeCapture capture) async {
    final rawValue = await _detectionCoordinator.handleDetection(
      candidates: capture.barcodes
          .map(
            (barcode) => BarcodeScanCandidate(
              format: barcode.format,
              rawValue: barcode.rawValue,
            ),
          )
          .toList(growable: false),
      stopScanner: _controller.stop,
    );
    if (!mounted || rawValue == null) {
      return;
    }

    Navigator.of(context).pop(rawValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ler codigo de barras')),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.black.withValues(alpha: 0.65),
              child: const Text(
                'Aponte a camera para um codigo EAN ou UPC.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
