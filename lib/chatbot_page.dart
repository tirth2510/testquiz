import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class ChatbotPage extends StatefulWidget {
  @override
  _ChatbotPageState createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;
  String _typingText = '';
  Timer? _typingTimer;

  Future<void> _sendMessage(String message) async {
    setState(() {
      _messages.add({"role": "user", "text": message});
      _isLoading = true;
      _typingText = '';
    });

    _scrollToBottom();

    final url = Uri.parse('https://flaskgenerate.onrender.com/chatbot');

    final body = jsonEncode({
      "question": message,
      "correctAnswer": "N/A"
    });

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final fullReply = data['explanation'] ?? 'No response.';

        // Typing animation
        _simulateTyping(fullReply);
      } else {
        _addBotMessage('Error: ${response.statusCode}');
      }
    } catch (e) {
      _addBotMessage('Connection error: $e');
    }
  }

  void _simulateTyping(String text) {
    int index = 0;
    const duration = Duration(milliseconds: 30); // typing speed

    _typingTimer?.cancel();
    _typingTimer = Timer.periodic(duration, (timer) {
      if (index < text.length) {
        setState(() {
          _typingText += text[index];
        });
        index++;
        _scrollToBottom();
      } else {
        timer.cancel();
        _addBotMessage(_typingText);
        _typingText = '';
        _isLoading = false;
      }
    });
  }

  void _addBotMessage(String text) {
    setState(() {
      _messages.add({"role": "bot", "text": text});
      _isLoading = false;
      _typingText = '';
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 100,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Widget _buildMessageBubble(String text, String role) {
    final isUser = role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: isUser ? Colors.orange[300] : Colors.grey[200],
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(14),
            topRight: Radius.circular(14),
            bottomLeft: Radius.circular(isUser ? 14 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 14),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(fontSize: 16, color: isUser ? Colors.white : Colors.black87),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allMessages = [..._messages];
    if (_isLoading && _typingText.isNotEmpty) {
      allMessages.add({"role": "bot", "text": _typingText});
    }

    return Scaffold(
      appBar: AppBar(title: Text("Gemini Chat")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              itemCount: allMessages.length + (_isLoading && _typingText.isEmpty ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < allMessages.length) {
                  final message = allMessages[index];
                  return _buildMessageBubble(message['text']!, message['role']!);
                } else {
                  return _buildThinkingBubble(); // Gemini is thinking...
                }
              },
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              minLines: 1,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: "Ask something...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
          SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.send, color: Colors.orange),
            onPressed: _isLoading
                ? null
                : () {
                    final text = _controller.text.trim();
                    if (text.isNotEmpty) {
                      _controller.clear();
                      _sendMessage(text);
                    }
                  },
          )
        ],
      ),
    );
  }

  Widget _buildThinkingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(14),
            topRight: Radius.circular(14),
            bottomRight: Radius.circular(14),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Gemini is thinking",
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            SizedBox(width: 6),
            LoadingDots(),
          ],
        ),
      ),
    );
  }
}

class LoadingDots extends StatefulWidget {
  @override
  _LoadingDotsState createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<LoadingDots> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _dotCount;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: Duration(milliseconds: 900), vsync: this)..repeat();
    _dotCount = StepTween(begin: 1, end: 3).animate(_controller);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _dotCount,
      builder: (context, child) {
        return Text("." * _dotCount.value, style: TextStyle(fontSize: 18));
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
