import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/apple_theme.dart';

class GitHubContributions extends StatefulWidget {
  const GitHubContributions({this.dataFuture, super.key});

  final Future<Map<String, dynamic>>? dataFuture;

  @override
  State<GitHubContributions> createState() => _GitHubContributionsState();
}

class _GitHubContributionsState extends State<GitHubContributions> {
  static const _assetPath = 'assets/github-profile/contributions.json';
  static const _cellSize = 11.0;
  static const _gap = 3.0;
  static const _step = _cellSize + _gap;
  late Future<Map<String, dynamic>> _data;

  @override
  void initState() {
    super.initState();
    _data = widget.dataFuture ?? _loadAsset();
  }

  @override
  void didUpdateWidget(covariant GitHubContributions oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dataFuture != widget.dataFuture) {
      _data = widget.dataFuture ?? _loadAsset();
    }
  }

  Future<Map<String, dynamic>> _loadAsset() async {
    return jsonDecode(await rootBundle.loadString(_assetPath))
        as Map<String, dynamic>;
  }

  void _retry() {
    rootBundle.evict(_assetPath);
    setState(() {
      _data = widget.dataFuture ?? _loadAsset();
    });
  }

  Color _emptyColor(BuildContext context) => AppleTheme.isDark(context)
      ? const Color(0xFF2D333B)
      : const Color(0xFFEBEDF0);

  Color _color(String value) {
    if (!RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(value)) {
      throw const FormatException('Invalid contribution color');
    }
    return Color(0xFF000000 | int.parse(value.substring(1), radix: 16));
  }

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('github-contributions'),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppleTheme.surface(context),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppleTheme.separator(context)),
    ),
    child: FutureBuilder<Map<String, dynamic>>(
      future: _data,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Text('기여 기록을 불러오는 중…', style: AppleTheme.caption(context));
        }
        if (snapshot.hasData) {
          try {
            return _calendar(context, snapshot.data!);
          } catch (_) {
            return _error(context);
          }
        }
        return _error(context);
      },
    ),
  );

  Widget _error(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Text('기여 기록을 불러오지 못했습니다.', style: AppleTheme.body(context)),
      const SizedBox(height: 6),
      TextButton(
        key: const Key('github-contributions-retry'),
        onPressed: _retry,
        child: const Text('다시 불러오기'),
      ),
    ],
  );

  Widget _calendar(BuildContext context, Map<String, dynamic> data) {
    final username = data['username'] as String;
    final fetchedAt = DateTime.parse(
      data['fetchedAt'] as String,
    ).toIso8601String().substring(0, 10);
    final weeks = (data['weeks'] as List).cast<Map<String, dynamic>>();
    final colors = (data['colors'] as List).cast<String>().map(_color).toList();
    final gridWidth = weeks.length * _step - _gap;
    final caption = AppleTheme.caption(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Semantics(
          header: true,
          child: Text(
            username,
            style: AppleTheme.body(
              context,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 14),
        if (weeks.isEmpty)
          Text('표시할 기여 기록이 없습니다.', style: caption)
        else
          SingleChildScrollView(
            key: const Key('github-contributions-scroll'),
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(right: 9),
                  child: Column(
                    children: <Widget>[
                      for (var weekday = 0; weekday < 7; weekday++)
                        SizedBox(
                          width: 16,
                          height: weekday == 6 ? _cellSize : _step,
                          child: Text(switch (weekday) {
                            1 => '월',
                            3 => '수',
                            5 => '금',
                            _ => '',
                          }, style: caption.copyWith(fontSize: 9, height: 1)),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _months(context, weeks, gridWidth),
                    Row(
                      key: const Key('github-contributions-grid'),
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        for (final (index, week) in weeks.indexed)
                          Padding(
                            padding: EdgeInsets.only(
                              right: index == weeks.length - 1 ? 0 : _gap,
                            ),
                            child: _week(context, week),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            Text('적음', style: caption),
            for (final color in <Color>[_emptyColor(context), ...colors])
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: _square(color),
              ),
            const SizedBox(width: 4),
            Text('많음', style: caption),
          ],
        ),
        const SizedBox(height: 10),
        Text('최신 반영: $fetchedAt', style: caption),
      ],
    );
  }

  Widget _months(
    BuildContext context,
    List<Map<String, dynamic>> weeks,
    double width,
  ) {
    const names = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final labels = <Widget>[];
    int? previousMonth;
    var previousPosition = -40.0;
    for (final (index, week) in weeks.indexed) {
      final month = DateTime.parse(week['firstDay'] as String).month;
      final position = (index * _step).clamp(
        0.0,
        (width - 28).clamp(0.0, width),
      );
      if (month != previousMonth && position - previousPosition >= 28) {
        labels.add(
          Positioned(
            left: position,
            child: Text(
              names[month - 1],
              style: AppleTheme.caption(context).copyWith(fontSize: 10),
            ),
          ),
        );
        previousPosition = position;
      }
      previousMonth = month;
    }
    return SizedBox(
      width: width,
      height: 22,
      child: Stack(clipBehavior: Clip.none, children: labels),
    );
  }

  Widget _week(BuildContext context, Map<String, dynamic> week) {
    final days = <int, Map<String, dynamic>>{
      for (final day
          in (week['contributionDays'] as List).cast<Map<String, dynamic>>())
        day['weekday'] as int: day,
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (var weekday = 0; weekday < 7; weekday++)
          Padding(
            padding: EdgeInsets.only(bottom: weekday == 6 ? 0 : _gap),
            child: days[weekday] != null
                ? _day(context, days[weekday]!)
                : const SizedBox.square(dimension: _cellSize),
          ),
      ],
    );
  }

  Widget _day(BuildContext context, Map<String, dynamic> day) {
    final date = day['date'] as String;
    final count = day['contributionCount'] as int;
    final color = count == 0
        ? _emptyColor(context)
        : _color(day['color'] as String);
    return Tooltip(
      message: date,
      child: Semantics(
        label: date,
        excludeSemantics: true,
        child: _square(color, key: Key('github-contribution-$date')),
      ),
    );
  }

  Widget _square(Color color, {Key? key}) => Container(
    key: key,
    width: _cellSize,
    height: _cellSize,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(2),
    ),
  );
}
