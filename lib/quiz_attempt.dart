import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class QuizAttempt extends StatefulWidget {
  final String userEmail;
  final String quizId;

  QuizAttempt({required this.userEmail, required this.quizId});

  @override
  _QuizAttemptState createState() => _QuizAttemptState();
}

class _QuizAttemptState extends State<QuizAttempt> {
  List<dynamic> _questions = [];
  int _currentQuestionIndex = 0;
  bool _isLoading = true;
  int? _selectedOption; // Variable to track selected option

  @override
  void initState() {
    super.initState();
    _fetchQuizData();
  }

  Future<void> _fetchQuizData() async {
    final url = 'http://192.168.1.13:5001/fetch_quiz/${widget.userEmail}/${widget.quizId}';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _questions = data['mcqs'];
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedOption = null; // Reset selected option for the new question
      });
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
        _selectedOption = null; // Reset selected option for the previous question
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Quiz Attempt')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('Quiz Attempt')),
        body: Center(child: Text('No questions found.')),
      );
    }

    final question = _questions[_currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(title: Text('Quiz Attempt')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Question ${_currentQuestionIndex + 1}: ${question['question']}',
                    style: TextStyle(fontSize: 20),
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(
                    question['difficulty'] ?? 'Unknown',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            ...List.generate(4, (index) {
              String option = question['options'][index];
              return ListTile(
                title: Text(option),
                leading: Radio<int>(
                  value: index,
                  groupValue: _selectedOption,
                  onChanged: (int? value) {
                    setState(() {
                      _selectedOption = value; // Update selected option
                    });
                  },
                ),
              );
            }),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: _previousQuestion,
                  child: Text('Previous'),
                ),
                ElevatedButton(
                  onPressed: _nextQuestion,
                  child: Text('Next'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
