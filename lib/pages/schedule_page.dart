import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import './gameDetails_page.dart';
import '../widgets/score_card.dart';
import '../team_repository.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({Key? key}) : super(key: key);

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  DateTime selectedDate = DateTime.now();
  final DateTime startDate = DateTime(2000, 1, 1);
  final DateTime endDate = DateTime(2030, 12, 31);
  late final DateTime timelineStart;
  late final int numberOfWeeks;
  late final PageController _pageController;
  List<String> _favTeams = [];

  @override
  void initState() {
    super.initState();
    _loadFavoriteTeams();

    TeamRepository().fetchTeamData().then((_) {
      setState(() {});
    });

    timelineStart = _getMonday(startDate);
    numberOfWeeks = (endDate.difference(timelineStart).inDays ~/ 7) + 1;

    final currentMonday = _getMonday(selectedDate);
    final currentWeekIndex =
        (currentMonday.difference(timelineStart).inDays) ~/ 7;

    _pageController = PageController(initialPage: currentWeekIndex);
  }

  Future<void> _loadFavoriteTeams() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (doc.exists) {
      setState(() {
        _favTeams = List<String>.from(doc.data()?['favTeams'] ?? []);
      });
    }
  }

  DateTime _getMonday(DateTime date) {
    int subtract = date.weekday - 1;
    return DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: subtract));
  }

  Future<Map<String, dynamic>> _fetchScheduleData() async {
    final localMidnight = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    final asUtc = localMidnight.toUtc();
    final usEastern = asUtc.subtract(const Duration(hours: 5));
    final dateString = DateFormat('yyyyMMdd').format(usEastern);

    const baseUrl = 'tank01-fantasy-stats.p.rapidapi.com';
    const endpointPath = '/getNBAScoresOnly';

    final queryParams = {
      'gameDate': dateString,
    };

    final headers = {
      'X-RapidAPI-Key': 'e419ab8c9bmsh207d1141f52d94bp17f987jsnc1d87cac5dd9',
      'X-RapidAPI-Host': 'tank01-fantasy-stats.p.rapidapi.com',
    };

    final scheduleUri = Uri.https(baseUrl, endpointPath, queryParams);
    print('Requesting schedule from 2: $scheduleUri');

    final response = await http.get(scheduleUri, headers: headers);
    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      return jsonData['body'] as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load schedule. Code: ${response.statusCode}');
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _convertEstToIst(String rawTime) {
    if (rawTime.isEmpty) return '--';
    if (rawTime.contains('TBD')) return 'TBD';

    final lower = rawTime.toLowerCase().trim();
    final isPM = lower.endsWith('p');
    final isAM = lower.endsWith('a');

    final timePart = lower.substring(0, lower.length - 1);
    final parts = timePart.split(':');
    if (parts.length < 2) return '--';

    int hour = int.tryParse(parts[0]) ?? 0;
    int minute = int.tryParse(parts[1]) ?? 0;

    if (isPM && hour < 12) {
      hour += 12;
    } else if (isAM && hour == 12) {
      hour = 0;
    }

    final estDateTime = DateTime(2000, 1, 1, hour, minute);
    final istDateTime = estDateTime.add(const Duration(hours: 9, minutes: 30));

    final formatter = DateFormat('h:mma');
    final istString = formatter.format(istDateTime).toLowerCase();
    return istString.replaceFirst('am', ' AM').replaceFirst('pm', ' PM');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: false,
        toolbarHeight: 100,
        leadingWidth: 100,
        title: Row(
          children: [
            Image.asset(
              'assets/images/nbaLogo.png',
              height: 50,
            ),
            const SizedBox(width: 8),
            const Text(
              'NBA',
              style: TextStyle(
                color: Colors.black,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Schedule',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  DateFormat('MMMM yyyy').format(selectedDate),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 80,
              child: PageView.builder(
                controller: _pageController,
                itemCount: numberOfWeeks,
                onPageChanged: (pageIndex) {
                  setState(() {
                    final dayOffset = selectedDate.weekday - 1;
                    selectedDate = timelineStart
                        .add(Duration(days: pageIndex * 7 + dayOffset));
                  });
                },
                itemBuilder: (context, pageIndex) {
                  final weekStart =
                      timelineStart.add(Duration(days: pageIndex * 7));
                  final dayWidgets = <Widget>[];
                  for (int i = 0; i < 7; i++) {
                    final day = weekStart.add(Duration(days: i));
                    if (day.isAfter(endDate)) break;
                    dayWidgets.add(
                      DayItem(
                        date: day,
                        isSelected: _isSameDay(day, selectedDate),
                        onTap: () {
                          setState(() {
                            selectedDate = day;
                            final newPage = (_getMonday(selectedDate)
                                    .difference(timelineStart)
                                    .inDays) ~/
                                7;
                            _pageController.jumpToPage(newPage);
                          });
                        },
                      ),
                    );
                  }
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: dayWidgets,
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            FutureBuilder<Map<String, dynamic>>(
              future: _fetchScheduleData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Error loading schedule: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No schedule data found.'),
                  );
                } else {
                  final scheduleMap = snapshot.data!;
                  final sortedGames = scheduleMap.entries.toList()
                    ..sort((a, b) {
                      final epochA =
                          double.tryParse(a.value['gameTime_epoch'] ?? '0') ??
                              0;
                      final epochB =
                          double.tryParse(b.value['gameTime_epoch'] ?? '0') ??
                              0;
                      return epochA.compareTo(epochB);
                    });

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: sortedGames.length,
                    itemBuilder: (context, index) {
                      final gameEntry = sortedGames[index];
                      final gameData = gameEntry.value;

                      final awayTeam = gameData['away'] ?? '';
                      final homeTeam = gameData['home'] ?? '';
                      final awayPts = gameData['awayPts'] ?? '';
                      final homePts = gameData['homePts'] ?? '';
                      final gameTimeRaw = gameData['gameTime'] ?? '';
                      final gameClock = gameData['gameClock'] ?? '';
                      final gameStatus = gameData['gameStatus'] ?? '';
                      final gameID = gameData['gameID'] ?? '';

                      final awayScore = awayPts.isEmpty ? '0' : awayPts;
                      final homeScore = homePts.isEmpty ? '0' : homePts;

                      String displayTime;
                      final lowerStatus = gameStatus.toLowerCase();
                      if (lowerStatus.contains('live') ||
                          lowerStatus.contains('completed')) {
                        displayTime = gameClock.isEmpty ? '--' : gameClock;
                      } else {
                        displayTime = gameTimeRaw.isEmpty
                            ? '--'
                            : _convertEstToIst(gameTimeRaw);
                      }

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GameDetailsPage(
                                gameID: gameID,
                                awayScore: awayScore,
                                homeScore: homeScore,
                                gameStatus: gameStatus,
                                gameTime: displayTime,
                              ),
                            ),
                          );
                        },
                        child: ScoreCard(
                          awayTeam: awayTeam,
                          homeTeam: homeTeam,
                          awayScore: awayPts.isEmpty ? 0 : int.parse(awayPts),
                          homeScore: homePts.isEmpty ? 0 : int.parse(homePts),
                          gameTime: displayTime,
                          gameStatus: gameStatus,
                          isLive: lowerStatus.contains('live') ||
                              lowerStatus.contains('completed'),
                          gameClock: gameClock,
                          favoriteTeams: _favTeams, // Pass favorite teams
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class DayItem extends StatelessWidget {
  final DateTime date;
  final bool isSelected;
  final VoidCallback onTap;

  const DayItem({
    Key? key,
    required this.date,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dayName = DateFormat('E').format(date).substring(0, 3);
    final dayNum = date.day.toString();

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: isSelected
                  ? BoxDecoration(
                      color: Colors.blue[900],
                      shape: BoxShape.circle,
                    )
                  : null,
              alignment: Alignment.center,
              child: Text(
                dayNum,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              dayName,
              style: TextStyle(
                color: isSelected ? Colors.blue[900] : Colors.black,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
