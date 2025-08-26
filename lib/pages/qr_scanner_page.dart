import 'package:flutter/material.dart';
import 'package:qr_code_dart_scan/qr_code_dart_scan.dart';

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({super.key});

  @override
  _QRScannerPageState createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  String? scannedData;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Scan QR Code',
          style: TextStyle(color: Color(0xFFFFD700)),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Color(0xFFFFD700)),
      ),
      backgroundColor: Colors.black,
      body: QRCodeDartScanView(
        scanInvertedQRCode: true, // Enable scanning inverted QR codes
        typeScan: TypeScan.live, // Live scanning mode
        onCapture: (Result result) {
          setState(() {
            scannedData = result.text; // Store scanned data
          });
          Navigator.pop(
              context, scannedData); // Return scanned data to the previous page
        },
      ),
    );
  }
}
