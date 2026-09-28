import 'dart:convert';
import 'dart:io';

const contributionAsset = 'assets/github-profile/contributions.json';
const _query = r'''
query {
  viewer { login }
  user(login: "hesu-dev") {
    contributionsCollection {
      startedAt endedAt restrictedContributionsCount
      contributionCalendar {
        totalContributions colors
        weeks {
          firstDay
          contributionDays { date weekday contributionCount contributionLevel color }
        }
      }
    }
  }
}
''';

/// Whitelist aggregate calendar fields; never bundle credentials/repository data.
Map<String, dynamic> contributionSnapshot(
  Map<String, dynamic> response, {
  required String scopes,
  required DateTime fetchedAt,
}) {
  final data = response['data'] as Map<String, dynamic>?;
  if (response['errors'] != null || data?['user'] == null) {
    throw const FormatException(
      'GitHub did not return the contribution calendar.',
    );
  }
  final permissions = scopes.split(',').map((value) => value.trim()).toSet();
  final privateIncluded =
      (permissions.contains('read:user') || permissions.contains('user')) &&
      data!['viewer']['login'] == 'hesu-dev';
  if (!privateIncluded) {
    throw const FormatException(
      'Private contributions require hesu-dev authentication with read:user. '
      'Run: gh auth refresh -h github.com -s read:user',
    );
  }
  final collection =
      data['user']['contributionsCollection'] as Map<String, dynamic>;
  final calendar = collection['contributionCalendar'] as Map<String, dynamic>;
  final weeks = <Map<String, dynamic>>[];
  var total = 0;
  for (final week in calendar['weeks'] as List) {
    final days = <Map<String, dynamic>>[];
    for (final day in week['contributionDays'] as List) {
      final color = day['color'] as String;
      final count = day['contributionCount'] as int;
      final weekday = day['weekday'] as int;
      final date = day['date'] as String;
      if (!RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(color) ||
          count < 0 ||
          weekday < 0 ||
          weekday > 6 ||
          DateTime.tryParse(date) == null) {
        throw const FormatException('Invalid contribution day from GitHub.');
      }
      total += count;
      days.add({
        'date': date,
        'weekday': weekday,
        'contributionCount': count,
        'contributionLevel': day['contributionLevel'],
        'color': color,
      });
    }
    weeks.add({'firstDay': week['firstDay'], 'contributionDays': days});
  }
  if (weeks.isEmpty || total != calendar['totalContributions']) {
    throw const FormatException('GitHub contribution totals do not match.');
  }
  return {
    'username': 'hesu-dev',
    'source': 'https://api.github.com/graphql',
    'fetchedAt': fetchedAt.toUtc().toIso8601String(),
    'privateIncluded': privateIncluded,
    'startedAt': collection['startedAt'],
    'endedAt': collection['endedAt'],
    'totalContributions': total,
    'colors': calendar['colors'],
    'weeks': weeks,
  };
}

Future<void> refreshGitHubContributions() async {
  final result = await Process.run('gh', [
    'api',
    'graphql',
    '--include',
    '-f',
    'query=$_query',
  ]);
  if (result.exitCode != 0) {
    throw const ProcessException(
      'gh',
      [],
      'GitHub authentication or request failed.',
    );
  }
  final output = result.stdout as String;
  final jsonStart = output.indexOf('{');
  if (jsonStart < 0) throw const FormatException('Missing GitHub response.');
  final headers = output.substring(0, jsonStart);
  final scopes =
      RegExp(
        r'^x-oauth-scopes:\s*([^\r\n]*)',
        multiLine: true,
        caseSensitive: false,
      ).firstMatch(headers)?.group(1) ??
      '';
  final snapshot = contributionSnapshot(
    jsonDecode(output.substring(jsonStart)) as Map<String, dynamic>,
    scopes: scopes,
    fetchedAt: DateTime.now(),
  );
  final temporary = File('$contributionAsset.tmp');
  await temporary.writeAsString(
    '${const JsonEncoder.withIndent('  ').convert(snapshot)}\n',
  );
  await temporary.rename(contributionAsset);
  stdout.writeln(
    'GitHub calendar updated: ${snapshot['totalContributions']} contributions; '
    'private included: ${snapshot['privateIncluded']}.',
  );
}

Future<void> main(List<String> arguments) async {
  if (arguments.isNotEmpty) {
    stderr.writeln('Usage: dart run tool/refresh_github_contributions.dart');
    exitCode = 64;
    return;
  }
  try {
    await refreshGitHubContributions();
  } catch (error) {
    stderr.writeln(
      'Contribution refresh failed; existing snapshot preserved. $error',
    );
    exitCode = 1;
  }
}
