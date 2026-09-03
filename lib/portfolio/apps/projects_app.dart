import 'package:flutter/material.dart';

import '../data/portfolio_data.dart';
import '../services/external_launcher.dart';
import '../theme/apple_theme.dart';

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
          _BrowserToolbar(compact: widget.compact),
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
          child: _ProjectSidebar(
            projects: widget.data.projects,
            selectedIndex: _selectedIndex,
            onSelected: _selectProject,
          ),
        ),
        Expanded(child: _buildDetail(compact: false)),
      ],
    );
  }

  Widget _buildCompact() {
    return Column(
      children: <Widget>[
        _ProjectStrip(
          projects: widget.data.projects,
          selectedIndex: _selectedIndex,
          onSelected: _selectProject,
        ),
        Expanded(child: _buildDetail(compact: true)),
      ],
    );
  }

  Widget _buildDetail({required bool compact}) {
    return _ProjectDetail(
      project: widget.data.projects[_selectedIndex],
      projectIndex: _selectedIndex,
      compact: compact,
      feedback: _launchFeedback,
      launchSucceeded: _launchSucceeded,
      onOpenLink: _openLink,
    );
  }
}

class _BrowserToolbar extends StatelessWidget {
  const _BrowserToolbar({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppleTheme.surface(context),
        border: Border(
          bottom: BorderSide(color: AppleTheme.separator(context), width: 0.7),
        ),
      ),
      child: SizedBox(
        height: compact ? 54 : 62,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 18),
          child: Row(
            children: <Widget>[
              for (final color in const <Color>[
                Color(0xFFFF5F57),
                Color(0xFFFFBD2E),
                Color(0xFF28C840),
              ]) ...<Widget>[
                Container(
                  width: compact ? 9 : 11,
                  height: compact ? 9 : 11,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: compact ? 5 : 7),
              ],
              SizedBox(width: compact ? 4 : 14),
              Expanded(
                child: Container(
                  height: compact ? 34 : 38,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppleTheme.panel(context),
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: AppleTheme.separator(context)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        Icons.lock_rounded,
                        size: 13,
                        color: AppleTheme.secondaryLabel(context),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'portfolio.local/projects',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppleTheme.caption(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: compact ? 7 : 12),
              Icon(
                Icons.ios_share_rounded,
                color: AppleTheme.blue,
                size: compact ? 19 : 21,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProjectSidebar extends StatelessWidget {
  const _ProjectSidebar({
    required this.projects,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<PortfolioProject> projects;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppleTheme.panel(context),
        border: Border(
          right: BorderSide(color: AppleTheme.separator(context), width: 0.7),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.all(11),
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 9),
            child: Text(
              'PROJECT REPORTS',
              style: AppleTheme.caption(context).copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.7,
              ),
            ),
          ),
          for (final entry in projects.indexed)
            _ProjectSelector(
              project: entry.$2,
              index: entry.$1,
              selected: selectedIndex == entry.$1,
              compact: false,
              onTap: () => onSelected(entry.$1),
            ),
        ],
      ),
    );
  }
}

class _ProjectStrip extends StatelessWidget {
  const _ProjectStrip({
    required this.projects,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<PortfolioProject> projects;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppleTheme.panel(context),
        border: Border(
          bottom: BorderSide(color: AppleTheme.separator(context), width: 0.7),
        ),
      ),
      child: SizedBox(
        height: 58,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          child: Row(
            children: <Widget>[
              for (final entry in projects.indexed) ...<Widget>[
                _ProjectSelector(
                  project: entry.$2,
                  index: entry.$1,
                  selected: selectedIndex == entry.$1,
                  compact: true,
                  onTap: () => onSelected(entry.$1),
                ),
                if (entry.$1 != projects.length - 1) const SizedBox(width: 8),
              ],
            ],
          ),
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
    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 0 : 5),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: Key('project-selector-$index'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(compact ? 999 : 12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            constraints: BoxConstraints(
              maxWidth: compact ? 220 : double.infinity,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 14 : 11,
              vertical: compact ? 9 : 11,
            ),
            decoration: BoxDecoration(
              color: selected
                  ? AppleTheme.blue.withValues(
                      alpha: AppleTheme.isDark(context) ? 0.28 : 0.13,
                    )
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(compact ? 999 : 12),
              border: compact
                  ? Border.all(
                      color: selected
                          ? AppleTheme.blue.withValues(alpha: 0.3)
                          : AppleTheme.separator(context),
                    )
                  : null,
            ),
            child: Row(
              mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
              children: <Widget>[
                Icon(
                  selected ? Icons.article_rounded : Icons.description_outlined,
                  size: 18,
                  color: selected
                      ? AppleTheme.blue
                      : AppleTheme.secondaryLabel(context),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    project.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: selected
                          ? AppleTheme.blue
                          : AppleTheme.primaryLabel(context),
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
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
    return ListView(
      key: const Key('projects-detail-scroll'),
      padding: EdgeInsets.all(compact ? 16 : 30),
      children: <Widget>[
        Center(
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
                AppleSurfaceCard(
                  radius: 17,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Project overview',
                        style: AppleTheme.title(context),
                      ),
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
                      Text(
                        'Technology stack',
                        style: AppleTheme.title(context),
                      ),
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
                SizedBox(height: compact ? 16 : 20),
                AppleSurfaceCard(
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
                                key: Key(
                                  'project-link-$projectIndex-${entry.$1}',
                                ),
                                onPressed: () => onOpenLink(entry.$2),
                                icon: const Icon(
                                  Icons.open_in_new_rounded,
                                  size: 17,
                                ),
                                label: Text(entry.$2.label),
                              ),
                          ],
                        ),
                      ],
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
        ),
      ],
    );
  }
}
