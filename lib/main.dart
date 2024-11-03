import 'package:flutter/material.dart';
import 'package:flutter_chat/LoginScreen.dart';
import 'HomeScreen.dart';

void main() {
  runApp(ChatApp());
}

class ChatApp extends StatelessWidget {
  const ChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat App',
      home: LoginScreen(),
    );
  }
}
