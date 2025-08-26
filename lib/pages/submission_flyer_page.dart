import 'package:flutter/material.dart';
import 'dart:io';

class SubmissionFlyerPage extends StatelessWidget {
  final String guestName;
  final String photoPath;

  const SubmissionFlyerPage({
    super.key,
    required this.guestName,
    required this.photoPath,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          guestName,
          style: const TextStyle(color: Color(0xFFFFD700)),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Color(0xFFFFD700)),
      ),
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Guest: $guestName',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.file(
                  File(photoPath),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
