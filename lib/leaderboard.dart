import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LeaderboardPage extends StatefulWidget {
  final String quizId;

  LeaderboardPage({required this.quizId});

  @override
  _LeaderboardPageState createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  late Future<List<Map<String, dynamic>>> _leaderboardData;

  @override
  void initState() {
    super.initState();
    _leaderboardData = _fetchLeaderboardData();
  }

  Future<List<Map<String, dynamic>>> _fetchLeaderboardData() async {
    final leaderboardRef = FirebaseFirestore.instance
        .collection('leaderboard')
        .doc(widget.quizId)
        .collection('user_email');

    final querySnapshot = await leaderboardRef.get();

    final leaderboardData = querySnapshot.docs.map((doc) {
      final data = doc.data();
      final score = data['score'] ?? 0;
      final totalTimeTaken = data['totalTimeTaken'] ?? 1; // Avoid division by zero
      final questionsPerSecond = totalTimeTaken > 0 ? score / totalTimeTaken : 0;

      return {
        'userEmail': doc.id,
        'score': score,
        'totalTimeTaken': totalTimeTaken,
        'questionsPerSecond': questionsPerSecond,
      };
    }).toList();

    leaderboardData.sort((a, b) {
      int scoreComparison = b['score'].compareTo(a['score']);
      return scoreComparison != 0
          ? scoreComparison
          : b['questionsPerSecond'].compareTo(a['questionsPerSecond']);
    });

    return leaderboardData;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Leaderboard for Quiz ${widget.quizId}'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _leaderboardData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No data available.'));
          }

          final leaderboardData = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                // Top 3 Display
                if (leaderboardData.isNotEmpty) _buildTopThree(leaderboardData),

                SizedBox(height: 20),
                Text(
                  'Leaderboard',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),

                // Remaining Leaderboard Entries
                Expanded(
                  child: ListView.builder(
                    itemCount: leaderboardData.length > 3 ? leaderboardData.length - 3 : 0,
                    itemBuilder: (context, index) {
                      final entry = leaderboardData[index + 3];
                      return _buildLeaderboardTile(entry, index + 4);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopThree(List<Map<String, dynamic>> leaderboardData) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        if (leaderboardData.length > 1) _buildTopUser(leaderboardData[1], 2), // Second place
        _buildTopUser(leaderboardData[0], 1), // First place
        if (leaderboardData.length > 2) _buildTopUser(leaderboardData[2], 3), // Third place
      ],
    );
  }

  Widget _buildTopUser(Map<String, dynamic> user, int rank) {
    return Column(
      children: [
        CircleAvatar(
          radius: rank == 1 ? 40 : 30, // Larger for first place
          backgroundColor: rank == 1 ? Colors.green : Colors.purple,
          child: CircleAvatar(
            radius: rank == 1 ? 35 : 25,
            backgroundImage: AssetImage('assets/placeholder.png'), // Placeholder image
            child: Text(
              rank.toString(),
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
        SizedBox(height: 5),
        Container(
          width: 80, // Set a width limit to prevent overflow
          child: Text(
            user['userEmail'],
            style: TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis, // Ellipsis for long text
          ),
        ),
        Text(
          'Score: ${user['score']}',
          style: TextStyle(color: Colors.grey[700]),
        ),
        Text(
          'Q/Sec: ${user['questionsPerSecond'].toStringAsFixed(2)}',
          style: TextStyle(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildLeaderboardTile(Map<String, dynamic> entry, int rank) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8.0),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: AssetImage('assets/placeholder.png'),
        ),
        title: Text(
          entry['userEmail'],
          overflow: TextOverflow.ellipsis, // Prevents overflow for long emails
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Score: ${entry['score']} | Total Time: ${entry['totalTimeTaken']}s',
              style: TextStyle(color: Colors.grey[700]),
            ),
            Text(
              'Q/Sec: ${entry['questionsPerSecond'].toStringAsFixed(2)}',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: Text(
          '#$rank',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange),
        ),
      ),
    );
  }
}
