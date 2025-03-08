import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'mcq_results.dart';
import 'login.dart';
import 'quizzes.dart';
import 'dart:math';

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
        _textInput = null;
        _textController.clear();
      });
    }
  }

  Future<void> _generateMCQs(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });

    // Check if a file or text is provided
    if (_file == null && (_textInput == null || _textInput!.isEmpty)) {
      setState(() {
        _isLoading = false;
      });
      _scaffoldKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('Please upload a file or enter text to generate MCQs.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

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

    var request = http.MultipartRequest('POST', Uri.parse('http://192.168.29.108:5000/generate'));

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

        var userDocRef = FirebaseFirestore.instance.collection('users').doc(userEmail);
        var timepassDocRef = userDocRef.collection('timepass').doc(randomCode);
        await timepassDocRef.set({
          'status': 'enabled',
          'generated_by': userEmail,
          'mcqs': mcqs,
        });

        var quizDocRef = FirebaseFirestore.instance.collection('quiz').doc(randomCode);
        await quizDocRef.set({
          'status': 'enabled',
          'generated_by': userEmail,
          'mcqs': mcqs,
        });

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
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  void _deleteFile() {
    setState(() {
      _file = null;
      _textInput = null;
      _textController.clear();
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
                  MaterialPageRoute(builder: (context) => QuizzesPage()),
                );
              } else if (value == 'Logout') {
                _logout();
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
            Center(
              child: Text(
                'Generate MCQs from Your Text',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: _pickFile,
              icon: Icon(Icons.upload_file, color: Colors.white),
              label: Text('Upload Document (PDF, TXT, DOCX)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            if (_file != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Text(
                  'Selected File: ${basename(_file!.path)}',
                  style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                ),
              ),

            if (_file != null)
              ElevatedButton.icon(
                onPressed: _deleteFile,
                icon: Icon(Icons.delete, color: Colors.white),
                label: Text('Delete Selected File'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
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
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
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
                    child: Text('Generate MCQs', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
