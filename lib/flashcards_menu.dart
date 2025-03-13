import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'flashcards.dart';

class FlashcardsMenu extends StatefulWidget {
  @override
  _FlashcardsMenuState createState() => _FlashcardsMenuState();
}

class _FlashcardsMenuState extends State<FlashcardsMenu> {
  String? userEmail;
  List<Map<String, dynamic>> flashcardSets = [];

  @override
  void initState() {
    super.initState();
    _fetchFlashcardSets();
  }

  Future<void> _fetchFlashcardSets() async {
    try {
      userEmail = FirebaseAuth.instance.currentUser?.email;
      if (userEmail == null) return;

      QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore.instance
          .collection('leaderboard') // Adjust collection if needed
          .where('userEmail', isEqualTo: userEmail)
          .get();

      List<Map<String, dynamic>> flashcards = [];

      for (var doc in snapshot.docs) {
        Map<String, dynamic>? data = doc.data();
        if (data.containsKey('incorrectQuestions') && data['incorrectQuestions'] is List) {
          flashcards.add({
            'quizId': doc.id,
            'incorrectQuestions': List<Map<String, dynamic>>.from(data['incorrectQuestions']),
          });
        }
      }

      setState(() {
        flashcardSets = flashcards;
      });
    } catch (e) {
      print("Error fetching flashcards: $e");
    }
  }

  void _navigateToFlashcardsScreen(List<Map<String, dynamic>> incorrectQuestions) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FlashcardsScreen(incorrectQuestions: incorrectQuestions),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Flashcards Menu"),
        backgroundColor: Colors.deepOrange,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: flashcardSets.isEmpty
            ? Center(
                child: Text(
                  "No flashcard sets available.\nComplete a quiz to generate flashcards.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                ),
              )
            : ListView.builder(
                itemCount: flashcardSets.length,
                itemBuilder: (context, index) {
                  var flashcardSet = flashcardSets[index];

                  return Card(
                    elevation: 4,
                    margin: EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      contentPadding: EdgeInsets.all(16),
                      title: Text(
                        "Quiz ID: ${flashcardSet['quizId']}",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        "${flashcardSet['incorrectQuestions'].length} incorrect questions",
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                      trailing: Icon(Icons.arrow_forward_ios, color: Colors.deepOrange),
                      onTap: () => _navigateToFlashcardsScreen(flashcardSet['incorrectQuestions']),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
