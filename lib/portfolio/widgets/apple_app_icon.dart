import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/portfolio_app_id.dart';
import '../theme/apple_theme.dart';
import 'apple_app_artwork.dart';

class AppleAppIcon extends StatefulWidget {
  static const String terminalWindowTitle = 'Terminal - Portfolio zsh';

  const AppleAppIcon({
    required this.appId,
    this.onTap,
    this.compact = false,
    this.selected = false,
    this.running = false,
    this.showLabel = true,
    this.size,
    this.focusNode,
    this.autofocus = false,
    this.artworkSurface = AppleAppArtworkSurface.desktop,
    this.artworkForegroundColor,
    this.trashEmpty = false,
    super.key,
  });

  final PortfolioAppId appId;
  final VoidCallback? onTap;
  final bool compact;
  final bool selected;
  final bool running;
  final bool showLabel;
  final double? size;
  final FocusNode? focusNode;
  final bool autofocus;
  final AppleAppArtworkSurface artworkSurface;
  final Color? artworkForegroundColor;
  final bool trashEmpty;

  @override
  State<AppleAppIcon> createState() => _AppleAppIconState();

  static String labelFor(PortfolioAppId appId) => switch (appId) {
    PortfolioAppId.profile => '프로필',
    PortfolioAppId.about => 'About',
    PortfolioAppId.introduction => '자기소개',
    PortfolioAppId.skills => 'Skills',
    PortfolioAppId.projects => '포트폴리오',
    PortfolioAppId.terminal => 'Terminal',
    PortfolioAppId.photos => '사진',
    PortfolioAppId.settings => '설정',
    PortfolioAppId.thisMac => '프로젝트',
    PortfolioAppId.trash => 'Trash',
    PortfolioAppId.github => 'GitHub',
    PortfolioAppId.mail => 'Mail',
  };

  static String windowTitleFor(PortfolioAppId appId) => switch (appId) {
    PortfolioAppId.terminal => terminalWindowTitle,
    _ => labelFor(appId),
  };

  /// Legacy glyph access retained for utility apps that do not have bespoke
  /// artwork. Primary apps intentionally reject generic Material glyphs.
  static IconData iconFor(PortfolioAppId appId) =>
      AppleAppArtwork.utilityIconFor(appId);

  static List<Color> colorsFor(PortfolioAppId appId) =>
      AppleAppArtwork.colorsFor(appId);
}

class _AppleAppIconState extends State<AppleAppIcon> {
  bool _showFocusHighlight = false;

  @override
  Widget build(BuildContext context) {
    final appId = widget.appId;
    final compact = widget.compact;
    final selected = widget.selected;
    final running = widget.running;
    final showLabel = widget.showLabel;
    final onTap = widget.onTap;
    final label = labelFor(appId);
    final tileSize = widget.size ?? (compact ? 48.0 : 58.0);
    final cornerRadius = compact ? 13.0 : 16.0;
    return Semantics(
      key: Key('apple-app-icon-${appId.name}'),
      label: 'Open $label',
      button: true,
      enabled: onTap != null,
      selected: selected,
      value: appId == PortfolioAppId.trash
          ? (widget.trashEmpty ? 'Empty' : 'Contains items')
          : null,
      onTap: onTap,
      child: FocusableActionDetector(
        enabled: onTap != null,
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        mouseCursor: onTap == null
            ? SystemMouseCursors.basic
            : SystemMouseCursors.click,
        onShowFocusHighlight: (showHighlight) {
          if (_showFocusHighlight != showHighlight) {
            setState(() => _showFocusHighlight = showHighlight);
          }
        },
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              onTap?.call();
              return null;
            },
          ),
        },
        child: ExcludeSemantics(
          child: Tooltip(
            message: label,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 5 : 7,
                  vertical: compact ? 4 : 6,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    SizedBox(
                      key: Key('apple-app-icon-tile-${appId.name}'),
                      width: tileSize,
                      height: tileSize,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: <Widget>[
                          Positioned.fill(
                            child: AppleAppArtworkFrame(
                              appId: appId,
                              size: tileSize,
                              surface: widget.artworkSurface,
                              foregroundColor: widget.artworkForegroundColor,
                              trashEmpty: widget.trashEmpty,
                            ),
                          ),
                          if (selected)
                            Positioned.fill(
                              key: Key(
                                'apple-app-icon-selection-${appId.name}',
                              ),
                              child: IgnorePointer(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(
                                      cornerRadius + 2,
                                    ),
                                    border: Border.all(
                                      color: AppleTheme.blue.withValues(
                                        alpha: 0.9,
                                      ),
                                      width: 2.4,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          if (_showFocusHighlight)
                            Positioned.fill(
                              key: Key('apple-app-icon-focus-${appId.name}'),
                              child: IgnorePointer(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(
                                      cornerRadius + 3,
                                    ),
                                    border: Border.all(
                                      color: AppleTheme.blue,
                                      width: 3,
                                    ),
                                    boxShadow: <BoxShadow>[
                                      BoxShadow(
                                        color: AppleTheme.blue.withValues(
                                          alpha: 0.28,
                                        ),
                                        blurRadius: 9,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (showLabel) ...<Widget>[
                      const SizedBox(height: 6),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: compact ? 70 : 84,
                        ),
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: AppleTheme.primaryLabel(context),
                                fontSize: compact ? 10.5 : 11.5,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                shadows: <Shadow>[
                                  Shadow(
                                    color: AppleTheme.canvas(
                                      context,
                                    ).withValues(alpha: 0.5),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                        ),
                      ),
                    ],
                    SizedBox(
                      height: 7,
                      child: running
                          ? Container(
                              key: Key('apple-app-icon-running-${appId.name}'),
                              width: 4.5,
                              height: 4.5,
                              decoration: BoxDecoration(
                                color: AppleTheme.primaryLabel(context),
                                shape: BoxShape.circle,
                              ),
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String labelFor(PortfolioAppId appId) => AppleAppIcon.labelFor(appId);
}
