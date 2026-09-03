import 'package:flutter/material.dart';

import '../data/portfolio_data.dart';
import '../theme/apple_theme.dart';

class AboutApp extends StatelessWidget {
  const AboutApp({
    required this.data,
    this.compact = false,
    this.tablet = false,
    super.key,
  });

  final PortfolioData data;
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
                        _IdentityHeader(data: data, compact: compact),
                        SizedBox(height: compact ? 16 : 22),
                        _IntroductionCard(data: data),
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
                        for (final education in data.education) ...<Widget>[
                          _EducationCard(education: education),
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

class _IdentityHeader extends StatelessWidget {
  const _IdentityHeader({required this.data, required this.compact});

  final PortfolioData data;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final avatar = Container(
      width: compact ? 72 : 92,
      height: compact ? 72 : 92,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF80D7FF), Color(0xFF4875F7)],
        ),
        borderRadius: BorderRadius.circular(compact ? 22 : 28),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppleTheme.blue.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        'MH',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: compact ? 24 : 30,
          letterSpacing: -0.6,
        ),
      ),
    );
    final identity = Column(
      crossAxisAlignment: compact
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          data.identity.name,
          textAlign: compact ? TextAlign.center : TextAlign.start,
          style: AppleTheme.largeTitle(context),
        ),
        const SizedBox(height: 3),
        Text(
          data.identity.englishName,
          textAlign: compact ? TextAlign.center : TextAlign.start,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppleTheme.secondaryLabel(context),
          ),
        ),
        const SizedBox(height: 11),
        ApplePill(
          label: data.identity.headline,
          icon: Icons.flutter_dash_rounded,
          color: AppleTheme.blue,
        ),
      ],
    );

    if (compact) {
      return Column(
        children: <Widget>[avatar, const SizedBox(height: 16), identity],
      );
    }

    return Row(
      children: <Widget>[
        avatar,
        const SizedBox(width: 22),
        Expanded(child: identity),
      ],
    );
  }
}

class _IntroductionCard extends StatelessWidget {
  const _IntroductionCard({required this.data});

  final PortfolioData data;

  @override
  Widget build(BuildContext context) {
    return AppleSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Hello, I’m ${data.identity.englishName}.',
            style: AppleTheme.title(context),
          ),
          const SizedBox(height: 10),
          Text(
            data.identity.biography,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
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

class _EducationCard extends StatelessWidget {
  const _EducationCard({required this.education});

  final PortfolioEducation education;

  @override
  Widget build(BuildContext context) {
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
                ApplePill(
                  label: link.label,
                  icon: Icons.link_rounded,
                  color: AppleTheme.blue,
                ),
            ],
          ),
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
