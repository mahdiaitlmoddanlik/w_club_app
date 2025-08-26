import 'package:flutter/material.dart';
import 'pages/login_page.dart';

void main() {
  runApp(const MalakGuestApp());
}

class MalakGuestApp extends StatelessWidget {
  const MalakGuestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'W Club App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const LoginPage(),
    );
  }
}
