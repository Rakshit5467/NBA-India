import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Import your additional pages/widgets
import 'schedule_page.dart';
import '../widgets/top_news_section.dart';
import '../team_repository.dart';
import 'auth_page.dart';
import 'profile_page.dart';
import '../widgets/score_card.dart'; // for BlinkingDot


class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  int _currentIndex = 0;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _currentUser;

  // Schedule page variables
  final DateTime startDate = DateTime(2000, 1, 1);
  final DateTime endDate = DateTime(2030, 12, 31);
  late final DateTime timelineStart;
  late final int numberOfWeeks;
  late final PageController _pageController;
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _initializeFirebase();

    // Initialize auth listener
    _auth.authStateChanges().listen((User? user) {
      setState(() {
        _currentUser = user;
      });
    });

    // Fetch team data once (for logos & records)
    TeamRepository().fetchTeamData().then((_) {
      setState(() {});
    });

    // Schedule page initialization
    timelineStart = _getMonday(startDate);
    numberOfWeeks = (endDate.difference(timelineStart).inDays ~/ 7) + 1;
    final currentMonday = _getMonday(selectedDate);
    final currentWeekIndex =
        (currentMonday.difference(timelineStart).inDays) ~/ 7;
    _pageController = PageController(initialPage: currentWeekIndex);
  }

  Future<void> _initializeFirebase() async {
    await Firebase.initializeApp();
  }

  /// Returns the Monday of the week for a given date
  DateTime _getMonday(DateTime date) {
    int subtract = date.weekday - 1; // Monday is weekday=1
    return DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: subtract));
  }

  /// Fetch schedule data from your RapidAPI endpoint, returning the earliest game
  Future<Map<String, dynamic>?> _fetchSingleGame() async {
    final localMidnight = DateTime(
    selectedDate.year,
    selectedDate.month,
    selectedDate.day,
  );
  final asUtc      = localMidnight.toUtc();
  final usEastern  = asUtc.subtract(const Duration(hours: 5));
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
    print('Requesting schedule from: $scheduleUri');

    final response = await http.get(scheduleUri, headers: headers);
    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      final scheduleMap = jsonData['body'] as Map<String, dynamic>?;
      if (scheduleMap == null || scheduleMap.isEmpty) return null;

      List<String> favTeams = [];
      if (_currentUser != null) {
        try {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(_currentUser!.uid)
              .get();
          if (userDoc.exists) {
            favTeams = List<String>.from(userDoc.data()?['favTeams'] ?? []);
          }
        } catch (e) {
          print('Error fetching favorite teams: $e');
        }
      }

      // Convert schedule map to list of games
      final games = scheduleMap.entries.toList();

      // If user has favorite teams, try to find a game involving them
      if (favTeams.isNotEmpty) {
        // First, look for games where either team is in favorites
        final favoriteGames = games.where((game) {
          final homeTeam = game.value['home'] ?? '';
          final awayTeam = game.value['away'] ?? '';
          return favTeams.contains(homeTeam) || favTeams.contains(awayTeam);
        }).toList();

        if (favoriteGames.isNotEmpty) {
          // Sort by gameTime_epoch ascending, pick the earliest favorite game
          favoriteGames.sort((a, b) {
            final epochA =
                double.tryParse(a.value['gameTime_epoch'] ?? '0') ?? 0;
            final epochB =
                double.tryParse(b.value['gameTime_epoch'] ?? '0') ?? 0;
            return epochA.compareTo(epochB);
          });
          return favoriteGames.first.value;
        }
      }

      // If no favorite games found or user not logged in, return the earliest game
      games.sort((a, b) {
        final epochA = double.tryParse(a.value['gameTime_epoch'] ?? '0') ?? 0;
        final epochB = double.tryParse(b.value['gameTime_epoch'] ?? '0') ?? 0;
        return epochA.compareTo(epochB);
      });

      return games.isNotEmpty ? games.first.value : null;
    } else {
      throw Exception('Failed to load schedule. Code: ${response.statusCode}');
    }
  }

  /// Converts an EST time string like "8:00p" into IST (e.g. "5:30 AM")
  String _convertEstToIst(String rawTime) {
    if (rawTime.isEmpty) return '--';

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
    // +9:30 from EST to IST
    final istDateTime = estDateTime.add(const Duration(hours: 9, minutes: 30));

    final formatter = DateFormat('h:mma');
    final istString = formatter.format(istDateTime).toLowerCase();
    return istString.replaceFirst('am', ' AM').replaceFirst('pm', ' PM');
  }

  List<Widget> get _pages {
    return [  
      SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            FutureBuilder<Map<String, dynamic>?>(
              future: _fetchSingleGame(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  );
                } else if (snapshot.data == null) {
                  return const Text('No game found.');
                } else {
                  final game = snapshot.data!;
                  final awayTeam = game['away'] ?? '';
                  final homeTeam = game['home'] ?? '';
                  final awayPts = game['awayPts'] ?? '';
                  final homePts = game['homePts'] ?? '';
                  final gameTimeRaw = game['gameTime'] ?? '';
                  final gameClock = game['gameClock'] ?? '';
                  final gameStatus = game['gameStatus'] ?? '';

                  // Convert to int for scoreboard
                  final awayScore = awayPts.isEmpty ? 0 : int.parse(awayPts);
                  final homeScore = homePts.isEmpty ? 0 : int.parse(homePts);

                  final awayLogoUrl = TeamRepository().getTeamLogo(awayTeam);
                  final homeLogoUrl = TeamRepository().getTeamLogo(homeTeam);
                  final awayRecord =
                      TeamRepository().getTeamRecord(awayTeam) ?? '--';
                  final homeRecord =
                      TeamRepository().getTeamRecord(homeTeam) ?? '--';

                  // Decide time
                  String displayTime;
                  final lowerStatus = gameStatus.toLowerCase();
                  if (lowerStatus.contains('live')) {
                    displayTime = gameClock.isEmpty ? '--' : gameClock;
                    displayTime = '$displayTime\nLive';
                  } else if (lowerStatus.contains('completed')) {
                    displayTime = 'Final';
                  } else if (lowerStatus.contains('not started yet')) {
                    displayTime = gameTimeRaw.isEmpty
                        ? '--'
                        : _convertEstToIst(gameTimeRaw);
                  } else {
                    displayTime = gameTimeRaw.isEmpty
                        ? '--'
                        : _convertEstToIst(gameTimeRaw);
                  }

                  Widget middleWidget;
              if (lowerStatus.contains('completed')) {
                middleWidget = const Text('Final', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16));
              } else if (lowerStatus.contains('live')) {
                final parts      = gameClock.split('-');
                final timePart   = parts.isNotEmpty ? parts[0].trim() : '--';
                final quarterStr = parts.length>1 ? parts[1].trim() : '';
                middleWidget = Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const BlinkingDot(),
                    const SizedBox(width: 6),
                    Text(
                      '$timePart $quarterStr',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                );
              } else {
                middleWidget = Text(
                  displayTime,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                );
              }

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Live Score',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 180,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
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
                              // Away column
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  awayLogoUrl != null
                                      ? Image.network(
                                          awayLogoUrl,
                                          height: 40,
                                          width: 40,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  const Icon(Icons.error),
                                        )
                                      : const Icon(Icons.image_not_supported,
                                          size: 40),
                                  const SizedBox(height: 4),
                                  Text(
                                    awayTeam,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    awayRecord,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$awayScore',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),

                              // Middle
                              middleWidget,

                              // Home column
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  homeLogoUrl != null
                                      ? Image.network(
                                          homeLogoUrl,
                                          height: 40,
                                          width: 40,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  const Icon(Icons.error),
                                        )
                                      : const Icon(Icons.image_not_supported,
                                          size: 40),
                                  const SizedBox(height: 4),
                                  Text(
                                    homeTeam,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    homeRecord,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$homeScore',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 20),
            const TopNewsSection(),
          ],
        ),
      ),

      // PAGE 1: Score (Schedule) - unchanged
      const SchedulePage(),

      // PAGE 2: Profile - now with Firebase integration
      _currentUser == null ? const AuthPage() : const ProfilePage(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _currentIndex == 0
          ? AppBar(
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
            )
          : null,
      backgroundColor: Colors.white,
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.grey[200],
        currentIndex: _currentIndex,
        selectedItemColor: Colors.black,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.score),
            label: 'Score',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
