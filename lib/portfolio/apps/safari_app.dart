import 'package:flutter/material.dart';

import '../data/portfolio_data.dart';
import '../mobile/apple_mobile_dock_geometry.dart';
import '../services/external_launcher.dart';
import '../theme/apple_theme.dart';
import '../widgets/apple_finder_scaffold.dart';
import 'safari_project_page.dart';
import 'safari_start_page.dart';

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
  // A null destination is the start page, including the initial history entry.
  final _history = <PortfolioProject?>[null];
  final _searchController = TextEditingController();
  final _pendingLinks = <Uri>{};
  int _cursor = 0;
  String _query = '';
  String? _feedback;
  int _navigationGeneration = 0;

  PortfolioProject? get _selected => _history[_cursor];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant SafariApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.data.projects, widget.data.projects)) {
      final current = _selected;
      _history
        ..clear()
        ..add(null);
      if (current != null && widget.data.projects.contains(current)) {
        _history.add(current);
      }
      _cursor = _history.length - 1;
      _query = '';
      _searchController.clear();
      _feedback = null;
      _navigationGeneration++;
    }
  }

  void _push(PortfolioProject? project) {
    if (project == _selected) return;
    _history.removeRange(_cursor + 1, _history.length);
    _history.add(project);
    _cursor = _history.length - 1;
    _feedback = null;
    _navigationGeneration++;
  }

  void _select(PortfolioProject? project) {
    FocusScope.of(context).unfocus();
    setState(() {
      _query = '';
      _searchController.clear();
      _push(project);
    });
  }

  void _search(String value) => setState(() {
    _push(null);
    _query = value;
  });

  void _go(int delta) {
    final next = _cursor + delta;
    if (next < 0 || next >= _history.length) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _cursor = next;
      _query = '';
      _searchController.clear();
      _feedback = null;
      _navigationGeneration++;
    });
  }

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
          _toolbar(context),
          Expanded(
            child: _selected == null
                ? SafariStartPage(
                    projects: widget.data.projects,
                    query: _query,
                    bottomClearance: clearance,
                    onOpenProject: _select,
                  )
                : _page(context, clearance),
          ),
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

  Widget _toolbar(BuildContext context) {
    final chrome = widget.windowChrome;
    final mobileLeading = chrome?.mobileLeadingControlsBuilder;
    return MouseRegion(
      cursor: chrome?.cursor ?? MouseCursor.defer,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: chrome?.onDragStart,
        onPanUpdate: chrome?.onDragUpdate,
        child: Container(
          key: const Key('safari-toolbar'),
          padding: EdgeInsets.symmetric(
            horizontal: widget.compact ? 6 : 14,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: AppleTheme.panel(context).withValues(alpha: .95),
            border: Border(
              bottom: BorderSide(color: AppleTheme.separator(context)),
            ),
          ),
          child: Row(
            children: [
              if (mobileLeading != null)
                mobileLeading(_cursor > 0, () => _go(-1))
              else ...[
                if (chrome != null) ...[
                  chrome.leadingControls,
                  const SizedBox(width: 10),
                ],
                _navigationButton(false),
              ],
              _navigationButton(true),
              const SizedBox(width: 6),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 680),
                    child: TextField(
                      key: const Key('safari-search-field'),
                      controller: _searchController,
                      onChanged: _search,
                      onSubmitted: (_) => FocusScope.of(context).unfocus(),
                      textInputAction: TextInputAction.search,
                      maxLines: 1,
                      style: AppleTheme.body(context).copyWith(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: _selected?.title != null
                            ? 'www.${_selected?.title}.com'
                            : '프로젝트 이름 검색',
                        hintStyle: AppleTheme.body(context).copyWith(
                          color: AppleTheme.secondaryLabel(context),
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          size: 20,
                          color: AppleTheme.secondaryLabel(context),
                        ),
                        suffixIcon: _query.isEmpty
                            ? null
                            : IconButton(
                                key: const Key('safari-search-clear'),
                                tooltip: '검색 지우기',
                                onPressed: () {
                                  _searchController.clear();
                                  _search('');
                                },
                                icon: const Icon(
                                  Icons.cancel_rounded,
                                  size: 18,
                                ),
                              ),
                        filled: true,
                        fillColor: AppleTheme.surface(context),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide(
                            color: AppleTheme.separator(context),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: const BorderSide(
                            color: AppleTheme.blue,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                key: const Key('safari-home'),
                tooltip: '시작 페이지',
                onPressed: () => _select(null),
                icon: const Icon(Icons.grid_view_rounded, size: 21),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _page(BuildContext context, double bottomClearance) {
    final project = _selected!;
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
}
