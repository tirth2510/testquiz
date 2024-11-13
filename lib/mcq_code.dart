import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'quiz_attempt.dart';
import 'login.dart';

class MCQCode extends StatefulWidget {
  @override
  _MCQCodeState createState() => _MCQCodeState();
}

class _MCQCodeState extends State<MCQCode> {
  String? enteredCode = '';

  Future<void> _checkQuizStatus(String code) async {
    try {
      var quizDoc = await FirebaseFirestore.instance.collection('quiz').doc(code).get();

      if (quizDoc.exists) {
        if (quizDoc['status'] == 'enabled') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => QuizAttempt(
                userEmail: FirebaseAuth.instance.currentUser!.email ?? '',
                quizId: code,
              ),
            ),
          );
        } else {
          _showCustomDialog(
            title: 'Quiz Disabled',
            content: 'This quiz is currently disabled. Please try another one.',
          );
        }
      } else {
        _showCustomDialog(
          title: 'Invalid Code',
          content: 'The quiz code you entered is invalid or does not exist.',
        );
      }
    } catch (e) {
      print('Error checking quiz status: $e');
    }
  }

  void _showCustomDialog({required String title, required String content}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text(content),
          actions: [
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        );
      },
    );
  }

  void _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    } catch (e) {
      print('Error logging out: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Enter Quiz Code'),
        actions: [
          PopupMenuButton<int>(
            onSelected: (value) {
              if (value == 1) {
                _logout();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<int>(
                value: 1,
                child: Text('Logout'),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 20),
            Text(
              'Enter Quiz Code',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            Text(
              'Enter the quiz code to access the MCQs:',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30),
            TextField(
              onChanged: (value) {
                setState(() {
                  enteredCode = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Enter quiz code',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                if (enteredCode != null && enteredCode!.isNotEmpty) {
                  _checkQuizStatus(enteredCode!);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter a quiz code.')),
                  );
                }
              },
              child: Text('Enter'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 15, horizontal: 50),
                textStyle: TextStyle(fontSize: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                backgroundColor: Colors.orange,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
