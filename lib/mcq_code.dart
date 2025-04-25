import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mcqapp/chatbot_page.dart';
import 'package:mcqapp/contactus.dart';
import 'quiz_attempt.dart';
import 'login.dart';
import 'flashcards_menu.dart';
import 'qr_scanner.dart';

class MCQCode extends StatefulWidget {
  final String? initialCode;

  MCQCode({this.initialCode});

  @override
  _MCQCodeState createState() => _MCQCodeState();
}

class _MCQCodeState extends State<MCQCode> {
  late TextEditingController _codeController;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: widget.initialCode ?? '');
  }

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

  void _navigateToFlashcardsMenu() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FlashcardsMenu()),
    );
  }

  void _navigateToQRScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => QRScannerPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Enter Quiz Code'),
        backgroundColor: Colors.deepPurple,
        actions: [
          PopupMenuButton<int>(
            onSelected: (value) {
              if (value == 1) {
                _navigateToFlashcardsMenu();
              } else if (value == 2) {
                _logout();
              } else if (value == 3) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ContactUsPage()),
                );
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<int>(
                value: 1,
                child: Row(
                  children: [
                    Icon(Icons.menu_book, color: Colors.black),
                    SizedBox(width: 10),
                    Text('Flashcards'),
                  ],
                ),
              ),
              PopupMenuItem<int>(
                value: 2,
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.black),
                    SizedBox(width: 10),
                    Text('Logout'),
                  ],
                ),
              ),
              PopupMenuItem<int>(
                value: 3,
                child: Row(
                  children: [
                    Icon(Icons.contact_page, color: Colors.black),
                    SizedBox(width: 10),
                    Text('Contact Us'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 40),
              Text(
                'Enter Quiz Code',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              Text(
                'Type or scan your quiz code to begin:',
                style: TextStyle(fontSize: 16, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 30),
              TextField(
                controller: _codeController,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.vpn_key),
                  hintText: 'Enter your quiz code',
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              SizedBox(height: 25),
              ElevatedButton.icon(
                onPressed: _navigateToQRScanner,
                icon: Icon(Icons.qr_code_scanner),
                label: Text('Scan QR Code'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                  textStyle: TextStyle(fontSize: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  String code = _codeController.text.trim();
                  if (code.isNotEmpty) {
                    _checkQuizStatus(code);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Please enter a quiz code.')),
                    );
                  }
                },
                icon: Icon(Icons.play_arrow),
                label: Text('Start Quiz'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                  textStyle: TextStyle(fontSize: 18, color: Colors.white),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ChatbotPage()),
                  );
                },
                icon: Icon(Icons.chat_bubble_outline, color: Colors.blue),
                label: Text('Chat with AI Assistant', style: TextStyle(color: Colors.blue)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.blue),
                  padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                  textStyle: TextStyle(fontSize: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
