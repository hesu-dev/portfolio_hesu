import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../data/portfolio_data.dart';
import '../mobile/apple_mobile_dock_geometry.dart';
import '../models/portfolio_app_id.dart';
import '../services/external_launcher.dart';
import '../theme/apple_theme.dart';
import '../widgets/apple_app_icon.dart';
import '../widgets/apple_app_artwork.dart';
import '../widgets/apple_finder_scaffold.dart';
import '../widgets/apple_finder_list_row.dart';
import '../widgets/portfolio_printer_shortcut.dart';
import '../widgets/project_app_icon.dart';
import 'safari_project_page.dart';

enum _ProjectsLocation {
  recent,
  files,
  iCloudDrive,
  desktop,
  career,
  personalProjects,
}

enum _DirectoryView { icons, list }

enum _DirectorySort {
  name('이름'),
  kind('종류'),
  date('날짜'),
  size('크기'),
  tags('태그');

  const _DirectorySort(this.label);
  final String label;
}

typedef _DirectoryOptions = ({_DirectoryView view, _DirectorySort sort});

const _defaultDirectoryOptions = (
  view: _DirectoryView.icons,
  sort: _DirectorySort.kind,
);

extension on _ProjectsLocation {
  String get id => switch (this) {
    _ProjectsLocation.recent => 'recent',
    _ProjectsLocation.files => 'files',
    _ProjectsLocation.iCloudDrive => 'icloud-drive',
    _ProjectsLocation.desktop => 'desktop',
    _ProjectsLocation.career => 'career',
    _ProjectsLocation.personalProjects => 'personal-projects',
  };

  String get label => switch (this) {
    _ProjectsLocation.recent => '최근 항목',
    _ProjectsLocation.files => '파일',
    _ProjectsLocation.iCloudDrive => 'iCloud Drive',
    _ProjectsLocation.desktop => '데스크탑',
    _ProjectsLocation.career => '회사',
    _ProjectsLocation.personalProjects => '개인 프로젝트',
  };

  IconData get icon => switch (this) {
    _ProjectsLocation.recent => Icons.access_time_filled_rounded,
    _ProjectsLocation.files => Icons.folder_rounded,
    _ProjectsLocation.iCloudDrive => Icons.cloud_rounded,
    _ProjectsLocation.desktop => Icons.desktop_mac_rounded,
    _ProjectsLocation.career => Icons.business_center_rounded,
    _ProjectsLocation.personalProjects => Icons.folder_special_rounded,
  };

  PortfolioProjectCategory? get category => switch (this) {
    _ProjectsLocation.career => PortfolioProjectCategory.career,
    _ProjectsLocation.personalProjects => PortfolioProjectCategory.personal,
    _ => null,
  };
}

@immutable
class _ProjectsDestination {
  const _ProjectsDestination(this.location, {this.projectIndex});

  final _ProjectsLocation location;
  final int? projectIndex;
}

@immutable
class _ProjectEntry {
  const _ProjectEntry({required this.index, required this.project});

  final int index;
  final PortfolioProject project;
}

class ProjectsApp extends StatefulWidget {
  const ProjectsApp({
    required this.data,
    required this.launcher,
    this.compact = false,
    this.tablet = false,
    this.finderWindowChrome,
    this.onOpenApp,
    this.trashEmpty = false,
    super.key,
  });

  final PortfolioData data;
  final ExternalLauncher launcher;
  final bool compact;
  final bool tablet;
  final AppleFinderWindowChrome? finderWindowChrome;
  final ValueChanged<PortfolioAppId>? onOpenApp;
  final bool trashEmpty;

  @override
  State<ProjectsApp> createState() => _ProjectsAppState();
}

class _ProjectsAppState extends State<ProjectsApp> {
  static const List<_ProjectsLocation> _allLocationValues = <_ProjectsLocation>[
    _ProjectsLocation.recent,
    _ProjectsLocation.files,
    _ProjectsLocation.iCloudDrive,
    _ProjectsLocation.desktop,
    _ProjectsLocation.career,
    _ProjectsLocation.personalProjects,
  ];

  static const List<_ProjectsLocation> _desktopLocationValues =
      <_ProjectsLocation>[
        _ProjectsLocation.iCloudDrive,
        _ProjectsLocation.desktop,
        _ProjectsLocation.files,
        _ProjectsLocation.career,
        _ProjectsLocation.personalProjects,
      ];

  static const List<_ProjectsLocation> _mobileLocationValues =
      <_ProjectsLocation>[
        _ProjectsLocation.recent,
        _ProjectsLocation.files,
        _ProjectsLocation.career,
        _ProjectsLocation.personalProjects,
      ];

  static final List<AppleFinderLocation> _finderLocations = List.unmodifiable(
    _desktopLocationValues.map(
      (location) => AppleFinderLocation(
        id: location.id,
        label: location.label,
        icon: location.icon,
      ),
    ),
  );

  static const AppleFinderLocation _finderRecentLocation = AppleFinderLocation(
    id: 'recent',
    label: '최근 항목',
    icon: Icons.access_time_filled_rounded,
  );

  static final List<AppleFinderMobileDestination> _mobileDestinations =
      List.unmodifiable(
        _mobileLocationValues.map(
          (location) => AppleFinderMobileDestination(
            id: location.id,
            label: location == _ProjectsLocation.personalProjects
                ? '개인'
                : location.label,
            icon: location.icon,
          ),
        ),
      );

  final List<_ProjectsDestination> _history = <_ProjectsDestination>[
    _ProjectsDestination(_ProjectsLocation.files),
  ];
  final Map<_ProjectsLocation, int?> _selectedProject =
      <_ProjectsLocation, int?>{};
  // Each navigable folder owns its options, independently of navigation history.
  final Map<_ProjectsLocation, _DirectoryOptions> _directoryOptions = {};

  _DirectoryOptions _optionsFor(_ProjectsLocation location) =>
      _directoryOptions[location] ?? _defaultDirectoryOptions;

  Future<void> _showDirectoryOptions(BuildContext context) async {
    final location = _currentDestination.location;
    final options = _optionsFor(location);
    final box = context.findRenderObject()! as RenderBox;
    final origin = box.localToGlobal(Offset.zero);
    final choice = await showGeneralDialog<Object>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '더보기 메뉴 닫기',
      barrierColor: Colors.black.withValues(alpha: 0.12),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (menuContext, _, _) => SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final right = math.max(
              12.0,
              constraints.maxWidth - origin.dx - box.size.width + 12,
            );
            final top = (origin.dy + 58 - MediaQuery.paddingOf(menuContext).top)
                .clamp(8.0, constraints.maxHeight * 0.35);
            return Padding(
              padding: EdgeInsets.fromLTRB(12, top, right, 12),
              child: Align(
                alignment: Alignment.topRight,
                child: _DirectoryOptionsMenu(options: options),
              ),
            );
          },
        ),
      ),
      transitionBuilder: (context, animation, _, child) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1).animate(animation),
          alignment: Alignment.topRight,
          child: child,
        ),
      ),
    );
    if (!mounted || choice == null) return;
    setState(() {
      _directoryOptions[location] = (
        view: choice is _DirectoryView ? choice : options.view,
        sort: choice is _DirectorySort ? choice : options.sort,
      );
    });
  }

  int _historyCursor = 0;
  int _launchRequestGeneration = 0;
  String? _launchFeedback;
  final Map<Uri, int> _pendingLaunches = <Uri, int>{};

  _ProjectsDestination get _currentDestination => _history[_historyCursor];

  List<_ProjectEntry> _projectsFor(PortfolioProjectCategory category) {
    return widget.data.projects.indexed
        .where((entry) => entry.$2.category == category)
        .map((entry) => _ProjectEntry(index: entry.$1, project: entry.$2))
        .toList(growable: false);
  }

  List<_ProjectEntry> _projectsForLocation(_ProjectsLocation location) {
    final category = location.category;
    if (category == null) {
      return location == _ProjectsLocation.recent
          ? widget.data.projects.indexed
                .map(
                  (entry) => _ProjectEntry(index: entry.$1, project: entry.$2),
                )
                .toList(growable: false)
          : const <_ProjectEntry>[];
    }
    return _projectsFor(category);
  }

  @override
  void didUpdateWidget(covariant ProjectsApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.data, widget.data)) {
      _launchRequestGeneration++;
      _history
        ..clear()
        ..add(const _ProjectsDestination(_ProjectsLocation.files));
      _historyCursor = 0;
      _selectedProject.clear();
      _directoryOptions.clear();
      _launchFeedback = null;
      _pendingLaunches.clear();
      return;
    }
    if (!identical(oldWidget.launcher, widget.launcher)) {
      _launchRequestGeneration++;
      _launchFeedback = null;
      _pendingLaunches.clear();
    }

    final historyIsInvalid = _history.any((destination) {
      final index = destination.projectIndex;
      if (index == null) {
        return false;
      }
      if (index >= widget.data.projects.length) {
        return true;
      }
      final category = destination.location.category;
      return category != null &&
          widget.data.projects[index].category != category;
    });
    if (historyIsInvalid) {
      _history
        ..clear()
        ..add(const _ProjectsDestination(_ProjectsLocation.files));
      _historyCursor = 0;
      _selectedProject.clear();
      _launchFeedback = null;
      _pendingLaunches.clear();
      return;
    }

    for (final location in _allLocationValues) {
      final selection = _selectedProject[location];
      final category = location.category;
      if (selection != null &&
          (selection >= widget.data.projects.length ||
              (category != null &&
                  widget.data.projects[selection].category != category))) {
        _selectedProject[location] = null;
      }
    }
  }

  void _selectLocation(_ProjectsLocation location) {
    final current = _currentDestination;
    if (location == current.location && current.projectIndex == null) {
      return;
    }
    _launchRequestGeneration++;
    setState(() {
      _pushDestination(_ProjectsDestination(location));
      _launchFeedback = null;
      _pendingLaunches.clear();
    });
  }

  void _pushDestination(_ProjectsDestination destination) {
    if (_historyCursor < _history.length - 1) {
      _history.removeRange(_historyCursor + 1, _history.length);
    }
    _history.add(destination);
    _historyCursor = _history.length - 1;
  }

  void _selectLocationById(String id) {
    for (final location in _allLocationValues) {
      if (location.id == id) {
        _selectLocation(location);
        return;
      }
    }
  }

  void _moveThroughHistory(int offset) {
    final nextCursor = _historyCursor + offset;
    if (nextCursor < 0 || nextCursor >= _history.length) {
      return;
    }
    _launchRequestGeneration++;
    setState(() {
      _historyCursor = nextCursor;
      _launchFeedback = null;
      _pendingLaunches.clear();
    });
  }

  void _selectProject(_ProjectsLocation location, int index) {
    _launchRequestGeneration++;
    setState(() {
      _selectedProject[location] = index;
      _pushDestination(_ProjectsDestination(location, projectIndex: index));
      _launchFeedback = null;
      _pendingLaunches.clear();
    });
  }

  Future<void> _openLink(PortfolioProjectLink link) async {
    if (_pendingLaunches.containsKey(link.uri)) {
      return;
    }
    final requestGeneration = ++_launchRequestGeneration;
    setState(() {
      _pendingLaunches[link.uri] = requestGeneration;
      _launchFeedback = null;
    });
    var succeeded = false;
    try {
      succeeded = await widget.launcher.launch(link.uri);
    } catch (_) {
      succeeded = false;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      if (_pendingLaunches[link.uri] == requestGeneration) {
        _pendingLaunches.remove(link.uri);
      }
      if (requestGeneration != _launchRequestGeneration) {
        return;
      }
      _launchFeedback = succeeded ? null : '${link.label} 링크를 열 수 없습니다.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final destination = _currentDestination;
    final location = destination.location;
    final projectIndex = destination.projectIndex;
    final mobileLayout = widget.compact || widget.tablet;
    return AppleFinderScaffold(
      surfaceKey: const Key('projects-app'),
      keyPrefix: 'projects',
      currentLocation: location.label,
      toolbarTitle: projectIndex == null
          ? location.label
          : widget.data.projects[projectIndex].title,
      ownerName: widget.data.identity.name,
      locations: mobileLayout ? null : _finderLocations,
      recentLocation: mobileLayout ? null : _finderRecentLocation,
      selectedLocationId: location.id,
      onLocationSelected: _selectLocationById,
      compact: widget.compact,
      tablet: widget.tablet,
      canGoBack: mobileLayout ? projectIndex != null : _historyCursor > 0,
      canGoForward: _historyCursor < _history.length - 1,
      onBack: () => _moveThroughHistory(-1),
      onForward: () => _moveThroughHistory(1),
      windowChrome: widget.finderWindowChrome,
      onViewPressed: projectIndex == null
          ? () => _showDirectoryOptions(context)
          : null,
      mobileBottomNavigation: mobileLayout
          ? AppleFinderMobileNavigationBar(
              keyPrefix: 'projects-finder',
              destinations: _mobileDestinations,
              selectedId: location.id,
              onSelected: _selectLocationById,
              tablet: widget.tablet,
            )
          : null,
      bodyBuilder: (context, compactLayout) {
        final bottomContentInset = mobileLayout
            ? AppleMobileDockGeometry.height(tablet: widget.tablet) +
                  AppleMobileDockGeometry.appBottomClearance(
                    tablet: widget.tablet,
                    safeAreaBottom: MediaQuery.paddingOf(context).bottom,
                  )
            : 0.0;
        return _buildLocation(
          destination,
          compact: compactLayout,
          bottomContentInset: bottomContentInset,
        );
      },
    );
  }

  Widget _buildLocation(
    _ProjectsDestination destination, {
    required bool compact,
    required double bottomContentInset,
  }) {
    final location = destination.location;
    final projectIndex = destination.projectIndex;
    final options = _optionsFor(location);
    if (projectIndex != null) {
      return _ProjectDetail(
        project: widget.data.projects[projectIndex],
        compact: compact,
        bottomContentInset: bottomContentInset,
        feedback: _launchFeedback,
        pendingLaunches: _pendingLaunches.keys.toSet(),
        onOpenLink: _openLink,
      );
    }

    return switch (location) {
      _ProjectsLocation.recent => _ApplicationsDirectory(
        keyPrefix: 'projects-recent',
        apps: _fileApps,
        projects: _projectsForLocation(location),
        selectedProject: _selectedProject[location],
        onSelectProject: (index) => _selectProject(location, index),
        printerData: widget.compact || widget.tablet ? widget.data : null,
        options: options,
        compact: compact,
        bottomContentInset: bottomContentInset,
        onOpenApp: widget.onOpenApp,
        trashEmpty: widget.trashEmpty,
      ),
      _ProjectsLocation.iCloudDrive => _ScrollableEmptyDirectory(
        contentKey: const Key('projects-icloud-empty'),
        icon: Icons.cloud_outlined,
        title: 'iCloud Drive가 비어 있습니다',
        message: '연결된 파일이 생기면 이 위치에 표시됩니다.',
        bottomContentInset: bottomContentInset,
      ),
      _ProjectsLocation.files => _ApplicationsDirectory(
        keyPrefix: 'projects-files',
        apps: _fileApps,
        printerData: widget.compact || widget.tablet ? widget.data : null,
        options: options,
        compact: compact,
        bottomContentInset: bottomContentInset,
        onOpenApp: widget.onOpenApp,
        trashEmpty: widget.trashEmpty,
      ),
      _ProjectsLocation.desktop => _ApplicationsDirectory(
        keyPrefix: 'projects-desktop',
        apps: portfolioMacDesktopLauncherAppIds,
        options: options,
        compact: compact,
        bottomContentInset: bottomContentInset,
        onOpenApp: widget.onOpenApp,
      ),
      _ProjectsLocation.career ||
      _ProjectsLocation.personalProjects => _ProjectConnectionDirectory(
        key: const Key('projects-connection-directory'),
        locationId: location.id,
        locationLabel: location.label,
        projects: _sortedProjects(location, options.sort),
        view: options.view,
        selectedIndex: _selectedProject[location],
        compact: compact,
        bottomContentInset: bottomContentInset,
        onSelected: (index) => _selectProject(location, index),
      ),
    };
  }

  List<PortfolioAppId> get _fileApps => [
    for (final app in portfolioFileAppIds)
      if (!(widget.compact || widget.tablet) || app != PortfolioAppId.settings)
        app,
  ];

  List<_ProjectEntry> _sortedProjects(
    _ProjectsLocation location,
    _DirectorySort sort,
  ) {
    String sortValue(PortfolioProject project) => switch (sort) {
      _DirectorySort.name => project.title.toLowerCase(),
      _DirectorySort.kind =>
        project.category == PortfolioProjectCategory.career
            ? '회사 프로젝트'
            : '개인 프로젝트',
      _DirectorySort.date => _projectStartDate(project.period),
      _DirectorySort.tags =>
        (project.technologies.map((tag) => tag.toLowerCase()).toList()..sort())
            .join(', '),
      _DirectorySort.size => '',
    };
    return _projectsForLocation(location)..sort((a, b) {
      final order = _compareAvailable(
        sortValue(a.project),
        sortValue(b.project),
      );
      return order == 0 ? a.index.compareTo(b.index) : order;
    });
  }
}

int _compareAvailable(String a, String b) {
  if (a.isEmpty != b.isEmpty) return a.isEmpty ? 1 : -1;
  return a.compareTo(b);
}

String _projectStartDate(String period) {
  final match = RegExp(
    r'((?:19|20)\d{2})(?:[./-](\d{1,2})(?:[./-](\d{1,2}))?)?',
  ).firstMatch(period);
  if (match == null) return '';
  return '${match[1]}-${(match[2] ?? '1').padLeft(2, '0')}-${(match[3] ?? '1').padLeft(2, '0')}';
}

/// Files-style iOS popover: grouped controls on a translucent Cupertino surface.
class _DirectoryOptionsMenu extends StatelessWidget {
  const _DirectoryOptionsMenu({required this.options});

  final _DirectoryOptions options;

  @override
  Widget build(BuildContext context) {
    final foreground = AppleTheme.primaryLabel(context);
    final secondary = AppleTheme.secondaryLabel(context);
    Widget heading(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          color: secondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
    Widget separator() =>
        Container(height: 7, color: foreground.withValues(alpha: 0.05));
    return SizedBox(
      width: 288,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 28,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: CupertinoTheme(
          data: CupertinoThemeData(
            brightness: Theme.of(context).brightness,
            primaryColor: AppleTheme.blue,
          ),
          child: CupertinoPopupSurface(
            child: DefaultTextStyle(
              style: TextStyle(
                fontFamily: Theme.of(context).textTheme.bodyLarge?.fontFamily,
                fontSize: 17,
                color: foreground,
                height: 1.3,
              ),
              child: SingleChildScrollView(
                key: const Key('projects-directory-options'),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    heading('보기'),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: Row(
                        children: [
                          for (final view in _DirectoryView.values)
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                ),
                                child: Semantics(
                                  key: Key('projects-view-${view.name}'),
                                  selected: options.view == view,
                                  button: true,
                                  child: CupertinoButton(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: 4,
                                    ),
                                    color: options.view == view
                                        ? foreground.withValues(alpha: 0.09)
                                        : foreground.withValues(alpha: 0.025),
                                    borderRadius: BorderRadius.circular(10),
                                    onPressed: () =>
                                        Navigator.pop(context, view),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          view == _DirectoryView.icons
                                              ? CupertinoIcons.square_grid_2x2
                                              : CupertinoIcons.list_bullet,
                                          color: foreground,
                                          size: 23,
                                        ),
                                        const SizedBox(height: 7),
                                        Text(
                                          view == _DirectoryView.icons
                                              ? '아이콘'
                                              : '목록',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: foreground,
                                            fontWeight: options.view == view
                                                ? FontWeight.w600
                                                : FontWeight.w400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    separator(),
                    heading('정렬 · 오름차순'),
                    for (final sort in _DirectorySort.values)
                      Semantics(
                        key: Key('projects-sort-${sort.name}'),
                        selected: options.sort == sort,
                        enabled: sort != _DirectorySort.size,
                        button: true,
                        child: CupertinoButton(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 11,
                          ),
                          onPressed: sort == _DirectorySort.size
                              ? null
                              : () => Navigator.pop(context, sort),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 26,
                                child: options.sort == sort
                                    ? Icon(
                                        CupertinoIcons.check_mark,
                                        color: foreground,
                                        size: 18,
                                      )
                                    : null,
                              ),
                              Expanded(
                                child: Text(
                                  sort.label,
                                  style: TextStyle(
                                    color: sort == _DirectorySort.size
                                        ? secondary.withValues(alpha: 0.55)
                                        : foreground,
                                    fontSize: 17,
                                  ),
                                ),
                              ),
                              Icon(
                                switch (sort) {
                                  _DirectorySort.name =>
                                    CupertinoIcons.textformat_abc,
                                  _DirectorySort.kind =>
                                    CupertinoIcons.square_grid_2x2,
                                  _DirectorySort.date =>
                                    CupertinoIcons.calendar,
                                  _DirectorySort.size =>
                                    CupertinoIcons
                                        .arrow_up_left_arrow_down_right,
                                  _DirectorySort.tags => CupertinoIcons.tag,
                                },
                                size: 19,
                                color: sort == _DirectorySort.size
                                    ? secondary.withValues(alpha: 0.55)
                                    : foreground,
                              ),
                            ],
                          ),
                        ),
                      ),
                    separator(),
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Text(
                        '날짜: 프로젝트 시작일 · 바로가기 예시 날짜\n태그: 기술 스택 · 파일 분류\n크기: 정보가 없어 선택할 수 없음',
                        style: TextStyle(
                          fontSize: 11,
                          color: secondary,
                          height: 1.5,
                        ),
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
  }
}

class _ProjectFolderGrid extends StatelessWidget {
  const _ProjectFolderGrid({
    required this.keyPrefix,
    required this.projects,
    required this.selectedIndex,
    required this.compact,
    required this.view,
    required this.onSelected,
  });

  final String keyPrefix;
  final List<_ProjectEntry> projects;
  final int? selectedIndex;
  final bool compact;
  final _DirectoryView view;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    if (view == _DirectoryView.list) {
      return Column(
        key: const Key('projects-finder-list'),
        children: [
          for (final entry in projects)
            AppleFinderListRow(
              key: Key('project-selector-${entry.index}'),
              selected: selectedIndex == entry.index,
              artworkHasBackground: ProjectAppIcon.hasOwnBackground(
                entry.project.appIconAsset,
              ),
              artwork: entry.project.appIconAsset == null
                  ? const Icon(Icons.folder_rounded, size: 40)
                  : ProjectAppIcon(
                      assetPath: entry.project.appIconAsset!,
                      size: 40,
                      alignment: Alignment.center,
                    ),
              title: entry.project.title,
              subtitle: [
                if (entry.project.period.isNotEmpty) entry.project.period,
                if (entry.project.technologies.isNotEmpty)
                  entry.project.technologies.join(' · '),
              ].join(' · '),
              onTap: () => onSelected(entry.index),
            ),
        ],
      );
    }
    return LayoutBuilder(
      key: const Key('projects-finder-grid'),
      builder: (context, constraints) {
        const spacing = 8.0;
        const preferredTileWidth = 112.0;
        const minimumCompactTileWidth = 104.0;
        const maximumCompactColumnCount = 4;
        final availableWidth = constraints.maxWidth;
        final columnBasis = compact
            ? minimumCompactTileWidth
            : preferredTileWidth;
        final preferredColumnCount = math.max(
          1,
          ((availableWidth + spacing) / (columnBasis + spacing)).floor(),
        );
        final columnCount = compact
            ? math.min(maximumCompactColumnCount, preferredColumnCount)
            : preferredColumnCount;
        final tileWidth = compact
            ? (availableWidth - spacing * (columnCount - 1)) / columnCount
            : availableWidth.clamp(0.0, preferredTileWidth);
        return Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: availableWidth,
            child: Wrap(
              alignment: WrapAlignment.start,
              spacing: spacing,
              runSpacing: spacing,
              children: <Widget>[
                for (final entry in projects.indexed)
                  SizedBox(
                    key: Key('$keyPrefix-folder-${entry.$1}'),
                    width: tileWidth,
                    child: AppleFinderFolderTile(
                      key: Key('project-selector-${entry.$2.index}'),
                      label: entry.$2.project.title,
                      semanticsLabel: 'Open project ${entry.$2.project.title}',
                      selected: selectedIndex == entry.$2.index,
                      imageAsset: entry.$2.project.appIconAsset,
                      compact: compact,
                      onPressed: () => onSelected(entry.$2.index),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProjectConnectionDirectory extends StatelessWidget {
  const _ProjectConnectionDirectory({
    required this.locationId,
    required this.locationLabel,
    required this.projects,
    required this.selectedIndex,
    required this.compact,
    required this.view,
    required this.bottomContentInset,
    required this.onSelected,
    super.key,
  });

  final String locationId;
  final String locationLabel;
  final List<_ProjectEntry> projects;
  final int? selectedIndex;
  final bool compact;
  final _DirectoryView view;
  final double bottomContentInset;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    if (projects.isEmpty) {
      return _ScrollableEmptyDirectory(
        contentKey: Key('projects-$locationId-empty'),
        icon: Icons.folder_open_rounded,
        title: '$locationLabel 연결 준비 중',
        message: '분류 정보가 추가되면 이 위치에 프로젝트 폴더가 표시됩니다.',
        bottomContentInset: bottomContentInset,
      );
    }

    return _ProjectCollection(
      locationId: locationId,
      projects: projects,
      selectedIndex: selectedIndex,
      compact: compact,
      view: view,
      bottomContentInset: bottomContentInset,
      onSelectProject: onSelected,
    );
  }
}

class _ScrollableEmptyDirectory extends StatelessWidget {
  const _ScrollableEmptyDirectory({
    required this.contentKey,
    required this.icon,
    required this.title,
    required this.message,
    this.bottomContentInset = 0,
  });

  final Key contentKey;
  final IconData icon;
  final String title;
  final String message;
  final double bottomContentInset;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.only(bottom: bottomContentInset),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: AppleEmptyState(
              key: contentKey,
              icon: icon,
              title: title,
              message: message,
            ),
          ),
        );
      },
    );
  }
}

class _ProjectCollection extends StatelessWidget {
  const _ProjectCollection({
    required this.locationId,
    required this.projects,
    required this.selectedIndex,
    required this.compact,
    required this.view,
    required this.bottomContentInset,
    required this.onSelectProject,
  });

  final String locationId;
  final List<_ProjectEntry> projects;
  final int? selectedIndex;
  final bool compact;
  final _DirectoryView view;
  final double bottomContentInset;
  final ValueChanged<int> onSelectProject;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const Key('projects-collection-scroll'),
      padding: EdgeInsets.fromLTRB(
        compact ? 16 : 30,
        compact ? 16 : 24,
        compact ? 16 : 30,
        24 + bottomContentInset,
      ),
      children: <Widget>[
        _FinderProjectCollection(
          locationId: locationId,
          projects: projects,
          selectedIndex: selectedIndex,
          compact: compact,
          view: view,
          onSelected: onSelectProject,
        ),
      ],
    );
  }
}

class _FinderProjectCollection extends StatelessWidget {
  const _FinderProjectCollection({
    required this.locationId,
    required this.projects,
    required this.selectedIndex,
    required this.compact,
    required this.view,
    required this.onSelected,
  });

  final String locationId;
  final List<_ProjectEntry> projects;
  final int? selectedIndex;
  final bool compact;
  final _DirectoryView view;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: _ProjectFolderGrid(
          keyPrefix: 'projects-$locationId',
          projects: projects,
          selectedIndex: selectedIndex,
          compact: compact,
          view: view,
          onSelected: onSelected,
        ),
      ),
    );
  }
}

class _ProjectDetail extends StatelessWidget {
  const _ProjectDetail({
    required this.project,
    required this.compact,
    required this.bottomContentInset,
    required this.feedback,
    required this.pendingLaunches,
    required this.onOpenLink,
  });

  final PortfolioProject project;
  final bool compact;
  final double bottomContentInset;
  final String? feedback;
  final Set<Uri> pendingLaunches;
  final ValueChanged<PortfolioProjectLink> onOpenLink;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const Key('projects-detail-scroll'),
      padding: EdgeInsets.fromLTRB(
        compact ? 16 : 30,
        compact ? 16 : 30,
        compact ? 16 : 30,
        (compact ? 16 : 30) + bottomContentInset,
      ),
      children: <Widget>[
        SafariProjectPage(
          project: project,
          compact: compact,
          feedback: feedback,
          pendingLinks: pendingLaunches,
          onOpenLink: onOpenLink,
        ),
      ],
    );
  }
}

class _FileEntry {
  const _FileEntry.app(PortfolioAppId value) : app = value, project = null;
  const _FileEntry.project(_ProjectEntry value) : project = value, app = null;
  const _FileEntry.printer() : project = null, app = null;

  final PortfolioAppId? app;
  final _ProjectEntry? project;
  bool get artworkHasBackground => project != null
      ? ProjectAppIcon.hasOwnBackground(project!.project.appIconAsset)
      : app != null && !AppleAppArtwork.usesMobileTranslucentTile(app!);
  bool get isPrinter => app == null && project == null;
  String get label =>
      project?.project.title ??
      (app == null ? '프린터' : AppleAppIcon.labelFor(app!));
  String get kind => project != null
      ? project!.project.category == PortfolioProjectCategory.career
            ? '회사 프로젝트'
            : '개인 프로젝트'
      : isPrinter
      ? '프린터'
      : '앱';

  // Stable sample metadata for app shortcuts, all before the first project's
  // December 2020 date. Project participation dates remain authoritative.
  String get date => project != null
      ? _projectStartDate(project!.project.period)
      : switch (app) {
          PortfolioAppId.music => '2019-07-18',
          PortfolioAppId.photos => '2020-02-06',
          PortfolioAppId.mail => '2018-10-23',
          PortfolioAppId.settings => '2020-09-14',
          PortfolioAppId.trash => '2017-04-09',
          null => '2019-11-27',
          _ =>
            '2016-${(app!.index % 11 + 1).toString().padLeft(2, '0')}-${(app!.index % 27 + 1).toString().padLeft(2, '0')}',
        };
  String get tags => project != null
      ? (project!.project.technologies.toList()..sort()).join(' · ')
      : switch (app) {
          PortfolioAppId.music => '음악',
          PortfolioAppId.photos => '사진',
          PortfolioAppId.mail => '연락',
          PortfolioAppId.settings => '환경 설정',
          PortfolioAppId.trash => '정리',
          null => '문서',
          _ => label,
        };
  String sortValue(_DirectorySort sort) => switch (sort) {
    _DirectorySort.name => label.toLowerCase(),
    _DirectorySort.kind => kind,
    _DirectorySort.date => date,
    _DirectorySort.tags =>
      project == null
          ? tags.toLowerCase()
          : (project!.project.technologies
                    .map((tag) => tag.toLowerCase())
                    .toList()
                  ..sort())
                .join(', '),
    _DirectorySort.size => '',
  };
}

class _ApplicationsDirectory extends StatelessWidget {
  const _ApplicationsDirectory({
    required this.keyPrefix,
    required this.apps,
    required this.options,
    required this.compact,
    required this.bottomContentInset,
    required this.onOpenApp,
    this.trashEmpty = false,
    this.printerData,
    this.projects = const [],
    this.selectedProject,
    this.onSelectProject,
  });

  final String keyPrefix;
  final List<PortfolioAppId> apps;
  final _DirectoryOptions options;
  final bool compact;
  final double bottomContentInset;
  final ValueChanged<PortfolioAppId>? onOpenApp;
  final bool trashEmpty;
  final PortfolioData? printerData;
  final List<_ProjectEntry> projects;
  final int? selectedProject;
  final ValueChanged<int>? onSelectProject;

  VoidCallback? _onOpen(BuildContext context, _FileEntry entry) {
    if (entry.project case final project?) {
      return onSelectProject == null
          ? null
          : () => onSelectProject!(project.index);
    }
    if (entry.app case final app?) {
      return onOpenApp == null ? null : () => onOpenApp!(app);
    }
    return () => PortfolioPrinterShortcut.open(context, printerData!);
  }

  Widget _artwork(BuildContext context, _FileEntry entry) {
    if (entry.project case final project?) {
      return project.project.appIconAsset == null
          ? const Icon(Icons.folder_rounded, color: Color(0xFF55B8F5), size: 40)
          : ProjectAppIcon(
              assetPath: project.project.appIconAsset!,
              size: 40,
              alignment: Alignment.center,
            );
    }
    if (entry.app case final app?) {
      return AppleAppArtwork(
        appId: app,
        size: 40,
        trashEmpty: trashEmpty,
        includeEffects: false,
      );
    }
    return SvgPicture.asset(
      'assets/icons/printer.svg',
      width: 40,
      height: 40,
      theme: SvgTheme(currentColor: AppleTheme.primaryLabel(context)),
    );
  }

  Key _entryKey(_FileEntry entry) => entry.project != null
      ? Key('project-selector-${entry.project!.index}')
      : Key('$keyPrefix-app-${entry.app?.name ?? 'printer'}');

  @override
  Widget build(BuildContext context) {
    final entries = [
      for (final project in projects) _FileEntry.project(project),
      for (final app in apps) _FileEntry.app(app),
      if (printerData != null) const _FileEntry.printer(),
    ];
    final originalOrder = entries.toList();
    entries.sort((a, b) {
      final order = _compareAvailable(
        a.sortValue(options.sort),
        b.sortValue(options.sort),
      );
      return order == 0
          ? originalOrder.indexOf(a).compareTo(originalOrder.indexOf(b))
          : order;
    });
    final padding = EdgeInsets.fromLTRB(
      compact ? 16 : 24,
      compact ? 16 : 24,
      compact ? 16 : 24,
      (compact ? 16 : 24) + bottomContentInset,
    );
    if (options.view == _DirectoryView.list) {
      return ListView(
        key: Key('$keyPrefix-app-list'),
        padding: padding,
        children: [
          for (final entry in entries)
            AppleFinderListRow(
              key: _entryKey(entry),
              artwork: _artwork(context, entry),
              artworkHasBackground: entry.artworkHasBackground,
              title: entry.label,
              subtitle: switch (options.sort) {
                _DirectorySort.date => entry.date,
                _DirectorySort.tags => entry.tags,
                _ => null,
              },
              selected:
                  entry.project != null &&
                  selectedProject == entry.project!.index,
              onTap: _onOpen(context, entry),
            ),
        ],
      );
    }
    return GridView.builder(
      key: Key('$keyPrefix-app-grid'),
      padding: padding,
      physics: const BouncingScrollPhysics(),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: compact ? 118 : 132,
        mainAxisExtent:
            (compact ? 154.0 : 166.0) +
            math.max(0, MediaQuery.textScalerOf(context).scale(12) - 12),
        crossAxisSpacing: compact ? 6 : 10,
        mainAxisSpacing: compact ? 8 : 12,
      ),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final tile = AppleFinderFolderTile(
          key: _entryKey(entry),
          label: entry.label,
          semanticsLabel: entry.project != null
              ? 'Open project ${entry.label}'
              : 'Open ${entry.label}',
          selected:
              entry.project != null && selectedProject == entry.project!.index,
          artwork: _artwork(context, entry),
          artworkHasBackground: entry.artworkHasBackground,
          compact: compact,
          onPressed: _onOpen(context, entry),
        );
        if (entry.project case final project?) {
          return SizedBox(
            key: Key('$keyPrefix-folder-${project.index}'),
            child: tile,
          );
        }
        return tile;
      },
    );
  }
}
