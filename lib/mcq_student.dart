import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MCQStudent extends StatefulWidget {
  final String quizCode;

  MCQStudent({required this.quizCode});

  @override
  _MCQStudentState createState() => _MCQStudentState();
}

class _MCQStudentState extends State<MCQStudent> {
  String _mcqs = ''; // Now it's a string instead of a list
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
        _mcqs = quizDoc.data()?['mcqs'] ?? ''; // Assign the mcqs string directly
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
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView( // Make the body scrollable
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Quiz Questions:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    SizedBox(height: 20),
                    _buildQuizView(_mcqs),
                  ],
                ),
              ),
            ),
    );
  }

  // This method is responsible for displaying the questions and options from the string.
  Widget _buildQuizView(String quizData) {
    // Split the quiz data based on your format.
    // For example, you could split it by 'Question' or some other delimiter.
    // Here I am assuming each question is separated by a newline and options by ';'
    List<String> questions = quizData.split('Question'); // Split by the word "Question"
    
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(), // Disable internal scroll of ListView
      itemCount: questions.length,
      itemBuilder: (context, index) {
        String question = questions[index].trim();
        if (question.isEmpty) return SizedBox.shrink(); // Skip empty segments
        
        // Further splitting the question and options
        List<String> parts = question.split(';');
        String questionText = parts[0].trim(); // The question itself
        List<String> options = parts.sublist(1).map((e) => e.trim()).toList(); // Options

        return Padding(
          padding: const EdgeInsets.only(bottom: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${index + 1}. $questionText', style: TextStyle(fontSize: 18)),
              ...options.map<Widget>((option) {
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
    );
  }
}
