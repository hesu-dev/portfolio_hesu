import 'package:flutter_test/flutter_test.dart';

import '../../tool/refresh_github_contributions.dart';

void main() {
  Map<String, dynamic> response() => {
    'data': {
      'viewer': {'login': 'hesu-dev'},
      'user': {
        'contributionsCollection': {
          'startedAt': '2026-09-27T00:00:00Z',
          'endedAt': '2026-09-27T23:59:59Z',
          'privateRepositoryName': 'must-not-be-bundled',
          'contributionCalendar': {
            'colors': ['#216e39'],
            'totalContributions': 7,
            'weeks': [
              {
                'firstDay': '2026-09-27',
                'contributionDays': [
                  {
                    'date': '2026-09-27',
                    'weekday': 0,
                    'contributionCount': 7,
                    'contributionLevel': 'FOURTH_QUARTILE',
                    'color': '#216e39',
                  },
                ],
              },
            ],
          },
        },
      },
    },
  };

  test(
    'private calendar preserves GitHub colors and only emits aggregate fields',
    () {
      final snapshot = contributionSnapshot(
        response(),
        scopes: 'repo, read:user',
        fetchedAt: DateTime.utc(2026, 9, 28),
      );
      expect(snapshot['privateIncluded'], isTrue);
      expect(snapshot['totalContributions'], 7);
      expect(snapshot['weeks'][0]['contributionDays'][0]['color'], '#216e39');
      expect(snapshot.toString(), isNot(contains('must-not-be-bundled')));
      expect(snapshot.containsKey('viewer'), isFalse);
    },
  );

  test(
    'missing read:user or wrong viewer cannot be labelled private-inclusive',
    () {
      expect(
        () => contributionSnapshot(
          response(),
          scopes: 'repo',
          fetchedAt: DateTime.now(),
        ),
        throwsFormatException,
      );
      final other = response();
      other['data']['viewer']['login'] = 'another-account';
      expect(
        () => contributionSnapshot(
          other,
          scopes: 'repo, read:user',
          fetchedAt: DateTime.now(),
        ),
        throwsFormatException,
      );
    },
  );

  test('invalid day totals cannot replace a calendar snapshot', () {
    final invalid = response();
    invalid['data']['user']['contributionsCollection']['contributionCalendar']['totalContributions'] =
        8;
    expect(
      () => contributionSnapshot(
        invalid,
        scopes: 'repo, read:user',
        fetchedAt: DateTime.now(),
      ),
      throwsFormatException,
    );
  });
}
