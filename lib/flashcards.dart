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

class _FlashcardsScreenState extends State<FlashcardsScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  List<String> _explanations = [];
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _fetchExplanations();

    // Animation Controller
    _controller = AnimationController(vsync: this, duration: Duration(milliseconds: 300));
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
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
        title: Text("Flashcards", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepOrange,
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.white), // Cross button
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
        child: Column(
          children: [
            // Progress Indicator
            LinearProgressIndicator(
              value: (_currentIndex + 1) / widget.incorrectQuestions.length,
              backgroundColor: Colors.grey[300],
              color: Colors.deepOrange,
            ),
            SizedBox(height: 10),
            Text(
              "Question ${_currentIndex + 1} of ${widget.incorrectQuestions.length}",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 10),

            // Flashcard UI (Expanded to prevent overflow)
            Expanded(
              child: ScaleTransition(
                scale: _animation,
                child: Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  color: Colors.white,
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: SingleChildScrollView( // Ensures scrolling if needed
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Question Text
                          Text(
                            "Q: ${question['question']}",
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          SizedBox(height: 12),

                          // Answer Options
                          Column(
                            children: question['options'].map<Widget>((opt) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 5.0),
                              child: Container(
                                padding: EdgeInsets.all(10),
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: opt.startsWith(question['correctAnswer']) ? Colors.green[100] : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  opt,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: opt.startsWith(question['correctAnswer']) ? Colors.green[800] : Colors.black87,
                                  ),
                                ),
                              ),
                            )).toList(),
                          ),

                          SizedBox(height: 15),

                          // Selected Answer
                          Text(
                            "Your Answer: ${question['selectedAnswer']}",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
                          ),

                          // Correct Answer
                          Text(
                            "Correct Answer: ${question['correctAnswer']}",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green[700]),
                          ),

                          SizedBox(height: 15),

                          // Explanation
                          Text("Explanation:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          SizedBox(height: 5),
                          Container(
                            padding: EdgeInsets.all(12),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.orange[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: SingleChildScrollView(
                              child: Text(
                                _explanations[_currentIndex],
                                style: TextStyle(fontSize: 16, color: Colors.black87),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Navigation Buttons
            Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentIndex > 0)
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _currentIndex--;
                          _controller.forward(from: 0.0); // Restart animation
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text("Previous", style: TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                  if (_currentIndex < widget.incorrectQuestions.length - 1)
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _currentIndex++;
                          _controller.forward(from: 0.0); // Restart animation
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text("Next", style: TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
