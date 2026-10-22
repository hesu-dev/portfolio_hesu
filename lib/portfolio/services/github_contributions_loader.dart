import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config/app_config.dart';

final _endpoint = Uri.parse(AppConfig.githubContributionsUrl);

/// Fetch only on an explicit open/refresh, not on ordinary widget rebuilds.
Future<Map<String, dynamic>> loadGitHubContributions({
  http.Client? client,
}) async {
  final connection = client ?? http.Client();
  try {
    final response = await connection
        .get(_endpoint, headers: {'Cache-Control': 'no-cache'})
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw const FormatException('Contribution request failed.');
    }
    return liveContributionSnapshot(
      jsonDecode(response.body) as Map<String, dynamic>,
      fetchedAt: DateTime.now().toUtc(),
    );
  } finally {
    if (client == null) connection.close();
  }
}

/// Adapt the public calendar without inventing missing days or contribution counts.
Map<String, dynamic> liveContributionSnapshot(
  Map<String, dynamic> response, {
  required DateTime fetchedAt,
}) {
  const palette = ['#ebedf0', '#9be9a8', '#40c463', '#30a14e', '#216e39'];
  final values = response['contributions'];
  if (values is! List || values.isEmpty) {
    throw const FormatException('Missing contribution days.');
  }
  final days = <Map<String, dynamic>>[];
  final dates = <String>{};
  for (final value in values) {
    if (value is! Map) throw const FormatException('Invalid contribution day.');
    final date = value['date'];
    final count = value['count'];
    final level = value['level'];
    final parsed = date is String
        ? DateTime.tryParse('${date}T00:00:00Z')
        : null;
    if (date is! String ||
        !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date) ||
        parsed == null ||
        parsed.toIso8601String().substring(0, 10) != date ||
        !dates.add(date) ||
        count is! int ||
        count < 0 ||
        level is! int ||
        level < 0 ||
        level > 4) {
      throw const FormatException('Invalid contribution day.');
    }
    days.add({
      'date': date,
      'weekday': parsed.weekday % 7,
      'contributionCount': count,
      'color': palette[level],
    });
  }
  days.sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));
  final weeks = <String, List<Map<String, dynamic>>>{};
  for (final day in days) {
    final date = DateTime.parse('${day['date']}T00:00:00Z');
    final sunday = date.subtract(Duration(days: day['weekday'] as int));
    final firstDay = sunday.toIso8601String().substring(0, 10);
    (weeks[firstDay] ??= []).add(day);
  }
  return {
    'username': 'hesu-dev',
    'source': _endpoint.toString(),
    'fetchedAt': fetchedAt.toUtc().toIso8601String(),
    'isFallback': false,
    'visibility': 'public',
    'totalContributions': days.fold<int>(
      0,
      (total, day) => total + (day['contributionCount'] as int),
    ),
    'colors': palette.skip(1).toList(),
    'weeks': [
      for (final week in weeks.entries)
        {'firstDay': week.key, 'contributionDays': week.value},
    ],
  };
}
