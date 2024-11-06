import 'package:flutter/material.dart';

class MCQResults extends StatelessWidget {
  final String mcqs;
  final String randomCode;

  // Constructor to accept MCQs and random code
  MCQResults({required this.mcqs, required this.randomCode});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('MCQ Results'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Center(
              child: Text(
                'MCQs Generated',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Random Code: $randomCode',
              style: TextStyle(fontSize: 18),
            ),
            Divider(),
            SizedBox(height: 20),
            Text(
              mcqs,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                // Add any action here if needed
                // For example, navigating back or saving data
                Navigator.pop(context);
              },
              child: Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}
