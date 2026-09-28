import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../data/portfolio_data.dart';
import '../services/external_launcher.dart';
import '../theme/apple_theme.dart';
import '../widgets/apple_finder_scaffold.dart';
import '../widgets/github_contributions.dart';
import '../widgets/project_app_icon.dart';

class ThisMacApp extends StatefulWidget {
  const ThisMacApp({
    required this.data,
    this.compact = false,
    this.tablet = false,
    this.finderWindowChrome,
    super.key,
  });

  final PortfolioData data;
  final bool compact;
  final bool tablet;
  final AppleFinderWindowChrome? finderWindowChrome;

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
      windowChrome: widget.finderWindowChrome,
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
                              imageAsset: entry.$2.appIconAsset,
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
                    if (project.appIconAsset case final assetPath?)
                      ProjectAppIcon(
                        assetPath: assetPath,
                        size: compact ? 48 : 58,
                      )
                    else
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
                if (project.period.trim().isNotEmpty) ...<Widget>[
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ApplePill(
                      label: project.period,
                      icon: Icons.calendar_month_rounded,
                      color: AppleTheme.indigo,
                    ),
                  ),
                ],
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

class TrashApp extends StatefulWidget {
  const TrashApp({
    required this.data,
    this.compact = false,
    this.tablet = false,
    this.trashEmpty = false,
    this.onTrashEmptied,
    super.key,
  });

  final PortfolioData data;
  final bool compact;
  final bool tablet;
  final bool trashEmpty;
  final VoidCallback? onTrashEmptied;

  @override
  State<TrashApp> createState() => _TrashAppState();
}

class _TrashAppState extends State<TrashApp> {
  static const List<_TrashItemData> _items = <_TrashItemData>[
    _TrashItemData(
      name: '이전-이력서-초안.docx',
      detail: '워드 문서 · 84KB',
      deleted: '오늘 오전 10:42',
      icon: Icons.description_rounded,
      color: Color(0xFF2468C8),
    ),
    _TrashItemData(
      name: '포트폴리오-미리보기.png',
      detail: 'PNG 이미지 · 1.8MB',
      deleted: '어제 오후 6:16',
      icon: Icons.image_rounded,
      color: Color(0xFFB94ACE),
    ),
    _TrashItemData(
      name: '디버그-기록.log',
      detail: '로그 파일 · 32KB',
      deleted: '9월 3일 오후 9:05',
      icon: Icons.terminal_rounded,
      color: Color(0xFF5C6370),
    ),
  ];

  late bool _empty;

  @override
  void initState() {
    super.initState();
    _empty = widget.trashEmpty;
  }

  @override
  void didUpdateWidget(covariant TrashApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trashEmpty != widget.trashEmpty) {
      _empty = widget.trashEmpty;
    }
  }

  Future<void> _requestEmptyTrash() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const _TrashConfirmationDialog(),
    );
    if (confirmed != true || !mounted || _empty) {
      return;
    }
    setState(() => _empty = true);
    widget.onTrashEmptied?.call();
  }

  @override
  Widget build(BuildContext context) {
    return AppleAppSurface(
      key: const Key('trash-app'),
      child: Column(
        children: <Widget>[
          Container(
            key: const Key('trash-toolbar'),
            constraints: const BoxConstraints(minHeight: 48),
            padding: EdgeInsets.symmetric(horizontal: widget.compact ? 16 : 22),
            decoration: BoxDecoration(
              color: AppleTheme.panel(context),
              border: Border(
                bottom: BorderSide(color: AppleTheme.separator(context)),
              ),
            ),
            child: Row(
              children: <Widget>[
                const Spacer(),
                FilledButton(
                  key: const Key('trash-empty-button'),
                  onPressed: _empty ? null : _requestEmptyTrash,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF6E6E73),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppleTheme.separator(context),
                    disabledForegroundColor: AppleTheme.secondaryLabel(context),
                    minimumSize: const Size(0, 32),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    visualDensity: VisualDensity.standard,
                    tapTargetSize: MaterialTapTargetSize.padded,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('비우기'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              key: const Key('trash-scroll'),
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              padding: EdgeInsets.all(widget.compact ? 14 : 22),
              itemCount: _empty ? 0 : _items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) => _TrashItemRow(
                key: Key('trash-item-$index'),
                item: _items[index],
                compact: widget.compact,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrashItemData {
  const _TrashItemData({
    required this.name,
    required this.detail,
    required this.deleted,
    required this.icon,
    required this.color,
  });

  final String name;
  final String detail;
  final String deleted;
  final IconData icon;
  final Color color;
}

class _TrashItemRow extends StatelessWidget {
  const _TrashItemRow({required this.item, required this.compact, super.key});

  final _TrashItemData item;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return AppleSurfaceCard(
      radius: 15,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 14 : 18,
        vertical: compact ? 12 : 14,
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: compact ? 42 : 48,
            height: compact ? 42 : 48,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, color: item.color),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppleTheme.body(
                    context,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(item.detail, style: AppleTheme.caption(context)),
              ],
            ),
          ),
          if (!compact) ...<Widget>[
            const SizedBox(width: 12),
            Text(item.deleted, style: AppleTheme.caption(context)),
          ],
        ],
      ),
    );
  }
}

class _TrashConfirmationDialog extends StatelessWidget {
  const _TrashConfirmationDialog();

  @override
  Widget build(BuildContext context) {
    void close(bool confirmed) => Navigator.of(context).pop(confirmed);

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.keyY): () => close(true),
        const SingleActivator(LogicalKeyboardKey.keyN): () => close(false),
      },
      child: Focus(
        autofocus: true,
        child: AlertDialog(
          key: const Key('trash-empty-dialog'),
          title: const Text('휴지통을 비우겠습니까?'),
          content: const Text('모든 파일이 삭제됩니다.'),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: <Widget>[
            TextButton(
              key: const Key('trash-empty-cancel'),
              onPressed: () => close(false),
              child: const Text('아니오'),
            ),
            FilledButton(
              key: const Key('trash-empty-confirm'),
              onPressed: () => close(true),
              child: const Text('네'),
            ),
          ],
        ),
      ),
    );
  }
}

const _githubProfile = (
  username: 'hesu-dev',
  name: 'sunell_dev',
  avatarAsset: 'assets/github-profile/hesu-dev-avatar.png',
);

const _githubAccounts = [
  _githubProfile,
  (
    username: 'sukenell',
    name: 'sukenell',
    avatarAsset: 'assets/github-profile/sukenell-avatar.png',
  ),
  (
    username: 'sunelll',
    name: 'sunell',
    avatarAsset: 'assets/github-profile/sunelll-avatar.png',
  ),
];

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
      destinationLabel: 'GitHub',
      uri: Uri.parse(data.githubUrl),
      launcher: launcher,
      compact: compact,
      tablet: tablet,
    );
  }
}

String _encodeQueryParameters(Map<String, String> parameters) {
  return parameters.entries
      .map(
        (entry) =>
            '${Uri.encodeComponent(entry.key)}=${Uri.encodeComponent(entry.value)}',
      )
      .join('&');
}

class MailApp extends StatefulWidget {
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
  State<MailApp> createState() => _MailAppState();
}

class _MailAppState extends State<MailApp> {
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  int _launchRequestGeneration = 0;
  String? _feedback;

  @override
  void didUpdateWidget(covariant MailApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data.email != widget.data.email ||
        !identical(oldWidget.launcher, widget.launcher)) {
      _launchRequestGeneration++;
      _feedback = null;
    }
  }

  @override
  void dispose() {
    _launchRequestGeneration++;
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Uri _composeUri() {
    final subject = _subjectController.text.trim();
    final body = _bodyController.text.trim();
    if (subject.isEmpty && body.isEmpty) {
      return Uri.parse(widget.data.mailUrl);
    }
    return Uri(
      scheme: 'mailto',
      path: widget.data.email.trim(),
      query: _encodeQueryParameters(<String, String>{
        if (subject.isNotEmpty) 'subject': subject,
        if (body.isNotEmpty) 'body': body,
      }),
    );
  }

  Future<void> _launch() async {
    final requestGeneration = ++_launchRequestGeneration;
    var succeeded = false;
    try {
      succeeded = await widget.launcher.launch(_composeUri());
    } catch (_) {
      succeeded = false;
    }
    if (!mounted || requestGeneration != _launchRequestGeneration) {
      return;
    }
    setState(() {
      _feedback = succeeded ? null : 'Mail 링크를 열 수 없습니다.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final padding = widget.compact ? 16.0 : (widget.tablet ? 24.0 : 30.0);
    return AppleAppSurface(
      key: const Key('mail-app'),
      child: ListView(
        key: const Key('mail-app-scroll'),
        padding: EdgeInsets.all(padding),
        children: <Widget>[
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  AppleSurfaceCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 12, 10, 10),
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  '새로운 메시지',
                                  style: AppleTheme.title(context),
                                ),
                              ),
                              IconButton.filled(
                                key: const Key('mail-external-action'),
                                onPressed: _launch,
                                tooltip: '메일 앱에서 보내기',
                                icon: const Icon(Icons.send_rounded),
                              ),
                            ],
                          ),
                        ),
                        Divider(
                          height: 1,
                          color: AppleTheme.separator(context),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 13,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              SizedBox(
                                width: 76,
                                child: Text(
                                  '받는 사람',
                                  style: AppleTheme.caption(context),
                                ),
                              ),
                              Expanded(
                                child: SelectableText(
                                  widget.data.email,
                                  style: AppleTheme.body(
                                    context,
                                  ).copyWith(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Divider(
                          height: 1,
                          color: AppleTheme.separator(context),
                        ),
                        TextField(
                          key: const Key('mail-subject-input'),
                          controller: _subjectController,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: '제목',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 14,
                            ),
                          ),
                        ),
                        Divider(
                          height: 1,
                          color: AppleTheme.separator(context),
                        ),
                        TextField(
                          key: const Key('mail-body-input'),
                          controller: _bodyController,
                          keyboardType: TextInputType.multiline,
                          textInputAction: TextInputAction.newline,
                          minLines: widget.compact ? 9 : 12,
                          maxLines: null,
                          decoration: const InputDecoration(
                            hintText: '메시지를 입력하세요.',
                            border: InputBorder.none,
                            alignLabelWithHint: true,
                            contentPadding: EdgeInsets.all(18),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_feedback case final message?) ...<Widget>[
                    const SizedBox(height: 14),
                    AppleFeedbackBanner(
                      key: const Key('mail-launch-feedback'),
                      message: message,
                      success: false,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExternalProfilePage extends StatefulWidget {
  const _ExternalProfilePage({
    required this.rootKey,
    required this.feedbackKey,
    required this.destinationLabel,
    required this.uri,
    required this.launcher,
    required this.compact,
    required this.tablet,
  });

  final String rootKey;
  final String feedbackKey;
  final String destinationLabel;
  final Uri uri;
  final ExternalLauncher launcher;
  final bool compact;
  final bool tablet;

  @override
  State<_ExternalProfilePage> createState() => _ExternalProfilePageState();
}

class _ExternalProfilePageState extends State<_ExternalProfilePage> {
  late final Future<String> _readme = rootBundle.loadString(
    'assets/github-profile/README.md',
  );
  int _launchRequestGeneration = 0;
  String? _feedback;

  @override
  void didUpdateWidget(covariant _ExternalProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.uri != widget.uri ||
        !identical(oldWidget.launcher, widget.launcher)) {
      _launchRequestGeneration++;
      _feedback = null;
    }
  }

  Future<void> _launch({Uri? target, String? rawTarget}) async {
    final requestGeneration = ++_launchRequestGeneration;
    var succeeded = false;
    try {
      final uri = rawTarget == null
          ? target ?? widget.uri
          : Uri.parse(rawTarget);
      succeeded = await widget.launcher.launch(uri);
    } catch (_) {
      succeeded = false;
    }
    if (!mounted || requestGeneration != _launchRequestGeneration) {
      return;
    }
    setState(() {
      _feedback = succeeded ? null : '${widget.destinationLabel} 링크를 열 수 없습니다.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final padding = widget.compact ? 16.0 : (widget.tablet ? 24.0 : 30.0);
    return AppleAppSurface(
      key: Key(widget.rootKey),
      child: ListView(
        key: Key('${widget.rootKey}-scroll'),
        padding: EdgeInsets.all(padding),
        children: <Widget>[
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  AppleSurfaceCard(
                    key: const Key('github-profile-card'),
                    padding: EdgeInsets.all(widget.compact ? 20 : 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Semantics(
                          link: true,
                          child: InkWell(
                            key: const Key('github-profile-link'),
                            onTap: () => _launch(),
                            borderRadius: BorderRadius.circular(10),
                            child: Row(
                              children: <Widget>[
                                _GitHubAvatar(
                                  asset: _githubProfile.avatarAsset,
                                  size: 56,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        _githubProfile.name,
                                        style: AppleTheme.title(context),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _githubProfile.username,
                                        style: AppleTheme.caption(context),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        FutureBuilder<String>(
                          future: _readme,
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return const Text('프로필을 불러올 수 없습니다.');
                            }
                            if (!snapshot.hasData) {
                              return const Text('프로필을 불러오는 중입니다.');
                            }
                            return MarkdownBody(
                              key: const Key('github-profile-markdown'),
                              data: snapshot.data!,
                              styleSheet:
                                  MarkdownStyleSheet.fromTheme(
                                    Theme.of(context),
                                  ).copyWith(
                                    p: AppleTheme.body(context),
                                    a: AppleTheme.body(context).copyWith(
                                      color: AppleTheme.blue,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                              imageBuilder: (uri, title, alt) {
                                final image = Image.asset(
                                  uri.path,
                                  height: alt == 'header' ? null : 28,
                                  fit: BoxFit.contain,
                                  semanticLabel: alt == 'header'
                                      ? '반갑습니다! 👋'
                                      : alt,
                                );
                                return alt == 'header'
                                    ? AspectRatio(
                                        aspectRatio: 854 / 300,
                                        child: image,
                                      )
                                    : image;
                              },
                              onTapLink: (text, href, title) {
                                if (href != null) {
                                  _launch(rawTarget: href);
                                }
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  if (_feedback case final message?) ...<Widget>[
                    const SizedBox(height: 14),
                    AppleFeedbackBanner(
                      key: Key(widget.feedbackKey),
                      message: message,
                      success: false,
                    ),
                  ],
                  const SizedBox(height: 18),
                  const GitHubContributions(),
                  const SizedBox(height: 18),
                  Column(
                    key: const Key('github-accounts-section'),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final account in _githubAccounts)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: AppleSurfaceCard(
                            padding: EdgeInsets.zero,
                            child: Material(
                              type: MaterialType.transparency,
                              child: ListTile(
                                key: Key('github-account-${account.username}'),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 10,
                                ),
                                leading: _GitHubAvatar(
                                  asset: account.avatarAsset,
                                  size: 44,
                                ),
                                title: Text(
                                  account.name,
                                  style: AppleTheme.body(
                                    context,
                                  ).copyWith(fontWeight: FontWeight.w600),
                                ),
                                subtitle: account.name == account.username
                                    ? null
                                    : Text(
                                        account.username,
                                        style: AppleTheme.caption(context),
                                      ),
                                trailing: Icon(
                                  Icons.open_in_new_rounded,
                                  size: 18,
                                  color: AppleTheme.secondaryLabel(context),
                                ),
                                onTap: () => _launch(
                                  target:
                                      account.username ==
                                          _githubProfile.username
                                      ? widget.uri
                                      : Uri.parse(
                                          'https://github.com/${account.username}',
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GitHubAvatar extends StatelessWidget {
  const _GitHubAvatar({required this.asset, required this.size});

  final String? asset;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: asset == null
          ? Icon(
              Icons.account_circle_outlined,
              size: size,
              color: AppleTheme.blue,
            )
          : Image.asset(
              asset!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              excludeFromSemantics: true,
            ),
    );
  }
}
