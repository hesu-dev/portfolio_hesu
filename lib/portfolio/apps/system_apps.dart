import 'package:flutter/material.dart';

import '../data/portfolio_data.dart';
import '../services/external_launcher.dart';
import '../theme/apple_theme.dart';
import '../widgets/apple_finder_scaffold.dart';

class ThisMacApp extends StatefulWidget {
  const ThisMacApp({
    required this.data,
    this.compact = false,
    this.tablet = false,
    super.key,
  });

  final PortfolioData data;
  final bool compact;
  final bool tablet;

  @override
  State<ThisMacApp> createState() => _ThisMacAppState();
}

class _ThisMacAppState extends State<ThisMacApp> {
  int? _selectedProjectIndex;

  @override
  void didUpdateWidget(covariant ThisMacApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    final selectedIndex = _selectedProjectIndex;
    if (selectedIndex != null && selectedIndex >= widget.data.projects.length) {
      _selectedProjectIndex = null;
    }
  }

  void _openProject(int index) {
    setState(() => _selectedProjectIndex = index);
  }

  void _showProjectFolders() {
    if (_selectedProjectIndex != null) {
      setState(() => _selectedProjectIndex = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _selectedProjectIndex;
    final selectedProject = selectedIndex == null
        ? null
        : widget.data.projects[selectedIndex];

    return AppleFinderScaffold(
      surfaceKey: const Key('this-mac-app'),
      keyPrefix: 'project-hub',
      currentLocation: selectedProject?.title ?? '프로젝트',
      ownerName: widget.data.identity.name,
      compact: widget.compact,
      tablet: widget.tablet,
      canGoBack: selectedProject != null,
      canGoForward: false,
      onBack: _showProjectFolders,
      onForward: () {},
      backTooltip: '프로젝트 폴더 목록으로 돌아가기',
      bodyBuilder: (context, compactLayout) {
        if (widget.data.projects.isEmpty) {
          return const AppleEmptyState(
            icon: Icons.folder_off_rounded,
            title: '프로젝트가 없습니다',
            message: '프로젝트가 추가되면 이 폴더에 표시됩니다.',
          );
        }
        if (selectedProject != null) {
          return _ProjectHubDetail(
            project: selectedProject,
            compact: compactLayout,
          );
        }
        return _ProjectHubFolderList(
          projects: widget.data.projects,
          compact: compactLayout,
          onOpenProject: _openProject,
        );
      },
    );
  }
}

class _ProjectHubFolderList extends StatelessWidget {
  const _ProjectHubFolderList({
    required this.projects,
    required this.compact,
    required this.onOpenProject,
  });

  final List<PortfolioProject> projects;
  final bool compact;
  final ValueChanged<int> onOpenProject;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const Key('project-hub-folder-list'),
      padding: EdgeInsets.all(compact ? 14 : 28),
      children: <Widget>[
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text('프로젝트', style: AppleTheme.title(context)),
                    ),
                    Text(
                      '${projects.length}개 폴더',
                      style: AppleTheme.caption(context),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final availableColumns = compact
                        ? (constraints.maxWidth / 132).floor().clamp(1, 2)
                        : (constraints.maxWidth / 156).floor().clamp(1, 4);
                    final columnCount = projects.length < availableColumns
                        ? projects.length
                        : availableColumns;
                    const spacing = 10.0;
                    final tileWidth =
                        (constraints.maxWidth - spacing * (columnCount - 1)) /
                        columnCount;
                    return Wrap(
                      spacing: spacing,
                      runSpacing: 12,
                      children: <Widget>[
                        for (final entry in projects.indexed)
                          SizedBox(
                            width: tileWidth,
                            child: AppleFinderFolderTile(
                              key: Key('project-hub-folder-${entry.$1}'),
                              label: entry.$2.title,
                              semanticsLabel: '${entry.$2.title} 열기',
                              compact: compact,
                              onPressed: () => onOpenProject(entry.$1),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProjectHubDetail extends StatelessWidget {
  const _ProjectHubDetail({required this.project, required this.compact});

  final PortfolioProject project;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const Key('project-hub-detail-scroll'),
      padding: EdgeInsets.all(compact ? 16 : 30),
      children: <Widget>[
        Center(
          child: ConstrainedBox(
            key: const Key('project-hub-detail'),
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(
                      Icons.folder_open_rounded,
                      size: compact ? 48 : 58,
                      color: const Color(0xFF55B8F5),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        project.title,
                        key: const Key('project-hub-detail-title'),
                        style: compact
                            ? Theme.of(context).textTheme.titleLarge
                            : Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerLeft,
                  child: ApplePill(
                    label: project.period,
                    icon: Icons.calendar_month_rounded,
                    color: AppleTheme.indigo,
                  ),
                ),
                SizedBox(height: compact ? 18 : 24),
                AppleSurfaceCard(
                  radius: 17,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('프로젝트 설명', style: AppleTheme.title(context)),
                      const SizedBox(height: 10),
                      Text(
                        project.description,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: compact ? 14 : 18),
                AppleSurfaceCard(
                  radius: 17,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('기술 스택', style: AppleTheme.title(context)),
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
                SizedBox(height: compact ? 14 : 18),
                const AppleSurfaceCard(
                  radius: 17,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Icon(Icons.info_outline_rounded, color: AppleTheme.blue),
                      SizedBox(width: 10),
                      Expanded(child: Text('상세 화면은 추후 기획 예정')),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class TrashApp extends StatelessWidget {
  const TrashApp({
    required this.data,
    this.compact = false,
    this.tablet = false,
    super.key,
  });

  final PortfolioData data;
  final bool compact;
  final bool tablet;

  @override
  Widget build(BuildContext context) {
    return AppleAppSurface(
      key: const Key('trash-app'),
      child: Column(
        children: <Widget>[
          AppleToolbar(
            title: 'Trash',
            subtitle: '0 items',
            compact: compact,
            leading: const Icon(Icons.delete_rounded),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  key: const Key('trash-scroll'),
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: AppleEmptyState(
                      icon: Icons.delete_outline_rounded,
                      title: 'Trash is Empty',
                      message:
                          'There are no deleted portfolio items for ${data.identity.englishName}.',
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class GitHubApp extends StatelessWidget {
  const GitHubApp({
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
  Widget build(BuildContext context) {
    return _ExternalProfilePage(
      rootKey: 'github-app',
      feedbackKey: 'github-launch-feedback',
      actionKey: 'github-external-action',
      title: 'GitHub',
      subtitle: 'Developer profile',
      actionLabel: 'Open GitHub profile',
      destinationLabel: 'GitHub',
      uri: Uri.parse(data.githubUrl),
      data: data,
      launcher: launcher,
      icon: Icons.code_rounded,
      colors: const <Color>[Color(0xFF50535A), Color(0xFF15161A)],
      compact: compact,
      tablet: tablet,
    );
  }
}

class MailApp extends StatelessWidget {
  const MailApp({
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
  Widget build(BuildContext context) {
    return _ExternalProfilePage(
      rootKey: 'mail-app',
      feedbackKey: 'mail-launch-feedback',
      actionKey: 'mail-external-action',
      title: 'Mail',
      subtitle: 'Contact ${data.identity.englishName}',
      actionLabel: 'Compose email',
      destinationLabel: 'Mail',
      uri: Uri.parse(data.mailUrl),
      data: data,
      launcher: launcher,
      icon: Icons.mail_rounded,
      colors: const <Color>[Color(0xFF62D0FF), Color(0xFF176CFF)],
      compact: compact,
      tablet: tablet,
    );
  }
}

class _ExternalProfilePage extends StatefulWidget {
  const _ExternalProfilePage({
    required this.rootKey,
    required this.feedbackKey,
    required this.actionKey,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.destinationLabel,
    required this.uri,
    required this.data,
    required this.launcher,
    required this.icon,
    required this.colors,
    required this.compact,
    required this.tablet,
  });

  final String rootKey;
  final String feedbackKey;
  final String actionKey;
  final String title;
  final String subtitle;
  final String actionLabel;
  final String destinationLabel;
  final Uri uri;
  final PortfolioData data;
  final ExternalLauncher launcher;
  final IconData icon;
  final List<Color> colors;
  final bool compact;
  final bool tablet;

  @override
  State<_ExternalProfilePage> createState() => _ExternalProfilePageState();
}

class _ExternalProfilePageState extends State<_ExternalProfilePage> {
  int _launchRequestGeneration = 0;
  String? _feedback;
  bool _succeeded = false;

  @override
  void didUpdateWidget(covariant _ExternalProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.uri != widget.uri ||
        !identical(oldWidget.launcher, widget.launcher)) {
      _launchRequestGeneration++;
      _feedback = null;
    }
  }

  Future<void> _launch() async {
    final requestGeneration = ++_launchRequestGeneration;
    var succeeded = false;
    try {
      succeeded = await widget.launcher.launch(widget.uri);
    } catch (_) {
      succeeded = false;
    }
    if (!mounted || requestGeneration != _launchRequestGeneration) {
      return;
    }
    setState(() {
      _succeeded = succeeded;
      _feedback = succeeded
          ? '${widget.destinationLabel} 앱을 열었습니다.'
          : '${widget.destinationLabel} 링크를 열 수 없습니다.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final padding = widget.compact ? 16.0 : (widget.tablet ? 24.0 : 30.0);
    return AppleAppSurface(
      key: Key(widget.rootKey),
      child: Column(
        children: <Widget>[
          AppleToolbar(
            title: widget.title,
            subtitle: widget.subtitle,
            compact: widget.compact,
            leading: Icon(widget.icon, color: AppleTheme.blue),
          ),
          Expanded(
            child: ListView(
              key: Key('${widget.rootKey}-scroll'),
              padding: EdgeInsets.all(padding),
              children: <Widget>[
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 620),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        AppleSurfaceCard(
                          padding: EdgeInsets.all(widget.compact ? 20 : 28),
                          child: Column(
                            children: <Widget>[
                              Container(
                                width: widget.compact ? 76 : 92,
                                height: widget.compact ? 76 : 92,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: widget.colors,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    widget.compact ? 22 : 27,
                                  ),
                                  boxShadow: <BoxShadow>[
                                    BoxShadow(
                                      color: widget.colors.last.withValues(
                                        alpha: 0.25,
                                      ),
                                      blurRadius: 24,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  widget.icon,
                                  color: Colors.white,
                                  size: widget.compact ? 36 : 42,
                                ),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                widget.data.identity.englishName,
                                textAlign: TextAlign.center,
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 5),
                              Text(
                                widget.title == 'Mail'
                                    ? widget.data.identity.email
                                    : widget.data.identity.headline,
                                textAlign: TextAlign.center,
                                style: AppleTheme.body(context).copyWith(
                                  color: AppleTheme.secondaryLabel(context),
                                ),
                              ),
                              const SizedBox(height: 20),
                              FilledButton.icon(
                                key: Key(widget.actionKey),
                                onPressed: _launch,
                                icon: Icon(
                                  widget.title == 'Mail'
                                      ? Icons.edit_rounded
                                      : Icons.open_in_new_rounded,
                                  size: 18,
                                ),
                                label: Text(widget.actionLabel),
                              ),
                            ],
                          ),
                        ),
                        if (_feedback case final message?) ...<Widget>[
                          const SizedBox(height: 14),
                          AppleFeedbackBanner(
                            key: Key(widget.feedbackKey),
                            message: message,
                            success: _succeeded,
                          ),
                        ],
                        const SizedBox(height: 18),
                        AppleSurfaceCard(
                          radius: 17,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                widget.title == 'Mail'
                                    ? 'Contact card'
                                    : 'Profile card',
                                style: AppleTheme.title(context),
                              ),
                              const SizedBox(height: 12),
                              _InfoRow(
                                label: 'Name',
                                value:
                                    '${widget.data.identity.name} · ${widget.data.identity.englishName}',
                              ),
                              const SizedBox(height: 10),
                              _InfoRow(
                                label: widget.title == 'Mail'
                                    ? 'Address'
                                    : 'Profile',
                                value: widget.title == 'Mail'
                                    ? widget.data.identity.email
                                    : widget.data.identity.githubUrl,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: 104,
          child: Text(label, style: AppleTheme.caption(context)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            style: AppleTheme.body(
              context,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
