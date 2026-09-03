import 'package:flutter/material.dart';

import '../data/portfolio_data.dart';
import '../services/external_launcher.dart';
import '../theme/apple_theme.dart';
import '../widgets/apple_notes_surface.dart';

class AboutApp extends StatelessWidget {
  const AboutApp({
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
    final horizontalPadding = compact ? 16.0 : (tablet ? 24.0 : 32.0);
    final dark = AppleTheme.isDark(context);

    return AppleAppSurface(
      key: const Key('about-app'),
      child: AppleNotesPaper(
        paperKey: const Key('about-notes-body'),
        darkPaper: dark,
        child: ListView(
          key: const Key('about-scroll'),
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            compact ? 18 : 28,
            horizontalPadding,
            compact ? 24 : 36,
          ),
          children: <Widget>[
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: _AboutNotesBody(
                  data: data,
                  launcher: launcher,
                  compact: compact,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutNotesBody extends StatelessWidget {
  const _AboutNotesBody({
    required this.data,
    required this.launcher,
    required this.compact,
  });

  final PortfolioData data;
  final ExternalLauncher launcher;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = _AboutNotePalette.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          data.identity.name,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            color: colors.primary,
            fontSize: compact ? 28 : 34,
            height: 1.12,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          data.identity.englishName,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: colors.secondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: compact ? 15 : 18),
        Text(
          data.identity.headline,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: colors.accent,
            fontWeight: FontWeight.w700,
            height: 1.35,
          ),
        ),
        SizedBox(height: compact ? 13 : 16),
        Container(height: 1, color: colors.divider),
        SizedBox(height: compact ? 13 : 16),
        Text(
          data.identity.biography,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: colors.primary, height: 1.58),
        ),
        _NoteSectionDivider(compact: compact),
        const _NoteSectionTitle(
          title: 'Career',
          subtitle: 'Professional experience',
        ),
        SizedBox(height: compact ? 12 : 16),
        for (final experience in data.experiences.indexed) ...<Widget>[
          _ExperienceCard(experience: experience.$2),
          if (experience.$1 != data.experiences.length - 1)
            const _NoteEntryDivider(),
        ],
        _NoteSectionDivider(compact: compact),
        const _NoteSectionTitle(
          title: 'Education',
          subtitle: 'Learning and foundations',
        ),
        SizedBox(height: compact ? 12 : 16),
        for (final entry in data.education.indexed) ...<Widget>[
          _EducationCard(
            education: entry.$2,
            index: entry.$1,
            launcher: launcher,
          ),
          if (entry.$1 != data.education.length - 1) const _NoteEntryDivider(),
        ],
        _NoteSectionDivider(compact: compact),
        const _NoteSectionTitle(
          title: 'Contact',
          subtitle: 'Let’s build something thoughtful',
        ),
        SizedBox(height: compact ? 12 : 16),
        _ContactCard(data: data),
      ],
    );
  }
}

class _NoteSectionDivider extends StatelessWidget {
  const _NoteSectionDivider({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: compact ? 22 : 28),
      child: Divider(height: 1, color: _AboutNotePalette.of(context).divider),
    );
  }
}

class _NoteEntryDivider extends StatelessWidget {
  const _NoteEntryDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Divider(
        height: 1,
        color: _AboutNotePalette.of(context).entryDivider,
      ),
    );
  }
}

class _NoteSectionTitle extends StatelessWidget {
  const _NoteSectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = _AboutNotePalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: colors.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: AppleTheme.caption(
            context,
          ).copyWith(color: colors.sectionSecondary),
        ),
      ],
    );
  }
}

class _ExperienceCard extends StatelessWidget {
  const _ExperienceCard({required this.experience});

  final PortfolioExperience experience;

  @override
  Widget build(BuildContext context) {
    final colors = _AboutNotePalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(top: 5),
            decoration: const BoxDecoration(
              color: AppleTheme.green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Wrap(
                  spacing: 8,
                  runSpacing: 5,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    Text(
                      experience.role,
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(color: colors.primary),
                    ),
                    Text(
                      experience.period,
                      style: AppleTheme.caption(context).copyWith(
                        color: colors.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  experience.organization,
                  style: AppleTheme.body(context).copyWith(
                    color: colors.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  experience.description,
                  style: AppleTheme.body(
                    context,
                  ).copyWith(color: colors.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EducationCard extends StatefulWidget {
  const _EducationCard({
    required this.education,
    required this.index,
    required this.launcher,
  });

  final PortfolioEducation education;
  final int index;
  final ExternalLauncher launcher;

  @override
  State<_EducationCard> createState() => _EducationCardState();
}

class _EducationCardState extends State<_EducationCard> {
  int _launchRequestGeneration = 0;
  String? _feedback;
  bool _launchSucceeded = false;

  @override
  void didUpdateWidget(covariant _EducationCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.education.link?.url != widget.education.link?.url ||
        !identical(oldWidget.launcher, widget.launcher)) {
      _launchRequestGeneration++;
      _feedback = null;
    }
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
      _feedback = succeeded
          ? '${link.label} 링크를 열었습니다.'
          : '${link.label} 링크를 열 수 없습니다.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final education = widget.education;
    final colors = _AboutNotePalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            education.program,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: colors.primary),
          ),
          const SizedBox(height: 6),
          Text(
            education.institution,
            style: AppleTheme.body(context).copyWith(color: colors.secondary),
          ),
          const SizedBox(height: 7),
          Wrap(
            spacing: 8,
            runSpacing: 7,
            children: <Widget>[
              ApplePill(
                label: education.period,
                icon: Icons.calendar_today_rounded,
                color: AppleTheme.indigo,
              ),
              if (education.link case final link?)
                OutlinedButton.icon(
                  key: Key('about-education-link-${widget.index}'),
                  onPressed: () => _openLink(link),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.accent,
                    side: BorderSide(color: colors.linkBorder),
                    minimumSize: const Size(44, 44),
                  ),
                  icon: const Icon(Icons.open_in_new_rounded, size: 17),
                  label: Text('Open ${link.label}'),
                ),
            ],
          ),
          if (_feedback case final message?) ...<Widget>[
            const SizedBox(height: 12),
            AppleFeedbackBanner(
              key: const Key('about-link-feedback'),
              message: message,
              success: _launchSucceeded,
            ),
          ],
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.data});

  final PortfolioData data;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 18,
      runSpacing: 16,
      children: <Widget>[
        _ContactItem(
          icon: Icons.mail_rounded,
          label: 'Email',
          value: data.identity.email,
        ),
        _ContactItem(
          icon: Icons.code_rounded,
          label: 'GitHub',
          value: data.identity.githubUrl,
        ),
      ],
    );
  }
}

class _ContactItem extends StatelessWidget {
  const _ContactItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = _AboutNotePalette.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 220, maxWidth: 360),
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppleTheme.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppleTheme.blue, size: 20),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: AppleTheme.caption(
                    context,
                  ).copyWith(color: colors.sectionSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppleTheme.body(context).copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w600,
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

class _AboutNotePalette {
  const _AboutNotePalette({
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.sectionSecondary,
    required this.divider,
    required this.entryDivider,
    required this.linkBorder,
  });

  static const light = _AboutNotePalette(
    primary: Color(0xFF242426),
    secondary: Color(0xFF515158),
    accent: Color(0xFF315879),
    sectionSecondary: Color(0xFF65656C),
    divider: Color(0xFFE3DED2),
    entryDivider: Color(0xFFE9E4D9),
    linkBorder: Color(0xFF9AAAB7),
  );

  static const dark = _AboutNotePalette(
    primary: Color(0xFFF5F5F7),
    secondary: Color(0xFFC8C8CE),
    accent: Color(0xFF8AC4FF),
    sectionSecondary: Color(0xFFB7BAC2),
    divider: Color(0xFF3D4654),
    entryDivider: Color(0xFF343D4B),
    linkBorder: Color(0xFF667A8F),
  );

  static _AboutNotePalette of(BuildContext context) {
    return AppleTheme.isDark(context) ? dark : light;
  }

  final Color primary;
  final Color secondary;
  final Color accent;
  final Color sectionSecondary;
  final Color divider;
  final Color entryDivider;
  final Color linkBorder;
}
