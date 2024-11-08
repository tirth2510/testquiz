import 'dart:io';
import 'dart:convert'; // For JSON decoding
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:mcqapp/quiz_attempt.dart';
import 'package:path/path.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firebase Firestore
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Authentication
import 'mcq_results.dart'; // Import the MCQResults screen
import 'mcq_code.dart'; // Import the MCQCode screen
import 'login.dart'; // Import your login page
import 'quizzes.dart'; // Import the new quizzes page
import 'quiz_attempt.dart'; // Import the new QuizAttempt screen
import 'dart:math'; // For generating random code

class MCQGenerator extends StatefulWidget {
  @override
  _MCQGeneratorState createState() => _MCQGeneratorState();
}

class _MCQGeneratorState extends State<MCQGenerator> {
  File? _file;
  String? _textInput;
  bool _isLoading = false;

  final TextEditingController _textController = TextEditingController();
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey = GlobalKey<ScaffoldMessengerState>();

  // Function to generate random 6-digit alphanumeric code
  String _generateRandomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random();
    return List.generate(6, (index) => chars[rand.nextInt(chars.length)]).join();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'txt', 'docx'],
    );
    if (result != null) {
      setState(() {
        _file = File(result.files.single.path!);
        _textInput = null; // Clear text input when a file is picked
        _textController.clear(); // Clear the text field
      });
    }
  }

  Future<void> _generateMCQs(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });

    if (_file == null && (_textInput == null || _textInput!.isEmpty)) {
      setState(() {
        _isLoading = false; // Stop loading indicator
      });
      _scaffoldKey.currentState?.showSnackBar(
        SnackBar(content: Text('Please upload a file or enter text.')),
      );
      return;
    }

    // Get the current user's email from Firebase Authentication
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
      });
      _scaffoldKey.currentState?.showSnackBar(
        SnackBar(content: Text('Please log in to continue.')),
      );
      return;
    }
    String userEmail = user.email ?? 'Unknown';

    var request = http.MultipartRequest('POST', Uri.parse('http://192.168.1.13:5000/generate'));

    if (_file != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'file',
        _file!.path,
        filename: basename(_file!.path),
      ));
    }

    if (_textInput != null && _textInput!.isNotEmpty) {
      request.fields['text'] = _textInput!;
    }

    try {
      var response = await request.send();
      if (response.statusCode == 200) {
        var responseBody = await response.stream.bytesToString();
        final Map<String, dynamic> jsonResponse = jsonDecode(responseBody);
        String mcqs = jsonResponse['mcqs'];

        String randomCode = _generateRandomCode();

        // Get the current user's document reference in Firestore
        var userDocRef = FirebaseFirestore.instance.collection('users').doc(userEmail);

        // Store the random code in the 'timepass' sub-collection under the user's document
        var timepassDocRef = userDocRef.collection('timepass').doc(randomCode);

        await timepassDocRef.set({
          'status': 'enabled', // Add 'status' field as 'enabled' here
          'generated_by': userEmail, // Save the email of the logged-in user
          'mcqs': mcqs, // Store the MCQs in the 'mcqs' field
        });

        // Create a separate 'quiz' collection and store the random code as document ID
        var quizDocRef = FirebaseFirestore.instance.collection('quiz').doc(randomCode);

        // Store 'status', 'mcqs', and 'generated_by' fields in the 'quiz' collection
        await quizDocRef.set({
          'status': 'enabled', // Add 'status' field as 'enabled' here as well
          'generated_by': userEmail, // Save the email of the logged-in user
          'mcqs': mcqs, // Store the MCQs in the 'mcqs' field
        });

        // Navigate to the MCQResults screen after successful submission
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MCQResults(
                mcqs: mcqs,
                randomCode: randomCode,
              ),
            ),
          );
        });
      } else {
        var responseBody = await response.stream.bytesToString();
        print('Error: ${response.statusCode}, Details: $responseBody');
      }
    } catch (e) {
      print('Failed to generate MCQs: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      this.context,
      MaterialPageRoute(builder: (context) => LoginPage()), // Navigate to login page
    );
  }

  void _deleteFile() {
    setState(() {
      _file = null; // Clear the selected file
      _textInput = null; // Optionally clear text input
      _textController.clear(); // Clear the text field
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('MCQ Generator'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'My quizzes') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => QuizzesPage()), // Navigate to quizzes page
                );
              } else if (value == 'Logout') {
                _logout(); // Perform logout
              }
            },
            itemBuilder: (BuildContext context) {
              return {'My quizzes', 'Logout'}.map((String choice) {
                return PopupMenuItem<String>(
                  value: choice,
                  child: Text(choice),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Center(child: Text('Generate MCQs from Your Text', style: TextStyle(fontSize: 24))),
            SizedBox(height: 20),

            ElevatedButton(
              onPressed: _pickFile,
              child: Text('Upload your document (PDF, TXT, DOCX)'),
            ),

            if (_file != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Text('Selected File: ${basename(_file!.path)}'),
              ),

            if (_file != null)
              ElevatedButton(
                onPressed: _deleteFile,
                child: Text('Delete Selected File'),
              ),

            if (_file == null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(),
                  TextFormField(
                    controller: _textController,
                    maxLines: 6,
                    decoration: InputDecoration(
                      hintText: 'Or enter text directly',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _textInput = value;
                      });
                    },
                  ),
                ],
              ),
            SizedBox(height: 30),

            _isLoading
                ? Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: () => _generateMCQs(context),
                    child: Text('Generate MCQs'),
                  ),

            SizedBox(height: 30),

            // Button to attempt quiz
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => QuizAttempt(
                      userEmail: FirebaseAuth.instance.currentUser!.email ?? 'Unknown', // Pass current user's email
                      quizId: 'VNZVEG', // The specified quiz document ID
                    ),
                  ),
                );
              },
              child: Text('Attempt Quiz'),
            ),
          ],
        ),
      ),
    );
  }
}
