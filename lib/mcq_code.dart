import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Auth
import 'mcq_student.dart'; // Import the MCQStudent screen
import 'login.dart'; // Import the login screen

class MCQCode extends StatefulWidget {
  @override
  _MCQCodeState createState() => _MCQCodeState();
}

class _MCQCodeState extends State<MCQCode> {
  String? enteredCode = '';

  // Function to check quiz status from Firestore
  Future<void> _checkQuizStatus(String code) async {
    try {
      // Reference to the quiz document with the entered code
      var quizDoc = await FirebaseFirestore.instance.collection('quiz').doc(code).get();

      if (quizDoc.exists) {
        // Check if the 'status' field is 'enabled'
        if (quizDoc['status'] == 'enabled') {
          // Redirect to MCQStudent screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MCQStudent(quizCode: code),
            ),
          );
        } else {
          // Show a popup if the quiz status is disabled
          _showQuizDisabledDialog();
        }
      } else {
        // Handle case where the code doesn't exist in the collection
        _showInvalidCodeDialog();
      }
    } catch (e) {
      // Error handling
      print('Error checking quiz status: $e');
    }
  }

  // Show dialog when quiz is disabled
  void _showQuizDisabledDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Quiz Disabled'),
          content: Text('This quiz is currently disabled. Please try another one.'),
          actions: [
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

  // Show dialog when code is invalid
  void _showInvalidCodeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Invalid Code'),
          content: Text('The quiz code you entered is invalid or does not exist.'),
          actions: [
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

  // Function to handle logout
  void _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      // Redirect the user to the login screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()), // Navigate to LoginPage (login.dart)
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
          // Popup menu with a logout option
          PopupMenuButton<int>(
            onSelected: (value) {
              if (value == 1) {
                _logout(); // Handle logout when option 1 is selected
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Enter the quiz code to access the MCQs:'),
            SizedBox(height: 20),
            TextField(
              onChanged: (value) {
                setState(() {
                  enteredCode = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Enter quiz code',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (enteredCode != null && enteredCode!.isNotEmpty) {
                  // Check the quiz status before proceeding
                  _checkQuizStatus(enteredCode!);
                }
              },
              child: Text('Enter'),
            ),
          ],
        ),
      ),
    );
  }
}
