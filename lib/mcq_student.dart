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
                  ],
                ),
              ),
            ),
    );
  }

  // This method builds the quiz view from the fetched string
  Widget _buildQuizView(String quizData) {
    // Split the string by '##' to extract each question block
    List<String> questionBlocks = quizData.split('##');

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(), // Disable internal scroll of ListView
      itemCount: questionBlocks.length,
      itemBuilder: (context, index) {
        String questionBlock = questionBlocks[index].trim();
        if (questionBlock.isEmpty) return SizedBox.shrink(); // Skip empty segments

        // Split by 'Correct Answer:' to separate options and correct answer
        List<String> parts = questionBlock.split('Correct Answer:');
        
        // First part is the question with options
        String questionWithOptions = parts[0].trim();
        String correctAnswer = parts.length > 1 ? parts[1].trim() : '';

        // Further split the question with options to extract the actual question and options
        List<String> questionParts = questionWithOptions.split('Question:');
        String questionText = questionParts[1].trim(); // The question text

        // Now extract options that appear after the '?' mark and exclude everything after the "Correct Answer:"
        String questionAndOptions = questionText.split('?')[0]; // Question without the options part
        String optionsPart = questionText.split('?')[1].trim(); // Options part after the question
        
        // Regular expression to capture options starting with A), B), C), D)
        RegExp regExp = RegExp(r'([A-D]\))\s([^\n]*)');
        Iterable<RegExpMatch> matches = regExp.allMatches(optionsPart);

        // Extract options from the matches
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
                String optionLetter = 'A)'; // Default option letter
                if (options.indexOf(option) == 1) optionLetter = 'B)';
                if (options.indexOf(option) == 2) optionLetter = 'C)';
                if (options.indexOf(option) == 3) optionLetter = 'D)';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0), // Add space between options
                  child: Row(
                    children: [
                      Text(optionLetter, style: TextStyle(fontSize: 16)), // Option letter on left
                      SizedBox(width: 10), // Space between letter and radio button
                      Radio<String>(
                        value: option,
                        groupValue: _selectedAnswers[index], // Grouping by question index
                        onChanged: (value) {
                          setState(() {
                            _selectedAnswers[index] = value;
                          });
                        },
                      ),
                      Text(option, style: TextStyle(fontSize: 16)), // Option text on the right
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
}
