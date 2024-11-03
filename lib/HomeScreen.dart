import 'package:flutter/material.dart';
import 'package:flutter_chat/LoginScreen.dart';
import 'ChatScreen.dart';
import 'SettingsScreen.dart';

class HomeScreen extends StatefulWidget {
  final String username;

  const HomeScreen({super.key, required this.username});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController recipientController = TextEditingController();
  final TextEditingController encryptionKeyController = TextEditingController();

  bool _showImages = true;

  void startChat() {
    String recipientId = recipientController.text;
    String encryptionKey = encryptionKeyController.text;

    if (recipientId.isNotEmpty && encryptionKey.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            userId: widget.username,
            encryptionKey: encryptionKey,
            recipientId: recipientId,
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
          showImages: _showImages,
          onShowImagesChanged: (value) {
            setState(() {
              _showImages = value;
            });
          },
        ),
      ),
    );
  }

  void logout() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Home'),
        backgroundColor: Colors.deepPurple[900],
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: openSettings,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: recipientController,
              decoration: const InputDecoration(labelText: 'Recipient ID'),
            ),
            TextField(
              controller: encryptionKeyController,
              decoration: const InputDecoration(labelText: 'Encryption Key'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: startChat,
              child: const Text('Start Chat'),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: logout,
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}
