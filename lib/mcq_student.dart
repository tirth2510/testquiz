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
  Map<int, dynamic> _selectedAnswers = {}; // Stores the selected answers by question index

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

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: questionBlocks.length,
      itemBuilder: (context, index) {
        String questionBlock = questionBlocks[index].trim();
        if (questionBlock.isEmpty) return SizedBox.shrink(); // Skip empty segments

        List<String> parts = questionBlock.split('Correct Answer:');
        String questionWithOptions = parts[0].trim();
        String correctAnswer = parts.length > 1 ? parts[1].trim() : '';

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
                            _selectedAnswers[index] = value;
                          });
                        },
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

  // Handle the submission of answers (you can implement further logic here)
  void _submitAnswers() {
    // You can perform any action here such as saving answers or navigating to another page
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Your answers have been submitted!')));
    // Example: Navigate to a result page or back to the previous screen
    // Navigator.pop(context); // If you want to go back
  }
}
