import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class LeaderboardPage extends StatefulWidget {
  final String quizId;

  LeaderboardPage({required this.quizId});

  @override
  _LeaderboardPageState createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  late Future<List<Map<String, dynamic>>> _leaderboardData;
  int? _touchedIndex;

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
      final totalTimeTaken = data['totalTimeTaken'] ?? 1;
      final questionsPerSecond =
          totalTimeTaken > 0 ? score / totalTimeTaken : 0;

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
                if (leaderboardData.isNotEmpty)
                  _buildTopThree(leaderboardData),

                SizedBox(height: 20),
                Text(
                  'Leaderboard',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),

                // Scatter Plot
                SizedBox(
                  height: 280,
                  child: Stack(
                    children: [
                      _buildScatterChart(leaderboardData),
                      if (_touchedIndex != null &&
                          _touchedIndex! < leaderboardData.length)
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Card(
                            color: Colors.white,
                            elevation: 5,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Email: ${leaderboardData[_touchedIndex!]['userEmail']}',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text('Score: ${leaderboardData[_touchedIndex!]['score']}'),
                                  Text(
                                    'Q/Sec: ${leaderboardData[_touchedIndex!]['questionsPerSecond'].toStringAsFixed(2)}',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(height: 10),

                // Leaderboard List
                Expanded(
                  child: ListView.builder(
                    itemCount:
                        leaderboardData.length > 3 ? leaderboardData.length - 3 : 0,
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
        if (leaderboardData.length > 1)
          _buildTopUser(leaderboardData[1], 2),
        _buildTopUser(leaderboardData[0], 1),
        if (leaderboardData.length > 2)
          _buildTopUser(leaderboardData[2], 3),
      ],
    );
  }

  Widget _buildTopUser(Map<String, dynamic> user, int rank) {
    return Column(
      children: [
        CircleAvatar(
          radius: rank == 1 ? 40 : 30,
          backgroundColor: rank == 1 ? Colors.green : Colors.purple,
          child: Text(
            rank.toString(),
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
        SizedBox(height: 5),
        Container(
          width: 80,
          child: Text(
            user['userEmail'],
            style: TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text('Score: ${user['score']}', style: TextStyle(color: Colors.grey[700])),
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
          child: Text(entry['userEmail'][0].toUpperCase()),
        ),
        title: Text(
          entry['userEmail'],
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Score: ${entry['score']} | Time: ${entry['totalTimeTaken']}s',
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

  Widget _buildScatterChart(List<Map<String, dynamic>> data) {
  final scores = data.map((e) => (e['score'] as num).toDouble()).toList();
  final speeds = data.map((e) => (e['questionsPerSecond'] as num).toDouble()).toList();

  final minX = (speeds.reduce((a, b) => a < b ? a : b) - 0.5).clamp(0.0, double.infinity);
  final maxX = (speeds.reduce((a, b) => a > b ? a : b) + 0.5);
  final minY = (scores.reduce((a, b) => a < b ? a : b) - 2).clamp(0.0, double.infinity);
  final maxY = (scores.reduce((a, b) => a > b ? a : b) + 2);

  return ScatterChart(
    ScatterChartData(
      scatterSpots: data.asMap().entries.map((entry) {
        int index = entry.key;
        var user = entry.value;

        return ScatterSpot(
          (user['questionsPerSecond'] as num).toDouble(),
          (user['score'] as num).toDouble(),
          color: _touchedIndex == index ? Colors.red : Colors.blue,
          radius: _touchedIndex == index ? 10 : 6,
        );
      }).toList(),
      minX: minX,
      maxX: maxX,
      minY: minY,
      maxY: maxY,
      gridData: FlGridData(show: true),
      borderData: FlBorderData(show: true),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: ((maxY - minY) / 5).ceilToDouble().clamp(1, 10),
            getTitlesWidget: (value, _) =>
                Text('${value.toInt()}', style: TextStyle(fontSize: 12)),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(  
            showTitles: true,
            interval: ((maxX - minX) / 5).clamp(0.5, 2.0),
            getTitlesWidget: (value, _) =>
                Text('${value.toStringAsFixed(1)}', style: TextStyle(fontSize: 12)),
          ),
        ),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      scatterTouchData: ScatterTouchData(
        enabled: true,
        handleBuiltInTouches: true,
        touchTooltipData: ScatterTouchTooltipData(tooltipBgColor: Colors.transparent),
        touchCallback: (FlTouchEvent event, ScatterTouchResponse? response) {
          if (event is FlTapUpEvent && response != null) {
            setState(() {
              _touchedIndex = response.touchedSpot != null
                  ? response.touchedSpot!.spotIndex
                  : null;
            });
          }
        },
      ),
    ),
  );
}

}
