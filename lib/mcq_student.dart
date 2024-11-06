import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MCQStudent extends StatefulWidget {
  final String quizCode;

  MCQStudent({required this.quizCode});

  @override
  _MCQStudentState createState() => _MCQStudentState();
}

class _MCQStudentState extends State<MCQStudent> {
  List<dynamic> _mcqs = [];
  Map<int, dynamic> _selectedAnswers = {};

  @override
  void initState() {
    super.initState();
    _fetchQuiz();
  }

  Future<void> _fetchQuiz() async {
    var quizDoc = await FirebaseFirestore.instance.collection('quiz').doc(widget.quizCode).get();
    if (quizDoc.exists) {
      setState(() {
        _mcqs = quizDoc.data()?['mcqs'] ?? [];
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Quiz not found.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz for Code: ${widget.quizCode}'),
      ),
      body: _mcqs.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _mcqs.length,
              itemBuilder: (context, index) {
                var mcq = _mcqs[index];
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${index + 1}. ${mcq['question']}'),
                      ...mcq['options'].map<Widget>((option) {
                        return RadioListTile(
                          value: option,
                          groupValue: _selectedAnswers[index],
                          title: Text(option),
                          onChanged: (value) {
                            setState(() {
                              _selectedAnswers[index] = value;
                            });
                          },
                        );
                      }).toList(),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
