import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'leaderboard.dart';

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

  // Toggle quiz status (enabled/disabled)
  Future<void> _toggleStatus(String documentId, bool currentStatus) async {
    try {
      String userEmail = _currentUser?.email ?? '';

      var timepassDocRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userEmail)
          .collection('timepass')
          .doc(documentId);

      var quizDocRef = FirebaseFirestore.instance.collection('quiz').doc(documentId);

      await timepassDocRef.update({'status': currentStatus ? 'disabled' : 'enabled'});
      await quizDocRef.update({'status': currentStatus ? 'disabled' : 'enabled'});
    } catch (e) {
      print('Error updating status: $e');
    }
  }

  // Update totalQuestionsToAsk
  Future<void> _updateTotalQuestions(String documentId, int selectedTotal) async {
    try {
      String userEmail = _currentUser?.email ?? '';

      var timepassDocRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userEmail)
          .collection('timepass')
          .doc(documentId);

      var quizDocRef = FirebaseFirestore.instance.collection('quiz').doc(documentId);

      await timepassDocRef.update({'totalQuestionsToAsk': selectedTotal});
      await quizDocRef.update({'totalQuestionsToAsk': selectedTotal});
    } catch (e) {
      print('Error updating total questions: $e');
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
                    var currentTotalQuestions = quizDoc.data().toString().contains('totalQuestionsToAsk')
                        ? quizDoc['totalQuestionsToAsk']
                        : 10; // default 10 if not found

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 4,
                        child: ListTile(
                          title: Text(
                            'Quiz ID: $quizId',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentStatus ? 'Status: Enabled' : 'Status: Disabled',
                                style: TextStyle(color: currentStatus ? Colors.green : Colors.red),
                              ),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  Text('Total Questions: ', style: TextStyle(fontSize: 16)),
                                  SizedBox(width: 10),
                                  DropdownButton<int>(
                                    value: currentTotalQuestions,
                                    items: [10, 15, 20, 25].map((value) {
                                      return DropdownMenuItem<int>(
                                        value: value,
                                        child: Text('$value'),
                                      );
                                    }).toList(),
                                    onChanged: (newValue) {
                                      if (newValue != null) {
                                        _updateTotalQuestions(quizId, newValue);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LeaderboardPage(quizId: quizId),
                              ),
                            );
                          },
                          trailing: Switch(
                            value: currentStatus,
                            activeColor: Colors.orange,
                            onChanged: (value) {
                              _toggleStatus(quizId, currentStatus);
                            },
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
