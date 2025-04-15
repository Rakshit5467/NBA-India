import 'package:flutter/material.dart';
import '../team_repository.dart';

class BlinkingDot extends StatefulWidget {
  const BlinkingDot({Key? key}) : super(key: key);

  @override
  _BlinkingDotState createState() => _BlinkingDotState();
}

class _BlinkingDotState extends State<BlinkingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 1.0, end: 0.2).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: const Icon(Icons.circle, color: Colors.red, size: 12),
    );
  }
}

class ScoreCard extends StatelessWidget {
  final String awayTeam;
  final String homeTeam;
  final int awayScore;
  final int homeScore;
  final String gameTime;
  final String gameStatus;
  final bool isLive;
  final String gameClock;
  final List<String> favoriteTeams;

  const ScoreCard({
    Key? key,
    required this.awayTeam,
    required this.homeTeam,
    required this.awayScore,
    required this.homeScore,
    required this.gameTime,
    required this.gameStatus,
    this.isLive = false,
    this.gameClock = '',
    this.favoriteTeams = const [],
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final teamRepo = TeamRepository();
    final awayLogoUrl = teamRepo.getTeamLogo(awayTeam);
    final homeLogoUrl = teamRepo.getTeamLogo(homeTeam);
    final awayRecord = teamRepo.getTeamRecord(awayTeam) ?? '--';
    final homeRecord = teamRepo.getTeamRecord(homeTeam) ?? '--';

    Widget middleWidget;
    final lowerTime = gameTime.toLowerCase();
    final bool isFinal = lowerTime.contains('final');
    if (isFinal) {
      middleWidget = const Text(
        'Final',
        style: TextStyle(fontWeight: FontWeight.bold),
      );
    } else if (isLive) {
      final parts = gameClock.split('-');
      final timePart = parts.isNotEmpty ? parts[0].trim() : '--';
      final quarterPart = parts.length > 1 ? parts[1].trim() : '';
      middleWidget = Row(
        children: [
          const BlinkingDot(),
          const SizedBox(width: 4),
          Text(
            '$timePart $quarterPart',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      );
    } else {
      middleWidget = Text(
        gameTime.isNotEmpty ? gameTime : '--',
        style: const TextStyle(fontWeight: FontWeight.bold),
      );
    }

    final bool notStarted = gameStatus.toLowerCase().contains('not started');
    Widget awayScoreWidget = notStarted
        ? const SizedBox(width: 20)
        : Text(
            '$awayScore',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          );
    Widget homeScoreWidget = notStarted
        ? const SizedBox(width: 20)
        : Text(
            '$homeScore',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          );

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Away team
          Column(
            children: [
              awayLogoUrl != null
                  ? Image.network(
                      awayLogoUrl,
                      height: 40,
                      width: 40,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.error),
                    )
                  : const Icon(Icons.image_not_supported, size: 40),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    awayTeam,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (favoriteTeams.contains(awayTeam))
                    const Padding(
                      padding: EdgeInsets.only(left: 4.0),
                      child: Icon(Icons.star, color: Colors.blue, size: 16),
                    ),
                ],
              ),
              Text(
                awayRecord,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          awayScoreWidget,
          middleWidget,
          homeScoreWidget,
          // Home team
          Column(
            children: [
              homeLogoUrl != null
                  ? Image.network(
                      homeLogoUrl,
                      height: 40,
                      width: 40,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.error),
                    )
                  : const Icon(Icons.image_not_supported, size: 40),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    homeTeam,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (favoriteTeams.contains(homeTeam))
                    const Padding(
                      padding: EdgeInsets.only(left: 4.0),
                      child: Icon(Icons.star, color: Colors.blue, size: 16),
                    ),
                ],
              ),
              Text(
                homeRecord,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}