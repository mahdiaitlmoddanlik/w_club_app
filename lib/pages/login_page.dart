import 'package:flutter/material.dart';
import 'guest_form_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

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
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo/Title
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 30),
                child: Image.asset(
                  'assets/frame_outline.png',
                  width: screenSize.width * 0.5,
                  color: Colors.black.withOpacity(0),
                ),
              ),

              // Name Input Field
              Container(
                width: screenSize.width * 0.7,
                height: 50,
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
                    controller: _nameController,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color.fromARGB(255, 243, 180, 5),
                      fontSize: 16,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Enter your name',
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

              const SizedBox(height: 30),

              // Login Button
              GestureDetector(
                onTap: () {
                  if (_nameController.text.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GuestFormPage(
                          workerName: _nameController.text,
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter your name'),
                        backgroundColor: Color.fromARGB(255, 30, 30, 30),
                      ),
                    );
                  }
                },
                child: Container(
                  width: screenSize.width * 0.4,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 243, 180, 5),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromARGB(255, 243, 180, 5)
                            .withOpacity(0.5),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'LOGIN',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}
