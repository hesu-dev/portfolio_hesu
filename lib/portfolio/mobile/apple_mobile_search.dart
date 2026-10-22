import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/portfolio_app_id.dart';
import '../theme/apple_theme.dart';
import '../widgets/apple_app_artwork.dart';
import '../widgets/apple_app_icon.dart';

class AppleMobileSearch extends StatefulWidget {
  const AppleMobileSearch({
    required this.tablet,
    required this.onOpenApp,
    required this.onClose,
    this.trashEmpty = false,
    super.key,
  });

  final bool tablet;
  final bool trashEmpty;
  final ValueChanged<PortfolioAppId> onOpenApp;
  final VoidCallback onClose;

  @override
  State<AppleMobileSearch> createState() => _AppleMobileSearchState();
}

class _AppleMobileSearchState extends State<AppleMobileSearch> {
  static final _apps = {
    ...portfolioMobileLauncherAppIds,
    ...portfolioFileAppIds,
  }.toList();
  static const _suggestions = [
    PortfolioAppId.profile,
    PortfolioAppId.projects,
    PortfolioAppId.safari,
    PortfolioAppId.skills,
  ];
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _controller.text.trim().toLowerCase();
    final apps = query.isEmpty
        ? _suggestions
        : _apps
              .where(
                (app) =>
                    '${AppleAppIcon.labelFor(app)} ${app.name} ${app == PortfolioAppId.mail ? 'email' : ''}'
                        .toLowerCase()
                        .contains(query),
              )
              .toList();
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): widget.onClose,
      },
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Material(
            key: const Key('mobile-search-screen'),
            color: AppleTheme.canvas(context).withValues(alpha: 0.76),
            child: SafeArea(
              child: AnimatedPadding(
                duration: const Duration(milliseconds: 180),
                padding: EdgeInsets.only(
                  bottom: MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 700),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        widget.tablet ? 32 : 12,
                        16,
                        12,
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  key: const Key('mobile-search-input'),
                                  controller: _controller,
                                  autofocus: true,
                                  textInputAction: TextInputAction.search,
                                  onChanged: (_) => setState(() {}),
                                  onSubmitted: (_) {
                                    if (query.isNotEmpty && apps.length == 1) {
                                      widget.onOpenApp(apps.single);
                                    }
                                  },
                                  decoration: InputDecoration(
                                    hintText: '앱 검색',
                                    prefixIcon: const Icon(
                                      CupertinoIcons.search,
                                    ),
                                    fillColor: AppleTheme.surface(
                                      context,
                                    ).withValues(alpha: 0.8),
                                    suffixIcon: query.isEmpty
                                        ? null
                                        : IconButton(
                                            key: const Key(
                                              'mobile-search-clear',
                                            ),
                                            tooltip: '검색어 지우기',
                                            onPressed: () =>
                                                setState(_controller.clear),
                                            icon: const Icon(
                                              CupertinoIcons
                                                  .clear_circled_solid,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              TextButton(
                                key: const Key('mobile-search-cancel'),
                                onPressed: widget.onClose,
                                child: const Text('취소'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Expanded(
                            child: ListView(
                              keyboardDismissBehavior:
                                  ScrollViewKeyboardDismissBehavior.onDrag,
                              children: [
                                Semantics(
                                  header: true,
                                  child: Text(
                                    query.isEmpty ? 'Siri 제안' : '검색 결과',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleLarge,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                if (apps.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 32,
                                    ),
                                    child: Text(
                                      '검색 결과가 없습니다.',
                                      style: AppleTheme.caption(context),
                                    ),
                                  )
                                else
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppleTheme.surface(
                                        context,
                                      ).withValues(alpha: 0.62),
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color: AppleTheme.separator(
                                          context,
                                        ).withValues(alpha: 0.5),
                                      ),
                                    ),
                                    child: LayoutBuilder(
                                      builder: (context, constraints) => Wrap(
                                        spacing: 4,
                                        runSpacing: 12,
                                        children: [
                                          for (final app in apps)
                                            SizedBox(
                                              width:
                                                  (constraints.maxWidth - 12) /
                                                  4,
                                              child: AppleAppIcon(
                                                key: Key(
                                                  'mobile-search-app-${app.name}',
                                                ),
                                                appId: app,
                                                size: widget.tablet ? 62 : 48,
                                                compact: !widget.tablet,
                                                artworkSurface:
                                                    AppleAppArtworkSurface
                                                        .mobile,
                                                trashEmpty: widget.trashEmpty,
                                                onTap: () =>
                                                    widget.onOpenApp(app),
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
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
