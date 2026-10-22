import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:portfolio_hesu/portfolio/services/github_contributions_loader.dart';

void main() {
  final fetchedAt = DateTime.utc(2026, 10, 16, 4, 30);
  const live = {
    'contributions': [
      {'date': '2026-10-12', 'count': 3, 'level': 2},
      {'date': '2026-10-10', 'count': 0, 'level': 0},
      {'date': '2026-10-11', 'count': 7, 'level': 4},
    ],
  };

  test(
    'sorts dates into Sunday weeks and preserves counts and level colors',
    () {
      final result = liveContributionSnapshot(live, fetchedAt: fetchedAt);
      expect(result['totalContributions'], 10);
      expect(result['fetchedAt'], '2026-10-16T04:30:00.000Z');
      expect(result['isFallback'], isFalse);
      final weeks = result['weeks'] as List;
      expect(weeks, hasLength(2));
      expect(weeks[0]['firstDay'], '2026-10-04');
      expect(weeks[0]['contributionDays'][0]['weekday'], 6);
      expect(weeks[1]['firstDay'], '2026-10-11');
      expect(weeks[1]['contributionDays'][0]['color'], '#216e39');
      expect(weeks[1]['contributionDays'][1]['weekday'], 1);
    },
  );

  test(
    'rejects impossible dates, duplicate dates, invalid counts and levels',
    () {
      for (final day in [
        {'date': '2026-02-30', 'count': 1, 'level': 1},
        {'date': '2026-10-16', 'count': -1, 'level': 1},
        {'date': '2026-10-16', 'count': 1, 'level': 5},
      ]) {
        expect(
          () => liveContributionSnapshot({
            'contributions': [day],
          }, fetchedAt: fetchedAt),
          throwsFormatException,
        );
      }
      final sameDay = (live['contributions'] as List).first;
      expect(
        () => liveContributionSnapshot({
          'contributions': [sameDay, sameDay],
        }, fetchedAt: fetchedAt),
        throwsFormatException,
      );
    },
  );

  test('each open requests a fresh response without credentials', () async {
    var requests = 0;
    final client = MockClient((request) async {
      requests++;
      expect(
        request.url.toString(),
        const String.fromEnvironment(
          'GITHUB_CONTRIBUTIONS_URL',
          defaultValue:
              'https://portfolio-hesu-api.portfolio-hesu.workers.dev/api/github/contributions',
        ),
      );
      expect(request.headers['Cache-Control'], 'no-cache');
      expect(request.headers.containsKey('Authorization'), isFalse);
      return http.Response(jsonEncode(live), 200);
    });
    for (var i = 0; i < 2; i++) {
      final data = await loadGitHubContributions(client: client);
      expect(data['isFallback'], isFalse);
    }
    expect(requests, 2);
    client.close();
  });

  test(
    'HTTP and malformed payload errors fail instead of returning saved data',
    () async {
      for (final response in [
        http.Response('{}', 503),
        http.Response('bad json', 200),
        http.Response('{}', 200),
      ]) {
        final client = MockClient((_) async => response);
        await expectLater(
          loadGitHubContributions(client: client),
          throwsFormatException,
        );
        client.close();
      }
    },
  );

  test(
    'network errors fail instead of reading bundled contribution data',
    () async {
      final client = MockClient(
        (_) async => throw http.ClientException('offline'),
      );
      await expectLater(
        loadGitHubContributions(client: client),
        throwsA(isA<http.ClientException>()),
      );
      client.close();
    },
  );
}
