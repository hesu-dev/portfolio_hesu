import 'package:flutter/material.dart';

import '../data/portfolio_data.dart';
import '../models/portfolio_app_id.dart';
import '../services/external_launcher.dart';
import '../theme/apple_theme.dart';
import '../widgets/apple_app_icon.dart';
import '../widgets/apple_finder_scaffold.dart';

enum _ProjectsLocation {
  recent,
  iCloudDrive,
  desktop,
  career,
  personalProjects,
}

extension on _ProjectsLocation {
  String get id => switch (this) {
    _ProjectsLocation.recent => 'recent',
    _ProjectsLocation.iCloudDrive => 'icloud-drive',
    _ProjectsLocation.desktop => 'desktop',
    _ProjectsLocation.career => 'career',
    _ProjectsLocation.personalProjects => 'personal-projects',
  };

  String get label => switch (this) {
    _ProjectsLocation.recent => '최근 항목',
    _ProjectsLocation.iCloudDrive => 'iCloud Drive',
    _ProjectsLocation.desktop => '데스크탑',
    _ProjectsLocation.career => '경력',
    _ProjectsLocation.personalProjects => '개인 프로젝트',
  };

  IconData get icon => switch (this) {
    _ProjectsLocation.recent => Icons.access_time_filled_rounded,
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
    super.key,
  });

  final PortfolioData data;
  final ExternalLauncher launcher;
  final bool compact;
  final bool tablet;
  final AppleFinderWindowChrome? finderWindowChrome;
  final ValueChanged<PortfolioAppId>? onOpenApp;

  @override
  State<ProjectsApp> createState() => _ProjectsAppState();
}

class _ProjectsAppState extends State<ProjectsApp> {
  static const List<_ProjectsLocation> _allLocationValues = <_ProjectsLocation>[
    _ProjectsLocation.recent,
    _ProjectsLocation.iCloudDrive,
    _ProjectsLocation.desktop,
    _ProjectsLocation.career,
    _ProjectsLocation.personalProjects,
  ];

  static const List<_ProjectsLocation> _desktopLocationValues =
      <_ProjectsLocation>[
        _ProjectsLocation.iCloudDrive,
        _ProjectsLocation.desktop,
        _ProjectsLocation.career,
        _ProjectsLocation.personalProjects,
      ];

  static const List<_ProjectsLocation> _mobileLocationValues =
      <_ProjectsLocation>[
        _ProjectsLocation.recent,
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
    _ProjectsDestination(_ProjectsLocation.career),
  ];
  final Map<_ProjectsLocation, int?> _selectedProject =
      <_ProjectsLocation, int?>{};
  int _historyCursor = 0;
  int _launchRequestGeneration = 0;
  String? _launchFeedback;
  bool _launchSucceeded = false;
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
        ..add(const _ProjectsDestination(_ProjectsLocation.career));
      _historyCursor = 0;
      _selectedProject.clear();
      _launchFeedback = null;
      _launchSucceeded = false;
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
        ..add(const _ProjectsDestination(_ProjectsLocation.career));
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
      _launchSucceeded = succeeded;
      _launchFeedback = succeeded
          ? '${link.label} 링크를 열었습니다.'
          : '${link.label} 링크를 열 수 없습니다.';
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
      selectedLocationId: location.id,
      onLocationSelected: _selectLocationById,
      compact: widget.compact,
      tablet: widget.tablet,
      canGoBack: _historyCursor > 0,
      canGoForward: _historyCursor < _history.length - 1,
      onBack: () => _moveThroughHistory(-1),
      onForward: () => _moveThroughHistory(1),
      windowChrome: widget.finderWindowChrome,
      mobileBottomNavigation: mobileLayout
          ? AppleFinderMobileNavigationBar(
              keyPrefix: 'projects-finder',
              destinations: _mobileDestinations,
              selectedId: location.id,
              onSelected: _selectLocationById,
            )
          : null,
      bodyBuilder: (context, compactLayout) =>
          _buildLocation(destination, compact: compactLayout),
    );
  }

  Widget _buildLocation(
    _ProjectsDestination destination, {
    required bool compact,
  }) {
    final location = destination.location;
    final projectIndex = destination.projectIndex;
    if (projectIndex != null) {
      return _ProjectDetail(
        project: widget.data.projects[projectIndex],
        projectIndex: projectIndex,
        compact: compact,
        feedback: _launchFeedback,
        launchSucceeded: _launchSucceeded,
        pendingLaunches: _pendingLaunches.keys.toSet(),
        onOpenLink: _openLink,
      );
    }

    return switch (location) {
      _ProjectsLocation.recent => _ProjectConnectionDirectory(
        key: const Key('projects-connection-directory'),
        locationId: location.id,
        locationLabel: location.label,
        projects: _projectsForLocation(location),
        selectedIndex: _selectedProject[location],
        compact: compact,
        onSelected: (index) => _selectProject(location, index),
      ),
      _ProjectsLocation.iCloudDrive => const _ScrollableEmptyDirectory(
        contentKey: Key('projects-icloud-empty'),
        icon: Icons.cloud_outlined,
        title: 'iCloud Drive가 비어 있습니다',
        message: '연결된 파일이 생기면 이 위치에 표시됩니다.',
      ),
      _ProjectsLocation.desktop => _DesktopApplicationsDirectory(
        compact: compact,
        onOpenApp: widget.onOpenApp,
      ),
      _ProjectsLocation.career ||
      _ProjectsLocation.personalProjects => _ProjectConnectionDirectory(
        key: const Key('projects-connection-directory'),
        locationId: location.id,
        locationLabel: location.label,
        projects: _projectsForLocation(location),
        selectedIndex: _selectedProject[location],
        compact: compact,
        onSelected: (index) => _selectProject(location, index),
      ),
    };
  }
}

class _ProjectFolderGrid extends StatelessWidget {
  const _ProjectFolderGrid({
    required this.keyPrefix,
    required this.projects,
    required this.selectedIndex,
    required this.compact,
    required this.onSelected,
  });

  final String keyPrefix;
  final List<_ProjectEntry> projects;
  final int? selectedIndex;
  final bool compact;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      key: const Key('projects-finder-grid'),
      builder: (context, constraints) {
        const spacing = 10.0;
        const minimumTileWidth = 132.0;
        final gridWidth = compact
            ? constraints.maxWidth.clamp(0.0, minimumTileWidth * 2 + spacing)
            : constraints.maxWidth;
        final availableColumns =
            ((gridWidth + spacing) / (minimumTileWidth + spacing)).floor();
        final regularColumnCount = availableColumns < 1 ? 1 : availableColumns;
        final columnCount = compact ? 2 : regularColumnCount;
        final tileWidth = compact
            ? ((gridWidth - spacing) / columnCount).clamp(0.0, minimumTileWidth)
            : (gridWidth - spacing * (columnCount - 1)) / columnCount;
        return Align(
          alignment: compact ? Alignment.topCenter : Alignment.topLeft,
          child: SizedBox(
            width: gridWidth,
            child: Wrap(
              spacing: spacing,
              runSpacing: 12,
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
    required this.onSelected,
    super.key,
  });

  final String locationId;
  final String locationLabel;
  final List<_ProjectEntry> projects;
  final int? selectedIndex;
  final bool compact;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    if (projects.isEmpty) {
      return _ScrollableEmptyDirectory(
        contentKey: Key('projects-$locationId-empty'),
        icon: Icons.folder_open_rounded,
        title: '$locationLabel 연결 준비 중',
        message: '분류 정보가 추가되면 이 위치에 프로젝트 폴더가 표시됩니다.',
      );
    }

    return _ProjectCollection(
      locationId: locationId,
      projects: projects,
      selectedIndex: selectedIndex,
      compact: compact,
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
  });

  final Key contentKey;
  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
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
    required this.onSelectProject,
  });

  final String locationId;
  final List<_ProjectEntry> projects;
  final int? selectedIndex;
  final bool compact;
  final ValueChanged<int> onSelectProject;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const Key('projects-collection-scroll'),
      padding: EdgeInsets.fromLTRB(
        compact ? 16 : 30,
        compact ? 16 : 24,
        compact ? 16 : 30,
        24,
      ),
      children: <Widget>[
        _FinderProjectCollection(
          locationId: locationId,
          projects: projects,
          selectedIndex: selectedIndex,
          compact: compact,
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
    required this.onSelected,
  });

  final String locationId;
  final List<_ProjectEntry> projects;
  final int? selectedIndex;
  final bool compact;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: _ProjectFolderGrid(
          keyPrefix: 'projects-$locationId',
          projects: projects,
          selectedIndex: selectedIndex,
          compact: compact,
          onSelected: onSelected,
        ),
      ),
    );
  }
}

class _ProjectDetail extends StatelessWidget {
  const _ProjectDetail({
    required this.project,
    required this.projectIndex,
    required this.compact,
    required this.feedback,
    required this.launchSucceeded,
    required this.pendingLaunches,
    required this.onOpenLink,
  });

  final PortfolioProject project;
  final int projectIndex;
  final bool compact;
  final String? feedback;
  final bool launchSucceeded;
  final Set<Uri> pendingLaunches;
  final ValueChanged<PortfolioProjectLink> onOpenLink;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const Key('projects-detail-scroll'),
      padding: EdgeInsets.all(compact ? 16 : 30),
      children: <Widget>[
        _SelectedProjectDetail(
          project: project,
          projectIndex: projectIndex,
          compact: compact,
          feedback: feedback,
          launchSucceeded: launchSucceeded,
          pendingLaunches: pendingLaunches,
          onOpenLink: onOpenLink,
        ),
      ],
    );
  }
}

class _SelectedProjectDetail extends StatelessWidget {
  const _SelectedProjectDetail({
    required this.project,
    required this.projectIndex,
    required this.compact,
    required this.feedback,
    required this.launchSucceeded,
    required this.pendingLaunches,
    required this.onOpenLink,
  });

  final PortfolioProject project;
  final int projectIndex;
  final bool compact;
  final String? feedback;
  final bool launchSucceeded;
  final Set<Uri> pendingLaunches;
  final ValueChanged<PortfolioProjectLink> onOpenLink;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: compact ? 48 : 58,
                  height: compact ? 48 : 58,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[Color(0xFF69D5FF), Color(0xFF1675F8)],
                    ),
                    borderRadius: BorderRadius.circular(compact ? 14 : 17),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: AppleTheme.blue.withValues(alpha: 0.2),
                        blurRadius: 18,
                        offset: const Offset(0, 7),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.folder_open_rounded,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        project.title,
                        key: const Key('project-detail-title'),
                        style: compact
                            ? Theme.of(context).textTheme.titleLarge
                            : Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 7),
                      ApplePill(
                        label: project.period,
                        icon: Icons.calendar_month_rounded,
                        color: AppleTheme.indigo,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: compact ? 20 : 28),
            _ProjectActions(
              project: project,
              projectIndex: projectIndex,
              pendingLaunches: pendingLaunches,
              onOpenLink: onOpenLink,
            ),
            SizedBox(height: compact ? 16 : 20),
            AppleSurfaceCard(
              radius: 17,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Project overview', style: AppleTheme.title(context)),
                  const SizedBox(height: 10),
                  Text(
                    project.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
            SizedBox(height: compact ? 16 : 20),
            AppleSurfaceCard(
              radius: 17,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Technology stack', style: AppleTheme.title(context)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      for (final technology in project.technologies)
                        ApplePill(label: technology),
                    ],
                  ),
                ],
              ),
            ),
            if (feedback case final message?) ...<Widget>[
              const SizedBox(height: 14),
              AppleFeedbackBanner(
                key: const Key('project-launch-feedback'),
                message: message,
                success: launchSucceeded,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProjectActions extends StatelessWidget {
  const _ProjectActions({
    required this.project,
    required this.projectIndex,
    required this.pendingLaunches,
    required this.onOpenLink,
  });

  final PortfolioProject project;
  final int projectIndex;
  final Set<Uri> pendingLaunches;
  final ValueChanged<PortfolioProjectLink> onOpenLink;

  @override
  Widget build(BuildContext context) {
    return AppleSurfaceCard(
      radius: 17,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Actions', style: AppleTheme.title(context)),
          const SizedBox(height: 6),
          Text(
            project.links.isEmpty
                ? 'This project is currently documented as a portfolio case study.'
                : 'Open a verified project destination in a new app or tab.',
            style: AppleTheme.body(
              context,
            ).copyWith(color: AppleTheme.secondaryLabel(context)),
          ),
          if (project.links.isNotEmpty) ...<Widget>[
            const SizedBox(height: 13),
            Wrap(
              spacing: 9,
              runSpacing: 9,
              children: <Widget>[
                for (final entry in project.links.indexed)
                  OutlinedButton.icon(
                    key: Key('project-link-$projectIndex-${entry.$1}'),
                    onPressed: pendingLaunches.contains(entry.$2.uri)
                        ? null
                        : () => onOpenLink(entry.$2),
                    icon: const Icon(Icons.open_in_new_rounded, size: 17),
                    label: Text(entry.$2.label),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _DesktopApplicationsDirectory extends StatelessWidget {
  const _DesktopApplicationsDirectory({
    required this.compact,
    required this.onOpenApp,
  });

  final bool compact;
  final ValueChanged<PortfolioAppId>? onOpenApp;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      key: const Key('projects-desktop-app-grid'),
      padding: EdgeInsets.all(compact ? 16 : 24),
      physics: const BouncingScrollPhysics(),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: compact ? 118 : 132,
        mainAxisExtent: compact ? 108 : 122,
        crossAxisSpacing: compact ? 6 : 10,
        mainAxisSpacing: compact ? 8 : 12,
      ),
      itemCount: portfolioLauncherAppIds.length,
      itemBuilder: (context, index) {
        final appId = portfolioLauncherAppIds[index];
        return _DesktopApplicationTile(
          appId: appId,
          compact: compact,
          onOpen: onOpenApp == null ? null : () => onOpenApp!(appId),
        );
      },
    );
  }
}

class _DesktopApplicationTile extends StatelessWidget {
  const _DesktopApplicationTile({
    required this.appId,
    required this.compact,
    required this.onOpen,
  });

  final PortfolioAppId appId;
  final bool compact;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AppleAppIcon(
        key: Key('projects-desktop-app-${appId.name}'),
        appId: appId,
        compact: compact,
        size: compact ? 52 : 58,
        onTap: onOpen,
      ),
    );
  }
}
