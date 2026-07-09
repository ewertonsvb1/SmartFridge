import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:smartfridge_mobile/src/features/product/presentation/barcode_scanner_page.dart';

void main() {
  test('findFirstSupportedBarcodeValue should return first supported barcode',
      () {
    final result = findFirstSupportedBarcodeValue(const [
      BarcodeScanCandidate(format: BarcodeFormat.qrCode, rawValue: 'ignored'),
      BarcodeScanCandidate(
          format: BarcodeFormat.ean13, rawValue: '7891234567890'),
      BarcodeScanCandidate(
          format: BarcodeFormat.upcA, rawValue: '012345678905'),
    ]);

    expect(result, '7891234567890');
  });

  test(
      'findFirstSupportedBarcodeValue should ignore unsupported and empty values',
      () {
    final result = findFirstSupportedBarcodeValue(const [
      BarcodeScanCandidate(format: BarcodeFormat.qrCode, rawValue: 'ignored'),
      BarcodeScanCandidate(format: BarcodeFormat.ean8, rawValue: '   '),
      BarcodeScanCandidate(
          format: BarcodeFormat.dataMatrix, rawValue: 'still-ignored'),
    ]);

    expect(result, isNull);
  });

  test(
      'BarcodeDetectionCoordinator should stop scanner and process only first valid detection',
      () async {
    final coordinator = BarcodeDetectionCoordinator();
    var stopCalls = 0;

    final firstResult = await coordinator.handleDetection(
      candidates: const [
        BarcodeScanCandidate(format: BarcodeFormat.upcE, rawValue: '01234565'),
      ],
      stopScanner: () async {
        stopCalls++;
      },
    );

    final secondResult = await coordinator.handleDetection(
      candidates: const [
        BarcodeScanCandidate(
            format: BarcodeFormat.ean13, rawValue: '7891234567890'),
      ],
      stopScanner: () async {
        stopCalls++;
      },
    );

    expect(firstResult, '01234565');
    expect(secondResult, isNull);
    expect(stopCalls, 1);
    expect(coordinator.handledDetection, isTrue);
  });
}
