import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_hesu/portfolio/apps/music_app.dart';
import 'package:portfolio_hesu/portfolio/music/music_controller.dart';
import 'package:portfolio_hesu/portfolio/music/music_playback.dart';
import 'package:portfolio_hesu/portfolio/music/music_session_store.dart';
import 'package:portfolio_hesu/portfolio/music/music_track.dart';
import 'package:portfolio_hesu/portfolio/theme/apple_theme.dart';

void main() {
  const tracks = <MusicTrack>[
    MusicTrack(assetPath: 'assets/music/01-first.mp3', title: 'First Song'),
    MusicTrack(assetPath: 'assets/music/02-second.mp3', title: 'Second Song'),
    MusicTrack(assetPath: 'assets/music/03-third.mp3', title: 'Third Song'),
  ];

  group('MusicApp', () {
    testWidgets('shows an empty asset state with disabled controls', (
      tester,
    ) async {
      final controller = MusicController(
        tracks: const <MusicTrack>[],
        playbackFactory: _FakePlayback.new,
      );
      addTearDown(controller.dispose);

      await _pumpMusic(tester, controller: controller);

      expect(find.byKey(const Key('music-app')), findsOneWidget);
      expect(find.byKey(const Key('music-empty-state')), findsOneWidget);
      expect(find.text('음악 파일이 없습니다'), findsOneWidget);
      expect(find.textContaining('assets/music'), findsOneWidget);
      for (final key in const <Key>[
        Key('music-previous'),
        Key('music-play-pause'),
        Key('music-next'),
      ]) {
        expect(_transportButton(tester, key).onPressed, isNull);
      }
      expect(
        tester.widget<Slider>(find.byKey(const Key('music-volume'))).onChanged,
        isNull,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'shows the current card, count, and complete track list paused',
      (tester) async {
        final controller = MusicController(
          tracks: tracks,
          playbackFactory: _FakePlayback.new,
        );
        addTearDown(controller.dispose);

        await _pumpMusic(
          tester,
          controller: controller,
          size: const Size(900, 650),
          compact: false,
        );

        expect(find.byKey(const Key('music-track-card')), findsOneWidget);
        expect(
          find.byKey(const Key('music-track-card-assets/music/01-first.mp3-0')),
          findsOneWidget,
        );
        expect(find.text('First Song'), findsWidgets);
        expect(find.text('1 / 3'), findsOneWidget);
        for (final track in tracks) {
          expect(find.text(track.title), findsWidgets);
        }
        expect(controller.isPlaying, isFalse);
        expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
        expect(find.byKey(const Key('music-layout-desktop')), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('play, previous, next, and list selection control playback', (
      tester,
    ) async {
      final playback = _FakePlayback();
      final controller = MusicController(
        tracks: tracks,
        playbackFactory: () => playback,
      );
      addTearDown(controller.dispose);
      addTearDown(playback.dispose);
      await _pumpMusic(tester, controller: controller);

      await tester.tap(find.byKey(const Key('music-play-pause')));
      await tester.pumpAndSettle();
      expect(controller.isPlaying, isTrue);
      expect(playback.playedTracks, <MusicTrack>[tracks[0]]);
      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);

      await tester.tap(find.byKey(const Key('music-previous')));
      await tester.pumpAndSettle();
      expect(controller.currentIndex, 2);
      expect(playback.playedTracks.last, tracks[2]);

      await tester.tap(find.byKey(const Key('music-next')));
      await tester.pumpAndSettle();
      expect(controller.currentIndex, 0);

      await tester.tap(find.byKey(const Key('music-track-row-1')));
      await tester.pumpAndSettle();
      expect(controller.currentIndex, 1);
      expect(playback.playedTracks.last, tracks[1]);
      expect(tester.takeException(), isNull);
    });

    testWidgets('horizontal swipes navigate and wrap the queue', (
      tester,
    ) async {
      final controller = MusicController(
        tracks: tracks,
        playbackFactory: _FakePlayback.new,
      );
      addTearDown(controller.dispose);
      await _pumpMusic(tester, controller: controller);

      await tester.fling(
        find.byKey(const Key('music-track-gesture')),
        const Offset(-240, 0),
        900,
      );
      await tester.pumpAndSettle();
      expect(controller.currentIndex, 1);

      await tester.fling(
        find.byKey(const Key('music-track-gesture')),
        const Offset(240, 0),
        900,
      );
      await tester.pumpAndSettle();
      expect(controller.currentIndex, 0);

      await tester.fling(
        find.byKey(const Key('music-track-gesture')),
        const Offset(240, 0),
        900,
      );
      await tester.pumpAndSettle();
      expect(controller.currentIndex, 2);
    });

    testWidgets('changes queue mode and volume from accessible controls', (
      tester,
    ) async {
      final playback = _FakePlayback();
      final controller = MusicController(
        tracks: tracks,
        playbackFactory: () => playback,
      );
      addTearDown(controller.dispose);
      addTearDown(playback.dispose);
      final semantics = tester.ensureSemantics();
      await _pumpMusic(tester, controller: controller);

      await tester.tap(find.byKey(const Key('music-mode-repeat-one')));
      await tester.pump();
      expect(controller.mode, MusicPlaybackMode.repeatOne);
      expect(find.text('한 곡 반복'), findsOneWidget);

      await tester.tap(find.byKey(const Key('music-mode-queue')));
      await tester.pump();
      expect(controller.mode, MusicPlaybackMode.queue);

      final slider = tester.widget<Slider>(
        find.byKey(const Key('music-volume')),
      );
      slider.onChanged!(0.35);
      await tester.pumpAndSettle();
      expect(controller.volume, 0.35);

      final playSemantics = tester
          .getSemantics(find.byKey(const Key('music-play-pause')))
          .getSemanticsData();
      expect(playSemantics.label, contains('재생'));
      expect(playSemantics.flagsCollection.isButton, isTrue);
      expect(playSemantics.hasAction(ui.SemanticsAction.tap), isTrue);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });

    testWidgets('keyboard arrows navigate and space toggles playback', (
      tester,
    ) async {
      final playback = _FakePlayback();
      final controller = MusicController(
        tracks: tracks,
        playbackFactory: () => playback,
      );
      addTearDown(controller.dispose);
      addTearDown(playback.dispose);
      await _pumpMusic(tester, controller: controller);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(controller.currentIndex, 1);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(controller.currentIndex, 0);

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(controller.isPlaying, isTrue);
      expect(playback.playedTracks, <MusicTrack>[tracks[0]]);
    });

    testWidgets(
      'focused controls keep their standard Space and arrow actions',
      (tester) async {
        final playback = _FakePlayback();
        final controller = MusicController(
          tracks: tracks,
          playbackFactory: () => playback,
        );
        addTearDown(controller.dispose);
        addTearDown(playback.dispose);
        final semantics = tester.ensureSemantics();
        await _pumpMusic(tester, controller: controller);

        for (var index = 0; index < 5; index++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pump();
        }
        expect(
          tester
              .getSemantics(find.byKey(const Key('music-mode-repeat-one')))
              .getSemanticsData()
              .flagsCollection
              .isFocused,
          ui.Tristate.isTrue,
        );

        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pump();
        expect(controller.mode, MusicPlaybackMode.repeatOne);
        expect(controller.isPlaying, isFalse);

        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        final previousVolume = controller.volume;
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await tester.pump();
        expect(controller.currentIndex, 0);
        expect(controller.volume, lessThan(previousVolume));
        expect(controller.isPlaying, isFalse);

        semantics.dispose();
      },
    );

    testWidgets('each navigation gets a perspective half-flip revision key', (
      tester,
    ) async {
      final controller = MusicController(
        tracks: tracks.take(1),
        playbackFactory: _FakePlayback.new,
      );
      addTearDown(controller.dispose);
      await _pumpMusic(tester, controller: controller);

      expect(
        find.byKey(const Key('music-track-card-assets/music/01-first.mp3-0')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('music-next')));
      await tester.pump(const Duration(milliseconds: 85));

      const oldKey = Key('music-track-card-assets/music/01-first.mp3-0');
      const newKey = Key('music-track-card-assets/music/01-first.mp3-1');
      expect(_flipOpacity(tester, oldKey), 1);
      expect(_flipOpacity(tester, newKey), 0);

      final transforms = tester.widgetList<Transform>(
        find.descendant(
          of: find.byKey(const Key('music-track-switcher')),
          matching: find.byType(Transform),
        ),
      );
      expect(transforms, isNotEmpty);
      expect(
        transforms.any(
          (widget) => (widget.transform.entry(3, 2) - 0.001).abs() < 0.000001,
        ),
        isTrue,
      );
      for (final transform in transforms) {
        final cosine = transform.transform.entry(0, 0).clamp(-1.0, 1.0);
        expect(math.acos(cosine), lessThanOrEqualTo(math.pi / 2 + 0.001));
      }

      await tester.pump(const Duration(milliseconds: 170));
      expect(_flipOpacity(tester, oldKey), 0);
      expect(_flipOpacity(tester, newKey), 1);

      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('music-track-card-assets/music/01-first.mp3-1')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('music-next')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('music-track-card-assets/music/01-first.mp3-2')),
        findsOneWidget,
      );
    });

    testWidgets(
      'compact, tablet, and desktop layouts survive 200 percent text',
      (tester) async {
        for (final scenario
            in const <({Size size, bool compact, bool tablet, Key key})>[
              (
                size: Size(320, 420),
                compact: true,
                tablet: false,
                key: Key('music-layout-compact'),
              ),
              (
                size: Size(834, 700),
                compact: false,
                tablet: true,
                key: Key('music-layout-tablet'),
              ),
              (
                size: Size(980, 650),
                compact: false,
                tablet: false,
                key: Key('music-layout-desktop'),
              ),
            ]) {
          final controller = MusicController(
            tracks: tracks,
            playbackFactory: _FakePlayback.new,
          );
          await _pumpMusic(
            tester,
            controller: controller,
            size: scenario.size,
            compact: scenario.compact,
            tablet: scenario.tablet,
            textScaler: const TextScaler.linear(2),
          );

          expect(
            find.byKey(scenario.key),
            findsOneWidget,
            reason: '${scenario.size}',
          );
          expect(find.byKey(const Key('music-scroll')), findsOneWidget);
          await tester.ensureVisible(
            find.byKey(const Key('music-track-row-2')),
          );
          await tester.pump();
          for (final key in const <Key>[
            Key('music-previous'),
            Key('music-play-pause'),
            Key('music-next'),
          ]) {
            expect(
              tester.getSize(find.byKey(key)).height,
              greaterThanOrEqualTo(44),
              reason: '${scenario.size}/$key',
            );
          }
          expect(tester.takeException(), isNull, reason: '${scenario.size}');

          await tester.pumpWidget(const SizedBox.shrink());
          controller.dispose();
        }
      },
    );
  });
}

class _FakePlayback implements MusicPlayback {
  final List<MusicTrack> playedTracks = <MusicTrack>[];

  @override
  Stream<void> get onComplete => const Stream<void>.empty();

  @override
  Future<void> dispose() async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> play(MusicTrack track) async {
    playedTracks.add(track);
  }

  @override
  Future<void> resume() async {}

  @override
  Future<void> setVolume(double volume) async {}
}

IconButton _transportButton(WidgetTester tester, Key key) {
  return tester.widget<IconButton>(
    find.descendant(of: find.byKey(key), matching: find.byType(IconButton)),
  );
}

double _flipOpacity(WidgetTester tester, Key cardKey) {
  return tester
      .widget<Opacity>(
        find
            .ancestor(of: find.byKey(cardKey), matching: find.byType(Opacity))
            .first,
      )
      .opacity;
}

Future<void> _pumpMusic(
  WidgetTester tester, {
  required MusicController controller,
  Size size = const Size(390, 640),
  bool compact = true,
  bool tablet = false,
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppleTheme.light(),
      darkTheme: AppleTheme.dark(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: textScaler),
        child: child!,
      ),
      home: SizedBox.expand(
        child: MusicApp(
          controller: controller,
          compact: compact,
          tablet: tablet,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
