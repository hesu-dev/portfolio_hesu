import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/portfolio_data.dart';
import '../mobile/apple_mobile_dock_geometry.dart';
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
    _ProjectsLocation.career => '회사',
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
    if (projectIndex != null) {
      return _ProjectDetail(
        project: widget.data.projects[projectIndex],
        projectIndex: projectIndex,
        compact: compact,
        bottomContentInset: bottomContentInset,
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
        bottomContentInset: bottomContentInset,
        onSelected: (index) => _selectProject(location, index),
      ),
      _ProjectsLocation.iCloudDrive => _ScrollableEmptyDirectory(
        contentKey: const Key('projects-icloud-empty'),
        icon: Icons.cloud_outlined,
        title: 'iCloud Drive가 비어 있습니다',
        message: '연결된 파일이 생기면 이 위치에 표시됩니다.',
        bottomContentInset: bottomContentInset,
      ),
      _ProjectsLocation.desktop => _DesktopApplicationsDirectory(
        compact: compact,
        bottomContentInset: bottomContentInset,
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
        bottomContentInset: bottomContentInset,
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
    required this.bottomContentInset,
    required this.onSelected,
    super.key,
  });

  final String locationId;
  final String locationLabel;
  final List<_ProjectEntry> projects;
  final int? selectedIndex;
  final bool compact;
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
    required this.bottomContentInset,
    required this.onSelectProject,
  });

  final String locationId;
  final List<_ProjectEntry> projects;
  final int? selectedIndex;
  final bool compact;
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
    return Align(
      alignment: Alignment.topLeft,
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
    required this.bottomContentInset,
    required this.feedback,
    required this.launchSucceeded,
    required this.pendingLaunches,
    required this.onOpenLink,
  });

  final PortfolioProject project;
  final int projectIndex;
  final bool compact;
  final double bottomContentInset;
  final String? feedback;
  final bool launchSucceeded;
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
    final sections = _orderedProjectSections(project);
    final highlights = project.highlights
        .where((highlight) => highlight.trim().isNotEmpty)
        .toList(growable: false);
    final technologies = project.technologies
        .map((technology) => technology.trim())
        .where((technology) => technology.isNotEmpty)
        .toList(growable: false);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _ProjectCaseStudyHeader(project: project, compact: compact),
            SizedBox(height: compact ? 20 : 28),
            _ProjectActions(
              project: project,
              projectIndex: projectIndex,
              pendingLaunches: pendingLaunches,
              onOpenLink: onOpenLink,
            ),
            if (feedback case final message?) ...<Widget>[
              const SizedBox(height: 14),
              AppleFeedbackBanner(
                key: const Key('project-launch-feedback'),
                message: message,
                success: launchSucceeded,
              ),
            ],
            if (technologies.isNotEmpty) ...<Widget>[
              SizedBox(height: compact ? 16 : 20),
              Semantics(
                container: true,
                explicitChildNodes: true,
                child: AppleSurfaceCard(
                  key: const Key('project-technologies'),
                  radius: 17,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Semantics(
                        header: true,
                        child: Text(
                          '사용 언어 · 기술',
                          key: const Key('project-technologies-heading'),
                          style: AppleTheme.title(context),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: <Widget>[
                          for (final entry in technologies.indexed)
                            Semantics(
                              key: Key('project-technology-${entry.$1}'),
                              label: '사용 기술 ${entry.$2}',
                              excludeSemantics: true,
                              child: ApplePill(label: '#${entry.$2}'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (project.architecture case final architecture?) ...<Widget>[
              SizedBox(height: compact ? 16 : 20),
              _ProjectArchitectureCard(
                architecture: architecture,
                compact: compact,
              ),
            ],
            if (highlights.isNotEmpty) ...<Widget>[
              SizedBox(height: compact ? 16 : 20),
              _ProjectHighlightsCard(highlights: highlights),
            ],
            if (sections.isNotEmpty) ...<Widget>[
              SizedBox(height: compact ? 16 : 20),
              _ProjectNarrativeCard(sections: sections, compact: compact),
            ],
          ],
        ),
      ),
    );
  }
}

List<PortfolioProjectSection> _orderedProjectSections(
  PortfolioProject project,
) {
  final sections = project.sections
      .where((section) => section.body.trim().isNotEmpty)
      .toList(growable: true);
  if (sections.isEmpty && project.description.trim().isNotEmpty) {
    sections.add(
      PortfolioProjectSection(
        kind: PortfolioProjectSectionKind.work,
        body: project.description,
      ),
    );
  }
  sections.sort((left, right) => left.kind.index.compareTo(right.kind.index));
  return List<PortfolioProjectSection>.unmodifiable(sections);
}

class _ProjectCaseStudyHeader extends StatelessWidget {
  const _ProjectCaseStudyHeader({required this.project, required this.compact});

  final PortfolioProject project;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final year = project.displayYear;
    final yearBadge = year == null
        ? null
        : Semantics(
            label: '프로젝트 시작 연도 $year',
            excludeSemantics: true,
            child: Container(
              key: const Key('project-detail-year'),
              constraints: const BoxConstraints(minWidth: 74, minHeight: 74),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[Color(0xFF0066CC), Color(0xFF003E80)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AppleTheme.buttonBlue.withValues(alpha: 0.22),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    year,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'YEAR',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          );
    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Semantics(
          header: true,
          child: Text(
            project.title,
            key: const Key('project-detail-title'),
            style: compact
                ? Theme.of(context).textTheme.titleLarge
                : Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        const SizedBox(height: 9),
        ApplePill(
          label: project.period,
          icon: Icons.calendar_month_rounded,
          color: AppleTheme.indigo,
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = compact || constraints.maxWidth < 460;
        return Semantics(
          container: true,
          explicitChildNodes: true,
          child: stacked
              ? Column(
                  key: const Key('project-detail-header'),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (yearBadge case final badge?) ...<Widget>[
                      badge,
                      const SizedBox(height: 16),
                    ],
                    title,
                  ],
                )
              : Row(
                  key: const Key('project-detail-header'),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (yearBadge case final badge?) ...<Widget>[
                      badge,
                      const SizedBox(width: 18),
                    ],
                    Expanded(child: title),
                  ],
                ),
        );
      },
    );
  }
}

class _ProjectArchitectureCard extends StatelessWidget {
  const _ProjectArchitectureCard({
    required this.architecture,
    required this.compact,
  });

  final PortfolioProjectArchitecture architecture;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final nodes = architecture.nodes
        .where((node) => node.trim().isNotEmpty)
        .toList(growable: false);
    final semanticPrefix =
        architecture.presentation == PortfolioArchitecturePresentation.flow
        ? '아키텍처 흐름'
        : '아키텍처 구성 요소';
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: AppleSurfaceCard(
        key: const Key('project-architecture'),
        radius: 17,
        color: Color.alphaBlend(
          AppleTheme.blue.withValues(
            alpha: AppleTheme.isDark(context) ? 0.1 : 0.05,
          ),
          AppleTheme.surface(context),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Semantics(
              header: true,
              child: Text(architecture.title, style: AppleTheme.title(context)),
            ),
            if (architecture.description.trim().isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                architecture.description,
                style: AppleTheme.body(
                  context,
                ).copyWith(color: AppleTheme.secondaryLabel(context)),
              ),
            ],
            if (nodes.isNotEmpty) ...<Widget>[
              const SizedBox(height: 18),
              Semantics(
                label: '$semanticPrefix: ${nodes.join(', ')}',
                excludeSemantics: true,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (architecture.presentation ==
                        PortfolioArchitecturePresentation.components) {
                      return _buildComponents(nodes, constraints);
                    }
                    return _buildFlow(nodes, constraints);
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFlow(List<String> nodes, BoxConstraints constraints) {
    final vertical = compact || constraints.maxWidth < 480;
    if (vertical) {
      return Column(
        children: <Widget>[
          for (final entry in nodes.indexed) ...<Widget>[
            SizedBox(
              width: double.infinity,
              child: _ArchitectureNode(index: entry.$1, label: entry.$2),
            ),
            if (entry.$1 < nodes.length - 1)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 5),
                child: Icon(
                  Icons.arrow_downward_rounded,
                  size: 18,
                  color: AppleTheme.blue,
                ),
              ),
          ],
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        for (final entry in nodes.indexed) ...<Widget>[
          Expanded(
            child: _ArchitectureNode(index: entry.$1, label: entry.$2),
          ),
          if (entry.$1 < nodes.length - 1)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 5),
              child: Icon(
                Icons.arrow_forward_rounded,
                size: 18,
                color: AppleTheme.blue,
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildComponents(List<String> nodes, BoxConstraints constraints) {
    final singleColumn = compact || constraints.maxWidth < 480;
    final nodeWidth = singleColumn
        ? constraints.maxWidth
        : (constraints.maxWidth - 10) / 2;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: <Widget>[
        for (final entry in nodes.indexed)
          SizedBox(
            width: nodeWidth,
            child: _ArchitectureNode(index: entry.$1, label: entry.$2),
          ),
      ],
    );
  }
}

class _ArchitectureNode extends StatelessWidget {
  const _ArchitectureNode({required this.index, required this.label});

  final int index;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: Key('project-architecture-node-$index'),
      constraints: const BoxConstraints(minHeight: 62),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppleTheme.surface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppleTheme.blue.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _ProjectHighlightsCard extends StatelessWidget {
  const _ProjectHighlightsCard({required this.highlights});

  final List<String> highlights;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: AppleSurfaceCard(
        key: const Key('project-highlights'),
        radius: 17,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Semantics(
              header: true,
              child: Text('핵심 포인트', style: AppleTheme.title(context)),
            ),
            const SizedBox(height: 12),
            for (final entry in highlights.indexed) ...<Widget>[
              Semantics(
                container: true,
                label: '${entry.$1 + 1}. ${entry.$2}',
                excludeSemantics: true,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      key: Key('project-highlight-index-${entry.$1}'),
                      constraints: const BoxConstraints(
                        minWidth: 24,
                        minHeight: 24,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppleTheme.buttonBlue,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${entry.$1 + 1}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        entry.$2,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ],
                ),
              ),
              if (entry.$1 < highlights.length - 1) const SizedBox(height: 11),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProjectNarrativeCard extends StatelessWidget {
  const _ProjectNarrativeCard({required this.sections, required this.compact});

  final List<PortfolioProjectSection> sections;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: AppleSurfaceCard(
        key: const Key('project-narrative'),
        radius: 17,
        padding: EdgeInsets.all(compact ? 17 : 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Semantics(
              header: true,
              child: Text('프로젝트 회고', style: AppleTheme.title(context)),
            ),
            const SizedBox(height: 8),
            for (final entry in sections.indexed) ...<Widget>[
              if (entry.$1 > 0)
                Divider(height: 1, color: AppleTheme.separator(context)),
              _ProjectNarrativeRow(section: entry.$2, compact: compact),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProjectNarrativeRow extends StatelessWidget {
  const _ProjectNarrativeRow({required this.section, required this.compact});

  final PortfolioProjectSection section;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final keyPrefix = 'project-section-${section.kind.name}';
    final accent = AppleTheme.isDark(context)
        ? const Color(0xFF73B5FF)
        : AppleTheme.buttonBlue;
    final label = Semantics(
      header: true,
      child: Text(
        section.kind.label,
        key: Key('$keyPrefix-label'),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: accent,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
    final body = Text(
      section.body,
      key: Key('$keyPrefix-body'),
      style: Theme.of(context).textTheme.bodyLarge,
    );

    return LayoutBuilder(
      key: Key(keyPrefix),
      builder: (context, constraints) {
        final stacked = compact || constraints.maxWidth < 480;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 15),
          child: stacked
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[label, const SizedBox(height: 8), body],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(width: 92, child: label),
                    const SizedBox(width: 16),
                    Expanded(child: body),
                  ],
                ),
        );
      },
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
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: AppleSurfaceCard(
        key: const Key('project-actions'),
        radius: 17,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Semantics(
              header: true,
              child: Text(
                '프로젝트 링크',
                key: const Key('project-actions-heading'),
                style: AppleTheme.title(context),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              project.links.isEmpty
                  ? '현재 공개된 외부 링크가 없습니다.'
                  : '스토어와 공개 문서를 외부에서 열어 프로젝트를 확인할 수 있습니다.',
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
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 44),
                      ),
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
      ),
    );
  }
}

class _DesktopApplicationsDirectory extends StatelessWidget {
  const _DesktopApplicationsDirectory({
    required this.compact,
    required this.bottomContentInset,
    required this.onOpenApp,
  });

  final bool compact;
  final double bottomContentInset;
  final ValueChanged<PortfolioAppId>? onOpenApp;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      key: const Key('projects-desktop-app-grid'),
      padding: EdgeInsets.fromLTRB(
        compact ? 16 : 24,
        compact ? 16 : 24,
        compact ? 16 : 24,
        (compact ? 16 : 24) + bottomContentInset,
      ),
      physics: const BouncingScrollPhysics(),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: compact ? 118 : 132,
        mainAxisExtent: compact ? 108 : 122,
        crossAxisSpacing: compact ? 6 : 10,
        mainAxisSpacing: compact ? 8 : 12,
      ),
      itemCount: portfolioMacDesktopLauncherAppIds.length,
      itemBuilder: (context, index) {
        final appId = portfolioMacDesktopLauncherAppIds[index];
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
        artworkForegroundColor: appId == PortfolioAppId.github
            ? Colors.black
            : null,
        onTap: onOpen,
      ),
    );
  }
}
