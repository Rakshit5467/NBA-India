import 'dart:convert';
import 'package:http/http.dart' as http;

class TeamRepository {
  static final TeamRepository _instance = TeamRepository._internal();
  factory TeamRepository() => _instance;
  TeamRepository._internal();

  Map<String, dynamic>? _teamData;

  Map<String, dynamic>? get teamData => _teamData;

  /// Call this method once (e.g., at app start) to fetch team details.
  Future<void> fetchTeamData() async {
    const baseUrl = 'tank01-fantasy-stats.p.rapidapi.com';
    const endpointPath = '/getNBATeams';

    final headers = {
      'X-RapidAPI-Key':
          'e419ab8c9bmsh207d1141f52d94bp17f987jsnc1d87cac5dd9', // Replace with your actual key.
      'X-RapidAPI-Host': baseUrl,
    };

    final uri = Uri.https(baseUrl, endpointPath);
    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      final List<dynamic> teamList = jsonData['body'];
      _teamData = {};
      for (var team in teamList) {
        final String abv = team['teamAbv'];
        _teamData![abv] = team;
      }
    } else {
      throw Exception(
          'Failed to fetch team data. Code: ${response.statusCode}');
    }
  }

  /// Returns the team logo URL for the given team abbreviation.
  String? getTeamLogo(String teamAbv, {String source = 'espnLogo1'}) {
    if (_teamData == null) return null;
    if (_teamData!.containsKey(teamAbv)) {
      return _teamData![teamAbv][source] as String?;
    }
    return null;
  }

  /// Returns the team record in the format "wins-loss".
  String? getTeamRecord(String teamAbv) {
    if (_teamData == null) return null;
    if (_teamData!.containsKey(teamAbv)) {
      final teamInfo = _teamData![teamAbv];
      final String wins = teamInfo['wins'] ?? '0';
      final String loss = teamInfo['loss'] ?? '0';
      return '$wins-$loss';
    }
    return null;
  }
}
