import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/apple_theme.dart';
import '../widgets/apple_selection_control.dart';

class PhotosApp extends StatefulWidget {
  const PhotosApp({
    this.compact = false,
    this.tablet = false,
    this.onDetailVisibilityChanged,
    super.key,
  });

  final bool compact;
  final bool tablet;
  final ValueChanged<bool>? onDetailVisibilityChanged;

  @override
  State<PhotosApp> createState() => _PhotosAppState();
}

class _PhotosAppState extends State<PhotosApp> {
  _PhotosTab _selectedTab = _PhotosTab.library;
  _PhotoAlbum? _selectedAlbum;
  _GalleryPhoto? _selectedPhoto;

  void _openPhoto(_GalleryPhoto photo) {
    setState(() => _selectedPhoto = photo);
    widget.onDetailVisibilityChanged?.call(true);
  }

  void _closePhoto() {
    setState(() => _selectedPhoto = null);
    widget.onDetailVisibilityChanged?.call(_selectedAlbum != null);
  }

  void _closeAlbum() {
    setState(() => _selectedAlbum = null);
    widget.onDetailVisibilityChanged?.call(false);
  }

  void _selectTab(_PhotosTab tab) {
    setState(() {
      _selectedTab = tab;
      _selectedAlbum = null;
    });
    widget.onDetailVisibilityChanged?.call(false);
  }

  @override
  Widget build(BuildContext context) {
    final selectedPhoto = _selectedPhoto;
    return AppleAppSurface(
      key: const Key('photos-app'),
      child: selectedPhoto != null
          ? _PhotoDetailView(
              key: ValueKey<String>('photo-detail-${selectedPhoto.id}'),
              photo: selectedPhoto,
              compact: widget.compact,
              onClose: _closePhoto,
            )
          : Column(
              children: <Widget>[
                Expanded(child: _gallery(context)),
                _PhotosTabBar(
                  selectedTab: _selectedTab,
                  onSelected: _selectTab,
                ),
              ],
            ),
    );
  }

  Widget _gallery(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = widget.compact ? 14.0 : 24.0;
        final selectedAlbum = _selectedAlbum;
        final showAlbums =
            _selectedTab == _PhotosTab.albums && selectedAlbum == null;
        final visiblePhotos = selectedAlbum == null
            ? _galleryPhotos
            : _galleryPhotos
                  .where((photo) => photo.album == selectedAlbum)
                  .toList(growable: false);
        return CallbackShortcuts(
          bindings: <ShortcutActivator, VoidCallback>{
            if (selectedAlbum != null)
              const SingleActivator(LogicalKeyboardKey.escape): _closeAlbum,
          },
          child: KeyedSubtree(
            key: const Key('photos-scroll'),
            child: CustomScrollView(
              key: PageStorageKey<String>(
                'photos-${_selectedTab.name}-${selectedAlbum?.name ?? 'root'}',
              ),
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: <Widget>[
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    16,
                    horizontalPadding,
                    18,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        if (selectedAlbum != null) ...<Widget>[
                          TextButton.icon(
                            key: const Key('photos-album-back'),
                            onPressed: _closeAlbum,
                            icon: const Icon(CupertinoIcons.back, size: 20),
                            label: const Text('앨범'),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(44, 44),
                              alignment: Alignment.centerLeft,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        Text(
                          selectedAlbum?.label ?? (showAlbums ? '앨범' : '보관함'),
                          key: selectedAlbum == null
                              ? null
                              : const Key('photos-active-album-title'),
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                color: AppleTheme.primaryLabel(context),
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          showAlbums
                              ? '나의 앨범'
                              : selectedAlbum == null
                              ? '2026년 7월–9월 · 사진 ${visiblePhotos.length}장'
                              : '사진 ${visiblePhotos.length}장',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppleTheme.secondaryLabel(context),
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.symmetric(
                    horizontal: showAlbums ? horizontalPadding : 2,
                  ),
                  sliver: showAlbums
                      ? SliverToBoxAdapter(
                          child: LayoutBuilder(
                            builder: (context, albumConstraints) {
                              final columns = constraints.maxWidth >= 680
                                  ? 3
                                  : 2;
                              final cardWidth =
                                  (albumConstraints.maxWidth -
                                      14 * (columns - 1)) /
                                  columns;
                              return Wrap(
                                key: const Key('photos-albums-grid'),
                                spacing: 14,
                                runSpacing: 22,
                                children: <Widget>[
                                  for (final album in _PhotoAlbum.values)
                                    SizedBox(
                                      width: cardWidth,
                                      child: _AlbumCard(
                                        album: album,
                                        onPressed: () {
                                          setState(
                                            () => _selectedAlbum = album,
                                          );
                                          widget.onDetailVisibilityChanged
                                              ?.call(true);
                                        },
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        )
                      : SliverGrid(
                          key: Key(
                            selectedAlbum == null
                                ? 'photos-library-grid'
                                : 'photos-album-grid',
                          ),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: _columnCount(
                                  constraints.maxWidth,
                                ),
                                mainAxisSpacing: 2,
                                crossAxisSpacing: 2,
                              ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => _PhotoThumbnail(
                              photo: visiblePhotos[index],
                              onPressed: () => _openPhoto(visiblePhotos[index]),
                            ),
                            childCount: visiblePhotos.length,
                          ),
                        ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          ),
        );
      },
    );
  }

  int _columnCount(double width) {
    if (widget.compact || width < 480) return 3;
    if (width >= 900) return 6;
    if (widget.tablet || width >= 680) return 5;
    return 4;
  }
}

class _PhotosTabBar extends StatelessWidget {
  const _PhotosTabBar({required this.selectedTab, required this.onSelected});

  final _PhotosTab selectedTab;
  final ValueChanged<_PhotosTab> onSelected;

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(999));
    return Padding(
      key: const Key('photos-tab-bar'),
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Container(
            key: const Key('photos-tab-capsule'),
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: AppleTheme.panel(context),
              border: Border.all(color: AppleTheme.separator(context)),
              borderRadius: radius,
            ),
            child: Row(
              children: <Widget>[
                for (final (index, tab) in _PhotosTab.values.indexed) ...[
                  if (index > 0) const SizedBox(width: 4),
                  Expanded(
                    child: AppleSelectionControl(
                      key: Key('photos-${tab.name}-tab'),
                      semanticsLabel: '${tab.label} 탭',
                      selected: selectedTab == tab,
                      onPressed: () => onSelected(tab),
                      borderRadius: radius,
                      child: AnimatedContainer(
                        key: Key('photos-${tab.name}-tab-surface'),
                        width: double.infinity,
                        duration: const Duration(milliseconds: 160),
                        constraints: const BoxConstraints(minHeight: 58),
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          color: selectedTab == tab
                              ? AppleTheme.blue.withValues(alpha: 0.12)
                              : Colors.transparent,
                          borderRadius: radius,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Icon(
                              tab == _PhotosTab.library
                                  ? CupertinoIcons.photo_on_rectangle
                                  : CupertinoIcons.rectangle_stack,
                              size: 24,
                              color: selectedTab == tab
                                  ? AppleTheme.blue
                                  : AppleTheme.secondaryLabel(context),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              tab.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: selectedTab == tab
                                        ? AppleTheme.blue
                                        : AppleTheme.secondaryLabel(context),
                                    fontSize: 11,
                                    height: 1.2,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AlbumCard extends StatelessWidget {
  const _AlbumCard({required this.album, required this.onPressed});

  final _PhotoAlbum album;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final photos = _galleryPhotos
        .where((photo) => photo.album == album)
        .toList(growable: false);
    return AppleSelectionControl(
      key: Key('photos-album-${album.name}'),
      semanticsLabel: '${album.label} 앨범, 사진 ${photos.length}장',
      selected: false,
      onPressed: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _PhotoArtwork(photo: photos.first),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            album.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppleTheme.primaryLabel(context),
            ),
          ),
          Text(
            '${photos.length}',
            maxLines: 1,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppleTheme.secondaryLabel(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoThumbnail extends StatelessWidget {
  const _PhotoThumbnail({required this.photo, required this.onPressed});

  final _GalleryPhoto photo;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.zero;
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
        child: _PhotoArtwork(photo: photo),
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
                            fit: BoxFit.contain,
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
    this.fit = BoxFit.cover,
    super.key,
  });

  final _GalleryPhoto photo;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) =>
      Image.asset(photo.assetName, fit: fit, excludeFromSemantics: true);
}

enum _PhotosTab {
  library('보관함'),
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
    required this.assetName,
    required this.title,
    required this.dateLabel,
    required this.album,
  });

  final String id;
  final String assetName;
  final String title;
  final String dateLabel;
  final _PhotoAlbum album;
}

const List<_GalleryPhoto> _galleryPhotos = <_GalleryPhoto>[
  _GalleryPhoto(
    id: 'coffee',
    assetName: 'assets/photos/img1.png',
    title: '오후의 커피',
    dateLabel: '2026년 9월 4일 오후 3:24',
    album: _PhotoAlbum.daily,
  ),
  _GalleryPhoto(
    id: 'sunlight',
    assetName: 'assets/photos/img2.png',
    title: '창가의 햇빛',
    dateLabel: '2026년 8월 30일 오전 9:18',
    album: _PhotoAlbum.daily,
  ),
  _GalleryPhoto(
    id: 'dinner',
    assetName: 'assets/photos/img3.png',
    title: '저녁 식탁',
    dateLabel: '2026년 8월 27일 오후 7:42',
    album: _PhotoAlbum.daily,
  ),
  _GalleryPhoto(
    id: 'vinyl',
    assetName: 'assets/photos/img4.png',
    title: '오늘의 음악',
    dateLabel: '2026년 8월 21일 오후 10:06',
    album: _PhotoAlbum.daily,
  ),
  _GalleryPhoto(
    id: 'workspace',
    assetName: 'assets/photos/img5.png',
    title: '작업 공간',
    dateLabel: '2026년 8월 18일 오전 11:35',
    album: _PhotoAlbum.work,
  ),
  _GalleryPhoto(
    id: 'prototype',
    assetName: 'assets/photos/img6.png',
    title: '프로토타입',
    dateLabel: '2026년 8월 14일 오후 2:12',
    album: _PhotoAlbum.work,
  ),
  _GalleryPhoto(
    id: 'whiteboard',
    assetName: 'assets/photos/img7.png',
    title: '아이디어 보드',
    dateLabel: '2026년 8월 9일 오후 4:48',
    album: _PhotoAlbum.work,
  ),
  _GalleryPhoto(
    id: 'launch',
    assetName: 'assets/photos/img8.png',
    title: '릴리스 데이',
    dateLabel: '2026년 8월 2일 오후 6:30',
    album: _PhotoAlbum.work,
  ),
  _GalleryPhoto(
    id: 'coast',
    assetName: 'assets/photos/img9.png',
    title: '푸른 해안',
    dateLabel: '2026년 7월 24일 오후 1:15',
    album: _PhotoAlbum.travel,
  ),
  _GalleryPhoto(
    id: 'forest',
    assetName: 'assets/photos/img10.png',
    title: '숲길',
    dateLabel: '2026년 7월 22일 오전 10:08',
    album: _PhotoAlbum.travel,
  ),
  _GalleryPhoto(
    id: 'city',
    assetName: 'assets/photos/img11.png',
    title: '도시 산책',
    dateLabel: '2026년 7월 18일 오후 5:51',
    album: _PhotoAlbum.travel,
  ),
  _GalleryPhoto(
    id: 'night-train',
    assetName: 'assets/photos/img12.png',
    title: '밤 기차',
    dateLabel: '2026년 7월 17일 오후 11:03',
    album: _PhotoAlbum.travel,
  ),
];
