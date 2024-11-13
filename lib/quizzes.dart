import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'leaderboard.dart'; // Import the LeaderboardPage

class QuizzesPage extends StatefulWidget {
  @override
  _QuizzesPageState createState() => _QuizzesPageState();
}

class _QuizzesPageState extends State<QuizzesPage> {
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
  }

  // Function to toggle the status
  Future<void> _toggleStatus(String documentId, bool currentStatus) async {
    try {
      String userEmail = _currentUser?.email ?? '';
      
      // Update the status in the 'timepass' subcollection
      var timepassDocRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userEmail)
          .collection('timepass')
          .doc(documentId);

      await timepassDocRef.update({'status': currentStatus ? 'disabled' : 'enabled'});

      // Update the status in the main 'quiz' collection
      var quizDocRef = FirebaseFirestore.instance.collection('quiz').doc(documentId);

      await quizDocRef.update({'status': currentStatus ? 'disabled' : 'enabled'});
    } catch (e) {
      print('Error updating status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Quizzes'),
      ),
      body: _currentUser == null
          ? Center(child: Text('No user logged in'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(_currentUser!.email)
                  .collection('timepass')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No quizzes found.'));
                }

                final quizDocs = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: quizDocs.length,
                  itemBuilder: (context, index) {
                    var quizDoc = quizDocs[index];
                    var quizId = quizDoc.id;
                    var currentStatus = quizDoc['status'] == 'enabled';

                    return ListTile(
                      title: GestureDetector(
                        child: Text('Quiz ID: $quizId'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LeaderboardPage(quizId: quizId),
                            ),
                          );
                        },
                      ),
                      trailing: Switch(
                        value: currentStatus,
                        onChanged: (value) {
                          _toggleStatus(quizId, currentStatus);
                        },
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
