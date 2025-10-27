import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'report_page.dart';
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController username = TextEditingController();
  final TextEditingController password = TextEditingController();

  bool isLoading = false;

  void login() async {
    if (username.text.isEmpty || password.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter username and password")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final url = Uri.parse('http://192.168.100.17/vawc_php/login.php');

      final response = await http.post(
        url,
        body: {'username': username.text, 'password': password.text},
      );

      final data = jsonDecode(response.body);

      if (data['success']) {
        final user = data['user'];
        final int userId = int.parse(user['user_id'].toString());

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ReportIncidentPage(currentUserId: userId),
          ),
        );

        // <-- extract the user info

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Login successful!")));
        // Navigate to next page
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? "Login failed")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error connecting to server: $e")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 147, 167, 213),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/new_lower_b.png', // your image path
                width: 150, // adjust the size
                height: 150,
              ),
              const SizedBox(height: 20),

              // App Title
              const Text(
                "VAWC Reporting App",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color.fromRGBO(218, 95, 19, 1),
                ),
              ),
              const SizedBox(height: 30),

              // Login Card
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 6,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      TextField(
                        controller: username,
                        decoration: const InputDecoration(
                          labelText: "Username",
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextField(
                        controller: password,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: "Password",
                          prefixIcon: Icon(Icons.lock),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          minimumSize: const Size(200, 50),
                          backgroundColor: const Color.fromARGB(
                            255,
                            75,
                            122,
                            234,
                          ),
                        ),
                        onPressed: login,
                        child: const Text("Log In"),
                      ),
                      const SizedBox(height: 13),
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: const Color.fromARGB(
                            255,
                            74,
                            97,
                            212,
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SignUpPage(),
                            ),
                          );
                        },
                        child: const Text("Create an Account"),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// TODO Implement this library.
