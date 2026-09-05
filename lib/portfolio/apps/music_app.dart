import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../music/music_controller.dart';
import '../music/music_session_store.dart';
import '../music/music_track.dart';
import '../theme/apple_theme.dart';
import '../widgets/apple_selection_control.dart';

class MusicApp extends StatefulWidget {
  const MusicApp({
    required this.controller,
    this.compact = false,
    this.tablet = false,
    this.shortcutsEnabled = true,
    super.key,
  });

  final MusicController controller;
  final bool compact;
  final bool tablet;
  final bool shortcutsEnabled;

  @override
  State<MusicApp> createState() => _MusicAppState();
}

class _MusicAppState extends State<MusicApp> {
  final FocusNode _shortcutFocusNode = FocusNode(
    debugLabel: 'music-player-shortcuts',
  );
  double _horizontalDrag = 0;

  @override
  void initState() {
    super.initState();
    _scheduleShortcutFocus();
  }

  @override
  void didUpdateWidget(MusicApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.shortcutsEnabled && widget.shortcutsEnabled) {
      _scheduleShortcutFocus();
    } else if (oldWidget.shortcutsEnabled && !widget.shortcutsEnabled) {
      _shortcutFocusNode.unfocus();
    }
  }

  void _scheduleShortcutFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          widget.shortcutsEnabled &&
          _shortcutFocusNode.canRequestFocus) {
        _shortcutFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _shortcutFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppleAppSurface(
      key: const Key('music-app'),
      child: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          final controller = widget.controller;
          return Focus(
            focusNode: _shortcutFocusNode,
            canRequestFocus: widget.shortcutsEnabled,
            descendantsAreFocusable: widget.shortcutsEnabled,
            onKeyEvent: (node, event) {
              if (!widget.shortcutsEnabled ||
                  !node.hasPrimaryFocus ||
                  event is! KeyDownEvent) {
                return KeyEventResult.ignored;
              }
              if (controller.tracks.isEmpty) {
                return KeyEventResult.ignored;
              }
              if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                unawaited(controller.previous());
                return KeyEventResult.handled;
              }
              if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                unawaited(controller.next());
                return KeyEventResult.handled;
              }
              if (event.logicalKey == LogicalKeyboardKey.space) {
                unawaited(controller.togglePlayback());
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (controller.tracks.isEmpty) {
                  return _MusicEmptyView(controller: controller);
                }

                final layout = widget.compact
                    ? _MusicLayout.compact
                    : widget.tablet
                    ? _MusicLayout.tablet
                    : _MusicLayout.desktop;
                final useColumns =
                    layout == _MusicLayout.desktop &&
                    constraints.maxWidth >= 720;
                final nowPlaying = _NowPlayingPane(
                  controller: controller,
                  compact: layout == _MusicLayout.compact,
                  onDragStart: () => _horizontalDrag = 0,
                  onDragUpdate: (delta) => _horizontalDrag += delta,
                  onDragEnd: (velocity) {
                    _finishHorizontalDrag(controller, velocity);
                  },
                );
                final trackList = _TrackList(controller: controller);

                return SingleChildScrollView(
                  key: const Key('music-scroll'),
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  padding: EdgeInsets.all(
                    layout == _MusicLayout.compact ? 14 : 24,
                  ),
                  child: KeyedSubtree(
                    key: Key('music-layout-${layout.name}'),
                    child: useColumns
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Expanded(flex: 6, child: nowPlaying),
                              const SizedBox(width: 24),
                              Expanded(flex: 5, child: trackList),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              nowPlaying,
                              SizedBox(
                                height: layout == _MusicLayout.compact
                                    ? 16
                                    : 24,
                              ),
                              trackList,
                            ],
                          ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _finishHorizontalDrag(
    MusicController controller,
    double primaryVelocity,
  ) {
    final effectiveDelta = primaryVelocity.abs() >= 240
        ? primaryVelocity
        : _horizontalDrag;
    _horizontalDrag = 0;
    if (effectiveDelta <= -34) {
      unawaited(controller.next());
    } else if (effectiveDelta >= 34) {
      unawaited(controller.previous());
    }
  }
}

enum _MusicLayout { compact, tablet, desktop }

class _MusicEmptyView extends StatelessWidget {
  const _MusicEmptyView({required this.controller});

  final MusicController controller;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const Key('music-scroll'),
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: <Widget>[
          const KeyedSubtree(
            key: Key('music-empty-state'),
            child: AppleEmptyState(
              icon: Icons.music_off_rounded,
              title: '음악 파일이 없습니다',
              message: 'assets/music 폴더에 음악 파일을 추가하면 목록에 표시됩니다.',
            ),
          ),
          _TransportControls(controller: controller, enabled: false),
          const SizedBox(height: 12),
          _VolumeControl(controller: controller, enabled: false),
        ],
      ),
    );
  }
}

class _NowPlayingPane extends StatelessWidget {
  const _NowPlayingPane({
    required this.controller,
    required this.compact,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  final MusicController controller;
  final bool compact;
  final VoidCallback onDragStart;
  final ValueChanged<double> onDragUpdate;
  final ValueChanged<double> onDragEnd;

  @override
  Widget build(BuildContext context) {
    final track = controller.currentTrack!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _FlipTrackCard(
          controller: controller,
          track: track,
          compact: compact,
          onDragStart: onDragStart,
          onDragUpdate: onDragUpdate,
          onDragEnd: onDragEnd,
        ),
        const SizedBox(height: 18),
        Text(
          track.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: AppleTheme.title(
            context,
          ).copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 5),
        Text(
          '${controller.currentIndex + 1} / ${controller.tracks.length}',
          textAlign: TextAlign.center,
          style: AppleTheme.caption(context).copyWith(
            color: AppleTheme.secondaryLabel(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        if (controller.errorMessage case final message?) ...<Widget>[
          AppleFeedbackBanner(message: message),
          const SizedBox(height: 12),
        ],
        _TransportControls(controller: controller),
        const SizedBox(height: 12),
        _PlaybackModePicker(controller: controller),
        const SizedBox(height: 12),
        _VolumeControl(controller: controller),
      ],
    );
  }
}

class _FlipTrackCard extends StatelessWidget {
  const _FlipTrackCard({
    required this.controller,
    required this.track,
    required this.compact,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  final MusicController controller;
  final MusicTrack track;
  final bool compact;
  final VoidCallback onDragStart;
  final ValueChanged<double> onDragUpdate;
  final ValueChanged<double> onDragEnd;

  @override
  Widget build(BuildContext context) {
    final cardKey = ValueKey<String>(
      'music-track-card-${track.assetPath}-${controller.navigationRevision}',
    );
    final direction =
        controller.navigationDirection ?? MusicNavigationDirection.next;
    final directionSign = direction == MusicNavigationDirection.next
        ? 1.0
        : -1.0;

    return Semantics(
      label: '현재 재생 곡 ${track.title}. 좌우로 쓸어 곡 이동',
      container: true,
      child: GestureDetector(
        key: const Key('music-track-gesture'),
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart: (_) => onDragStart(),
        onHorizontalDragUpdate: (details) => onDragUpdate(details.delta.dx),
        onHorizontalDragEnd: (details) =>
            onDragEnd(details.primaryVelocity ?? 0),
        child: SizedBox(
          key: const Key('music-track-card'),
          child: ClipRect(
            child: AnimatedSwitcher(
              key: const Key('music-track-switcher'),
              duration: const Duration(milliseconds: 340),
              reverseDuration: const Duration(milliseconds: 340),
              switchInCurve: Curves.linear,
              switchOutCurve: Curves.linear,
              layoutBuilder: (currentChild, previousChildren) => Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  ...previousChildren,
                  if (currentChild != null) currentChild,
                ],
              ),
              transitionBuilder: (child, animation) {
                final incoming = child.key == cardKey;
                return AnimatedBuilder(
                  animation: animation,
                  child: child,
                  builder: (context, child) {
                    final value = animation.value.clamp(0.0, 1.0);
                    final visible = incoming ? value >= 0.5 : value > 0.5;
                    final linearProgress = incoming
                        ? ((value - 0.5) * 2).clamp(0.0, 1.0)
                        : ((1 - value) * 2).clamp(0.0, 1.0);
                    final easedProgress = Curves.easeInOutCubic.transform(
                      linearProgress,
                    );
                    final rotation = incoming
                        ? (1 - easedProgress) * math.pi / 2 * directionSign
                        : easedProgress * math.pi / 2 * -directionSign;
                    return Opacity(
                      opacity: visible ? 1 : 0,
                      child: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001)
                          ..rotateY(rotation),
                        child: child,
                      ),
                    );
                  },
                );
              },
              child: _TrackArtwork(
                key: cardKey,
                track: track,
                compact: compact,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TrackArtwork extends StatelessWidget {
  const _TrackArtwork({required this.track, required this.compact, super.key});

  final MusicTrack track;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: compact ? 190 : 250),
      padding: EdgeInsets.all(compact ? 24 : 34),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFFFF5B75),
            Color(0xFFE6194D),
            Color(0xFF980F3A),
          ],
        ),
        borderRadius: BorderRadius.circular(compact ? 24 : 30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            Icons.music_note_rounded,
            size: compact ? 76 : 104,
            color: Colors.white,
          ),
          const SizedBox(height: 14),
          Text(
            track.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransportControls extends StatelessWidget {
  const _TransportControls({required this.controller, this.enabled = true});

  final MusicController controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '음악 재생 제어',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          _SemanticTransportButton(
            key: const Key('music-previous'),
            label: '이전 곡',
            enabled: enabled,
            onTap: enabled ? () => unawaited(controller.previous()) : null,
            child: IconButton(
              tooltip: '이전 곡',
              onPressed: enabled
                  ? () => unawaited(controller.previous())
                  : null,
              iconSize: 30,
              icon: const Icon(Icons.skip_previous_rounded),
            ),
          ),
          const SizedBox(width: 14),
          _SemanticTransportButton(
            key: const Key('music-play-pause'),
            label: controller.isPlaying ? '일시 정지' : '재생',
            enabled: enabled,
            onTap: enabled
                ? () => unawaited(controller.togglePlayback())
                : null,
            child: IconButton.filled(
              tooltip: controller.isPlaying ? '일시 정지' : '재생',
              onPressed: enabled
                  ? () => unawaited(controller.togglePlayback())
                  : null,
              iconSize: 34,
              padding: const EdgeInsets.all(14),
              style: IconButton.styleFrom(
                backgroundColor: AppleTheme.red,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppleTheme.separator(context),
                disabledForegroundColor: AppleTheme.secondaryLabel(context),
              ),
              icon: Icon(
                controller.isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
              ),
            ),
          ),
          const SizedBox(width: 14),
          _SemanticTransportButton(
            key: const Key('music-next'),
            label: '다음 곡',
            enabled: enabled,
            onTap: enabled ? () => unawaited(controller.next()) : null,
            child: IconButton(
              tooltip: '다음 곡',
              onPressed: enabled ? () => unawaited(controller.next()) : null,
              iconSize: 30,
              icon: const Icon(Icons.skip_next_rounded),
            ),
          ),
        ],
      ),
    );
  }
}

class _SemanticTransportButton extends StatelessWidget {
  const _SemanticTransportButton({
    required this.label,
    required this.enabled,
    required this.onTap,
    required this.child,
    super.key,
  });

  final String label;
  final bool enabled;
  final VoidCallback? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      enabled: enabled,
      onTap: onTap,
      excludeSemantics: true,
      child: child,
    );
  }
}

class _PlaybackModePicker extends StatelessWidget {
  const _PlaybackModePicker({required this.controller});

  final MusicController controller;

  @override
  Widget build(BuildContext context) {
    final stackChoices = MediaQuery.textScalerOf(context).scale(1) >= 1.5;
    final children = <Widget>[
      _ModeChoice(
        key: const Key('music-mode-queue'),
        label: '리스트 재생',
        icon: Icons.repeat_rounded,
        selected: controller.mode == MusicPlaybackMode.queue,
        onPressed: () => controller.setMode(MusicPlaybackMode.queue),
      ),
      _ModeChoice(
        key: const Key('music-mode-repeat-one'),
        label: '한 곡 반복',
        icon: Icons.repeat_one_rounded,
        selected: controller.mode == MusicPlaybackMode.repeatOne,
        onPressed: () => controller.setMode(MusicPlaybackMode.repeatOne),
      ),
    ];
    if (stackChoices) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[children[0], const SizedBox(height: 8), children[1]],
      );
    }
    return Row(
      children: <Widget>[
        Expanded(child: children[0]),
        const SizedBox(width: 8),
        Expanded(child: children[1]),
      ],
    );
  }
}

class _ModeChoice extends StatelessWidget {
  const _ModeChoice({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onPressed,
    super.key,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AppleSelectionControl(
      semanticsLabel: '$label 모드',
      selected: selected,
      onPressed: onPressed,
      borderRadius: BorderRadius.circular(12),
      focusColor: AppleTheme.red,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? AppleTheme.red.withValues(alpha: 0.13)
              : AppleTheme.panel(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? AppleTheme.red.withValues(alpha: 0.42)
                : AppleTheme.separator(context),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              icon,
              size: 19,
              color: selected
                  ? AppleTheme.red
                  : AppleTheme.secondaryLabel(context),
            ),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: selected
                      ? AppleTheme.red
                      : AppleTheme.primaryLabel(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VolumeControl extends StatelessWidget {
  const _VolumeControl({required this.controller, this.enabled = true});

  final MusicController controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '음량 ${(controller.volume * 100).round()}퍼센트',
      child: Row(
        children: <Widget>[
          Icon(
            controller.volume == 0
                ? Icons.volume_off_rounded
                : Icons.volume_down_rounded,
            color: AppleTheme.secondaryLabel(context),
          ),
          Expanded(
            child: Slider(
              key: const Key('music-volume'),
              value: controller.volume,
              activeColor: AppleTheme.red,
              onChanged: enabled
                  ? (value) => unawaited(controller.setVolume(value))
                  : null,
            ),
          ),
          Icon(
            Icons.volume_up_rounded,
            color: AppleTheme.secondaryLabel(context),
          ),
        ],
      ),
    );
  }
}

class _TrackList extends StatelessWidget {
  const _TrackList({required this.controller});

  final MusicController controller;

  @override
  Widget build(BuildContext context) {
    return AppleSurfaceCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 5, 8, 10),
            child: AppleSectionTitle(
              title: '재생 목록',
              subtitle: '${controller.tracks.length}곡 · 파일명 순서',
              icon: Icons.queue_music_rounded,
            ),
          ),
          for (
            var index = 0;
            index < controller.tracks.length;
            index++
          ) ...<Widget>[
            if (index > 0)
              Divider(
                height: 1,
                indent: 54,
                color: AppleTheme.separator(context),
              ),
            _TrackRow(
              key: Key('music-track-row-$index'),
              track: controller.tracks[index],
              index: index,
              selected: index == controller.currentIndex,
              playing: index == controller.currentIndex && controller.isPlaying,
              onPressed: () => unawaited(controller.select(index)),
            ),
          ],
        ],
      ),
    );
  }
}

class _TrackRow extends StatelessWidget {
  const _TrackRow({
    required this.track,
    required this.index,
    required this.selected,
    required this.playing,
    required this.onPressed,
    super.key,
  });

  final MusicTrack track;
  final int index;
  final bool selected;
  final bool playing;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AppleSelectionControl(
      semanticsLabel: '${index + 1}번 ${track.title}${playing ? ', 재생 중' : ''}',
      selected: selected,
      onPressed: onPressed,
      borderRadius: BorderRadius.circular(12),
      focusColor: AppleTheme.red,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        constraints: const BoxConstraints(minHeight: 58),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppleTheme.red.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 32,
              child: playing
                  ? Icon(Icons.graphic_eq_rounded, color: AppleTheme.red)
                  : Text(
                      '${index + 1}',
                      textAlign: TextAlign.center,
                      style: AppleTheme.caption(context).copyWith(
                        color: selected
                            ? AppleTheme.red
                            : AppleTheme.secondaryLabel(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    track.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppleTheme.body(context).copyWith(
                      color: selected
                          ? AppleTheme.red
                          : AppleTheme.primaryLabel(context),
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    track.assetPath.split('/').last,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppleTheme.caption(
                      context,
                    ).copyWith(color: AppleTheme.secondaryLabel(context)),
                  ),
                ],
              ),
            ),
            if (selected) ...<Widget>[
              const SizedBox(width: 8),
              Icon(
                playing ? Icons.pause_circle_filled : Icons.check_circle,
                color: AppleTheme.red,
                size: 21,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
