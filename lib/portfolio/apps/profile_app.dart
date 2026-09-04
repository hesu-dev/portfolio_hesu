import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/portfolio_data.dart';
import '../mobile/mobile_back_close_button.dart';
import '../models/portfolio_app_id.dart';
import '../services/external_launcher.dart';
import '../theme/apple_theme.dart';
import '../widgets/apple_app_icon.dart';
import '../widgets/apple_mobile_navigation_header.dart';

/// Mobile-only social profile built independently from the reusable About app.
class ProfileApp extends StatefulWidget {
  const ProfileApp({
    required this.data,
    required this.launcher,
    this.compact = false,
    this.tablet = false,
    this.onClose,
    super.key,
  });

  final PortfolioData data;
  final ExternalLauncher launcher;
  final bool compact;
  final bool tablet;
  final VoidCallback? onClose;

  @override
  State<ProfileApp> createState() => _ProfileAppState();
}

class _ProfileAppState extends State<ProfileApp> {
  final ScrollController _rootScrollController = ScrollController();
  bool _historyLiked = false;
  bool _historyOpen = false;
  double _rootScrollOffset = 0;

  @override
  void didUpdateWidget(covariant ProfileApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_hasSameHistory(oldWidget.data, widget.data)) {
      _historyOpen = false;
      _historyLiked = false;
      _rootScrollOffset = 0;
      _scheduleRootScrollRestore();
    }
  }

  @override
  void dispose() {
    _rootScrollController.dispose();
    super.dispose();
  }

  bool _hasSameHistory(PortfolioData previous, PortfolioData current) {
    if (previous.experiences.length != current.experiences.length ||
        previous.education.length != current.education.length) {
      return false;
    }

    for (var index = 0; index < previous.experiences.length; index++) {
      final previousItem = previous.experiences[index];
      final currentItem = current.experiences[index];
      if (previousItem.role != currentItem.role ||
          previousItem.organization != currentItem.organization ||
          previousItem.period != currentItem.period ||
          previousItem.description != currentItem.description) {
        return false;
      }
    }

    for (var index = 0; index < previous.education.length; index++) {
      final previousItem = previous.education[index];
      final currentItem = current.education[index];
      if (previousItem.program != currentItem.program ||
          previousItem.institution != currentItem.institution ||
          previousItem.period != currentItem.period ||
          !_hasSameLink(previousItem.link, currentItem.link)) {
        return false;
      }
    }

    return true;
  }

  bool _hasSameLink(
    PortfolioProjectLink? previous,
    PortfolioProjectLink? current,
  ) {
    return identical(previous, current) ||
        (previous != null &&
            current != null &&
            previous.label == current.label &&
            previous.url == current.url);
  }

  void _scheduleRootScrollRestore() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_rootScrollController.hasClients) {
        return;
      }
      final position = _rootScrollController.position;
      _rootScrollController.jumpTo(
        _rootScrollOffset.clamp(
          position.minScrollExtent,
          position.maxScrollExtent,
        ),
      );
    });
  }

  void _openHistory() {
    if (_rootScrollController.hasClients) {
      _rootScrollOffset = _rootScrollController.offset;
    }
    setState(() => _historyOpen = true);
  }

  void _toggleHistoryLike() {
    setState(() => _historyLiked = !_historyLiked);
  }

  void _handleLeadingAction() {
    if (_historyOpen) {
      setState(() => _historyOpen = false);
      _scheduleRootScrollRestore();
      return;
    }
    widget.onClose?.call();
  }

  @override
  Widget build(BuildContext context) {
    final label = AppleAppIcon.labelFor(PortfolioAppId.profile);

    return SizedBox.expand(
      key: const Key('profile-app'),
      child: ColoredBox(
        key: const Key('profile-background'),
        color: AppleTheme.canvas(context),
        child: Column(
          children: <Widget>[
            AppleMobileNavigationHeader(
              key: const Key('mobile-app-navigation-bar'),
              keyPrefix: 'mobile-app-profile',
              title: AppleAppIcon.windowTitleFor(PortfolioAppId.profile),
              titleKey: const Key('mobile-app-title'),
              moreKey: const Key('mobile-app-more-profile'),
              leading: MobileBackCloseButton(
                appId: PortfolioAppId.profile,
                windowLabel: label,
                action: _historyOpen
                    ? MobileBackCloseAction.back
                    : MobileBackCloseAction.close,
                onPressed: _handleLeadingAction,
              ),
            ),
            Expanded(
              child: !_historyOpen
                  ? _ProfileFeed(
                      data: widget.data,
                      launcher: widget.launcher,
                      compact: widget.compact,
                      tablet: widget.tablet,
                      scrollController: _rootScrollController,
                      onOpenHistory: _openHistory,
                    )
                  : _ProfileHistoryDetail(
                      data: widget.data,
                      launcher: widget.launcher,
                      liked: _historyLiked,
                      onToggleLike: _toggleHistoryLike,
                      compact: widget.compact,
                      tablet: widget.tablet,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileFeed extends StatelessWidget {
  const _ProfileFeed({
    required this.data,
    required this.launcher,
    required this.compact,
    required this.tablet,
    required this.scrollController,
    required this.onOpenHistory,
  });

  final PortfolioData data;
  final ExternalLauncher launcher;
  final bool compact;
  final bool tablet;
  final ScrollController scrollController;
  final VoidCallback onOpenHistory;

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = compact ? 16.0 : (tablet ? 28.0 : 24.0);

    return CustomScrollView(
      key: const Key('profile-scroll'),
      controller: scrollController,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: <Widget>[
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            compact ? 18 : 24,
            horizontalPadding,
            compact ? 36 : 44,
          ),
          sliver: SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _ProfileSummary(data: data, compact: compact),
                    SizedBox(height: compact ? 24 : 30),
                    _ProfileActions(data: data, launcher: launcher),
                    SizedBox(height: compact ? 28 : 34),
                    Divider(height: 1, color: AppleTheme.separator(context)),
                    SizedBox(height: compact ? 3 : 4),
                    _ProfileHistoryGrid(
                      data: data,
                      onOpenHistory: onOpenHistory,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileSummary extends StatelessWidget {
  const _ProfileSummary({required this.data, required this.compact});

  final PortfolioData data;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final postCount = data.experiences.isEmpty && data.education.isEmpty
        ? 0
        : 1;

    return Column(
      key: const Key('profile-summary'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            _ProfileAvatar(monogram: data.monogram, compact: compact),
            SizedBox(width: compact ? 18 : 28),
            Expanded(
              child: Row(
                key: const Key('profile-stats'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: _ProfileStat(
                      count: postCount,
                      label: '게시물',
                      semanticsLabel: '게시물 $postCount개',
                    ),
                  ),
                  Expanded(
                    child: _ProfileStat(
                      count: data.experiences.length,
                      label: '경력',
                      semanticsLabel: '경력 ${data.experiences.length}개',
                    ),
                  ),
                  Expanded(
                    child: _ProfileStat(
                      count: data.education.length,
                      label: '교육',
                      semanticsLabel: '교육 ${data.education.length}개',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: compact ? 18 : 24),
        Text(
          data.identity.name,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppleTheme.primaryLabel(context),
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          data.identity.englishName,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppleTheme.secondaryLabel(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          data.identity.headline,
          style: AppleTheme.body(context).copyWith(
            color: AppleTheme.primaryLabel(context),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          data.identity.biography,
          style: AppleTheme.body(
            context,
          ).copyWith(color: AppleTheme.primaryLabel(context), height: 1.55),
        ),
      ],
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.monogram, required this.compact});

  final String monogram;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 82.0 : 106.0;
    return Semantics(
      label: '프로필 사진',
      image: true,
      child: Container(
        key: const Key('profile-avatar'),
        width: size,
        height: size,
        padding: EdgeInsets.all(compact ? 3 : 4),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: SweepGradient(
            colors: <Color>[
              Color(0xFFFCAF45),
              Color(0xFFE1306C),
              Color(0xFF833AB4),
              Color(0xFFE1306C),
              Color(0xFFFCAF45),
            ],
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppleTheme.canvas(context),
          ),
          child: Padding(
            padding: EdgeInsets.all(compact ? 3 : 4),
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: AppleTheme.isDark(context)
                      ? const <Color>[Color(0xFF424650), Color(0xFF22242A)]
                      : const <Color>[Color(0xFFF0F2F6), Color(0xFFD8DDE6)],
                ),
              ),
              child: Center(
                child: Text(
                  monogram,
                  maxLines: 1,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppleTheme.primaryLabel(context),
                    fontSize: compact ? 24 : 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
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

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({
    required this.count,
    required this.label,
    required this.semanticsLabel,
  });

  final int count;
  final String label;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel,
      container: true,
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              '$count',
              maxLines: 1,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppleTheme.primaryLabel(context),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppleTheme.caption(
                context,
              ).copyWith(color: AppleTheme.secondaryLabel(context)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileActions extends StatelessWidget {
  const _ProfileActions({required this.data, required this.launcher});

  final PortfolioData data;
  final ExternalLauncher launcher;

  Future<void> _launch(Uri uri) async {
    try {
      await launcher.launch(uri);
    } catch (_) {
      // External navigation should never interrupt the portfolio surface.
    }
  }

  @override
  Widget build(BuildContext context) {
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.4;
    return LayoutBuilder(
      builder: (context, constraints) {
        final stackActions = largeText || constraints.maxWidth < 340;
        final actions = <Widget>[
          _ProfileActionButton(
            key: const Key('profile-github-action'),
            icon: Icons.code_rounded,
            label: 'GitHub',
            onPressed: () => _launch(Uri.parse(data.identity.githubUrl)),
          ),
          _ProfileActionButton(
            key: const Key('profile-mail-action'),
            icon: Icons.mail_outline_rounded,
            label: '이메일',
            onPressed: () => _launch(Uri.parse(data.mailUrl)),
          ),
        ];

        if (stackActions) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              actions.first,
              const SizedBox(height: 10),
              actions.last,
            ],
          );
        }

        return Row(
          children: <Widget>[
            Expanded(child: actions.first),
            const SizedBox(width: 10),
            Expanded(child: actions.last),
          ],
        );
      },
    );
  }
}

class _ProfileActionButton extends StatelessWidget {
  const _ProfileActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppleTheme.primaryLabel(context),
        backgroundColor: AppleTheme.surface(context),
        side: BorderSide(color: AppleTheme.separator(context)),
        minimumSize: const Size(44, 44),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      icon: Icon(icon, size: 19),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}

class _ProfileHistoryGrid extends StatelessWidget {
  const _ProfileHistoryGrid({required this.data, required this.onOpenHistory});

  final PortfolioData data;
  final VoidCallback onOpenHistory;

  @override
  Widget build(BuildContext context) {
    if (data.experiences.isEmpty && data.education.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 36),
        child: Text(
          '등록된 경력과 교육이 없습니다.',
          textAlign: TextAlign.center,
          style: AppleTheme.body(
            context,
          ).copyWith(color: AppleTheme.secondaryLabel(context)),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 3.0;
        final tileWidth = ((constraints.maxWidth - (spacing * 2)) / 3) - 0.01;

        return Wrap(
          key: const Key('profile-history-grid'),
          spacing: spacing,
          runSpacing: spacing,
          children: <Widget>[
            SizedBox(
              width: tileWidth,
              child: _ProfileHistoryCard(
                key: const Key('profile-history-post'),
                label: '경력과 교육 게시물 열기',
                title: '경력 · 교육',
                summary:
                    '경력 ${data.experiences.length}개 · 교육 ${data.education.length}개',
                onTap: onOpenHistory,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ProfileHistoryCard extends StatelessWidget {
  const _ProfileHistoryCard({
    required this.label,
    required this.title,
    required this.summary,
    required this.onTap,
    super.key,
  });

  final String label;
  final String title;
  final String summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = _profileAccents.first;
    final companion = AppleTheme.indigo;
    final dark = AppleTheme.isDark(context);

    return Semantics(
      label: label,
      button: true,
      onTap: onTap,
      excludeSemantics: true,
      child: AspectRatio(
        aspectRatio: 1,
        child: ExcludeSemantics(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Ink(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      Color.alphaBlend(
                        accent.withValues(alpha: dark ? 0.72 : 0.58),
                        AppleTheme.panel(context),
                      ),
                      Color.alphaBlend(
                        companion.withValues(alpha: dark ? 0.58 : 0.44),
                        AppleTheme.surface(context),
                      ),
                    ],
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    CustomPaint(
                      painter: _ProfileArtworkPainter(
                        accent: accent,
                        companion: companion,
                        seed: 0,
                      ),
                    ),
                    Positioned(
                      top: 6,
                      left: 7,
                      right: 7,
                      height: 40,
                      child: Column(
                        key: const Key('profile-history-post-meta'),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.34),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '프로필',
                              maxLines: 1,
                              textScaler: MediaQuery.textScalerOf(
                                context,
                              ).clamp(maxScaleFactor: 1),
                              style: AppleTheme.caption(context).copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            summary,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textScaler: MediaQuery.textScalerOf(
                              context,
                            ).clamp(maxScaleFactor: 1),
                            style: AppleTheme.caption(context).copyWith(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                              shadows: const <Shadow>[
                                Shadow(color: Color(0x99000000), blurRadius: 4),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: 46,
                      child: Container(
                        key: const Key('profile-history-post-title'),
                        width: double.infinity,
                        alignment: Alignment.bottomLeft,
                        padding: const EdgeInsets.fromLTRB(8, 8, 8, 5),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: <Color>[
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.74),
                            ],
                          ),
                        ),
                        child: Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textScaler: MediaQuery.textScalerOf(
                            context,
                          ).clamp(maxScaleFactor: 1.25),
                          style: AppleTheme.caption(context).copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            height: 1.12,
                          ),
                        ),
                      ),
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
}

class _ProfileHistoryDetail extends StatefulWidget {
  const _ProfileHistoryDetail({
    required this.data,
    required this.launcher,
    required this.liked,
    required this.onToggleLike,
    required this.compact,
    required this.tablet,
  });

  final PortfolioData data;
  final ExternalLauncher launcher;
  final bool liked;
  final VoidCallback onToggleLike;
  final bool compact;
  final bool tablet;

  @override
  State<_ProfileHistoryDetail> createState() => _ProfileHistoryDetailState();
}

class _ProfileHistoryDetailState extends State<_ProfileHistoryDetail> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _replyThreadKey = GlobalKey();

  Future<void> _launch(Uri uri) async {
    try {
      await widget.launcher.launch(uri);
    } catch (_) {
      // Keep the in-app profile usable if the host rejects a URL.
    }
  }

  void _scrollToReplyThread() {
    final threadContext = _replyThreadKey.currentContext;
    if (threadContext == null) {
      return;
    }
    Feedback.forTap(context);
    Scrollable.ensureVisible(
      threadContext,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      alignment: 0,
    );
  }

  void _acknowledgeAction() {
    Feedback.forTap(context);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kindLabel = '경력 ${widget.data.experiences.length}개';
    final period = '교육 ${widget.data.education.length}개';

    return SizedBox.expand(
      key: const Key('profile-history-detail'),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return CustomScrollView(
            key: const Key('profile-history-detail-scroll'),
            controller: _scrollController,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: <Widget>[
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    SizedBox(
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                      child: _ProfileReelOverlay(
                        compact: widget.compact,
                        liked: widget.liked,
                        kindLabel: kindLabel,
                        title: '경력과 교육',
                        organization: widget.data.identity.headline,
                        period: period,
                        name: widget.data.identity.name,
                        monogram: widget.data.monogram,
                        onCamera: _acknowledgeAction,
                        onToggleLike: widget.onToggleLike,
                        onComment: _scrollToReplyThread,
                        onShare: _acknowledgeAction,
                      ),
                    ),
                    _ProfileReplyThread(
                      key: _replyThreadKey,
                      data: widget.data,
                      compact: widget.compact,
                      tablet: widget.tablet,
                      onLaunch: _launch,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileReelOverlay extends StatelessWidget {
  const _ProfileReelOverlay({
    required this.compact,
    required this.liked,
    required this.kindLabel,
    required this.title,
    required this.organization,
    required this.period,
    required this.name,
    required this.monogram,
    required this.onCamera,
    required this.onToggleLike,
    required this.onComment,
    required this.onShare,
  });

  final bool compact;
  final bool liked;
  final String kindLabel;
  final String title;
  final String organization;
  final String period;
  final String name;
  final String monogram;
  final VoidCallback onCamera;
  final VoidCallback onToggleLike;
  final VoidCallback onComment;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final dark = AppleTheme.isDark(context);
    final foreground = dark ? Colors.white : AppleTheme.primaryLabel(context);
    final mediaColor = dark ? const Color(0xFF151619) : const Color(0xFFF0F1F3);

    return Stack(
      key: const Key('profile-reel-overlay'),
      fit: StackFit.expand,
      children: <Widget>[
        Positioned.fill(
          child: ColoredBox(
            key: const Key('profile-reel-media-slot'),
            color: mediaColor,
          ),
        ),
        Positioned(
          top: compact ? 8 : 12,
          left: compact ? 14 : 18,
          right: compact ? 4 : 8,
          child: Row(
            key: const Key('profile-reel-top-bar'),
            children: <Widget>[
              Expanded(
                child: Text(
                  'Reels',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _ProfileReelIconAction(
                actionKey: const Key('profile-reel-camera-action'),
                semanticsLabel: '카메라',
                icon: Icons.camera_alt_outlined,
                color: foreground,
                onPressed: onCamera,
              ),
            ],
          ),
        ),
        Positioned(
          top: compact ? 90 : 116,
          right: compact ? 4 : 8,
          child: Column(
            key: const Key('profile-reel-action-rail'),
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _ProfileReelIconAction(
                actionKey: const Key('profile-reel-like-action'),
                semanticsLabel: liked ? '좋아요 취소' : '좋아요',
                icon: liked
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: liked ? AppleTheme.red : foreground,
                onPressed: onToggleLike,
              ),
              const SizedBox(height: 4),
              _ProfileReelIconAction(
                actionKey: const Key('profile-reel-comment-action'),
                semanticsLabel: '댓글 보기',
                icon: Icons.mode_comment_outlined,
                color: foreground,
                onPressed: onComment,
              ),
              const SizedBox(height: 4),
              _ProfileReelIconAction(
                actionKey: const Key('profile-reel-share-action'),
                semanticsLabel: '공유',
                icon: Icons.send_rounded,
                color: foreground,
                onPressed: onShare,
              ),
            ],
          ),
        ),
        Positioned(
          left: compact ? 14 : 18,
          right: compact ? 64 : 72,
          bottom: compact ? 16 : 20,
          child: Column(
            key: const Key('profile-reel-info'),
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _ProfileReelAccountRow(
                name: name,
                monogram: monogram,
                foreground: foreground,
              ),
              SizedBox(height: compact ? 12 : 16),
              Text(
                title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                organization,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppleTheme.body(context).copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$kindLabel · $period',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppleTheme.caption(context).copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileReelIconAction extends StatefulWidget {
  const _ProfileReelIconAction({
    required this.actionKey,
    required this.semanticsLabel,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final Key actionKey;
  final String semanticsLabel;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  State<_ProfileReelIconAction> createState() => _ProfileReelIconActionState();
}

class _ProfileReelIconActionState extends State<_ProfileReelIconAction> {
  bool _pressed = false;
  bool _hovered = false;

  void _setPressed(bool pressed) {
    if (_pressed == pressed) {
      return;
    }
    setState(() => _pressed = pressed);
  }

  void _setHovered(bool hovered) {
    if (_hovered == hovered) {
      return;
    }
    setState(() => _hovered = hovered);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: widget.actionKey,
      label: widget.semanticsLabel,
      button: true,
      onTap: widget.onPressed,
      excludeSemantics: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => _setHovered(true),
        onExit: (_) => _setHovered(false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onPressed,
          onTapDown: (_) => _setPressed(true),
          onTapUp: (_) => _setPressed(false),
          onTapCancel: () => _setPressed(false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 90),
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _pressed
                  ? widget.color.withValues(alpha: 0.20)
                  : _hovered
                  ? widget.color.withValues(alpha: 0.10)
                  : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(widget.icon, color: widget.color, size: 28),
          ),
        ),
      ),
    );
  }
}

class _ProfileReelAccountRow extends StatelessWidget {
  const _ProfileReelAccountRow({
    required this.name,
    required this.monogram,
    required this.foreground,
  });

  final String name;
  final String monogram;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const Key('profile-reel-account-row'),
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Container(
          key: const Key('profile-reel-avatar'),
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: foreground.withValues(alpha: 0.12),
            border: Border.all(color: foreground, width: 1.5),
          ),
          child: Text(
            monogram,
            maxLines: 1,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            name,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileReplyThread extends StatelessWidget {
  const _ProfileReplyThread({
    required this.data,
    required this.compact,
    required this.tablet,
    required this.onLaunch,
    super.key,
  });

  final PortfolioData data;
  final bool compact;
  final bool tablet;
  final Future<void> Function(Uri uri) onLaunch;

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[
      for (final entry in data.experiences.indexed)
        _ProfileReplyItem.experience(
          key: Key('profile-reel-reply-item-experience-${entry.$1}'),
          identityName: data.identity.name,
          monogram: data.monogram,
          index: entry.$1,
          experience: entry.$2,
          compact: compact,
        ),
      for (final entry in data.education.indexed)
        _ProfileReplyItem.education(
          key: Key('profile-reel-reply-item-education-${entry.$1}'),
          identityName: data.identity.name,
          monogram: data.monogram,
          index: entry.$1,
          education: entry.$2,
          compact: compact,
          onLaunch: onLaunch,
        ),
    ];

    final horizontalPadding = compact ? 14.0 : (tablet ? 30.0 : 24.0);

    return Padding(
      key: const Key('profile-reel-reply-thread'),
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        compact ? 22 : 28,
        horizontalPadding,
        compact ? 38 : 48,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (final item in items.indexed) ...<Widget>[
                if (item.$1 > 0)
                  Padding(
                    padding: EdgeInsets.only(
                      left: compact ? 50 : 58,
                      top: compact ? 18 : 22,
                      bottom: compact ? 18 : 22,
                    ),
                    child: Divider(
                      height: 1,
                      color: AppleTheme.separator(context),
                    ),
                  ),
                item.$2,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileReplyItem extends StatelessWidget {
  const _ProfileReplyItem.experience({
    required this.identityName,
    required this.monogram,
    required this.index,
    required this.experience,
    required this.compact,
    super.key,
  }) : kind = _ProfileHistoryKind.experience,
       education = null,
       onLaunch = null;

  const _ProfileReplyItem.education({
    required this.identityName,
    required this.monogram,
    required this.index,
    required this.education,
    required this.compact,
    required this.onLaunch,
    super.key,
  }) : kind = _ProfileHistoryKind.education,
       experience = null;

  final String identityName;
  final String monogram;
  final int index;
  final _ProfileHistoryKind kind;
  final PortfolioExperience? experience;
  final PortfolioEducation? education;
  final bool compact;
  final Future<void> Function(Uri uri)? onLaunch;

  @override
  Widget build(BuildContext context) {
    final kindName = kind.name;
    final bodyStyle = AppleTheme.body(
      context,
    ).copyWith(color: AppleTheme.primaryLabel(context), height: 1.5);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: compact ? 38 : 42,
          height: compact ? 38 : 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppleTheme.selectionBackground(context, AppleTheme.red),
            shape: BoxShape.circle,
            border: Border.all(color: AppleTheme.separator(context)),
          ),
          child: Text(
            monogram,
            style: AppleTheme.caption(context).copyWith(
              color: AppleTheme.primaryLabel(context),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        SizedBox(width: compact ? 10 : 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                key: Key('profile-reel-reply-author-$kindName-$index'),
                constraints: const BoxConstraints(minHeight: 24),
                alignment: Alignment.centerLeft,
                child: Text(
                  identityName,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppleTheme.primaryLabel(context),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SizedBox(height: compact ? 8 : 10),
              Container(
                padding: EdgeInsets.only(left: compact ? 12 : 16),
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: AppleTheme.separator(context),
                      width: 2,
                    ),
                  ),
                ),
                child: Column(
                  key: Key('profile-reel-reply-content-$kindName-$index'),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: kind == _ProfileHistoryKind.experience
                      ? _experienceContent(context, bodyStyle)
                      : _educationContent(context, bodyStyle),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _experienceContent(BuildContext context, TextStyle bodyStyle) {
    final item = experience!;
    return <Widget>[
      Text(item.role, style: bodyStyle.copyWith(fontWeight: FontWeight.w800)),
      const SizedBox(height: 5),
      Text(
        item.organization,
        style: bodyStyle.copyWith(fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 4),
      Text(
        item.period,
        style: AppleTheme.caption(
          context,
        ).copyWith(color: AppleTheme.secondaryLabel(context), height: 1.4),
      ),
      const SizedBox(height: 10),
      Text(item.description, style: bodyStyle),
    ];
  }

  List<Widget> _educationContent(BuildContext context, TextStyle bodyStyle) {
    final item = education!;
    return <Widget>[
      Text(
        item.program,
        style: bodyStyle.copyWith(fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 5),
      Text(
        item.institution,
        style: bodyStyle.copyWith(fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 4),
      Text(
        item.period,
        style: AppleTheme.caption(
          context,
        ).copyWith(color: AppleTheme.secondaryLabel(context), height: 1.4),
      ),
      if (item.link case final link?) ...<Widget>[
        const SizedBox(height: 8),
        _ProfileReplyLinkAction(
          actionKey: Key('profile-reel-reply-link-education-$index'),
          link: link,
          onLaunch: onLaunch!,
        ),
      ],
    ];
  }
}

class _ProfileReplyLinkAction extends StatefulWidget {
  const _ProfileReplyLinkAction({
    required this.actionKey,
    required this.link,
    required this.onLaunch,
  });

  final Key actionKey;
  final PortfolioProjectLink link;
  final Future<void> Function(Uri uri) onLaunch;

  @override
  State<_ProfileReplyLinkAction> createState() =>
      _ProfileReplyLinkActionState();
}

class _ProfileReplyLinkActionState extends State<_ProfileReplyLinkAction> {
  bool _pressed = false;
  bool _hovered = false;

  void _setPressed(bool pressed) {
    if (_pressed == pressed) {
      return;
    }
    setState(() => _pressed = pressed);
  }

  void _setHovered(bool hovered) {
    if (_hovered == hovered) {
      return;
    }
    setState(() => _hovered = hovered);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: widget.actionKey,
      label: 'Open ${widget.link.label}',
      button: true,
      onTap: () => widget.onLaunch(widget.link.uri),
      excludeSemantics: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => _setHovered(true),
        onExit: (_) => _setHovered(false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => widget.onLaunch(widget.link.uri),
          onTapDown: (_) => _setPressed(true),
          onTapUp: (_) => _setPressed(false),
          onTapCancel: () => _setPressed(false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 90),
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: _pressed
                  ? AppleTheme.blue.withValues(alpha: 0.14)
                  : _hovered
                  ? AppleTheme.blue.withValues(alpha: 0.08)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(
                  Icons.open_in_new_rounded,
                  size: 17,
                  color: AppleTheme.blue,
                ),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    widget.link.label,
                    style: AppleTheme.body(context).copyWith(
                      color: AppleTheme.blue,
                      fontWeight: FontWeight.w700,
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

class _ProfileArtworkPainter extends CustomPainter {
  const _ProfileArtworkPainter({
    required this.accent,
    required this.companion,
    required this.seed,
  });

  final Color accent;
  final Color companion;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final shortSide = math.min(size.width, size.height);
    final translucent = Paint()
      ..color = Colors.white.withValues(alpha: 0.14)
      ..style = PaintingStyle.fill;
    final outline = Paint()
      ..color = Colors.white.withValues(alpha: 0.34)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.5, shortSide * 0.012);
    final accentPaint = Paint()
      ..color = Color.alphaBlend(
        companion.withValues(alpha: 0.46),
        accent.withValues(alpha: 0.42),
      )
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width * (0.26 + ((seed % 3) * 0.08)), size.height * 0.27),
      shortSide * 0.27,
      translucent,
    );
    canvas.drawCircle(
      Offset(size.width * 0.74, size.height * 0.67),
      shortSide * 0.34,
      accentPaint,
    );

    final frame = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.51),
        width: size.width * 0.58,
        height: size.width * 0.58,
      ),
      Radius.circular(shortSide * 0.12),
    );
    canvas.drawRRect(frame, outline);

    final path = Path()
      ..moveTo(size.width * 0.18, size.height * 0.78)
      ..quadraticBezierTo(
        size.width * 0.48,
        size.height * (0.62 + ((seed % 2) * 0.05)),
        size.width * 0.86,
        size.height * 0.84,
      );
    canvas.drawPath(path, outline);
  }

  @override
  bool shouldRepaint(covariant _ProfileArtworkPainter oldDelegate) {
    return oldDelegate.accent != accent ||
        oldDelegate.companion != companion ||
        oldDelegate.seed != seed;
  }
}

enum _ProfileHistoryKind { experience, education }

const List<Color> _profileAccents = <Color>[
  Color(0xFFE1306C),
  Color(0xFF833AB4),
  Color(0xFFFCAF45),
  Color(0xFF0A84FF),
  Color(0xFF30D158),
  Color(0xFF5E5CE6),
];
