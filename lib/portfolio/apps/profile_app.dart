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
    this.onOpenApp,
    this.onClose,
    super.key,
  });

  final PortfolioData data;
  final ExternalLauncher launcher;
  final bool compact;
  final bool tablet;
  final ValueChanged<PortfolioAppId>? onOpenApp;
  final VoidCallback? onClose;

  @override
  State<ProfileApp> createState() => _ProfileAppState();
}

class _ProfileAppState extends State<ProfileApp> {
  final ScrollController _rootScrollController = ScrollController();
  final Set<_ProfileHistoryKind> _likedHistory = <_ProfileHistoryKind>{};
  _ProfileHistoryKind? _selectedHistoryKind;
  double _rootScrollOffset = 0;
  bool _following = false;

  @override
  void didUpdateWidget(covariant ProfileApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_hasSameHistory(oldWidget.data, widget.data)) {
      _selectedHistoryKind = null;
      _likedHistory.clear();
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

  void _openHistory(_ProfileHistoryKind kind) {
    if (_rootScrollController.hasClients) {
      _rootScrollOffset = _rootScrollController.offset;
    }
    setState(() => _selectedHistoryKind = kind);
  }

  void _showProfileFeed() {
    if (_selectedHistoryKind != null) {
      setState(() => _selectedHistoryKind = null);
      _scheduleRootScrollRestore();
      return;
    }
    if (_rootScrollController.hasClients) {
      _rootScrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _openCareerReel() {
    if (widget.data.experiences.isNotEmpty) {
      _openHistory(_ProfileHistoryKind.experience);
    } else if (widget.data.education.isNotEmpty) {
      _openHistory(_ProfileHistoryKind.education);
    }
  }

  VoidCallback? _openAppAction(PortfolioAppId appId) {
    final onOpenApp = widget.onOpenApp;
    if (onOpenApp == null) {
      return null;
    }
    return () => onOpenApp(appId);
  }

  void _toggleFollowing() {
    setState(() => _following = !_following);
  }

  void _toggleHistoryLike(_ProfileHistoryKind kind) {
    setState(() {
      if (!_likedHistory.remove(kind)) {
        _likedHistory.add(kind);
      }
    });
  }

  void _handleLeadingAction() {
    if (_selectedHistoryKind != null) {
      setState(() => _selectedHistoryKind = null);
      _scheduleRootScrollRestore();
      return;
    }
    widget.onClose?.call();
  }

  @override
  Widget build(BuildContext context) {
    final selectedHistoryKind = _selectedHistoryKind;
    final label = AppleAppIcon.labelFor(PortfolioAppId.profile);
    final onOpenMail = _openAppAction(PortfolioAppId.mail);
    final onOpenProjects = _openAppAction(PortfolioAppId.projects);
    final onOpenSettings = _openAppAction(PortfolioAppId.settings);
    final content = Column(
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
            action: selectedHistoryKind != null
                ? MobileBackCloseAction.back
                : MobileBackCloseAction.close,
            onPressed: _handleLeadingAction,
          ),
        ),
        Expanded(
          child: selectedHistoryKind == null
              ? _ProfileFeed(
                  data: widget.data,
                  compact: widget.compact,
                  tablet: widget.tablet,
                  following: _following,
                  scrollController: _rootScrollController,
                  onToggleFollowing: _toggleFollowing,
                  onMessage: onOpenMail,
                  onOpenCareerProjects: onOpenProjects,
                  onOpenHistory: _openHistory,
                )
              : _ProfileHistoryDetail(
                  data: widget.data,
                  launcher: widget.launcher,
                  kind: selectedHistoryKind,
                  liked: _likedHistory.contains(selectedHistoryKind),
                  onToggleLike: () => _toggleHistoryLike(selectedHistoryKind),
                  compact: widget.compact,
                  tablet: widget.tablet,
                ),
        ),
      ],
    );

    return SizedBox.expand(
      key: const Key('profile-app'),
      child: ColoredBox(
        key: const Key('profile-background'),
        color: AppleTheme.canvas(context),
        child: widget.tablet
            ? Row(
                children: <Widget>[
                  _ProfileSidebar(
                    showingReel: selectedHistoryKind != null,
                    onShowProfile: _showProfileFeed,
                    onShowReels: _openCareerReel,
                    onOpenProjects: onOpenProjects,
                    onOpenMail: onOpenMail,
                    onOpenSettings: onOpenSettings,
                  ),
                  Expanded(child: content),
                ],
              )
            : content,
      ),
    );
  }
}

class _ProfileSidebar extends StatelessWidget {
  const _ProfileSidebar({
    required this.showingReel,
    required this.onShowProfile,
    required this.onShowReels,
    required this.onOpenProjects,
    required this.onOpenMail,
    required this.onOpenSettings,
  });

  final bool showingReel;
  final VoidCallback onShowProfile;
  final VoidCallback onShowReels;
  final VoidCallback? onOpenProjects;
  final VoidCallback? onOpenMail;
  final VoidCallback? onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const Key('profile-sidebar'),
      decoration: BoxDecoration(
        color: AppleTheme.surface(context).withValues(alpha: 0.96),
        border: Border(
          right: BorderSide(color: AppleTheme.separator(context), width: 0.8),
        ),
      ),
      child: SizedBox(
        width: 72,
        child: CustomScrollView(
          key: const Key('profile-sidebar-scroll'),
          primary: false,
          slivers: <Widget>[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
              sliver: SliverList.list(
                children: <Widget>[
                  const ExcludeSemantics(
                    child: SizedBox(
                      height: 52,
                      child: Icon(Icons.camera_alt_outlined, size: 27),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _ProfileSidebarAction(
                    actionKey: const Key('profile-sidebar-home-action'),
                    label: '프로필 홈',
                    icon: Icons.home_outlined,
                    selectedIcon: Icons.home_rounded,
                    selected: !showingReel,
                    onTap: onShowProfile,
                  ),
                  const SizedBox(height: 6),
                  _ProfileSidebarAction(
                    actionKey: const Key('profile-sidebar-reels-action'),
                    label: '릴스 보기',
                    icon: Icons.smart_display_outlined,
                    selectedIcon: Icons.smart_display_rounded,
                    selected: showingReel,
                    onTap: onShowReels,
                  ),
                  const SizedBox(height: 6),
                  _ProfileSidebarAction(
                    actionKey: const Key('profile-sidebar-projects-action'),
                    label: '회사 포트폴리오 열기',
                    icon: Icons.work_outline_rounded,
                    selectedIcon: Icons.work_rounded,
                    onTap: onOpenProjects,
                  ),
                  const SizedBox(height: 6),
                  _ProfileSidebarAction(
                    actionKey: const Key('profile-sidebar-message-action'),
                    label: '이메일 열기',
                    icon: Icons.send_outlined,
                    selectedIcon: Icons.send_rounded,
                    onTap: onOpenMail,
                  ),
                ],
              ),
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 18, 10, 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    Divider(height: 1, color: AppleTheme.separator(context)),
                    const SizedBox(height: 14),
                    _ProfileSidebarAction(
                      actionKey: const Key('profile-sidebar-settings-action'),
                      label: '설정 열기',
                      icon: Icons.menu_rounded,
                      selectedIcon: Icons.menu_rounded,
                      onTap: onOpenSettings,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileSidebarAction extends StatelessWidget {
  const _ProfileSidebarAction({
    required this.actionKey,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.onTap,
    this.selected = false,
  });

  final Key actionKey;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: actionKey,
      label: label,
      button: true,
      selected: selected,
      enabled: onTap != null,
      onTap: onTap,
      excludeSemantics: true,
      child: ExcludeSemantics(
        child: Material(
          color: selected
              ? AppleTheme.finderSelectionBackground(context)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: SizedBox.square(
              dimension: 48,
              child: Icon(
                selected ? selectedIcon : icon,
                size: 25,
                color: selected
                    ? AppleTheme.blue
                    : onTap == null
                    ? AppleTheme.secondaryLabel(context).withValues(alpha: 0.5)
                    : AppleTheme.primaryLabel(context),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileFeed extends StatelessWidget {
  const _ProfileFeed({
    required this.data,
    required this.compact,
    required this.tablet,
    required this.following,
    required this.scrollController,
    required this.onToggleFollowing,
    required this.onMessage,
    required this.onOpenCareerProjects,
    required this.onOpenHistory,
  });

  final PortfolioData data;
  final bool compact;
  final bool tablet;
  final bool following;
  final ScrollController scrollController;
  final VoidCallback onToggleFollowing;
  final VoidCallback? onMessage;
  final VoidCallback? onOpenCareerProjects;
  final ValueChanged<_ProfileHistoryKind> onOpenHistory;

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
                    _ProfileSummary(
                      data: data,
                      compact: compact,
                      following: following,
                      onToggleFollowing: onToggleFollowing,
                      onMessage: onMessage,
                    ),
                    SizedBox(height: compact ? 28 : 34),
                    Divider(height: 1, color: AppleTheme.separator(context)),
                    SizedBox(height: compact ? 3 : 4),
                    _ProfileHistoryGrid(
                      data: data,
                      onOpenCareerProjects: onOpenCareerProjects,
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
  const _ProfileSummary({
    required this.data,
    required this.compact,
    required this.following,
    required this.onToggleFollowing,
    required this.onMessage,
  });

  final PortfolioData data;
  final bool compact;
  final bool following;
  final VoidCallback onToggleFollowing;
  final VoidCallback? onMessage;

  @override
  Widget build(BuildContext context) {
    final postCount =
        (data.experiences.isNotEmpty ? 1 : 0) +
        (data.education.isNotEmpty ? 1 : 0);

    final stats = Row(
      key: const Key('profile-stats'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: _ProfileStat(
            value: '$postCount개',
            label: '게시물',
            semanticsLabel: '게시물 $postCount개',
          ),
        ),
        Expanded(
          child: _ProfileStat(
            value: '$_profileCareerYears년',
            label: '경력',
            semanticsLabel: '경력 $_profileCareerYears년',
          ),
        ),
        Expanded(
          child: _ProfileStat(
            value: '${data.education.length}번',
            label: '교육',
            semanticsLabel: '교육 ${data.education.length}번',
          ),
        ),
      ],
    );
    final identity = _ProfileIdentity(data: data);
    final actions = _ProfilePrimaryActions(
      following: following,
      onToggleFollowing: onToggleFollowing,
      onMessage: onMessage,
    );

    return LayoutBuilder(
      key: const Key('profile-summary'),
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 560;
        if (wide) {
          return Row(
            key: const Key('profile-summary-wide'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: _ProfileAvatar(monogram: data.monogram, compact: false),
              ),
              const SizedBox(width: 34),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    identity,
                    const SizedBox(height: 18),
                    stats,
                    const SizedBox(height: 20),
                    actions,
                  ],
                ),
              ),
            ],
          );
        }

        return Column(
          key: const Key('profile-summary-narrow'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                _ProfileAvatar(monogram: data.monogram, compact: compact),
                SizedBox(width: compact ? 18 : 24),
                Expanded(child: stats),
              ],
            ),
            SizedBox(height: compact ? 18 : 24),
            identity,
            SizedBox(height: compact ? 18 : 22),
            actions,
          ],
        );
      },
    );
  }
}

class _ProfileIdentity extends StatelessWidget {
  const _ProfileIdentity({required this.data});

  final PortfolioData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          data.identity.name,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppleTheme.primaryLabel(context),
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          _profileHandle,
          key: const Key('profile-handle'),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppleTheme.primaryLabel(context),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          data.identity.englishName,
          style: AppleTheme.caption(
            context,
          ).copyWith(color: AppleTheme.secondaryLabel(context)),
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

class _ProfilePrimaryActions extends StatelessWidget {
  const _ProfilePrimaryActions({
    required this.following,
    required this.onToggleFollowing,
    required this.onMessage,
  });

  final bool following;
  final VoidCallback onToggleFollowing;
  final VoidCallback? onMessage;

  @override
  Widget build(BuildContext context) {
    final follow = _ProfileActionButton(
      actionKey: const Key('profile-follow-action'),
      label: following ? '팔로우 취소' : '팔로우',
      visibleLabel: following ? '팔로잉' : '팔로우',
      primary: !following,
      onTap: onToggleFollowing,
    );
    final message = _ProfileActionButton(
      actionKey: const Key('profile-message-action'),
      label: '메시지 보내기',
      visibleLabel: '메시지 보내기',
      onTap: onMessage,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = MediaQuery.textScalerOf(context).scale(1);
        final vertical = constraints.maxWidth < 280 || scale > 1.45;
        if (vertical) {
          return Column(
            key: const Key('profile-actions-vertical'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[follow, const SizedBox(height: 8), message],
          );
        }
        return Row(
          key: const Key('profile-actions-horizontal'),
          children: <Widget>[
            Expanded(child: follow),
            const SizedBox(width: 10),
            Expanded(child: message),
          ],
        );
      },
    );
  }
}

class _ProfileActionButton extends StatelessWidget {
  const _ProfileActionButton({
    required this.actionKey,
    required this.label,
    required this.visibleLabel,
    required this.onTap,
    this.primary = false,
  });

  final Key actionKey;
  final String label;
  final String visibleLabel;
  final VoidCallback? onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final background = primary
        ? AppleTheme.buttonBlue
        : AppleTheme.panel(context);
    final foreground = primary
        ? Colors.white
        : AppleTheme.primaryLabel(context);
    return Semantics(
      key: actionKey,
      label: label,
      button: true,
      enabled: onTap != null,
      onTap: onTap,
      excludeSemantics: true,
      child: ExcludeSemantics(
        child: FilledButton(
          onPressed: onTap,
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 44),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            backgroundColor: background,
            foregroundColor: foreground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(
                color: primary
                    ? AppleTheme.buttonBlue
                    : AppleTheme.separator(context),
                width: 0.8,
              ),
            ),
          ),
          child: Text(
            visibleLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textScaler: MediaQuery.textScalerOf(
              context,
            ).clamp(maxScaleFactor: 1.6),
          ),
        ),
      ),
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
    required this.value,
    required this.label,
    required this.semanticsLabel,
  });

  final String value;
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
              value,
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

class _ProfileHistoryGrid extends StatelessWidget {
  const _ProfileHistoryGrid({
    required this.data,
    required this.onOpenCareerProjects,
    required this.onOpenHistory,
  });

  final PortfolioData data;
  final VoidCallback? onOpenCareerProjects;
  final ValueChanged<_ProfileHistoryKind> onOpenHistory;

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
            if (data.experiences.isNotEmpty)
              SizedBox(
                width: tileWidth,
                child: _ProfileHistoryCard(
                  key: const Key('profile-history-post-experience'),
                  label: '경력 게시물 열기',
                  title: '경력',
                  summary: '경력 ${data.experiences.length}개',
                  kind: _ProfileHistoryKind.experience,
                  linkActionKey: const Key('profile-career-projects-link'),
                  linkActionLabel: '포트폴리오 회사 열기',
                  onLinkTap: onOpenCareerProjects,
                  onTap: () => onOpenHistory(_ProfileHistoryKind.experience),
                ),
              ),
            if (data.education.isNotEmpty)
              SizedBox(
                width: tileWidth,
                child: _ProfileHistoryCard(
                  key: const Key('profile-history-post-education'),
                  label: '교육 게시물 열기',
                  title: '교육',
                  summary: '교육 ${data.education.length}개',
                  kind: _ProfileHistoryKind.education,
                  onTap: () => onOpenHistory(_ProfileHistoryKind.education),
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
    required this.kind,
    required this.onTap,
    this.linkActionKey,
    this.linkActionLabel,
    this.onLinkTap,
    super.key,
  }) : assert(onLinkTap == null || linkActionLabel != null);

  final String label;
  final String title;
  final String summary;
  final _ProfileHistoryKind kind;
  final VoidCallback onTap;
  final Key? linkActionKey;
  final String? linkActionLabel;
  final VoidCallback? onLinkTap;

  @override
  Widget build(BuildContext context) {
    final kindName = kind.name;
    final accent = kind == _ProfileHistoryKind.experience
        ? _profileAccents.first
        : AppleTheme.orange;
    final companion = kind == _ProfileHistoryKind.experience
        ? AppleTheme.indigo
        : AppleTheme.red;
    final seed = kind == _ProfileHistoryKind.experience ? 0 : 1;
    final dark = AppleTheme.isDark(context);
    final linked = onLinkTap != null;

    return Semantics(
      label: label,
      button: true,
      onTap: onTap,
      container: true,
      explicitChildNodes: true,
      child: AspectRatio(
        aspectRatio: 1,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            ExcludeSemantics(
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
                            seed: seed,
                          ),
                        ),
                        Positioned(
                          top: 6,
                          left: 7,
                          right: linked ? 44 : 7,
                          height: 40,
                          child: Column(
                            key: Key('profile-history-post-meta-$kindName'),
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
                                  title,
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
                                    Shadow(
                                      color: Color(0x99000000),
                                      blurRadius: 4,
                                    ),
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
                            key: Key('profile-history-post-title-$kindName'),
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
            if (linked)
              Positioned(
                top: 0,
                right: 0,
                width: 44,
                height: 44,
                child: Semantics(
                  key: linkActionKey,
                  label: linkActionLabel,
                  button: true,
                  onTap: onLinkTap,
                  excludeSemantics: true,
                  child: ExcludeSemantics(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onLinkTap,
                        customBorder: const CircleBorder(),
                        child: Center(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.48),
                              shape: BoxShape.circle,
                            ),
                            child: const SizedBox.square(
                              dimension: 26,
                              child: Icon(
                                Icons.arrow_outward_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHistoryDetail extends StatefulWidget {
  const _ProfileHistoryDetail({
    required this.data,
    required this.launcher,
    required this.kind,
    required this.liked,
    required this.onToggleLike,
    required this.compact,
    required this.tablet,
  });

  final PortfolioData data;
  final ExternalLauncher launcher;
  final _ProfileHistoryKind kind;
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
    final title = widget.kind == _ProfileHistoryKind.experience ? '경력' : '교육';
    final itemCount = widget.kind == _ProfileHistoryKind.experience
        ? widget.data.experiences.length
        : widget.data.education.length;

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
                      height: math.min(
                        constraints.maxHeight,
                        _ProfileReelOverlay.heightFor(compact: widget.compact),
                      ),
                      child: _ProfileReelOverlay(
                        compact: widget.compact,
                        liked: widget.liked,
                        title: title,
                        organization: widget.data.identity.headline,
                        metadata: '$title $itemCount개',
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
                      kind: widget.kind,
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
    required this.title,
    required this.organization,
    required this.metadata,
    required this.name,
    required this.monogram,
    required this.onCamera,
    required this.onToggleLike,
    required this.onComment,
    required this.onShare,
  });

  final bool compact;
  final bool liked;
  final String title;
  final String organization;
  final String metadata;
  final String name;
  final String monogram;
  final VoidCallback onCamera;
  final VoidCallback onToggleLike;
  final VoidCallback onComment;
  final VoidCallback onShare;

  static double heightFor({required bool compact}) {
    const actionSize = 48.0;
    const actionSpacing = 4.0;
    final actionTop = compact ? 90.0 : 116.0;
    final bottomSpacing = compact ? 16.0 : 20.0;
    return actionTop + (actionSize * 3) + (actionSpacing * 2) + bottomSpacing;
  }

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
                metadata,
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
    required this.kind,
    required this.compact,
    required this.tablet,
    required this.onLaunch,
    super.key,
  });

  final PortfolioData data;
  final _ProfileHistoryKind kind;
  final bool compact;
  final bool tablet;
  final Future<void> Function(Uri uri) onLaunch;

  @override
  Widget build(BuildContext context) {
    final items = switch (kind) {
      _ProfileHistoryKind.experience => <Widget>[
        for (final entry in data.experiences.indexed)
          _ProfileReplyItem.experience(
            key: Key('profile-reel-reply-item-experience-${entry.$1}'),
            identityName: data.identity.name,
            monogram: data.monogram,
            index: entry.$1,
            experience: entry.$2,
            compact: compact,
          ),
      ],
      _ProfileHistoryKind.education => <Widget>[
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
      ],
    };

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

const String _profileHandle = '@min_hesu';
const int _profileCareerYears = 3;

const List<Color> _profileAccents = <Color>[
  Color(0xFFE1306C),
  Color(0xFF833AB4),
  Color(0xFFFCAF45),
  Color(0xFF0A84FF),
  Color(0xFF30D158),
  Color(0xFF5E5CE6),
];
