import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../team_repository.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final User? user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<String> _favTeams = [];
  String _name = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (user == null) return;
    
    try {
      final doc = await _firestore.collection('users').doc(user!.uid).get();
      if (doc.exists) {
        setState(() {
          _favTeams = List<String>.from(doc.data()?['favTeams'] ?? []);
          _name = doc.data()?['name'] ?? 'User Name';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateFavTeams(List<String> teams) async {
    if (user == null) return;
    
    setState(() {
      _isLoading = true;
      _favTeams = teams;
    });

    try {
      await _firestore.collection('users').doc(user!.uid).set({
        'favTeams': teams,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
                  onPressed: () {
                  },
                ),
              ],
            ),
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Header
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: NetworkImage(
                          user?.photoURL ?? 'https://via.placeholder.com/150',
                        ),
                        backgroundColor: Colors.grey[200],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user?.email ?? 'No email',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Favourite Teams Section
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Favourite Teams',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_favTeams.isNotEmpty)
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _favTeams.map((team) {
                                return Chip(
                                  avatar: Image.network(
                                    TeamRepository().getTeamLogo(team) ?? '',
                                    height: 24,
                                    width: 24,
                                    errorBuilder: (_, __, ___) => 
                                        const Icon(Icons.sports_basketball, size: 16),
                                  ),
                                  label: Text(team),
                                  backgroundColor: Colors.blue[50],
                                );
                              }).toList(),
                            )
                          else
                            const Text('No teams selected'),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => _navigateToTeamSelection(context),
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.blue[700],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('Manage Favourite Teams'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    childAspectRatio: 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      _buildActionButton(
                        'Account',
                        Icons.account_circle,
                        onPressed: () {},
                      ),
                      _buildActionButton(
                        'Important Dates',
                        Icons.event,
                        onPressed: () {},
                      ),
                      _buildActionButton(
                        'Fantasy',
                        Icons.leaderboard,
                        onPressed: () {},
                      ),
                      _buildActionButton(
                        'League Pass',
                        Icons.subscriptions,
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Sign Out Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => FirebaseAuth.instance.signOut(),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Sign Out'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildActionButton(String text, IconData icon, {VoidCallback? onPressed}) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        side: const BorderSide(color: Colors.grey),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }

  Future<void> _navigateToTeamSelection(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TeamSelectionPage(
          currentTeams: _favTeams,
          onTeamsUpdated: (teams) {
            _updateFavTeams(teams);
          },
        ),
      ),
    );
  }
}

class TeamSelectionPage extends StatefulWidget {
  final List<String> currentTeams;
  final Function(List<String>) onTeamsUpdated;

  const TeamSelectionPage({
    Key? key,
    required this.currentTeams,
    required this.onTeamsUpdated,
  }) : super(key: key);

  @override
  State<TeamSelectionPage> createState() => _TeamSelectionPageState();
}

class _TeamSelectionPageState extends State<TeamSelectionPage> {
  late List<String> _selectedTeams;

  @override
  void initState() {
    super.initState();
    _selectedTeams = List.from(widget.currentTeams);
  }

  void _toggleTeamSelection(String team) {
    setState(() {
      if (_selectedTeams.contains(team)) {
        _selectedTeams.remove(team);
      } else {
        _selectedTeams.add(team);
      }
    });
    widget.onTeamsUpdated(_selectedTeams);
  }

  @override
  Widget build(BuildContext context) {
    final teams = TeamRepository().teamData?.keys.toList() ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Favourite Teams'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.9,
        ),
        itemCount: teams.length,
        itemBuilder: (context, index) {
          final team = teams[index];
          final isSelected = _selectedTeams.contains(team);
          final logoUrl = TeamRepository().getTeamLogo(team);

          return GestureDetector(
            onTap: () => _toggleTeamSelection(team),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: isSelected
                    ? const BorderSide(color: Colors.blue, width: 2)
                    : BorderSide.none,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (logoUrl != null)
                    Image.network(
                      logoUrl,
                      height: 60,
                      width: 60,
                      errorBuilder: (_, __, ___) => 
                          const Icon(Icons.sports_basketball, size: 40),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    team,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (isSelected)
                    const Icon(Icons.star, color: Colors.blue, size: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}