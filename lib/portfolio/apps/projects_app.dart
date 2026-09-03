import 'package:flutter/material.dart';

import '../data/portfolio_data.dart';
import '../services/external_launcher.dart';
import '../theme/apple_theme.dart';
import '../widgets/apple_selection_control.dart';

class ProjectsApp extends StatefulWidget {
  const ProjectsApp({
    required this.data,
    required this.launcher,
    this.compact = false,
    this.tablet = false,
    super.key,
  });

  final PortfolioData data;
  final ExternalLauncher launcher;
  final bool compact;
  final bool tablet;

  @override
  State<ProjectsApp> createState() => _ProjectsAppState();
}

class _ProjectsAppState extends State<ProjectsApp> {
  int _selectedIndex = 0;
  final List<int> _history = <int>[0];
  int _historyCursor = 0;
  int _launchRequestGeneration = 0;
  String? _launchFeedback;
  bool _launchSucceeded = false;

  @override
  void didUpdateWidget(covariant ProjectsApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.data, widget.data) ||
        !identical(oldWidget.launcher, widget.launcher)) {
      _launchRequestGeneration++;
      _launchFeedback = null;
    }
    if (_selectedIndex >= widget.data.projects.length) {
      _selectedIndex = 0;
      _history
        ..clear()
        ..add(0);
      _historyCursor = 0;
      _launchFeedback = null;
    }
  }

  void _selectProject(int index) {
    if (index == _selectedIndex) {
      return;
    }
    _launchRequestGeneration++;
    setState(() {
      _selectedIndex = index;
      if (_historyCursor < _history.length - 1) {
        _history.removeRange(_historyCursor + 1, _history.length);
      }
      _history.add(index);
      _historyCursor = _history.length - 1;
      _launchFeedback = null;
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
      _selectedIndex = _history[_historyCursor];
      _launchFeedback = null;
    });
  }

  Future<void> _openLink(PortfolioProjectLink link) async {
    final requestGeneration = ++_launchRequestGeneration;
    var succeeded = false;
    try {
      succeeded = await widget.launcher.launch(link.uri);
    } catch (_) {
      succeeded = false;
    }
    if (!mounted || requestGeneration != _launchRequestGeneration) {
      return;
    }
    setState(() {
      _launchSucceeded = succeeded;
      _launchFeedback = succeeded
          ? '${link.label} 링크를 열었습니다.'
          : '${link.label} 링크를 열 수 없습니다.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppleAppSurface(
      key: const Key('projects-app'),
      child: Column(
        children: <Widget>[
          _FinderToolbar(
            compact: widget.compact,
            canGoBack: _historyCursor > 0,
            canGoForward: _historyCursor < _history.length - 1,
            onBack: () => _moveThroughHistory(-1),
            onForward: () => _moveThroughHistory(1),
          ),
          Expanded(
            child: widget.data.projects.isEmpty
                ? const AppleEmptyState(
                    icon: Icons.folder_off_rounded,
                    title: 'No projects yet',
                    message: 'Project reports will appear here.',
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final wide =
                          !widget.compact && constraints.maxWidth >= 700;
                      return wide ? _buildWide() : _buildCompact();
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildWide() {
    return Row(
      children: <Widget>[
        SizedBox(
          width: widget.tablet ? 224 : 252,
          child: _ProjectSidebar(ownerName: widget.data.identity.name),
        ),
        Expanded(child: _buildDetail(compact: false)),
      ],
    );
  }

  Widget _buildCompact() {
    return Column(
      children: <Widget>[
        _FinderLocationStrip(ownerName: widget.data.identity.name),
        Expanded(child: _buildDetail(compact: true)),
      ],
    );
  }

  Widget _buildDetail({required bool compact}) {
    return _ProjectDetail(
      projects: widget.data.projects,
      project: widget.data.projects[_selectedIndex],
      projectIndex: _selectedIndex,
      compact: compact,
      feedback: _launchFeedback,
      launchSucceeded: _launchSucceeded,
      onSelectProject: _selectProject,
      onOpenLink: _openLink,
    );
  }
}

class _FinderToolbar extends StatelessWidget {
  const _FinderToolbar({
    required this.compact,
    required this.canGoBack,
    required this.canGoForward,
    required this.onBack,
    required this.onForward,
  });

  final bool compact;
  final bool canGoBack;
  final bool canGoForward;
  final VoidCallback onBack;
  final VoidCallback onForward;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const Key('projects-finder-toolbar'),
      decoration: BoxDecoration(
        color: AppleTheme.surface(context),
        border: Border(
          bottom: BorderSide(color: AppleTheme.separator(context), width: 0.7),
        ),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: compact ? 56 : 62),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 8 : 14,
            vertical: 5,
          ),
          child: Row(
            children: <Widget>[
              IconButton(
                key: const Key('finder-back'),
                tooltip: '뒤로',
                onPressed: canGoBack ? onBack : null,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              IconButton(
                key: const Key('finder-forward'),
                tooltip: '앞으로',
                onPressed: canGoForward ? onForward : null,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
              SizedBox(width: compact ? 3 : 10),
              Expanded(
                child: Container(
                  key: const Key('finder-current-location'),
                  alignment: Alignment.center,
                  constraints: const BoxConstraints(minHeight: 38),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    'iCloud Drive',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
              SizedBox(width: compact ? 4 : 8),
              IconButton(
                tooltip: '보기 방식',
                onPressed: null,
                icon: Icon(
                  Icons.grid_view_rounded,
                  color: AppleTheme.secondaryLabel(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProjectSidebar extends StatelessWidget {
  const _ProjectSidebar({required this.ownerName});

  final String ownerName;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const Key('projects-finder-sidebar'),
      decoration: BoxDecoration(
        color: AppleTheme.panel(context),
        border: Border(
          right: BorderSide(color: AppleTheme.separator(context), width: 0.7),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(10, 12, 10, 18),
        children: <Widget>[
          const _FinderSidebarItem(
            label: '최근 항목',
            icon: Icons.access_time_filled_rounded,
          ),
          const _FinderSidebarItem(label: '공유', icon: Icons.people_alt_rounded),
          const SizedBox(height: 12),
          const _FinderSidebarHeading(label: '위치'),
          const _FinderSidebarItem(
            label: 'iCloud Drive',
            icon: Icons.cloud_rounded,
            selected: true,
          ),
          _FinderSidebarItem(label: ownerName, icon: Icons.home_rounded),
        ],
      ),
    );
  }
}

class _FinderSidebarHeading extends StatelessWidget {
  const _FinderSidebarHeading({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(11, 4, 11, 5),
      child: Text(
        label,
        style: AppleTheme.caption(
          context,
        ).copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _FinderSidebarItem extends StatelessWidget {
  const _FinderSidebarItem({
    required this.label,
    required this.icon,
    this.selected = false,
  });

  final String label;
  final IconData icon;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: selected
            ? AppleTheme.selectionBackground(context, AppleTheme.blue)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 18, color: AppleTheme.blue),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: selected
                    ? AppleTheme.selectionForeground(context)
                    : AppleTheme.primaryLabel(context),
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FinderLocationStrip extends StatelessWidget {
  const _FinderLocationStrip({required this.ownerName});

  final String ownerName;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppleTheme.panel(context),
        border: Border(
          bottom: BorderSide(color: AppleTheme.separator(context), width: 0.7),
        ),
      ),
      child: SingleChildScrollView(
        key: const Key('projects-finder-locations'),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Row(
          children: <Widget>[
            const _FinderLocationChip(label: '최근 항목'),
            const _FinderLocationChip(label: '공유'),
            const _FinderLocationChip(label: 'iCloud Drive', selected: true),
            _FinderLocationChip(label: ownerName),
          ],
        ),
      ),
    );
  }
}

class _FinderLocationChip extends StatelessWidget {
  const _FinderLocationChip({required this.label, this.selected = false});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: selected
            ? AppleTheme.selectionBackground(context, AppleTheme.blue)
            : AppleTheme.surface(context),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppleTheme.separator(context)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: selected
              ? AppleTheme.selectionForeground(context)
              : AppleTheme.primaryLabel(context),
        ),
      ),
    );
  }
}

class _ProjectSelector extends StatelessWidget {
  const _ProjectSelector({
    required this.project,
    required this.index,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  final PortfolioProject project;
  final int index;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppleSelectionControl(
      key: Key('project-selector-$index'),
      semanticsLabel: 'Select project ${project.title}',
      selected: selected,
      onPressed: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        constraints: const BoxConstraints(minHeight: 126),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10,
          vertical: compact ? 10 : 12,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppleTheme.selectionBackground(context, AppleTheme.blue)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              selected ? Icons.folder_open_rounded : Icons.folder_rounded,
              size: compact ? 50 : 58,
              color: selected ? AppleTheme.blue : const Color(0xFF55B8F5),
            ),
            const SizedBox(height: 8),
            Text(
              project.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: selected
                    ? AppleTheme.selectionForeground(context)
                    : AppleTheme.primaryLabel(context),
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
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
  final int selectedIndex;
  final bool compact;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      key: const Key('projects-finder-grid'),
      builder: (context, constraints) {
        final columnCount = compact
            ? (constraints.maxWidth / 132).floor().clamp(1, 2)
            : projects.length + 1;
        const spacing = 10.0;
        final tileWidth =
            (constraints.maxWidth - spacing * (columnCount - 1)) / columnCount;
        return Wrap(
          spacing: spacing,
          runSpacing: 12,
          children: <Widget>[
            for (final entry in projects.indexed)
              SizedBox(
                width: tileWidth,
                child: _ProjectSelector(
                  project: entry.$2,
                  index: entry.$1,
                  selected: selectedIndex == entry.$1,
                  compact: compact,
                  onTap: () => onSelected(entry.$1),
                ),
              ),
            SizedBox(width: tileWidth, child: const _FinderReadmeFile()),
          ],
        );
      },
    );
  }
}

class _FinderReadmeFile extends StatelessWidget {
  const _FinderReadmeFile();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: const Key('finder-file-portfolio-readme'),
      label: 'Portfolio README file',
      readOnly: true,
      child: ExcludeSemantics(
        child: Container(
          constraints: const BoxConstraints(minHeight: 126),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  Icon(
                    Icons.insert_drive_file_rounded,
                    size: 56,
                    color: AppleTheme.surface(context),
                    shadows: <Shadow>[
                      Shadow(
                        color: AppleTheme.subtleShadow(context),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  Icon(
                    Icons.subject_rounded,
                    size: 24,
                    color: AppleTheme.secondaryLabel(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Portfolio README',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProjectDetail extends StatelessWidget {
  const _ProjectDetail({
    required this.projects,
    required this.project,
    required this.projectIndex,
    required this.compact,
    required this.feedback,
    required this.launchSucceeded,
    required this.onSelectProject,
    required this.onOpenLink,
  });

  final List<PortfolioProject> projects;
  final PortfolioProject project;
  final int projectIndex;
  final bool compact;
  final String? feedback;
  final bool launchSucceeded;
  final ValueChanged<int> onSelectProject;
  final ValueChanged<PortfolioProjectLink> onOpenLink;

  @override
  Widget build(BuildContext context) {
    final collection = _FinderProjectCollection(
      projects: projects,
      selectedIndex: projectIndex,
      compact: compact,
      onSelected: onSelectProject,
    );
    final detail = _SelectedProjectDetail(
      project: project,
      projectIndex: projectIndex,
      compact: compact,
      feedback: feedback,
      launchSucceeded: launchSucceeded,
      onOpenLink: onOpenLink,
    );

    if (compact) {
      return ListView(
        key: const Key('projects-detail-scroll'),
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              collection,
              const SizedBox(height: 22),
              Divider(color: AppleTheme.separator(context)),
              const SizedBox(height: 18),
              detail,
            ],
          ),
        ],
      );
    }

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(30, 24, 30, 16),
          child: collection,
        ),
        Divider(height: 1, color: AppleTheme.separator(context)),
        Expanded(
          child: ListView(
            key: const Key('projects-detail-scroll'),
            padding: const EdgeInsets.all(30),
            children: <Widget>[detail],
          ),
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
  final int selectedIndex;
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
    required this.onOpenLink,
  });

  final PortfolioProject project;
  final int projectIndex;
  final bool compact;
  final String? feedback;
  final bool launchSucceeded;
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
    required this.onOpenLink,
  });

  final PortfolioProject project;
  final int projectIndex;
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
                    onPressed: () => onOpenLink(entry.$2),
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
