import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LeaderboardPage extends StatefulWidget {
  @override
  _LeaderboardPageState createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Leaderboard'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('leaderboard').orderBy('score', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No leaderboard data available'));
          }

          final leaderboardData = snapshot.data!.docs;

          return ListView.builder(
            itemCount: leaderboardData.length,
            itemBuilder: (context, index) {
              final user = leaderboardData[index];
              final userName = user['name'] ?? 'Anonymous';
              final score = user['score'] ?? 0;

              return ListTile(
                leading: CircleAvatar(
                  child: Text('#${index + 1}'), // Rank
                ),
                title: Text(userName),
                subtitle: Text('Score: $score'),
              );
            },
          );
        },
      ),
    );
  }
}
