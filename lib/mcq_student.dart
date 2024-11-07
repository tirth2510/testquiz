import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MCQStudent extends StatefulWidget {
  final String quizCode;

  MCQStudent({required this.quizCode});

  @override
  _MCQStudentState createState() => _MCQStudentState();
}

class _MCQStudentState extends State<MCQStudent> {
  String _mcqs = ''; // Holds the raw MCQs string from Firestore
  Map<int, String?> _selectedAnswers = {}; // Stores the selected answers by question index
  List<String> _correctAnswers = []; // Stores the correct answers for comparison (A, B, C, D)
  int _score = 0; // Track the user's score

  @override
  void initState() {
    super.initState();
    _fetchQuiz();
  }

  // Fetch quiz data from Firestore
  Future<void> _fetchQuiz() async {
    var quizDoc = await FirebaseFirestore.instance.collection('quiz').doc(widget.quizCode).get();
    if (quizDoc.exists) {
      setState(() {
        _mcqs = quizDoc.data()?['mcqs'] ?? ''; // Fetch the MCQs string from Firestore
        _parseCorrectAnswers(); // Parse correct answers after loading the quiz
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Quiz not found.')));
    }
  }

  // This method parses the correct answers from the MCQ string
  void _parseCorrectAnswers() {
    List<String> questionBlocks = _mcqs.split('##');
    
    // Remove any empty trailing blocks
    questionBlocks.removeWhere((block) => block.isEmpty);

    for (var questionBlock in questionBlocks) {
      if (questionBlock.isEmpty) continue;

      List<String> parts = questionBlock.split('Correct Answer:');
      String correctAnswer = parts.length > 1 ? parts[1].trim().toLowerCase() : '';
      
      // Store the correct answer as A, B, C, or D
      _correctAnswers.add(correctAnswer);
    }

    // Debugging check to ensure the number of correct answers matches the number of questions
    if (_correctAnswers.length != questionBlocks.length) {
      print('Error: The number of correct answers does not match the number of questions!');
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
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Quiz Questions:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    SizedBox(height: 20),
                    _buildQuizView(_mcqs), // Build the quiz view from the string
                    SizedBox(height: 20),
                    Center(
                      child: ElevatedButton(
                        onPressed: _showSubmitDialog, // Call the function on press
                        child: Text('Submit'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // This method builds the quiz view from the fetched string
  Widget _buildQuizView(String quizData) {
    List<String> questionBlocks = quizData.split('##');

    // Remove any empty trailing blocks
    questionBlocks.removeWhere((block) => block.isEmpty);

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: questionBlocks.length,
      itemBuilder: (context, index) {
        // Ensure we're not going out of bounds of _correctAnswers
        if (index >= _correctAnswers.length) {
          return SizedBox.shrink(); // If the index is out of bounds, return an empty widget
        }

        String questionBlock = questionBlocks[index].trim();
        if (questionBlock.isEmpty) return SizedBox.shrink(); // Skip empty segments

        List<String> parts = questionBlock.split('Correct Answer:');
        String questionWithOptions = parts[0].trim();
        String correctAnswer = parts.length > 1 ? parts[1].trim().toLowerCase() : '';

        List<String> questionParts = questionWithOptions.split('Question:');
        String questionText = questionParts[1].trim();
        String questionAndOptions = questionText.split('?')[0];
        String optionsPart = questionText.split('?')[1].trim();

        RegExp regExp = RegExp(r'([A-D]\))\s([^\n]*)');
        Iterable<RegExpMatch> matches = regExp.allMatches(optionsPart);

        List<String> options = [];
        for (var match in matches) {
          options.add(match.group(2)?.trim() ?? '');
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Question ${index + 1}: $questionAndOptions?', style: TextStyle(fontSize: 18)),
              ...options.map<Widget>((option) {
                String optionLetter = 'A)';
                if (options.indexOf(option) == 1) optionLetter = 'B)';
                if (options.indexOf(option) == 2) optionLetter = 'C)';
                if (options.indexOf(option) == 3) optionLetter = 'D)';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Text(optionLetter, style: TextStyle(fontSize: 16)),
                      SizedBox(width: 10),
                      Radio<String>(
                        value: option,
                        groupValue: _selectedAnswers[index],
                        onChanged: (value) {
  setState(() {
    if (value != null) {
      _selectedAnswers[index] = value;

      // Map the selected option to A, B, C, or D
      String selectedLetter = '';
      if (options.indexOf(value) == 0) selectedLetter = 'a';
      if (options.indexOf(value) == 1) selectedLetter = 'b';
      if (options.indexOf(value) == 2) selectedLetter = 'c';
      if (options.indexOf(value) == 3) selectedLetter = 'd';

      // Debug: print the selected answer and correct answer
      print('Selected answer for Question ${index + 1}: $selectedLetter');
      print('Correct answer for Question ${index + 1}: ${_correctAnswers[index]}');

      // Compare selected letter with correct answer
      if (selectedLetter == _correctAnswers[index]) {
        _score++;
        print('Correct! Score: $_score');
      } else {
        print('Incorrect. Score: $_score');
      }
    }
  });
}

                      ),
                      Text(option, style: TextStyle(fontSize: 16)),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  // Function to show the confirmation dialog when the submit button is pressed
  void _showSubmitDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Submission'),
          content: Text('Are you sure you want to submit your answers?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _submitAnswers(); // Call the submit function
              },
              child: Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  // Handle the submission of answers and calculate the score
  void _submitAnswers() {
    // Show the score in a pop-up
    _showScorePopup();
  }

  // Function to show the score in a pop-up after submission
  void _showScorePopup() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Your Score'),
          content: Text('You scored $_score out of ${_correctAnswers.length}.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
