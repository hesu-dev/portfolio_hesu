import 'package:flutter/material.dart';

import '../theme/apple_theme.dart';
import '../services/github_contributions_loader.dart';

class GitHubContributions extends StatefulWidget {
  const GitHubContributions({this.dataFuture, this.dataLoader, super.key});

  final Future<Map<String, dynamic>>? dataFuture;
  final Future<Map<String, dynamic>> Function()? dataLoader;

  @override
  State<GitHubContributions> createState() => _GitHubContributionsState();
}

class _GitHubContributionsState extends State<GitHubContributions> {
  static const _cellSize = 11.0;
  static const _gap = 3.0;
  static const _step = _cellSize + _gap;
  late Future<Map<String, dynamic>> _data;
  String? _selectedDate;

  @override
  void initState() {
    super.initState();
    _data = _load();
  }

  @override
  void didUpdateWidget(covariant GitHubContributions oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dataFuture != widget.dataFuture ||
        oldWidget.dataLoader != widget.dataLoader) {
      _data = _load();
    }
  }

  Future<Map<String, dynamic>> _load() =>
      widget.dataFuture ??
      (widget.dataLoader?.call() ?? loadGitHubContributions());

  void _retry() {
    setState(() {
      _data = _load();
    });
  }

  Color _emptyColor(BuildContext context) => AppleTheme.isDark(context)
      ? const Color(0xFF1B3D26)
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
    child: FutureBuilder<Map<String, dynamic>>(
      future: _data,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          try {
            return _calendar(
              context,
              snapshot.data!,
              refreshing: snapshot.connectionState != ConnectionState.done,
            );
          } catch (_) {
            return _card(_error(context));
          }
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return _card(
            Text('기여 기록을 불러오는 중…', style: AppleTheme.caption(context)),
          );
        }
        return _card(_error(context));
      },
    ),
  );

  Widget _card(Widget child) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF143D20), Color(0xFF091B10)],
      ),
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: const Color(0xFF295E34)),
    ),
    child: child,
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

  Widget _calendar(
    BuildContext context,
    Map<String, dynamic> data, {
    required bool refreshing,
  }) {
    if (data['isFallback'] == true) {
      throw const FormatException('Saved contribution calendars are disabled.');
    }
    final username = data['username'] as String;
    final weeks = (data['weeks'] as List).cast<Map<String, dynamic>>();
    final colors = (data['colors'] as List).cast<String>().map(_color).toList();
    final gridWidth = weeks.length * _step - _gap;
    final caption = AppleTheme.caption(context);
    final days = [
      for (final week in weeks)
        ...(week['contributionDays'] as List).cast<Map<String, dynamic>>(),
    ]..sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));
    final selectedDay = _selectedDate == null
        ? days.lastOrNull
        : days.where((day) => day['date'] == _selectedDate).firstOrNull;
    final latestDate = days.isEmpty
        ? null
        : DateTime.parse('${days.last['date']}T00:00:00Z');
    final selectedDate = _selectedDate == null
        ? latestDate
        : DateTime.parse('${_selectedDate}T00:00:00Z');
    final count = selectedDay == null
        ? null
        : selectedDay['contributionCount'] as int;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (latestDate != null) ...[
          _dates(context, latestDate, selectedDate!, days),
          const SizedBox(height: 16),
        ],
        _card(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF24572F),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.code_rounded,
                      color: Color(0xFF56E36F),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('기여 기록', style: AppleTheme.title(context)),
                          Text(
                            username,
                            style: caption.copyWith(
                              color: const Color(0xFF70DC83),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    key: const Key('github-contributions-refresh'),
                    tooltip: '기여 기록 새로고침',
                    onPressed: refreshing ? null : _retry,
                    icon: refreshing
                        ? const SizedBox.square(
                            dimension: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: 12,
                runSpacing: 4,
                children: [
                  Text(
                    '${data['totalContributions']} contributions',
                    style: AppleTheme.body(
                      context,
                    ).copyWith(fontWeight: FontWeight.w600),
                  ),
                  if (selectedDate != null)
                    Text(
                      '${selectedDate.month}월 ${selectedDate.day}일 · ${count == null ? '기록 없음' : '$count회 기여'}',
                      key: const Key('github-selected-activity'),
                      style: caption.copyWith(color: const Color(0xFF96D8A2)),
                    ),
                ],
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
                                child: Text(
                                  switch (weekday) {
                                    1 => '월',
                                    3 => '수',
                                    5 => '금',
                                    _ => '',
                                  },
                                  style: caption.copyWith(
                                    fontSize: 9,
                                    height: 1,
                                  ),
                                ),
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
            ],
          ),
        ),
      ],
    );
  }

  Widget _dates(
    BuildContext context,
    DateTime latest,
    DateTime selected,
    List<Map<String, dynamic>> days,
  ) {
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = ((constraints.maxWidth - 36) / 7).clamp(
          44.0 * scale,
          double.infinity,
        );
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          reverse: true,
          child: Row(
            children: [
              for (var index = 6; index >= 0; index--)
                Builder(
                  builder: (context) {
                    final date = latest.subtract(Duration(days: index));
                    final value = date.toIso8601String().substring(0, 10);
                    final active = date == selected;
                    final day = days
                        .where((day) => day['date'] == value)
                        .firstOrNull;
                    final hasActivity =
                        ((day ?? const <String, dynamic>{})['contributionCount']
                                as int? ??
                            0) >
                        0;
                    return Padding(
                      padding: EdgeInsets.only(left: index == 6 ? 0 : 6),
                      child: Semantics(
                        selected: active,
                        button: true,
                        label: '${date.month}월 ${date.day}일 기여 기록',
                        child: Material(
                          color: active
                              ? const Color(0xFFF7F7F2)
                              : const Color(0xFF1B1B1D),
                          borderRadius: BorderRadius.circular(18),
                          child: InkWell(
                            key: Key('github-date-$value'),
                            borderRadius: BorderRadius.circular(18),
                            onTap: () => setState(() => _selectedDate = value),
                            child: SizedBox(
                              width: width,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      weekdays[date.weekday - 1],
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: active
                                            ? const Color(0xFF555558)
                                            : const Color(0xFFA6A6AB),
                                      ),
                                    ),
                                    Text(
                                      '${date.day}',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w600,
                                        height: 1.3,
                                        color: active
                                            ? Colors.black
                                            : Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Container(
                                      width: 5,
                                      height: 5,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: hasActivity
                                            ? const Color(0xFF4CDB65)
                                            : const Color(0xFF737378),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
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
