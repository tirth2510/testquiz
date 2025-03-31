import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'mcq_code.dart';

class QRScannerPage extends StatefulWidget {
  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  bool _isScanned = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Scan Quiz QR Code')),
      body: MobileScanner(
        onDetect: (BarcodeCapture capture) {
          final List<Barcode> barcodes = capture.barcodes;

          if (!_isScanned && barcodes.isNotEmpty && barcodes.first.rawValue != null) {
            final String code = barcodes.first.rawValue!;
            _isScanned = true;

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => MCQCode(initialCode: code),
              ),
            );
          }
        },
      ),
    );
  }
}
