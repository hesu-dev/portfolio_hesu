import 'package:flutter/material.dart';

import '../data/portfolio_data.dart';
import '../services/external_launcher.dart';
import '../theme/apple_theme.dart';

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

    return AppleAppSurface(
      key: const Key('about-app'),
      child: Column(
        children: <Widget>[
          AppleToolbar(
            title: 'About Me',
            subtitle: 'Portfolio profile',
            compact: compact,
            leading: const Icon(
              Icons.description_rounded,
              color: AppleTheme.orange,
            ),
          ),
          Expanded(
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        _AboutNotesCard(data: data, compact: compact),
                        SizedBox(height: compact ? 24 : 32),
                        const AppleSectionTitle(
                          title: 'Career',
                          subtitle: 'Professional experience',
                          icon: Icons.work_rounded,
                        ),
                        const SizedBox(height: 12),
                        for (final experience in data.experiences) ...<Widget>[
                          _ExperienceCard(experience: experience),
                          const SizedBox(height: 11),
                        ],
                        SizedBox(height: compact ? 14 : 20),
                        const AppleSectionTitle(
                          title: 'Education',
                          subtitle: 'Learning and foundations',
                          icon: Icons.school_rounded,
                        ),
                        const SizedBox(height: 12),
                        for (final entry in data.education.indexed) ...<Widget>[
                          _EducationCard(
                            education: entry.$2,
                            index: entry.$1,
                            launcher: launcher,
                          ),
                          const SizedBox(height: 11),
                        ],
                        SizedBox(height: compact ? 14 : 20),
                        const AppleSectionTitle(
                          title: 'Contact',
                          subtitle: 'Let’s build something thoughtful',
                          icon: Icons.alternate_email_rounded,
                        ),
                        const SizedBox(height: 12),
                        _ContactCard(data: data),
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

class _AboutNotesCard extends StatelessWidget {
  const _AboutNotesCard({required this.data, required this.compact});

  final PortfolioData data;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    const noteBody = Color(0xFFFFFEFC);
    const notePrimary = Color(0xFF242426);
    const noteSecondary = Color(0xFF515158);
    const noteAccent = Color(0xFF315879);

    return Container(
      key: const Key('about-notes-card'),
      decoration: BoxDecoration(
        color: noteBody,
        borderRadius: BorderRadius.circular(compact ? 22 : 28),
        border: Border.all(
          color: const Color(0xFFDDA51B).withValues(alpha: 0.72),
          width: 0.8,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppleTheme.subtleShadow(context),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(compact ? 21 : 27),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              key: const Key('about-notes-header'),
              padding: EdgeInsets.fromLTRB(
                compact ? 18 : 24,
                compact ? 16 : 19,
                compact ? 18 : 24,
                0,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[Color(0xFFFFD95A), Color(0xFFFFB51A)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(
                        Icons.folder_outlined,
                        color: Colors.white,
                        size: compact ? 27 : 31,
                      ),
                      SizedBox(width: compact ? 11 : 14),
                      Expanded(
                        child: Text(
                          '메모',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: const Color(0xFF3A2700),
                                fontSize: compact ? 22 : 25,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: compact ? 12 : 15),
                  const SizedBox(
                    key: Key('about-notes-separator'),
                    height: 8,
                    child: CustomPaint(painter: _NotesDotsPainter()),
                  ),
                ],
              ),
            ),
            Container(
              key: const Key('about-notes-body'),
              padding: EdgeInsets.fromLTRB(
                compact ? 18 : 26,
                compact ? 18 : 24,
                compact ? 18 : 26,
                compact ? 22 : 28,
              ),
              decoration: const BoxDecoration(color: noteBody),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: compact ? 42 : 48,
                    height: compact ? 42 : 48,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF584117),
                      borderRadius: BorderRadius.circular(compact ? 12 : 14),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        data.monogram,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: compact ? 12 : 15),
                  Text(
                    data.identity.name,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: notePrimary,
                      fontSize: compact ? 28 : 34,
                      height: 1.12,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    data.identity.englishName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: noteSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: compact ? 15 : 18),
                  Text(
                    data.identity.headline,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: noteAccent,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                  SizedBox(height: compact ? 13 : 16),
                  Container(height: 1, color: const Color(0xFFE3DED2)),
                  SizedBox(height: compact ? 13 : 16),
                  Text(
                    data.identity.biography,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: notePrimary,
                      height: 1.58,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotesDotsPainter extends CustomPainter {
  const _NotesDotsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF8D6507);
    const radius = 1.25;
    const gap = 8.0;
    for (var x = radius; x <= size.width - radius; x += gap) {
      canvas.drawCircle(Offset(x, size.height / 2), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _NotesDotsPainter oldDelegate) => false;
}

class _ExperienceCard extends StatelessWidget {
  const _ExperienceCard({required this.experience});

  final PortfolioExperience experience;

  @override
  Widget build(BuildContext context) {
    return AppleSurfaceCard(
      radius: 16,
      padding: const EdgeInsets.all(17),
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
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      experience.period,
                      style: AppleTheme.caption(context).copyWith(
                        color: AppleTheme.blue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  experience.organization,
                  style: AppleTheme.body(context).copyWith(
                    color: AppleTheme.secondaryLabel(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 7),
                Text(experience.description, style: AppleTheme.body(context)),
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
    return AppleSurfaceCard(
      radius: 16,
      padding: const EdgeInsets.all(17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            education.program,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            education.institution,
            style: AppleTheme.body(
              context,
            ).copyWith(color: AppleTheme.secondaryLabel(context)),
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
    return AppleSurfaceCard(
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
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
      ),
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
                Text(label, style: AppleTheme.caption(context)),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppleTheme.body(
                    context,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
