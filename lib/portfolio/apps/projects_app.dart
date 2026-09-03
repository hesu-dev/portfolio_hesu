import 'package:flutter/material.dart';

import '../data/portfolio_data.dart';
import '../services/external_launcher.dart';
import '../theme/apple_theme.dart';
import '../widgets/apple_finder_scaffold.dart';

class ProjectsApp extends StatefulWidget {
  const ProjectsApp({
    required this.data,
    required this.launcher,
    this.compact = false,
    this.tablet = false,
    this.finderWindowChrome,
    super.key,
  });

  final PortfolioData data;
  final ExternalLauncher launcher;
  final bool compact;
  final bool tablet;
  final AppleFinderWindowChrome? finderWindowChrome;

  @override
  State<ProjectsApp> createState() => _ProjectsAppState();
}

class _ProjectsAppState extends State<ProjectsApp> {
  int? _selectedIndex;
  final List<int?> _history = <int?>[null];
  int _historyCursor = 0;
  int _launchRequestGeneration = 0;
  String? _launchFeedback;
  bool _launchSucceeded = false;
  final Map<Uri, int> _pendingLaunches = <Uri, int>{};

  int? get _activeProjectIndex => _history[_historyCursor];

  @override
  void didUpdateWidget(covariant ProjectsApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.data, widget.data) ||
        !identical(oldWidget.launcher, widget.launcher)) {
      _launchRequestGeneration++;
      _launchFeedback = null;
      _pendingLaunches.clear();
    }
    final hasUnavailableProject = _history.any(
      (index) => index != null && index >= widget.data.projects.length,
    );
    if (hasUnavailableProject) {
      _selectedIndex = null;
      _history
        ..clear()
        ..add(null);
      _historyCursor = 0;
      _launchFeedback = null;
      _pendingLaunches.clear();
    } else if (_selectedIndex != null &&
        _selectedIndex! >= widget.data.projects.length) {
      _selectedIndex = null;
    }
  }

  void _selectProject(int index) {
    _launchRequestGeneration++;
    setState(() {
      _selectedIndex = index;
      if (_historyCursor < _history.length - 1) {
        _history.removeRange(_historyCursor + 1, _history.length);
      }
      _history.add(index);
      _historyCursor = _history.length - 1;
      _launchFeedback = null;
      _pendingLaunches.clear();
    });
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
    final activeProjectIndex = _activeProjectIndex;
    return AppleFinderScaffold(
      surfaceKey: const Key('projects-app'),
      keyPrefix: 'projects',
      currentLocation: 'iCloud Drive',
      toolbarTitle: activeProjectIndex == null
          ? 'Projects'
          : widget.data.projects[activeProjectIndex].title,
      ownerName: widget.data.identity.name,
      compact: widget.compact,
      tablet: widget.tablet,
      canGoBack: _historyCursor > 0,
      canGoForward: _historyCursor < _history.length - 1,
      onBack: () => _moveThroughHistory(-1),
      onForward: () => _moveThroughHistory(1),
      windowChrome: widget.finderWindowChrome,
      bodyBuilder: (context, compactLayout) {
        if (widget.data.projects.isEmpty) {
          return const AppleEmptyState(
            icon: Icons.folder_off_rounded,
            title: 'No projects yet',
            message: 'Project reports will appear here.',
          );
        }
        if (activeProjectIndex == null) {
          return _buildCollection(compact: compactLayout);
        }
        return _buildDetail(index: activeProjectIndex, compact: compactLayout);
      },
    );
  }

  Widget _buildCollection({required bool compact}) {
    return _ProjectCollection(
      projects: widget.data.projects,
      selectedIndex: _selectedIndex,
      compact: compact,
      tablet: widget.tablet,
      onSelectProject: _selectProject,
    );
  }

  Widget _buildDetail({required int index, required bool compact}) {
    return _ProjectDetail(
      project: widget.data.projects[index],
      projectIndex: index,
      compact: compact,
      feedback: _launchFeedback,
      launchSucceeded: _launchSucceeded,
      pendingLaunches: _pendingLaunches.keys.toSet(),
      onOpenLink: _openLink,
    );
  }
}

class _ProjectGrid extends StatelessWidget {
  const _ProjectGrid({
    required this.projects,
    required this.selectedIndex,
    required this.compact,
    required this.onSelected,
  });

  final List<PortfolioProject> projects;
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
        final itemCount = projects.length;
        final gridWidth = compact
            ? constraints.maxWidth.clamp(0.0, minimumTileWidth * 2 + spacing)
            : constraints.maxWidth;
        final columnCount = compact
            ? 2
            : ((gridWidth + spacing) / (minimumTileWidth + spacing))
                  .floor()
                  .clamp(1, itemCount);
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
                    width: tileWidth,
                    child: AppleFinderFolderTile(
                      key: Key('project-selector-${entry.$1}'),
                      label: entry.$2.title,
                      semanticsLabel: 'Open project ${entry.$2.title}',
                      selected: selectedIndex == entry.$1,
                      compact: compact,
                      onPressed: () => onSelected(entry.$1),
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
    final detail = _SelectedProjectDetail(
      project: project,
      projectIndex: projectIndex,
      compact: compact,
      feedback: feedback,
      launchSucceeded: launchSucceeded,
      pendingLaunches: pendingLaunches,
      onOpenLink: onOpenLink,
    );

    return ListView(
      key: const Key('projects-detail-scroll'),
      padding: EdgeInsets.all(compact ? 16 : 30),
      children: <Widget>[detail],
    );
  }
}

class _ProjectCollection extends StatelessWidget {
  const _ProjectCollection({
    required this.projects,
    required this.selectedIndex,
    required this.compact,
    required this.tablet,
    required this.onSelectProject,
  });

  final List<PortfolioProject> projects;
  final int? selectedIndex;
  final bool compact;
  final bool tablet;
  final ValueChanged<int> onSelectProject;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const Key('projects-collection-scroll'),
      padding: EdgeInsets.fromLTRB(
        compact ? 16 : (tablet ? 20 : 30),
        compact ? 16 : 24,
        compact ? 16 : (tablet ? 20 : 30),
        24,
      ),
      children: <Widget>[
        _FinderProjectCollection(
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
    required this.projects,
    required this.selectedIndex,
    required this.compact,
    required this.onSelected,
  });

  final List<PortfolioProject> projects;
  final int? selectedIndex;
  final bool compact;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(child: Text('프로젝트', style: AppleTheme.title(context))),
                Text(
                  '${projects.length}개 항목',
                  style: AppleTheme.caption(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _ProjectGrid(
              projects: projects,
              selectedIndex: selectedIndex,
              compact: compact,
              onSelected: onSelected,
            ),
          ],
        ),
      ),
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
