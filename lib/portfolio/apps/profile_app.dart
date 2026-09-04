import 'package:flutter/material.dart';

import '../data/portfolio_data.dart';
import '../services/external_launcher.dart';
import '../theme/apple_theme.dart';

/// Mobile-only social profile built independently from the reusable About app.
class ProfileApp extends StatelessWidget {
  const ProfileApp({
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
    final horizontalPadding = compact ? 16.0 : (tablet ? 28.0 : 24.0);

    return SizedBox.expand(
      key: const Key('profile-app'),
      child: ColoredBox(
        key: const Key('profile-background'),
        color: AppleTheme.canvas(context),
        child: CustomScrollView(
          key: const Key('profile-scroll'),
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: <Widget>[
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                compact ? 18 : 24,
                horizontalPadding,
                compact ? 32 : 42,
              ),
              sliver: SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 820),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        _ProfileSummary(data: data, compact: compact),
                        SizedBox(height: compact ? 24 : 32),
                        _ProfileActions(data: data, launcher: launcher),
                        SizedBox(height: compact ? 30 : 38),
                        _ProfileHighlights(data: data, compact: compact),
                        SizedBox(height: compact ? 28 : 36),
                        _ProfileProjectGallery(
                          projects: data.projects,
                          compact: compact,
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
  }
}

class _ProfileSummary extends StatelessWidget {
  const _ProfileSummary({required this.data, required this.compact});

  final PortfolioData data;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final skillCount = data.skillGroups.fold<int>(
      0,
      (total, group) => total + group.skills.length,
    );

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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: _ProfileStat(
                      count: data.projects.length,
                      label: '프로젝트',
                      semanticsLabel: '프로젝트 ${data.projects.length}개',
                    ),
                  ),
                  Expanded(
                    child: _ProfileStat(
                      count: skillCount,
                      label: '스킬',
                      semanticsLabel: '스킬 $skillCount개',
                    ),
                  ),
                  Expanded(
                    child: _ProfileStat(
                      count: data.experiences.length,
                      label: '경력',
                      semanticsLabel: '경력 ${data.experiences.length}개',
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
            onPressed: () => _launch(Uri.parse(data.githubUrl)),
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

class _ProfileHighlights extends StatelessWidget {
  const _ProfileHighlights({required this.data, required this.compact});

  final PortfolioData data;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('profile-highlights'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _ProfileSectionHeading(
          title: '스킬 하이라이트',
          subtitle: '관심 분야와 주로 사용하는 도구',
        ),
        SizedBox(height: compact ? 16 : 20),
        if (data.skillGroups.isEmpty)
          Text(
            '등록된 스킬이 없습니다.',
            style: AppleTheme.body(
              context,
            ).copyWith(color: AppleTheme.secondaryLabel(context)),
          )
        else
          Wrap(
            spacing: compact ? 12 : 18,
            runSpacing: 16,
            children: <Widget>[
              for (final entry in data.skillGroups.indexed)
                _ProfileHighlight(
                  key: Key('profile-skill-group-${entry.$1}'),
                  group: entry.$2,
                  compact: compact,
                  accent: _profileAccents[entry.$1 % _profileAccents.length],
                ),
            ],
          ),
      ],
    );
  }
}

class _ProfileHighlight extends StatelessWidget {
  const _ProfileHighlight({
    required this.group,
    required this.compact,
    required this.accent,
    super.key,
  });

  final PortfolioSkillGroup group;
  final bool compact;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final width = compact ? 86.0 : 104.0;
    final circleSize = compact ? 64.0 : 76.0;
    final initial = group.title.trim().isEmpty
        ? '#'
        : String.fromCharCodes(group.title.trim().runes.take(1));

    return SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: circleSize,
            height: circleSize,
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[accent, AppleTheme.indigo],
              ),
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppleTheme.surface(context),
              ),
              child: Center(
                child: Text(
                  initial.toUpperCase(),
                  maxLines: 1,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppleTheme.primaryLabel(context),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            group.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppleTheme.caption(context).copyWith(
              color: AppleTheme.primaryLabel(context),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${group.skills.length}개',
            maxLines: 1,
            style: AppleTheme.caption(
              context,
            ).copyWith(color: AppleTheme.secondaryLabel(context)),
          ),
        ],
      ),
    );
  }
}

class _ProfileProjectGallery extends StatelessWidget {
  const _ProfileProjectGallery({required this.projects, required this.compact});

  final List<PortfolioProject> projects;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _ProfileSectionHeading(
          title: '프로젝트',
          subtitle: '${projects.length}개의 포트폴리오',
          centered: true,
        ),
        SizedBox(height: compact ? 14 : 18),
        Divider(height: 1, color: AppleTheme.separator(context)),
        SizedBox(height: compact ? 3 : 4),
        if (projects.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 34),
            child: Text(
              '등록된 프로젝트가 없습니다.',
              textAlign: TextAlign.center,
              style: AppleTheme.body(
                context,
              ).copyWith(color: AppleTheme.secondaryLabel(context)),
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 3.0;
              final tileWidth =
                  ((constraints.maxWidth - (spacing * 2)) / 3) - 0.01;
              return Wrap(
                key: const Key('profile-project-grid'),
                spacing: spacing,
                runSpacing: spacing,
                children: <Widget>[
                  for (final entry in projects.indexed)
                    SizedBox(
                      key: Key('profile-project-${entry.$1}'),
                      width: tileWidth,
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: _ProfileProjectTile(
                          project: entry.$2,
                          index: entry.$1,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }
}

class _ProfileProjectTile extends StatelessWidget {
  const _ProfileProjectTile({required this.project, required this.index});

  final PortfolioProject project;
  final int index;

  @override
  Widget build(BuildContext context) {
    final accent = _profileAccents[index % _profileAccents.length];
    final dark = AppleTheme.isDark(context);
    return Semantics(
      label: '${project.title} 프로젝트',
      image: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              Color.alphaBlend(
                accent.withValues(alpha: dark ? 0.42 : 0.23),
                AppleTheme.panel(context),
              ),
              Color.alphaBlend(
                AppleTheme.indigo.withValues(alpha: dark ? 0.28 : 0.13),
                AppleTheme.surface(context),
              ),
            ],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Align(
              alignment: const Alignment(0, -0.2),
              child: Icon(
                index == 0
                    ? Icons.auto_stories_rounded
                    : Icons.widgets_outlined,
                size: 30,
                color: accent.withValues(alpha: dark ? 0.95 : 0.86),
              ),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(8, 18, 8, 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      Colors.transparent,
                      AppleTheme.surface(context).withValues(alpha: 0.92),
                    ],
                  ),
                ),
                child: Text(
                  project.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppleTheme.caption(context).copyWith(
                    color: AppleTheme.primaryLabel(context),
                    fontWeight: FontWeight.w800,
                    height: 1.15,
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

class _ProfileSectionHeading extends StatelessWidget {
  const _ProfileSectionHeading({
    required this.title,
    required this.subtitle,
    this.centered = false,
  });

  final String title;
  final String subtitle;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: centered
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          textAlign: centered ? TextAlign.center : TextAlign.start,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppleTheme.primaryLabel(context),
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          textAlign: centered ? TextAlign.center : TextAlign.start,
          style: AppleTheme.caption(
            context,
          ).copyWith(color: AppleTheme.secondaryLabel(context)),
        ),
      ],
    );
  }
}

const List<Color> _profileAccents = <Color>[
  Color(0xFFE1306C),
  Color(0xFF833AB4),
  Color(0xFFFCAF45),
  Color(0xFF0A84FF),
  Color(0xFF30D158),
  Color(0xFF5E5CE6),
];
