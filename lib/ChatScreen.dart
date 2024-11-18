import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:flutter/services.dart'; // Import for clipboard functionality
import 'LoginScreen.dart';
import 'Config.dart';

class ChatApp extends StatelessWidget {
  const ChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat App',
      theme: ThemeData(
        appBarTheme: const AppBarTheme(
          toolbarTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final String userId;
  final String recipientId;
  final String hashedKey;
  final String encryptionKey;

  const ChatScreen({
    required this.userId,
    required this.recipientId,
    required this.hashedKey,
    required this.encryptionKey,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Message> messages = [];
  Set<int> selectedMessages = {}; // Store selected message indices
  bool isMultiSelectMode = false; // Flag to track if multi-select mode is active
  bool firstSelectionLongPressed = false; // Track if first selection was long pressed
  bool isSending = false; // Flag to track if a message is being sent
  Timer? _refreshTimer;
  String? _lastMessageTimestamp;
  bool _hasNewMessage = false; // Track if there is a new message
  bool _showScrollButton = false;
  bool isMessageTooLong = false; // Track if the message length exceeds the maximum length

  @override
  void initState() {
    super.initState();
    retrieveMessages();
    // Start periodic refresh every 3 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        retrieveMessages();
      }
    });

    _scrollController.addListener(() {
      final shouldShow = _scrollController.hasClients &&
          _scrollController.position.pixels <
              (_scrollController.position.maxScrollExtent - 100);

      if (shouldShow != _showScrollButton) {
        setState(() {
          _showScrollButton = shouldShow;
          if (!shouldShow) {
            _hasNewMessage = false; // Reset new message indicator when hiding button
          }
        });
      }

      // Check if scrolled all the way down
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent) {
        setState(() {
          _hasNewMessage = false; // Reset new message indicator when at bottom
        });
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> retrieveMessages() async {
    try {
      final response = await http.get(Uri.parse(
          'http://krasserserver.com:8004/chat_api/retrieve.php?user1Id=${widget.userId}&user2Id=${widget.recipientId}&encryptionKey=${widget.hashedKey}'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse.containsKey('messages') &&
            jsonResponse['messages'] is List) {
          final List<Message> newMessages = (jsonResponse['messages'] as List)
              .map((msg) => Message(
                    msg['senderId'],
                    msg['message'],
                    DateTime.parse(msg['timestamp']),
                  ))
              .toList();

          // Only update state if there are new messages
          if (mounted &&
              (messages.isEmpty ||
                  newMessages.last.timestamp.toString() !=
                      _lastMessageTimestamp)) {
            setState(() {
              messages = newMessages;
              _lastMessageTimestamp = newMessages.last.timestamp.toString();
              _hasNewMessage = true; // Indicate that there is a new message
            });
          }
        }
      }
    } catch (e) {
      print('Error refreshing messages: $e');
    }
  }

  Future<void> sendMessage() async {
    String message = messageController.text;
    if (message.isNotEmpty) {
      String encryptedMessage = encryptMessage(message);
      setState(() {
        isSending = true; // Indicate that a message is being sent
      });

      try {
        final response = await http.post(
          Uri.parse(Config.backendUrl + '/save.php'),
          body: {
            'user1Id': widget.userId,
            'user2Id': widget.recipientId,
            'message': encryptedMessage,
            'encryptionKey': widget.hashedKey,
          },
        );

        if (response.statusCode == 200) {
          setState(() {
            messages.add(Message(widget.userId, encryptedMessage, DateTime.now()));
            messageController.clear();
            scrollToBottom(); // Scroll to the bottom when a new message is added
          });
        } else {
          print('Failed to send message: ${response.body}');
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to send message')));
        }
      } catch (e) {
        print('Error sending message: $e');
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error sending message')));
      } finally {
        setState(() {
          isSending = false;
        });
      }
    }
  }

  void scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  String encryptMessage(String message) {
    // Your encryption logic here
    return message;
  }

  String decryptMessage(String encryptedMessage) {
    // Your decryption logic here
    return encryptedMessage;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isMultiSelectMode
            ? '${selectedMessages.length} Selected'
            : 'Chat with ${widget.recipientId}'),
        backgroundColor: Colors.deepPurple,
        actions: [
          if (isMultiSelectMode) ...[
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Stop selection',
              onPressed: () {
                setState(() {
                  selectedMessages.clear();
                  isMultiSelectMode = false;
                  firstSelectionLongPressed = false;
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.copy),
              tooltip: 'Copy selected messages',
              onPressed: copySelectedMessages,
            ),
          ] else
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh messages',
              onPressed: retrieveMessages,
            ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return ListTile(
                      title: Text(message.content),
                      selected: selectedMessages.contains(index),
                      onLongPress: () {
                        setState(() {
                          isMultiSelectMode = true;
                          selectedMessages.add(index);
                        });
                      },
                      onTap: () {
                        if (isMultiSelectMode) {
                          setState(() {
                            if (selectedMessages.contains(index)) {
                              selectedMessages.remove(index);
                              if (selectedMessages.isEmpty) {
                                isMultiSelectMode = false;
                              }
                            } else {
                              selectedMessages.add(index);
                            }
                          });
                        }
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: messageController,
                        decoration: InputDecoration(
                          labelText: 'Type a message...',
                          border: OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: isMessageTooLong ? Colors.orange : Colors.blue,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: isMessageTooLong ? Colors.orange : Colors.grey,
                            ),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            isMessageTooLong = value.length > Config.maxMessageLength;
                          });
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: isSending ? null : sendMessage,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_showScrollButton)
            Positioned(
              right: 16.0,
              bottom: 80.0,
              child: FloatingActionButton(
                backgroundColor: _hasNewMessage ? Colors.deepPurple : Colors.white,
                onPressed: () {
                  _scrollController.animateTo(
                    _scrollController.position.maxScrollExtent,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                  setState(() {
                    _hasNewMessage = false; // Reset new message indicator
                    _showScrollButton = false; // Hide button after scrolling down
                  });
                },
                child: Icon(
                  Icons.arrow_downward,
                  color: _hasNewMessage ? Colors.white : Colors.deepPurple,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void copySelectedMessages() {
    final selectedTexts = selectedMessages
        .map((index) => decryptMessage(messages[index].content))
        .join('\n');
    Clipboard.setData(ClipboardData(text: selectedTexts)).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Copied ${selectedMessages.length} message(s)')));
      setState(() {
        selectedMessages.clear();
        isMultiSelectMode = false; // Exit multi-select mode after copying
        firstSelectionLongPressed = false; // Reset the long press state
      });
    });
  }
}

class Message {
  final String senderId;
  final String content;
  final DateTime timestamp;

  Message(this.senderId, this.content, this.timestamp);
}