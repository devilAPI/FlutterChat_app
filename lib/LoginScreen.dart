import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'HomeScreen.dart'; // Import the HomeScreen
import 'RegisterScreen.dart'; // Import the RegisterScreen

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  Future<void> login() async {
    String username = usernameController.text
        .trim()
        .replaceAll(' ', '_'); // Ersetzen Sie Leerzeichen durch '_'
    final String password = passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      // Show an error if fields are empty
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: const Text('Username and Password cannot be empty.'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://krasserserver.com:8004/chat_api/login.php'),
        headers: <String, String>{
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'username': username,
          'password': password,
        },
      );

      final Map<String, dynamic> jsonResponse = json.decode(response.body);

      // Check response status
      if (jsonResponse['status'] == 'success') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  HomeScreen(username: username)), // Pass username
        );
      } else {
        // Show error message from the response
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text(jsonResponse['message']),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('Error during login: $e');
      // Show a general error message
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: const Text('Failed to login. Please try again later.'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      );
    }
  }

  void navigateToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RegisterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Login'), backgroundColor: Colors.deepPurple[900]),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: login,
              child: const Text('Login'),
            ),
            TextButton(
              onPressed: navigateToRegister,
              child: const Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
}
