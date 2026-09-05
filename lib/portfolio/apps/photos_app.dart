import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/apple_theme.dart';
import '../widgets/apple_selection_control.dart';

class PhotosApp extends StatefulWidget {
  const PhotosApp({this.compact = false, this.tablet = false, super.key});

  final bool compact;
  final bool tablet;

  @override
  State<PhotosApp> createState() => _PhotosAppState();
}

class _PhotosAppState extends State<PhotosApp> {
  _PhotosTab _selectedTab = _PhotosTab.library;
  _PhotoAlbum _selectedAlbum = _PhotoAlbum.daily;
  _GalleryPhoto? _selectedPhoto;

  @override
  Widget build(BuildContext context) {
    final selectedPhoto = _selectedPhoto;
    return AppleAppSurface(
      key: const Key('photos-app'),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: selectedPhoto != null
            ? _PhotoDetailView(
                key: ValueKey<String>('photo-detail-${selectedPhoto.id}'),
                photo: selectedPhoto,
                compact: widget.compact,
                onClose: () => setState(() => _selectedPhoto = null),
              )
            : LayoutBuilder(
                key: const ValueKey<String>('photo-gallery'),
                builder: (context, constraints) {
                  final horizontalPadding = widget.compact
                      ? 14.0
                      : widget.tablet
                      ? 22.0
                      : 26.0;
                  final spacing = widget.compact ? 4.0 : 8.0;
                  final columns = _columnCount(constraints.maxWidth);
                  final visiblePhotos = _selectedTab == _PhotosTab.library
                      ? _galleryPhotos
                      : _galleryPhotos
                            .where((photo) => photo.album == _selectedAlbum)
                            .toList(growable: false);

                  return CustomScrollView(
                    key: const Key('photos-scroll'),
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    slivers: <Widget>[
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          widget.compact ? 14 : 22,
                          horizontalPadding,
                          widget.compact ? 14 : 20,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              _PhotosTabBar(
                                selectedTab: _selectedTab,
                                onSelected: (tab) =>
                                    setState(() => _selectedTab = tab),
                              ),
                              SizedBox(height: widget.compact ? 18 : 24),
                              if (_selectedTab == _PhotosTab.library)
                                _GallerySectionHeading(
                                  title: '최근 항목',
                                  detail: '사진 ${_galleryPhotos.length}장',
                                )
                              else ...<Widget>[
                                _AlbumPicker(
                                  selectedAlbum: _selectedAlbum,
                                  onSelected: (album) {
                                    setState(() => _selectedAlbum = album);
                                  },
                                ),
                                SizedBox(height: widget.compact ? 18 : 24),
                                _GallerySectionHeading(
                                  titleKey: const Key(
                                    'photos-active-album-title',
                                  ),
                                  title: _selectedAlbum.label,
                                  detail: '사진 ${visiblePhotos.length}장',
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                        ),
                        sliver: SliverGrid(
                          key: Key(
                            _selectedTab == _PhotosTab.library
                                ? 'photos-library-grid'
                                : 'photos-album-grid',
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => _PhotoThumbnail(
                              photo: visiblePhotos[index],
                              compact: widget.compact,
                              onPressed: () {
                                setState(
                                  () => _selectedPhoto = visiblePhotos[index],
                                );
                              },
                            ),
                            childCount: visiblePhotos.length,
                          ),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                mainAxisSpacing: spacing,
                                crossAxisSpacing: spacing,
                              ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: SizedBox(height: widget.compact ? 28 : 40),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }

  int _columnCount(double width) {
    if (widget.compact || width < 480) {
      return 3;
    }
    if (width >= 900) {
      return 6;
    }
    if (widget.tablet || width >= 680) {
      return 5;
    }
    return 4;
  }
}

class _PhotosTabBar extends StatelessWidget {
  const _PhotosTabBar({required this.selectedTab, required this.onSelected});

  final _PhotosTab selectedTab;
  final ValueChanged<_PhotosTab> onSelected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '사진 보기',
      child: Container(
        key: const Key('photos-tab-bar'),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppleTheme.panel(context),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: AppleTheme.separator(context).withValues(alpha: 0.72),
            width: 0.7,
          ),
        ),
        child: Row(
          children: <Widget>[
            for (final tab in _PhotosTab.values)
              Expanded(
                child: AppleSelectionControl(
                  key: Key('photos-${tab.name}-tab'),
                  semanticsLabel: '${tab.label} 탭',
                  selected: selectedTab == tab,
                  onPressed: () => onSelected(tab),
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    curve: Curves.easeOutCubic,
                    constraints: const BoxConstraints(minHeight: 42),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: selectedTab == tab
                          ? AppleTheme.surface(context)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      tab.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: selectedTab == tab
                            ? AppleTheme.primaryLabel(context)
                            : AppleTheme.secondaryLabel(context),
                        fontWeight: selectedTab == tab
                            ? FontWeight.w700
                            : FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GallerySectionHeading extends StatelessWidget {
  const _GallerySectionHeading({
    required this.title,
    required this.detail,
    this.titleKey,
  });

  final String title;
  final String detail;
  final Key? titleKey;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Expanded(
          child: Text(
            title,
            key: titleKey,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppleTheme.title(context),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          detail,
          maxLines: 1,
          style: AppleTheme.caption(
            context,
          ).copyWith(color: AppleTheme.secondaryLabel(context)),
        ),
      ],
    );
  }
}

class _AlbumPicker extends StatelessWidget {
  const _AlbumPicker({required this.selectedAlbum, required this.onSelected});

  final _PhotoAlbum selectedAlbum;
  final ValueChanged<_PhotoAlbum> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('photos-album-picker'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('나의 앨범', style: AppleTheme.title(context)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (final album in _PhotoAlbum.values)
              _AlbumChoice(
                album: album,
                selected: selectedAlbum == album,
                count: _galleryPhotos
                    .where((photo) => photo.album == album)
                    .length,
                onPressed: () => onSelected(album),
              ),
          ],
        ),
      ],
    );
  }
}

class _AlbumChoice extends StatelessWidget {
  const _AlbumChoice({
    required this.album,
    required this.selected,
    required this.count,
    required this.onPressed,
  });

  final _PhotoAlbum album;
  final bool selected;
  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(13);
    return AppleSelectionControl(
      key: Key('photos-album-${album.name}'),
      semanticsLabel: '${album.label} 앨범, 사진 $count장',
      selected: selected,
      onPressed: onPressed,
      borderRadius: borderRadius,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        constraints: const BoxConstraints(minWidth: 104, minHeight: 52),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? AppleTheme.selectionBackground(context, album.accent)
              : AppleTheme.surface(context),
          borderRadius: borderRadius,
          border: Border.all(
            color: selected
                ? album.accent.withValues(alpha: 0.55)
                : AppleTheme.separator(context).withValues(alpha: 0.75),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(album.icon, color: album.accent, size: 19),
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  album.label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppleTheme.primaryLabel(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '$count장',
                  style: AppleTheme.caption(context).copyWith(
                    color: AppleTheme.secondaryLabel(context),
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoThumbnail extends StatelessWidget {
  const _PhotoThumbnail({
    required this.photo,
    required this.compact,
    required this.onPressed,
  });

  final _GalleryPhoto photo;
  final bool compact;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(compact ? 7 : 11);
    return AppleSelectionControl(
      key: Key('photos-photo-${photo.id}'),
      semanticsLabel: '${photo.title} 열기, ${photo.album.label} 앨범',
      selected: false,
      onPressed: onPressed,
      borderRadius: radius,
      overlayColor: WidgetStatePropertyAll(
        Colors.white.withValues(alpha: 0.16),
      ),
      focusColor: Colors.white,
      child: ClipRRect(
        borderRadius: radius,
        child: _PhotoArtwork(photo: photo, compact: compact),
      ),
    );
  }
}

class _PhotoDetailView extends StatelessWidget {
  const _PhotoDetailView({
    required this.photo,
    required this.compact,
    required this.onClose,
    super.key,
  });

  final _GalleryPhoto photo;
  final bool compact;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = compact ? 10.0 : 20.0;
    final photoNumber = _galleryPhotos.indexOf(photo) + 1;

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.escape): onClose,
      },
      child: Focus(
        autofocus: true,
        child: ColoredBox(
          key: const Key('photos-detail-view'),
          color: const Color(0xFF08090C),
          child: Column(
            children: <Widget>[
              Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  compact ? 8 : 14,
                  horizontalPadding,
                  compact ? 6 : 10,
                ),
                child: Row(
                  children: <Widget>[
                    IconButton(
                      key: const Key('photos-detail-close'),
                      tooltip: '갤러리로 돌아가기',
                      onPressed: onClose,
                      color: Colors.white,
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            photo.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            photo.dateLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: const Color(0xFFAEAEB2)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 12 : 30,
                      vertical: compact ? 8 : 16,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            compact ? 12 : 18,
                          ),
                          child: _PhotoArtwork(
                            key: Key('photos-detail-artwork-${photo.id}'),
                            photo: photo,
                            compact: false,
                            detailed: true,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding + 8,
                  compact ? 8 : 12,
                  horizontalPadding + 8,
                  compact ? 14 : 20,
                ),
                child: Row(
                  children: <Widget>[
                    Icon(photo.album.icon, color: photo.album.accent, size: 18),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        '${photo.album.label} 앨범',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '$photoNumber / ${_galleryPhotos.length}',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: const Color(0xFFAEAEB2),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoArtwork extends StatelessWidget {
  const _PhotoArtwork({
    required this.photo,
    required this.compact,
    this.detailed = false,
    super.key,
  });

  final _GalleryPhoto photo;
  final bool compact;
  final bool detailed;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final extent = constraints.biggest.shortestSide;
        final artworkExtent = extent.isFinite
            ? extent
            : compact
            ? 84.0
            : 120.0;
        final highlightSize = detailed
            ? artworkExtent * 0.62
            : compact
            ? 66.0
            : 88.0;
        final iconSize = detailed
            ? artworkExtent * 0.3
            : compact
            ? 33.0
            : 44.0;

        return Stack(
          fit: StackFit.expand,
          children: <Widget>[
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: photo.colors,
                ),
              ),
            ),
            Positioned(
              left: detailed ? -artworkExtent * 0.14 : -18,
              top: detailed ? -artworkExtent * 0.2 : -24,
              child: Container(
                width: highlightSize,
                height: highlightSize,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Center(
              child: Icon(
                photo.icon,
                size: iconSize,
                color: Colors.white.withValues(alpha: 0.9),
                shadows: const <Shadow>[
                  Shadow(
                    color: Color(0x4D000000),
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: detailed
                    ? artworkExtent * 0.2
                    : compact
                    ? 18
                    : 24,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.28),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

enum _PhotosTab {
  library('라이브러리'),
  albums('앨범');

  const _PhotosTab(this.label);

  final String label;
}

enum _PhotoAlbum {
  daily('일상', Icons.auto_awesome_rounded, Color(0xFFFF9F0A)),
  work('작업', Icons.laptop_mac_rounded, Color(0xFF0A84FF)),
  travel('여행', Icons.explore_rounded, Color(0xFF30D158));

  const _PhotoAlbum(this.label, this.icon, this.accent);

  final String label;
  final IconData icon;
  final Color accent;
}

class _GalleryPhoto {
  const _GalleryPhoto({
    required this.id,
    required this.title,
    required this.dateLabel,
    required this.album,
    required this.icon,
    required this.colors,
  });

  final String id;
  final String title;
  final String dateLabel;
  final _PhotoAlbum album;
  final IconData icon;
  final List<Color> colors;
}

const List<_GalleryPhoto> _galleryPhotos = <_GalleryPhoto>[
  _GalleryPhoto(
    id: 'coffee',
    title: '오후의 커피',
    dateLabel: '2026년 9월 4일 오후 3:24',
    album: _PhotoAlbum.daily,
    icon: Icons.coffee_rounded,
    colors: <Color>[Color(0xFF7C4A32), Color(0xFFE6A15B)],
  ),
  _GalleryPhoto(
    id: 'sunlight',
    title: '창가의 햇빛',
    dateLabel: '2026년 8월 30일 오전 9:18',
    album: _PhotoAlbum.daily,
    icon: Icons.wb_sunny_rounded,
    colors: <Color>[Color(0xFFFFC857), Color(0xFFFF7A59)],
  ),
  _GalleryPhoto(
    id: 'dinner',
    title: '저녁 식탁',
    dateLabel: '2026년 8월 27일 오후 7:42',
    album: _PhotoAlbum.daily,
    icon: Icons.restaurant_rounded,
    colors: <Color>[Color(0xFFD1495B), Color(0xFF5B2A86)],
  ),
  _GalleryPhoto(
    id: 'vinyl',
    title: '오늘의 음악',
    dateLabel: '2026년 8월 21일 오후 10:06',
    album: _PhotoAlbum.daily,
    icon: Icons.album_rounded,
    colors: <Color>[Color(0xFF353A47), Color(0xFF8C6FF7)],
  ),
  _GalleryPhoto(
    id: 'workspace',
    title: '작업 공간',
    dateLabel: '2026년 8월 18일 오전 11:35',
    album: _PhotoAlbum.work,
    icon: Icons.laptop_mac_rounded,
    colors: <Color>[Color(0xFF0A84FF), Color(0xFF5E5CE6)],
  ),
  _GalleryPhoto(
    id: 'prototype',
    title: '프로토타입',
    dateLabel: '2026년 8월 14일 오후 2:12',
    album: _PhotoAlbum.work,
    icon: Icons.view_quilt_rounded,
    colors: <Color>[Color(0xFF36C5F0), Color(0xFF2EB67D)],
  ),
  _GalleryPhoto(
    id: 'whiteboard',
    title: '아이디어 보드',
    dateLabel: '2026년 8월 9일 오후 4:48',
    album: _PhotoAlbum.work,
    icon: Icons.draw_rounded,
    colors: <Color>[Color(0xFFFF375F), Color(0xFFFF9F0A)],
  ),
  _GalleryPhoto(
    id: 'launch',
    title: '릴리스 데이',
    dateLabel: '2026년 8월 2일 오후 6:30',
    album: _PhotoAlbum.work,
    icon: Icons.rocket_launch_rounded,
    colors: <Color>[Color(0xFF5856D6), Color(0xFFFF2D55)],
  ),
  _GalleryPhoto(
    id: 'coast',
    title: '푸른 해안',
    dateLabel: '2026년 7월 24일 오후 1:15',
    album: _PhotoAlbum.travel,
    icon: Icons.waves_rounded,
    colors: <Color>[Color(0xFF00C7BE), Color(0xFF007AFF)],
  ),
  _GalleryPhoto(
    id: 'forest',
    title: '숲길',
    dateLabel: '2026년 7월 22일 오전 10:08',
    album: _PhotoAlbum.travel,
    icon: Icons.park_rounded,
    colors: <Color>[Color(0xFF30D158), Color(0xFF006A5C)],
  ),
  _GalleryPhoto(
    id: 'city',
    title: '도시 산책',
    dateLabel: '2026년 7월 18일 오후 5:51',
    album: _PhotoAlbum.travel,
    icon: Icons.location_city_rounded,
    colors: <Color>[Color(0xFF7D8CA3), Color(0xFF27364D)],
  ),
  _GalleryPhoto(
    id: 'night-train',
    title: '밤 기차',
    dateLabel: '2026년 7월 17일 오후 11:03',
    album: _PhotoAlbum.travel,
    icon: Icons.train_rounded,
    colors: <Color>[Color(0xFF1A1F4B), Color(0xFF8E5CFF)],
  ),
];
