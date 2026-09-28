import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_hesu/portfolio/theme/apple_theme.dart';
import 'package:portfolio_hesu/portfolio/widgets/github_contributions.dart';

void main() {
  testWidgets('positions real dates by week and weekday with supplied colors', (
    tester,
  ) async {
    await _pumpContributions(tester, dataFuture: Future.value(_snapshot));

    expect(find.text('hesu-dev'), findsOneWidget);
    expect(find.text('공개 기여 기준'), findsNothing);
    expect(find.text('공개 · 비공개 기여 포함'), findsNothing);
    expect(find.text('최신 반영: 2026-02-11'), findsOneWidget);
    expect(find.textContaining('스냅샷'), findsNothing);
    final sunday = find.byKey(const Key('github-contribution-2026-01-25'));
    final monday = find.byKey(const Key('github-contribution-2026-01-26'));
    final nextSunday = find.byKey(const Key('github-contribution-2026-02-01'));
    expect(tester.getSize(monday), const Size(11, 11));
    expect(tester.getTopLeft(monday).dx, tester.getTopLeft(sunday).dx);
    expect(tester.getTopLeft(monday).dy - tester.getTopLeft(sunday).dy, 14);
    expect(tester.getTopLeft(nextSunday).dx - tester.getTopLeft(sunday).dx, 14);
    expect(tester.getTopLeft(nextSunday).dy, tester.getTopLeft(sunday).dy);
    expect(
      (tester.widget<Container>(monday).decoration! as BoxDecoration).color,
      const Color(0xFF9BE9A8),
    );
    expect(
      (tester.widget<Container>(nextSunday).decoration! as BoxDecoration).color,
      const Color(0xFF30A14E),
    );
    expect(
      tester.getSize(find.byKey(const Key('github-contributions-grid'))).height,
      95,
    );
    await tester.longPress(monday);
    await tester.pumpAndSettle();
    expect(find.text('2026-01-26'), findsOneWidget);
    expect(find.textContaining('회 기여'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps the full year readable and scrollable on a phone', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final weeks = <Map<String, dynamic>>[
      for (var index = 0; index < 53; index++)
        <String, dynamic>{
          'firstDay': DateTime(
            2025,
            2,
            9,
          ).add(Duration(days: index * 7)).toIso8601String().substring(0, 10),
          'contributionDays': <Map<String, dynamic>>[],
        },
    ];
    await _pumpContributions(
      tester,
      dataFuture: Future.value(<String, dynamic>{
        ..._snapshot,
        'privateIncluded': true,
        'weeks': weeks,
      }),
    );
    expect(find.text('공개 · 비공개 기여 포함'), findsNothing);
    expect(find.text('공개 기여 기준'), findsNothing);
    expect(find.textContaining('회 기여'), findsNothing);
    final scroll = find.byKey(const Key('github-contributions-scroll'));
    final grid = find.byKey(const Key('github-contributions-grid'));
    expect(tester.getSize(grid).width, 53 * 14 - 3);
    expect(
      tester.getSize(grid).width,
      greaterThan(tester.getSize(scroll).width),
    );
    final initialLeft = tester.getTopLeft(grid).dx;
    await tester.drag(scroll, const Offset(-250, 0));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(grid).dx, lessThan(initialLeft));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'shows no invented data after a load error and retries the asset',
    (tester) async {
      const assetPath = 'assets/github-profile/contributions.json';
      var requests = 0;
      final messenger = tester.binding.defaultBinaryMessenger;
      rootBundle.evict(assetPath);
      messenger.setMockMessageHandler('flutter/assets', (message) async {
        if (utf8.decode(message!.buffer.asUint8List()) != assetPath) {
          return null;
        }
        requests++;
        return requests == 1
            ? null
            : ByteData.sublistView(utf8.encode(jsonEncode(_snapshot)));
      });
      addTearDown(() {
        messenger.setMockMessageHandler('flutter/assets', null);
        rootBundle.evict(assetPath);
      });
      await _pumpContributions(tester);
      expect(find.text('기여 기록을 불러오지 못했습니다.'), findsOneWidget);
      expect(find.byKey(const Key('github-contributions-grid')), findsNothing);
      await tester.tap(find.byKey(const Key('github-contributions-retry')));
      await tester.pumpAndSettle();
      expect(requests, 2);
      expect(find.text('hesu-dev'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _pumpContributions(
  WidgetTester tester, {
  Future<Map<String, dynamic>>? dataFuture,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppleTheme.dark(),
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: GitHubContributions(dataFuture: dataFuture),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

const _snapshot = <String, dynamic>{
  'username': 'hesu-dev',
  'fetchedAt': '2026-02-11T08:20:00Z',
  'privateIncluded': false,
  'totalContributions': 10,
  'colors': <String>['#9be9a8', '#40c463', '#30a14e', '#216e39'],
  'weeks': <Map<String, dynamic>>[
    <String, dynamic>{
      'firstDay': '2026-01-25',
      'contributionDays': <Map<String, dynamic>>[
        <String, dynamic>{
          'date': '2026-01-25',
          'weekday': 0,
          'contributionCount': 0,
          'contributionLevel': 'NONE',
          'color': '#ebedf0',
        },
        <String, dynamic>{
          'date': '2026-01-26',
          'weekday': 1,
          'contributionCount': 1,
          'contributionLevel': 'FIRST_QUARTILE',
          'color': '#9be9a8',
        },
      ],
    },
    <String, dynamic>{
      'firstDay': '2026-02-01',
      'contributionDays': <Map<String, dynamic>>[
        <String, dynamic>{
          'date': '2026-02-01',
          'weekday': 0,
          'contributionCount': 3,
          'contributionLevel': 'THIRD_QUARTILE',
          'color': '#30a14e',
        },
        <String, dynamic>{
          'date': '2026-02-02',
          'weekday': 1,
          'contributionCount': 2,
          'contributionLevel': 'SECOND_QUARTILE',
          'color': '#40c463',
        },
      ],
    },
    <String, dynamic>{
      'firstDay': '2026-02-08',
      'contributionDays': <Map<String, dynamic>>[
        <String, dynamic>{
          'date': '2026-02-08',
          'weekday': 0,
          'contributionCount': 4,
          'contributionLevel': 'FOURTH_QUARTILE',
          'color': '#216e39',
        },
      ],
    },
  ],
};
