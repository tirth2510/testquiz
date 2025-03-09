import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'mcq_code.dart';

class FlashcardsScreen extends StatefulWidget {
  final List<Map<String, dynamic>> incorrectQuestions;

  FlashcardsScreen({required this.incorrectQuestions});

  @override
  _FlashcardsScreenState createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> {
  int _currentIndex = 0;
  List<String> _explanations = [];

  @override
  void initState() {
    super.initState();
    _fetchExplanations();
  }

  Future<void> _fetchExplanations() async {
    List<String> explanations = [];

    for (var question in widget.incorrectQuestions) {
      final response = await http.post(
        Uri.parse('http://192.168.29.108:5000/generate_explanation'), // Adjust host/port if needed
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({'question': question['question'], 'correctAnswer': question['correctAnswer']}),
      );

      if (response.statusCode == 200) {
        explanations.add(jsonDecode(response.body)['explanation']);
      } else {
        explanations.add("No explanation available.");
      }
    }

    setState(() {
      _explanations = explanations;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_explanations.isEmpty || _currentIndex >= widget.incorrectQuestions.length) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    var question = widget.incorrectQuestions[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text("Flashcards"),
        leading: IconButton(
          icon: Icon(Icons.close), // Cross button
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => MCQCode()),
              (Route<dynamic> route) => false,
            );
          },
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(  // Makes content scrollable
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Q: ${question['question']}", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Column(
                children: question['options'].map<Widget>((opt) => Padding(
                  padding: const EdgeInsets.only(bottom: 5.0),
                  child: Text(opt, style: TextStyle(fontSize: 16)),
                )).toList(),
              ),
              SizedBox(height: 10),
              Text("Your Answer: ${question['selectedAnswer']}", style: TextStyle(color: Colors.red, fontSize: 16)),
              Text("Correct Answer: ${question['correctAnswer']}", style: TextStyle(color: Colors.green, fontSize: 16)),
              SizedBox(height: 10),
              Text("Explanation: ${_explanations[_currentIndex]}", style: TextStyle(fontSize: 16)),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentIndex > 0)
                    ElevatedButton(
                      onPressed: () => setState(() => _currentIndex--),
                      child: Text("Previous"),
                    ),
                  if (_currentIndex < widget.incorrectQuestions.length - 1)
                    ElevatedButton(
                      onPressed: () => setState(() => _currentIndex++),
                      child: Text("Next"),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
