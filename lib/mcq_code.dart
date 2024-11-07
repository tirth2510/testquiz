import 'package:flutter/material.dart';
import 'mcq_student.dart'; // Import the MCQStudent screen

class MCQCode extends StatefulWidget {
  @override
  _MCQCodeState createState() => _MCQCodeState();
}

class _MCQCodeState extends State<MCQCode> {
  String? enteredCode = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Enter Quiz Code'),
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MCQStudent(quizCode: enteredCode!),
                    ),
                  );
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
