import 'package:flutter/material.dart';

import '../data/portfolio_data.dart';
import '../mobile/apple_mobile_dock_geometry.dart';
import '../services/external_launcher.dart';
import '../theme/apple_theme.dart';
import '../widgets/apple_finder_scaffold.dart';
import '../widgets/project_app_icon.dart';
import 'safari_project_page.dart';

class SafariApp extends StatefulWidget {
  const SafariApp({
    required this.data,
    required this.launcher,
    this.compact = false,
    this.tablet = false,
    this.windowChrome,
    super.key,
  });

  final PortfolioData data;
  final ExternalLauncher launcher;
  final bool compact;
  final bool tablet;
  final AppleFinderWindowChrome? windowChrome;

  @override
  State<SafariApp> createState() => _SafariAppState();
}

class _SafariAppState extends State<SafariApp> {
  final _history = <PortfolioProject>[];
  int _cursor = 0;
  bool _showTabs = false;
  final _pendingLinks = <Uri>{};
  String? _feedback;
  int _navigationGeneration = 0;

  PortfolioProject? get _selected =>
      _history.isEmpty ? null : _history[_cursor];

  @override
  void initState() {
    super.initState();
    if (widget.data.projects.isNotEmpty) {
      _history.add(widget.data.projects.first);
    }
  }

  @override
  void didUpdateWidget(covariant SafariApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.data.projects, widget.data.projects)) {
      final current = _selected;
      _history.clear();
      if (widget.data.projects.isNotEmpty) {
        _history.add(
          widget.data.projects.contains(current)
              ? current!
              : widget.data.projects.first,
        );
      }
      _cursor = 0;
      _feedback = null;
      _navigationGeneration++;
    }
  }

  void _select(PortfolioProject project) => setState(() {
    _showTabs = false;
    if (project == _selected) return;
    _history.removeRange(_history.isEmpty ? 0 : _cursor + 1, _history.length);
    _history.add(project);
    _cursor = _history.length - 1;
    _feedback = null;
    _navigationGeneration++;
  });

  void _go(int delta) => setState(() {
    _cursor += delta;
    _showTabs = false;
    _feedback = null;
    _navigationGeneration++;
  });

  Future<void> _openLink(PortfolioProjectLink link) async {
    if (!_pendingLinks.add(link.uri)) return;
    final generation = _navigationGeneration;
    setState(() => _feedback = null);
    var opened = false;
    try {
      opened = await widget.launcher.launch(link.uri);
    } catch (_) {
      opened = false;
    }
    if (!mounted) return;
    setState(() {
      _pendingLinks.remove(link.uri);
      if (generation == _navigationGeneration && !opened) {
        _feedback = '링크를 열 수 없습니다. 잠시 후 다시 시도해 주세요.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mobile = widget.compact || widget.tablet;
    final clearance = mobile
        ? AppleMobileDockGeometry.appBottomClearance(
            tablet: widget.tablet,
            safeAreaBottom: MediaQuery.paddingOf(context).bottom,
          )
        : 0.0;
    return Material(
      key: const Key('safari-app'),
      color: AppleTheme.surface(context),
      child: Column(
        children: [
          if (!widget.compact) _toolbar(context),
          if (!widget.compact) _bookmarks(context),
          if (!widget.compact) _introduction(context),
          Expanded(
            child: widget.compact && _showTabs
                ? _tabsOverview(context)
                : _page(context, widget.tablet ? clearance : 0),
          ),
          if (widget.compact) _phoneToolbar(context, clearance),
        ],
      ),
    );
  }

  Widget _navigationButton(bool forward) => IconButton(
    key: Key(forward ? 'safari-forward' : 'safari-back'),
    tooltip: forward ? '앞으로' : '뒤로',
    onPressed: (forward ? _cursor < _history.length - 1 : _cursor > 0)
        ? () => _go(forward ? 1 : -1)
        : null,
    icon: Icon(
      forward ? Icons.chevron_right_rounded : Icons.chevron_left_rounded,
    ),
  );

  Widget _introduction(BuildContext context) => Container(
    key: const Key('safari-report-introduction'),
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
    decoration: BoxDecoration(
      border: Border(bottom: BorderSide(color: AppleTheme.separator(context))),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            '프로젝트',
            style: AppleTheme.largeTitle(context).copyWith(fontSize: 28),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '프로젝트의 구조, 운영 환경, 문제 해결 과정을 확인하는 리포트',
          style: AppleTheme.body(context).copyWith(
            color: AppleTheme.secondaryLabel(context),
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    ),
  );

  Widget _toolbar(BuildContext context) {
    final chrome = widget.windowChrome;
    return MouseRegion(
      cursor: chrome?.cursor ?? MouseCursor.defer,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: chrome?.onDragStart,
        onPanUpdate: chrome?.onDragUpdate,
        child: Container(
          key: const Key('safari-toolbar'),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppleTheme.panel(context),
            border: Border(
              bottom: BorderSide(color: AppleTheme.separator(context)),
            ),
          ),
          child: Row(
            children: [
              if (chrome != null) ...[
                chrome.leadingControls,
                const SizedBox(width: 14),
              ],
              _navigationButton(false),
              _navigationButton(true),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: AppleTheme.surface(context),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: AppleTheme.separator(context)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.language_rounded,
                        size: 15,
                        color: AppleTheme.secondaryLabel(context),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _selected?.title ?? 'Portfolio',
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppleTheme.caption(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bookmarks(BuildContext context) => Container(
    key: const Key('safari-bookmarks'),
    decoration: BoxDecoration(
      color: AppleTheme.panel(context),
      border: Border(bottom: BorderSide(color: AppleTheme.separator(context))),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: Row(
        children: [
          for (final entry in widget.data.projects.indexed)
            Expanded(
              child: Tooltip(
                message: entry.$2.title,
                child: Semantics(
                  selected: _selected == entry.$2,
                  child: TextButton(
                    key: Key('safari-bookmark-${entry.$1}'),
                    onPressed: () => _select(entry.$2),
                    style: TextButton.styleFrom(
                      foregroundColor: _selected == entry.$2
                          ? AppleTheme.buttonBlue
                          : AppleTheme.primaryLabel(context),
                      backgroundColor: _selected == entry.$2
                          ? AppleTheme.blue.withValues(alpha: .1)
                          : null,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: _ProjectMark(project: entry.$2),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            switch (entry.$2.title) {
                              'ReadingLog' => '리딩로그',
                              'PersonaChat AI Character Chat' => 'AI 챗',
                              _ => entry.$2.title,
                            },
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
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
  );

  Widget _page(BuildContext context, double bottomClearance) {
    final project = _selected;
    if (project == null) return const Center(child: Text('프로젝트가 없습니다.'));
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 560;
        final padding = narrow ? 20.0 : 24.0;
        return SizedBox.expand(
          key: const Key('safari-page'),
          child: SingleChildScrollView(
            key: PageStorageKey<PortfolioProject>(project),
            padding: EdgeInsets.fromLTRB(
              padding,
              padding,
              padding,
              padding + bottomClearance,
            ),
            child: SafariProjectPage(
              project: project,
              compact: narrow,
              onOpenLink: _openLink,
              pendingLinks: _pendingLinks,
              feedback: _feedback,
            ),
          ),
        );
      },
    );
  }

  Widget _phoneToolbar(BuildContext context, double clearance) => Container(
    key: const Key('safari-phone-toolbar'),
    padding: EdgeInsets.fromLTRB(10, 8, 10, clearance),
    decoration: BoxDecoration(
      color: AppleTheme.panel(context),
      border: Border(top: BorderSide(color: AppleTheme.separator(context))),
    ),
    child: Row(
      children: [
        _navigationButton(false),
        _navigationButton(true),
        const SizedBox(width: 8),
        Expanded(
          child: TextButton.icon(
            key: const Key('safari-all-tabs'),
            onPressed: () => setState(() => _showTabs = !_showTabs),
            icon: Icon(
              _showTabs ? Icons.check_rounded : Icons.tab_rounded,
              size: 19,
            ),
            label: Text(
              _showTabs ? '완료' : '모든 탭(${widget.data.projects.length})',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _tabsOverview(BuildContext context) => SingleChildScrollView(
    key: const Key('safari-tabs-overview'),
    padding: const EdgeInsets.all(18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Text(
            '열린 탭 ${widget.data.projects.length}',
            style: AppleTheme.title(context),
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = MediaQuery.textScalerOf(context).scale(14) > 20
                ? 1
                : 2;
            final width = (constraints.maxWidth - 14 * (columns - 1)) / columns;
            return Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                for (final entry in widget.data.projects.indexed)
                  SizedBox(
                    width: width,
                    child: Semantics(
                      selected: entry.$2 == _selected,
                      button: true,
                      label: '${entry.$2.title} 탭 열기',
                      child: Material(
                        color: AppleTheme.panel(context),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: entry.$2 == _selected
                                ? AppleTheme.blue
                                : AppleTheme.separator(context),
                            width: entry.$2 == _selected ? 2 : 1,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          key: Key('safari-tab-${entry.$1}'),
                          onTap: () => _select(entry.$2),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              AspectRatio(
                                aspectRatio: 1.35,
                                child:
                                    entry.$2.appIconAsset == null &&
                                        entry.$2.screenshots.isNotEmpty
                                    ? Image.asset(
                                        entry.$2.screenshots.first.asset,
                                        fit: BoxFit.cover,
                                        excludeFromSemantics: true,
                                      )
                                    : Center(
                                        child: SizedBox(
                                          width: 54,
                                          height: 54,
                                          child: _ProjectMark(
                                            project: entry.$2,
                                          ),
                                        ),
                                      ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(
                                  entry.$2.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppleTheme.body(context).copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    ),
  );
}

class _ProjectMark extends StatelessWidget {
  const _ProjectMark({required this.project});
  final PortfolioProject project;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(7),
    child: project.appIconAsset != null
        ? ProjectAppIcon(assetPath: project.appIconAsset!)
        : ColoredBox(
            color: const Color(0xFFE3EDF9),
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: FittedBox(
                child: Text(
                  project.title.characters.take(2).toString().toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF334864),
                  ),
                ),
              ),
            ),
          ),
  );
}
