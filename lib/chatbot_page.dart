import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatbotPage extends StatefulWidget {
  @override
  _ChatbotPageState createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final TextEditingController _questionController = TextEditingController();
  String _response = '';
  bool _isLoading = false;

  Future<void> _askGemini(String question) async {
    setState(() {
      _isLoading = true;
      _response = '';
    });

    final url = Uri.parse('http://192.168.29.108:5000/generate_explanation'); // 👈 Replace with your IP

    final body = jsonEncode({
      "question": question,
      "correctAnswer": "N/A" // We treat general queries as "explanation" type prompts
    });

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: body,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _response = data['explanation'] ?? "No response.";
        _isLoading = false;
      });
    } else {
      setState(() {
        _response = "Error from Gemini: ${response.statusCode}";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Ask Gemini")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _questionController,
              decoration: InputDecoration(
                hintText: "Type your question here...",
                border: OutlineInputBorder(),
              ),
              minLines: 1,
              maxLines: 4,
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                if (_questionController.text.trim().isNotEmpty) {
                  _askGemini(_questionController.text.trim());
                }
              },
              child: Text("Ask"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            ),
            SizedBox(height: 20),
            if (_isLoading) CircularProgressIndicator(),
            if (_response.isNotEmpty)
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(_response, style: TextStyle(fontSize: 16)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
