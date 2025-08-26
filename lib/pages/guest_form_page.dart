import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'qr_scanner_page.dart';
import 'submissions_page.dart';
import 'dart:ui' as ui;
import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:typed_data';
import 'package:flutter/rendering.dart';

class GuestFormPage extends StatefulWidget {
  final String workerName;

  const GuestFormPage({super.key, required this.workerName});

  @override
  _GuestFormPageState createState() => _GuestFormPageState();
}

class _GuestFormPageState extends State<GuestFormPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _eventController = TextEditingController();
  final TextEditingController _ipController = TextEditingController();
  File? _guestImage;
  final ImagePicker _picker = ImagePicker();
  String? _serverIp;

  final ScrollController _scrollController = ScrollController();

  Future<void> _takePhoto() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _guestImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _importPhoto() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _guestImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitGuestInfo() async {
    if (_serverIp == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Please scan the server QR code or enter IP manually.')),
      );
      return;
    }

    String guestName = _nameController.text;
    String eventText = _eventController.text.trim();

    if (guestName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name')),
      );
      return;
    }

    try {
      String originalPhotoBase64 = '';
      bool hasPhoto = false;
      if (_guestImage != null) {
        final imageBytes = await _guestImage!.readAsBytes();
        originalPhotoBase64 = base64Encode(imageBytes);
        hasPhoto = true;
      }

      var response = await http.post(
        Uri.parse('http://$_serverIp/submit'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'guest_name': guestName,
          'original_photo': originalPhotoBase64,
          'worker_name': widget.workerName,
          'event_text': eventText,
          'has_photo': hasPhoto,
        }),
      );

      if (response.statusCode == 200) {
        _showSuccessOverlay(context); // New success overlay
        _nameController.clear();
        _eventController.clear();
        setState(() {
          _guestImage = null;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Failed to submit info! Response: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _scanQRCode() async {
    final scannedIp = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QRScannerPage()),
    );
    if (scannedIp != null) {
      String sanitizedIp = scannedIp
          .trim()
          .replaceAll(RegExp(r'http://|https://'), '')
          .split(':')[0];
      setState(() {
        _serverIp = '$sanitizedIp:5000';
        _ipController.text = _serverIp!; // Update the manual IP input field
      });
    }
  }

  Future<void> _viewAllSubmissions() async {
    if (_serverIp == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please scan QR code or enter server IP first'),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubmissionsPage(
          workerName: widget.workerName,
          serverIp: _serverIp!,
        ),
      ),
    );
  }

  void _showSuccessOverlay(BuildContext context) {
    OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => AnimatedOpacity(
        duration: const Duration(milliseconds: 800),
        opacity: 1.0,
        child: Container(
          color: Colors.green.withOpacity(0.3),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 10,
                  )
                ],
              ),
              child: const Text(
                'Sent',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry);

    Future.delayed(const Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        width: screenSize.width,
        height: screenSize.height,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            SingleChildScrollView(
              controller: _scrollController,
              physics: const ClampingScrollPhysics(),
              child: SafeArea(
                child: Container(
                  width: screenSize.width,
                  padding: EdgeInsets.only(
                    bottom: keyboardHeight + 120,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: screenSize.height * 0.03),
                      SizedBox(
                        width: screenSize.width *
                            0.7, // CHANGE: Reduce from 0.8 to 0.7 for overall frame width
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (_guestImage != null)
                              Image.file(
                                _guestImage!,
                                width: screenSize.width * 0.56,
                                height: screenSize.width * 0.7,
                                fit: BoxFit.contain,
                              ),
                            Image.asset(
                              'assets/frame_outline.png',
                              width: screenSize.width * 0.63,
                              //height: screenSize.height *0.4,

                              fit: BoxFit.contain,
                            ),
                          ],
                        ),
                      ),

                      Container(
                        width: screenSize.width * 0.7,
                        height: 100, // Increased height for multiline
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage('assets/name_textEdit.png'),
                            fit: BoxFit.fill,
                          ),
                        ),
                        child: Center(
                          child: TextField(
                            controller: _nameController,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color.fromARGB(255, 59, 26, 0),
                              fontSize: 18,
                            ),
                            maxLines: null, // Allow unlimited lines
                            keyboardType: TextInputType
                                .multiline, // Enable multiline input
                            textCapitalization: TextCapitalization
                                .sentences, // Capitalize first letter of each sentence
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Enter Name',
                              hintStyle: TextStyle(
                                color: Colors.white70,
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 10,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: screenSize.width * 0.7,
                        height: 50, // Smaller height
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 30, 30, 30),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color.fromARGB(255, 243, 180, 5),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color.fromARGB(255, 243, 180, 5)
                                  .withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: TextField(
                            controller: _eventController,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color.fromARGB(255, 243, 180, 5),
                              fontSize: 16,
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Event Name (Optional)',
                              hintStyle: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: _takePhoto,
                            child: Image.asset(
                              'assets/capture_btn.png',
                              width: screenSize.width *
                                  0.3, // Adjusted width for the row layout
                            ),
                          ),
                          const SizedBox(width: 10), // Space between buttons
                          GestureDetector(
                            onTap: _importPhoto,
                            child: Image.asset(
                              'assets/import_btn.png',
                              width: screenSize.width *
                                  0.08, // Adjusted width for the import button
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: _submitGuestInfo,
                        child: Image.asset(
                          'assets/send_btn.png',
                          width: screenSize.width * 0.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Add QR Scan and Manual IP Input Fields
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20.0, vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: _scanQRCode,
                              child: const Icon(
                                Icons.qr_code_scanner,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: TextField(
                                  controller: _ipController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(
                                    hintText: 'Scan QR or enter IP manually',
                                    hintStyle: TextStyle(
                                        color: Colors.white54, fontSize: 14),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding:
                                        EdgeInsets.symmetric(vertical: 8),
                                  ),
                                  onChanged: (value) =>
                                      setState(() => _serverIp = value),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: _viewAllSubmissions,
                              child: Image.asset(
                                'assets/viewAll_btn.png',
                                width: screenSize.width * 0.08,
                              ),
                            )
                          ],
                        ),
                      ),
                      SizedBox(height: keyboardHeight > 0 ? 0 : 60),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _eventController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
