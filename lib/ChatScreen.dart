import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:flutter/services.dart'; // Import for clipboard functionality
import 'package:just_audio/just_audio.dart';
import 'Config.dart';
import 'utils/MessageUtils.dart';
import 'utils/ApiHelper.dart';

class ChatScreen extends StatefulWidget {
  final String userId;
  final String encryptionKey;
  final String recipientId;
  final String hashedKey;

  const ChatScreen({super.key, 
    required this.userId,
    required this.encryptionKey,
    required this.recipientId,
    required this.hashedKey,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}
  String decryptMessage(String encryptedText, String encryptionKey) {
    return ApiHelper.decryptMessage(encryptedText, encryptionKey);
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
  Timer? _refreshTimer;
  String? _lastMessageTimestamp;
  bool _hasNewMessage = false; // Track if there is a new message
  bool _showScrollButton = false;
  final TextEditingController _controller = TextEditingController();
  int _remainingChars = Config.maxMessageLength;

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
        });
      }
    });
    _controller.addListener(_updateRemainingKeys);
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _controller.removeListener(_updateRemainingKeys);
    _controller.dispose();
    super.dispose();
  }

  Future<void> retrieveMessages() async {
    try {
      final response = await http.get(Uri.parse(
          '${Config.backendUrl}/retrieve.php?user1Id=${widget.userId}&user2Id=${widget.recipientId}&encryptionKey=${widget.hashedKey}'));

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
          if (mounted && (messages.isEmpty || 
              newMessages.last.timestamp.toString() != _lastMessageTimestamp)) {
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

  void scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> sendMessage() async {
    String message = _controller.text;
    if (message.isNotEmpty && message.length <= Config.maxMessageLength) {
      String encryptedMessage = ApiHelper.encryptMessage(message, widget.encryptionKey);
      setState(() {
        isSending = true; // Indicate that a message is being sent
      });

      try {
        final response = await ApiHelper.sendMessage(
          user1Id: widget.userId,
          user2Id: widget.recipientId,
          message: encryptedMessage,
          encryptionKey: widget.hashedKey,
        );

        if (response.statusCode == 200) {
          setState(() {
            messages
                .add(Message(widget.userId, encryptedMessage, DateTime.now()));
            _controller.clear();
            _remainingChars = Config.maxMessageLength; // Reset remaining keys
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
    } else {
      // Handle the case where the message is too long
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message exceeds the maximum length of ${Config.maxMessageLength} characters.'),
        ),
      );
    }
  }


  void copySelectedMessages() {
    final selectedTexts = selectedMessages
        .map((index) => ApiHelper.decryptMessage(messages[index].text, widget.encryptionKey))
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

  void _updateRemainingKeys() {
    setState(() {
      _remainingChars = Config.maxMessageLength - _controller.text.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isMultiSelectMode 
          ? '${selectedMessages.length} Selected' 
          : 'Chat with ${widget.recipientId}'),
        backgroundColor: Config.accentColor,
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
                            decryptMessage: ApiHelper.decryptMessage,
                            isSelected: selectedMessages
                                .contains(index), // Pass selection state to bubble
                            encryptionKey: widget.encryptionKey,
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
                    controller: _controller,
                    decoration: InputDecoration(
                    labelText: 'Message',
                    border: OutlineInputBorder(
                      borderSide: BorderSide(
                      color: _remainingChars < 0 ? Colors.orange : Colors.grey,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                      color: _remainingChars < 0 ? Colors.orange : Colors.grey,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                      color: _remainingChars < 0 ? Colors.orange : Config.accentColor,
                      ),
                    ),
                    ),
                    keyboardType: TextInputType.multiline,
                    maxLines: null, // Allows the TextField to expand vertically
                    onChanged: (text) {
                    _updateRemainingKeys();
                    },
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
                Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Characters remaining: $_remainingChars',
                  style: TextStyle(
                  color: _remainingChars < 0 ? Colors.orange : Colors.black54,
                  ),
                ),
              ),
            ],
          ),
          if (_showScrollButton)
            Positioned(
              right: 16.0,
              bottom: 80.0,
              child: FloatingActionButton(
                backgroundColor: _hasNewMessage ? Config.accentColor : Colors.white,
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
                  color: _hasNewMessage ? Colors.white : Config.accentColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool isSameDate(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date2.day == date2.day;
  }
}

class MessageBubble extends StatelessWidget {
  final Message message;
  final String currentUserId;
  final bool isEncrypted;
  final String Function(String, String) decryptMessage;
  final bool isSelected;
  final String encryptionKey;

  const MessageBubble({
    super.key,
    required this.message,
    required this.currentUserId,
    required this.isEncrypted,
    required this.decryptMessage,
    required this.isSelected,
    required this.encryptionKey,
  });

  @override
  Widget build(BuildContext context) {
    final isMe = message.senderId == currentUserId;
    final decryptedText =
        isEncrypted ? decryptMessage(message.text, encryptionKey) : message.text;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected
              ? Config.accentColor[200]
              : (isMe ? Config.accentColor[500] : Colors.grey[300]),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (Utils.isAudioUrl(decryptedText))
              AudioPlayerWidget(audioUrl: decryptedText)
            else
              MarkdownBody(
                data: decryptedText,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(color: isMe ? Colors.white : Colors.black),
                ),
              ),
            if (Utils.isImageUrl(decryptedText))
              FadeInImage(
                placeholder: MemoryImage(kTransparentImage),
                image: NetworkImage(decryptedText),
                fit: BoxFit.cover,
                imageErrorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.error, color: Colors.red);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class AudioPlayerWidget extends StatefulWidget {
  final String audioUrl;

  const AudioPlayerWidget({Key? key, required this.audioUrl}) : super(key: key);

  @override
  _AudioPlayerWidgetState createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool isPlaying = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer.setUrl(widget.audioUrl);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _togglePlayPause() async {
    if (isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play();
    }
    setState(() {
      isPlaying = !isPlaying;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
          onPressed: _togglePlayPause,
        ),
        Expanded(
          child: Text(
            widget.audioUrl,
            style: TextStyle(color: Colors.white),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class Message {
  final String senderId;
  final String text;
  final DateTime timestamp;

  Message(this.senderId, this.text, this.timestamp);
}
