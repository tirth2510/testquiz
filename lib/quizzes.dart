import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Auth

class QuizzesPage extends StatefulWidget {
  @override
  _QuizzesPageState createState() => _QuizzesPageState();
}

class _QuizzesPageState extends State<QuizzesPage> {
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser; // Get the current logged-in user
  }

  // Function to toggle the status
  Future<void> _toggleStatus(String documentId, bool currentStatus) async {
    try {
      String userEmail = _currentUser?.email ?? '';
      var docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userEmail)
          .collection('timepass')
          .doc(documentId);

      // Update the 'status' field in Firestore
      await docRef.update({'status': currentStatus ? 'disabled' : 'enabled'});
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
                  .snapshots(), // Listen to Firestore snapshots
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
                    var currentStatus = quizDoc['status'] == 'enabled'; // Check if status is 'enabled'

                    return ListTile(
                      title: Text('Quiz ID: $quizId'),
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
