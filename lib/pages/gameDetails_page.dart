import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../team_repository.dart';

class GameDetailsPage extends StatefulWidget {
  final String gameID;
  final String awayScore;
  final String homeScore;
  final String gameStatus;
  final String gameTime;

  const GameDetailsPage({
    Key? key,
    required this.gameID,
    required this.awayScore,
    required this.homeScore,
    required this.gameStatus,
    required this.gameTime,
  }) : super(key: key);

  @override
  State<GameDetailsPage> createState() => _GameDetailsPageState();
}

class _GameDetailsPageState extends State<GameDetailsPage> {
  Map<String, dynamic>? gameInfo;
  List<dynamic>? boxScore;
  bool isLoading = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _fetchGameDetails();
  }

  Future<void> _fetchGameDetails() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    try {
      final gameInfoUri = Uri.http('127.0.0.1:5000', '/getNBAGameInfo', {
        'gameID': widget.gameID,
      });
      final response = await http.get(gameInfoUri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          gameInfo = data['body'] as Map<String, dynamic>;
        });
        final nbaComLink = gameInfo?['nbaComLink'] ?? '';
        if (nbaComLink.isNotEmpty) {
          await _fetchBoxScore(nbaComLink);
        }
      } else {
        setState(() {
          error = 'Failed to load game info. Code: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        error = 'Error: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchBoxScore(String link) async {
    try {
      final boxScoreUri = Uri.http('127.0.0.1:5000', '/scrapeGameDetails', {
        'link': link,
      });
      final response = await http.get(boxScoreUri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          boxScore = data['boxScore'] as List<dynamic>;
        });
      } else {
        setState(() {
          error = 'Failed to fetch box score. Code: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        error = 'Box score error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Game Details'),
          backgroundColor: Colors.blue[900],
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (error != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Game Details'),
          backgroundColor: Colors.blue[900],
        ),
        body: Center(child: Text(error!, style: TextStyle(fontSize: 14))),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Game Details', style: TextStyle(fontSize: 18, color: Colors.white)),
        backgroundColor: Colors.blue[900],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGameDetailsCard(),
            const SizedBox(height: 16),
            _buildBoxScoreSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildGameDetailsCard() {
    final teamRepo = TeamRepository();
    final awayTeamAbv = gameInfo?['away'] ?? '';
    final homeTeamAbv = gameInfo?['home'] ?? '';
    final awayLogoUrl = teamRepo.getTeamLogo(awayTeamAbv);
    final homeLogoUrl = teamRepo.getTeamLogo(homeTeamAbv);
    final awayRecord = teamRepo.getTeamRecord(awayTeamAbv) ?? '--';
    final homeRecord = teamRepo.getTeamRecord(homeTeamAbv) ?? '--';

    final awayScore = widget.awayScore.isEmpty ? '--' : widget.awayScore;
    final homeScore = widget.homeScore.isEmpty ? '--' : widget.homeScore;
    final gameStatus = widget.gameStatus.isEmpty ? '--' : widget.gameStatus;
    final gameTime = widget.gameTime.isEmpty ? '--' : widget.gameTime;

    final gameID = gameInfo?['gameID'] ?? widget.gameID;
    final season = gameInfo?['season'] ?? '--';
    final gameDate = gameInfo?['gameDate'] ?? '--';
    final seasonType = gameInfo?['seasonType'] ?? '--';
    final nbaComLink = gameInfo?['nbaComLink'] ?? '--';
    final espnLink = gameInfo?['espnLink'] ?? '--';
    final cbsLink = gameInfo?['cbsLink'] ?? '--';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Teams and score
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Away team
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[200],
                      ),
                      child: awayLogoUrl != null
                          ? Image.network(
                              awayLogoUrl,
                              height: 48,
                              width: 48,
                            )
                          : const Icon(Icons.image_not_supported, size: 48),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      awayTeamAbv,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      awayRecord,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),

                // Score and status
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          awayScore,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getStatusColor(gameStatus),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            gameStatus,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          homeScore,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      gameTime,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),

                // Home team
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[200],
                      ),
                      child: homeLogoUrl != null
                          ? Image.network(
                              homeLogoUrl,
                              height: 48,
                              width: 48,
                            )
                          : const Icon(Icons.image_not_supported, size: 48),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      homeTeamAbv,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      homeRecord,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const Divider(height: 16, thickness: 1),

            // Game details
            _buildCompactDetailRow('Game ID', gameID),
            _buildCompactDetailRow('Season', season),
            _buildCompactDetailRow('Game Date', gameDate),
            _buildCompactDetailRow('Season Type', seasonType),
            _buildCompactLinkRow('NBA.com', nbaComLink),
            _buildCompactLinkRow('ESPN', espnLink),
            _buildCompactLinkRow('CBS', cbsLink),
          ],
        ),
      ),
    );
  }

  Widget _buildBoxScoreSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            'Box Score',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: boxScore == null
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: Center(
                      child: Text(
                        'No box score data available',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 12,
                      headingTextStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      dataTextStyle: const TextStyle(fontSize: 12),
                      columns: const [
                        DataColumn(label: Text('Player')),
                        DataColumn(label: Text('PTS'), numeric: true),
                        DataColumn(label: Text('REB'), numeric: true),
                        DataColumn(label: Text('AST'), numeric: true),
                      ],
                      rows: boxScore!.map((player) {
                        final name = player['player'] ?? 'Unknown';
                        final points = player['points']?.toString() ?? '0';
                        final rebounds = player['rebounds']?.toString() ?? '0';
                        final assists = player['assists']?.toString() ?? '0';
                        return DataRow(cells: [
                          DataCell(Text(name, style: TextStyle(fontSize: 12))),
                          DataCell(Text(points, style: TextStyle(fontSize: 12))),
                          DataCell(Text(rebounds, style: TextStyle(fontSize: 12))),
                          DataCell(Text(assists, style: TextStyle(fontSize: 12))),
                        ]);
                      }).toList(),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactLinkRow(String label, String url) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                // You would typically launch the URL here
              },
              child: Text(
                url,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'final':
        return Colors.green;
      case 'completed':
        return Colors.green;
      case 'live':
        return Colors.red;
      case 'scheduled':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}