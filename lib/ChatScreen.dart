import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:flutter/services.dart'; // Import for clipboard functionality

class ChatScreen extends StatefulWidget {
  final String userId;
  final String encryptionKey;
  final String recipientId;
  final String hashedKey;

  const ChatScreen({
    required this.userId,
    required this.encryptionKey,
    required this.recipientId,
    required this.hashedKey,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Message> messages = [];
  Set<int> selectedMessages = {}; // Store selected message indices
  bool isMultiSelectMode =
      false; // Flag to track if multi-select mode is active
  bool firstSelectionLongPressed =
      false; // Track if first selection was long pressed
  bool isSending = false; // Flag to track if a message is being sent

  @override
  void initState() {
    super.initState();
    retrieveMessages();
  }

  Future<void> retrieveMessages() async {
    try {
      final response = await http.get(Uri.parse(
          'http://krasserserver.com:8004/chat_api/retrieve.php?user1Id=${widget.userId}&user2Id=${widget.recipientId}&encryptionKey=${widget.hashedKey}'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse.containsKey('messages') &&
            jsonResponse['messages'] is List) {
          setState(() {
            messages = (jsonResponse['messages'] as List)
                .map((msg) => Message(
                      msg['senderId'],
                      msg['message'],
                      DateTime.parse(msg['timestamp']),
                    ))
                .toList();
            // Scroll to the bottom when messages are retrieved
            scrollToBottom();
          });
        } else {
          print('Error: Messages key not found or not a list');
        }
      } else {
        print('Error retrieving messages: ${response.body}');
      }
    } catch (e) {
      print('Error retrieving messages: $e');
    }
  }

  void scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  String encryptMessage(String message) {
    final key = encrypt.Key.fromUtf8(
        widget.encryptionKey.padRight(32, '0').substring(0, 32));
    final iv = encrypt.IV.fromLength(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    final encrypted = encrypter.encrypt(message, iv: iv);
    final encryptedMessage = '${iv.base64}:${encrypted.base64}';

    return encryptedMessage;
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
          Uri.parse('http://krasserserver.com:8004/chat_api/save.php'),
          body: {
            'user1Id': widget.userId,
            'user2Id': widget.recipientId,
            'message': encryptedMessage,
            'encryptionKey': widget.hashedKey,
          },
        );

        if (response.statusCode == 200) {
          setState(() {
            messages
                .add(Message(widget.userId, encryptedMessage, DateTime.now()));
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
          isSending = false; // Reset sending status
        });
      }
    }
  }

  String decryptMessage(String encryptedMessage) {
    // Check if the encrypted message contains the expected delimiter
    if (!encryptedMessage.contains(':')) {
      print("Decryption error: Invalid format of encrypted message");
      return "Decryption error: Invalid format of encrypted message";
    }

    try {
      // Ensure the encryption key is 32 characters long
      final key = encrypt.Key.fromUtf8(
          widget.encryptionKey.padRight(32, '0').substring(0, 32));
      final parts = encryptedMessage.split(':');

      // Check if both parts (IV and encrypted text) are present
      if (parts.length != 2) {
        print("Decryption error: Expected 2 parts, but got ${parts.length}");
        return "Decryption error: Expected 2 parts, but got ${parts.length}";
      }

      final iv = encrypt.IV.fromBase64(parts[0]);
      final encrypter = encrypt.Encrypter(encrypt.AES(key));
      final decrypted = encrypter.decrypt64(parts[1], iv: iv);

      return decrypted;
    } catch (e) {
      print("Decryption error: $e");
      return "Decryption error: $e";
    }
  }

  void copySelectedMessages() {
    final selectedTexts = selectedMessages
        .map((index) => decryptMessage(messages[index].text))
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
                    DateTime currentMessageDate = messages[index].timestamp;
                    String formattedDate =
                        DateFormat.yMMMMd().format(currentMessageDate);

                    bool showDateSeparator = index == 0 ||
                        !isSameDate(
                            currentMessageDate, messages[index - 1].timestamp);

                    return GestureDetector(
                      onTap: () {
                        // If already in selection mode, toggle selection state
                        if (isMultiSelectMode) {
                          setState(() {
                            if (selectedMessages.contains(index)) {
                              selectedMessages.remove(index);
                              // Exit multi-select mode if no messages are selected
                              if (selectedMessages.isEmpty) {
                                isMultiSelectMode = false;
                                firstSelectionLongPressed =
                                    false; // Reset the long press state
                              }
                            } else {
                              selectedMessages.add(index);
                            }
                          });
                        }
                        // If not in selection mode, initiate selection mode
                        else {
                          setState(() {
                            firstSelectionLongPressed =
                                false; // Reset the long press state
                          });
                        }
                      },
                      onLongPress: () {
                        // If not in selection mode, enter selection mode and select the first message
                        if (!isMultiSelectMode) {
                          setState(() {
                            selectedMessages.add(index);
                            isMultiSelectMode = true; // Enter multi-select mode
                            firstSelectionLongPressed =
                                true; // Set long press state
                          });
                        }
                        // If already in selection mode, allow multi-select
                        else {
                          setState(() {
                            selectedMessages.add(index);
                          });
                        }
                      },
                      child: Column(
                        children: [
                          if (showDateSeparator)
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 5),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 2, horizontal: 10),
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                formattedDate,
                                style: const TextStyle(
                                    color: Colors.black54, fontSize: 14),
                              ),
                            ),
                          MessageBubble(
                            message: messages[index],
                            currentUserId: widget.userId,
                            isEncrypted: true,
                            decryptMessage: decryptMessage,
                            isSelected: selectedMessages
                                .contains(index), // Pass selection state to bubble
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: messageController,
                      decoration: const InputDecoration(
                        labelText: 'Message',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.multiline,
                      maxLines: null, // Allows the TextField to expand vertically
                      onSubmitted: (text) {
                        // Send message when Enter is pressed
                        sendMessage();
                      },
                    ),
                  ),
                  IconButton(
                    icon: isSending
                        ? const CircularProgressIndicator()
                        : const Icon(Icons.send),
                    onPressed:
                        isSending ? null : sendMessage, // Disable while sending
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            right: 16.0,
            bottom: 80.0, // Position above message input area
            child: FloatingActionButton(
              mini: true, // Makes the FAB smaller
              onPressed: () {
                _scrollController.animateTo(
                  _scrollController.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              },
              child: const Icon(Icons.arrow_downward),
            ),
          ),
        ],
      ),
    );
  }

  bool isSameDate(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}

class MessageBubble extends StatelessWidget {
  final Message message;
  final String currentUserId;
  final bool isEncrypted;
  final Function decryptMessage;
  final bool isSelected;

  const MessageBubble({
    super.key,
    required this.message,
    required this.currentUserId,
    required this.isEncrypted,
    required this.decryptMessage,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isMe = message.senderId == currentUserId;
    final decryptedText =
        isEncrypted ? decryptMessage(message.text) : message.text;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blue[100]
              : (isMe ? Colors.deepPurple[500] : Colors.grey[300]),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            MarkdownBody(
              data: decryptedText,
              styleSheet: MarkdownStyleSheet(
                p: TextStyle(color: isMe ? Colors.white : Colors.black),
              ),
            ),
            if (isImageUrl(decryptedText))
              FadeInImage(
                placeholder: MemoryImage(kTransparentImage),
                image: NetworkImage(decryptedText),
                fit: BoxFit.cover,
              ),
          ],
        ),
      ),
    );
  }

  bool isImageUrl(String url) {
    return url.endsWith('.png') ||
        url.endsWith('.jpg') ||
        url.endsWith('.jpeg') ||
        url.endsWith('.gif') ||
        url.endsWith('.bmp') ||
        url.endsWith('.webp');
  }
}

class Message {
  final String senderId;
  final String text;
  final DateTime timestamp;

  Message(this.senderId, this.text, this.timestamp);
}
