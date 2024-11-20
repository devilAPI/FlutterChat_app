import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert'; // for the utf8.encode method
import 'ChatScreen.dart';
import 'Config.dart';
import 'SettingsScreen.dart';
import 'LoginScreen.dart';

class HomeScreen extends StatefulWidget {
  final String username;
  const HomeScreen({Key? key, required this.username}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController recipientController = TextEditingController();
  final TextEditingController encryptionKeyController = TextEditingController();
  bool _showImages = true;
  bool _showAudio = true;

  void startChat() {
    String recipientId = recipientController.text;
    String encryptionKey = encryptionKeyController.text;
    if (recipientId.isNotEmpty && encryptionKey.isNotEmpty) {
      // Hash the encryption key using SHA-256
      var bytes = utf8.encode(encryptionKey); // data being hashed
      var hashedKey = sha256.convert(bytes).toString();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            userId: widget.username,
            encryptionKey: encryptionKey,
            recipientId: recipientId,
            hashedKey: hashedKey,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter recipient ID and encryption key')),
      );
    }
  }

  void openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsScreen(
        ),
      ),
    );
  }

  void logout() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Screen'),
        backgroundColor: Config.accentColor,
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  TextField(
                    controller: recipientController,
                    decoration: const InputDecoration(
                      labelText: 'Recipient ID',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: encryptionKeyController,
                    decoration: const InputDecoration(
                      labelText: 'Encryption Key',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      ElevatedButton(
                        onPressed: startChat,
                        child: const Text('Start Chat'),
                      ),
                      ElevatedButton(
                        onPressed: openSettings,
                        child: const Text('Settings'),
                      ),
                      ElevatedButton(
                        onPressed: logout,
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 16.0,
            bottom: 16.0,
            child: Text(
              'Logged in as ${widget.username}',
              style: const TextStyle(
                fontSize: 16.0,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
