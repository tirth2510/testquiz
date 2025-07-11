import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:mcqapp/flashcards.dart';
import 'mcq_code.dart';

class QuizAttempt extends StatefulWidget {
  final String userEmail;
  final String quizId;

  QuizAttempt({required this.userEmail, required this.quizId});

  @override
  _QuizAttemptState createState() => _QuizAttemptState();
}

class _QuizAttemptState extends State<QuizAttempt> {
  List<dynamic> _allQuestions = [];
  List<dynamic> _questions = [];
  Set<int> _askedQuestions = {};
  int _currentQuestionIndex = 0;
  bool _isLoading = true;
  int? _selectedOption;
  int _score = 0;
  int _totalAnswered = 0;
  List<int> _timePerQuestion = [];
  DateTime? _questionStartTime;

  int totalQuestionsToAsk = 10; // <-- default fallback (will override after fetching)

  @override
  void initState() {
    super.initState();
    _fetchQuizSettingsAndData(); // <-- New combined function
  }

  // Fetch both totalQuestionsToAsk and quiz data
  Future<void> _fetchQuizSettingsAndData() async {
    try {
      // Fetch totalQuestionsToAsk first from Firestore
      var quizDoc = await FirebaseFirestore.instance.collection('quiz').doc(widget.quizId).get();

      if (quizDoc.exists && quizDoc.data()!.containsKey('totalQuestionsToAsk')) {
        totalQuestionsToAsk = quizDoc['totalQuestionsToAsk'];
      } else {
        totalQuestionsToAsk = 10; // fallback if not found
      }

      // Now fetch questions
      final url = 'https://flaskdisplay.onrender.com/fetch_quiz/${widget.userEmail}/${widget.quizId}';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _allQuestions = data['mcqs'];
          _questions = _allQuestions.where((q) => q['difficulty'] == 'Easy').take(5).toList();
          _askedQuestions.addAll(_questions.map((q) => _allQuestions.indexOf(q)));
          _isLoading = false;
          _initializeTimerForCurrentQuestion();
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching quiz settings and data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _initializeTimerForCurrentQuestion() {
    if (_timePerQuestion.length <= _currentQuestionIndex) {
      _timePerQuestion.add(0);
    }
    _questionStartTime = DateTime.now();
  }

  void _updateTimeForCurrentQuestion() {
    if (_questionStartTime != null) {
      final timeSpent = DateTime.now().difference(_questionStartTime!).inSeconds;
      _timePerQuestion[_currentQuestionIndex] += timeSpent;
      print("Time taken for question ${_currentQuestionIndex + 1}: ${_timePerQuestion[_currentQuestionIndex]} seconds");
    }
  }

  void _nextQuestion() {
    if (_selectedOption == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select an answer before proceeding.")),
      );
      return;
    }

    final correctAnswer = _questions[_currentQuestionIndex]['correctAnswer'];
    final selectedAnswer = _questions[_currentQuestionIndex]['options'][_selectedOption!][0];

    if (selectedAnswer == correctAnswer) {
      _score++;
    }

    _totalAnswered++;
    _updateTimeForCurrentQuestion();

    double scoreRatio = _score / _totalAnswered;
    String nextDifficulty;

    if (_totalAnswered >= 5 && _questions.length < totalQuestionsToAsk) {
      if (scoreRatio <= 0.33) {
        nextDifficulty = 'Easy';
      } else if (scoreRatio <= 0.66) {
        nextDifficulty = 'Medium';
      } else {
        nextDifficulty = 'Hard';
      }

      List<dynamic> nextQuestions = _allQuestions
          .where((q) => q['difficulty'] == nextDifficulty && !_askedQuestions.contains(_allQuestions.indexOf(q)))
          .toList();

      if (nextQuestions.isEmpty) {
        nextQuestions = _allQuestions
            .where((q) => !_askedQuestions.contains(_allQuestions.indexOf(q)))
            .toList();
      }

      if (nextQuestions.isNotEmpty) {
        _questions.add(nextQuestions.first);
        _askedQuestions.add(_allQuestions.indexOf(nextQuestions.first));
      }
    }

    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedOption = null;
        _initializeTimerForCurrentQuestion();
      });
    } else {
      _showFinalScoreDialog();
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      _updateTimeForCurrentQuestion();
      setState(() {
        _currentQuestionIndex--;
        _selectedOption = null;
        _initializeTimerForCurrentQuestion();
      });
    }
  }

  void _showFinalScoreDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Submit Quiz"),
        content: Text("Are you sure you want to submit the quiz?"),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              _showScorePopup();
            },
            child: Text("Submit"),
          ),
        ],
      ),
    );
  }

  Future<void> _saveResultsToFirestore() async {
    int totalTimeTaken = _timePerQuestion.reduce((a, b) => a + b);

    final quizData = {
      'score': _score,
      'timePerQuestion': _timePerQuestion,
      'totalTimeTaken': totalTimeTaken,
    };

    final leaderboardRef = FirebaseFirestore.instance
        .collection('leaderboard')
        .doc(widget.quizId)
        .collection('user_email')
        .doc(widget.userEmail);

    await leaderboardRef.set(quizData);
    print("Quiz results saved to Firestore: $quizData");
  }

  void _showScorePopup() async {
    await _saveResultsToFirestore();

    List<Map<String, dynamic>> incorrectQuestions = [];
    for (int i = 0; i < _questions.length; i++) {
      String correctAnswer = _questions[i]['correctAnswer'];
      String selectedAnswer = _questions[i]['options'][_selectedOption!][0];

      if (selectedAnswer != correctAnswer) {
        incorrectQuestions.add({
          'question': _questions[i]['question'],
          'options': _questions[i]['options'],
          'correctAnswer': correctAnswer,
          'selectedAnswer': selectedAnswer,
        });
      }
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => FlashcardsScreen(incorrectQuestions: incorrectQuestions),
      ),
    );
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
      appBar: AppBar(
        title: Text('Quiz Attempt'),
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: _showFinalScoreDialog,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: (_currentQuestionIndex + 1) / totalQuestionsToAsk,
                    backgroundColor: Colors.grey[300],
                    color: Colors.orange,
                  ),
                ),
                SizedBox(width: 10),
                Text('${_currentQuestionIndex + 1}/$totalQuestionsToAsk'),
              ],
            ),
            SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    question['question'],
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    question['difficulty'] ?? 'Unknown',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[800],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Column(
              children: List.generate(4, (index) {
                String option = question['options'][index];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedOption = index;
                    });
                  },
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 5),
                    padding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                    decoration: BoxDecoration(
                      color: _selectedOption == index ? Colors.orange[100] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Container(
                          height: 30,
                          width: 30,
                          decoration: BoxDecoration(
                            color: _selectedOption == index ? Colors.orange : Colors.grey[400],
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Center(
                            child: Text(
                              option[0],
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            option.substring(3),
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
            Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentQuestionIndex > 0)
                  ElevatedButton(
                    onPressed: _previousQuestion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    child: Text('Previous'),
                  ),
                ElevatedButton(
                  onPressed: _currentQuestionIndex == totalQuestionsToAsk - 1
                      ? _showFinalScoreDialog
                      : _nextQuestion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  child: Text(_currentQuestionIndex == totalQuestionsToAsk - 1 ? 'Submit' : 'Next'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
