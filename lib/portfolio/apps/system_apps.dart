import 'package:flutter/material.dart';

import '../data/portfolio_data.dart';
import '../services/external_launcher.dart';
import '../theme/apple_theme.dart';

class ThisMacApp extends StatelessWidget {
  const ThisMacApp({
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
    final padding = compact ? 16.0 : (tablet ? 24.0 : 30.0);

    return AppleAppSurface(
      key: const Key('this-mac-app'),
      child: Column(
        children: <Widget>[
          AppleToolbar(
            title: 'About This Mac',
            subtitle: 'Portfolio system profile',
            compact: compact,
            leading: const Icon(
              Icons.laptop_mac_rounded,
              color: AppleTheme.indigo,
            ),
          ),
          Expanded(
            child: ListView(
              key: const Key('this-mac-scroll'),
              padding: EdgeInsets.all(padding),
              children: <Widget>[
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        _MacProfileCard(data: data, compact: compact),
                        SizedBox(height: compact ? 16 : 22),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: <Widget>[
                            _StatCard(
                              label: 'Projects',
                              value: '${data.projects.length}',
                              icon: Icons.folder_rounded,
                              color: AppleTheme.blue,
                              compact: compact,
                            ),
                            _StatCard(
                              label: 'Skill groups',
                              value: '${data.skillGroups.length}',
                              icon: Icons.auto_awesome_rounded,
                              color: AppleTheme.indigo,
                              compact: compact,
                            ),
                            _StatCard(
                              label: 'Experience',
                              value: '${data.experiences.length}',
                              icon: Icons.work_rounded,
                              color: AppleTheme.green,
                              compact: compact,
                            ),
                          ],
                        ),
                        SizedBox(height: compact ? 16 : 22),
                        AppleSurfaceCard(
                          radius: 17,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Overview',
                                style: AppleTheme.title(context),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                data.identity.biography,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              const SizedBox(height: 15),
                              _InfoRow(
                                label: 'Primary focus',
                                value: data.identity.headline,
                              ),
                              const SizedBox(height: 10),
                              _InfoRow(
                                label: 'Contact',
                                value: data.identity.email,
                              ),
                            ],
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
    );
  }
}

class TrashApp extends StatelessWidget {
  const TrashApp({
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
    return AppleAppSurface(
      key: const Key('trash-app'),
      child: Column(
        children: <Widget>[
          AppleToolbar(
            title: 'Trash',
            subtitle: '0 items',
            compact: compact,
            leading: const Icon(Icons.delete_rounded),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  key: const Key('trash-scroll'),
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: AppleEmptyState(
                      icon: Icons.delete_outline_rounded,
                      title: 'Trash is Empty',
                      message:
                          'There are no deleted portfolio items for ${data.identity.englishName}.',
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class GitHubApp extends StatelessWidget {
  const GitHubApp({
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
    return _ExternalProfilePage(
      rootKey: 'github-app',
      feedbackKey: 'github-launch-feedback',
      actionKey: 'github-external-action',
      title: 'GitHub',
      subtitle: 'Developer profile',
      actionLabel: 'Open GitHub profile',
      destinationLabel: 'GitHub',
      uri: Uri.parse(data.githubUrl),
      data: data,
      launcher: launcher,
      icon: Icons.code_rounded,
      colors: const <Color>[Color(0xFF50535A), Color(0xFF15161A)],
      compact: compact,
      tablet: tablet,
    );
  }
}

class MailApp extends StatelessWidget {
  const MailApp({
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
    return _ExternalProfilePage(
      rootKey: 'mail-app',
      feedbackKey: 'mail-launch-feedback',
      actionKey: 'mail-external-action',
      title: 'Mail',
      subtitle: 'Contact ${data.identity.englishName}',
      actionLabel: 'Compose email',
      destinationLabel: 'Mail',
      uri: Uri.parse(data.mailUrl),
      data: data,
      launcher: launcher,
      icon: Icons.mail_rounded,
      colors: const <Color>[Color(0xFF62D0FF), Color(0xFF176CFF)],
      compact: compact,
      tablet: tablet,
    );
  }
}

class _ExternalProfilePage extends StatefulWidget {
  const _ExternalProfilePage({
    required this.rootKey,
    required this.feedbackKey,
    required this.actionKey,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.destinationLabel,
    required this.uri,
    required this.data,
    required this.launcher,
    required this.icon,
    required this.colors,
    required this.compact,
    required this.tablet,
  });

  final String rootKey;
  final String feedbackKey;
  final String actionKey;
  final String title;
  final String subtitle;
  final String actionLabel;
  final String destinationLabel;
  final Uri uri;
  final PortfolioData data;
  final ExternalLauncher launcher;
  final IconData icon;
  final List<Color> colors;
  final bool compact;
  final bool tablet;

  @override
  State<_ExternalProfilePage> createState() => _ExternalProfilePageState();
}

class _ExternalProfilePageState extends State<_ExternalProfilePage> {
  int _launchRequestGeneration = 0;
  String? _feedback;
  bool _succeeded = false;

  @override
  void didUpdateWidget(covariant _ExternalProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.uri != widget.uri ||
        !identical(oldWidget.launcher, widget.launcher)) {
      _launchRequestGeneration++;
      _feedback = null;
    }
  }

  Future<void> _launch() async {
    final requestGeneration = ++_launchRequestGeneration;
    var succeeded = false;
    try {
      succeeded = await widget.launcher.launch(widget.uri);
    } catch (_) {
      succeeded = false;
    }
    if (!mounted || requestGeneration != _launchRequestGeneration) {
      return;
    }
    setState(() {
      _succeeded = succeeded;
      _feedback = succeeded
          ? '${widget.destinationLabel} 앱을 열었습니다.'
          : '${widget.destinationLabel} 링크를 열 수 없습니다.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final padding = widget.compact ? 16.0 : (widget.tablet ? 24.0 : 30.0);
    return AppleAppSurface(
      key: Key(widget.rootKey),
      child: Column(
        children: <Widget>[
          AppleToolbar(
            title: widget.title,
            subtitle: widget.subtitle,
            compact: widget.compact,
            leading: Icon(widget.icon, color: AppleTheme.blue),
          ),
          Expanded(
            child: ListView(
              key: Key('${widget.rootKey}-scroll'),
              padding: EdgeInsets.all(padding),
              children: <Widget>[
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 620),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        AppleSurfaceCard(
                          padding: EdgeInsets.all(widget.compact ? 20 : 28),
                          child: Column(
                            children: <Widget>[
                              Container(
                                width: widget.compact ? 76 : 92,
                                height: widget.compact ? 76 : 92,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: widget.colors,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    widget.compact ? 22 : 27,
                                  ),
                                  boxShadow: <BoxShadow>[
                                    BoxShadow(
                                      color: widget.colors.last.withValues(
                                        alpha: 0.25,
                                      ),
                                      blurRadius: 24,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  widget.icon,
                                  color: Colors.white,
                                  size: widget.compact ? 36 : 42,
                                ),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                widget.data.identity.englishName,
                                textAlign: TextAlign.center,
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 5),
                              Text(
                                widget.title == 'Mail'
                                    ? widget.data.identity.email
                                    : widget.data.identity.headline,
                                textAlign: TextAlign.center,
                                style: AppleTheme.body(context).copyWith(
                                  color: AppleTheme.secondaryLabel(context),
                                ),
                              ),
                              const SizedBox(height: 20),
                              FilledButton.icon(
                                key: Key(widget.actionKey),
                                onPressed: _launch,
                                icon: Icon(
                                  widget.title == 'Mail'
                                      ? Icons.edit_rounded
                                      : Icons.open_in_new_rounded,
                                  size: 18,
                                ),
                                label: Text(widget.actionLabel),
                              ),
                            ],
                          ),
                        ),
                        if (_feedback case final message?) ...<Widget>[
                          const SizedBox(height: 14),
                          AppleFeedbackBanner(
                            key: Key(widget.feedbackKey),
                            message: message,
                            success: _succeeded,
                          ),
                        ],
                        const SizedBox(height: 18),
                        AppleSurfaceCard(
                          radius: 17,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                widget.title == 'Mail'
                                    ? 'Contact card'
                                    : 'Profile card',
                                style: AppleTheme.title(context),
                              ),
                              const SizedBox(height: 12),
                              _InfoRow(
                                label: 'Name',
                                value:
                                    '${widget.data.identity.name} · ${widget.data.identity.englishName}',
                              ),
                              const SizedBox(height: 10),
                              _InfoRow(
                                label: widget.title == 'Mail'
                                    ? 'Address'
                                    : 'Profile',
                                value: widget.title == 'Mail'
                                    ? widget.data.identity.email
                                    : widget.data.identity.githubUrl,
                              ),
                            ],
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
    );
  }
}

class _MacProfileCard extends StatelessWidget {
  const _MacProfileCard({required this.data, required this.compact});

  final PortfolioData data;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      width: compact ? 82 : 104,
      height: compact ? 82 : 104,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF7678F6), Color(0xFF4B55C7)],
        ),
        borderRadius: BorderRadius.circular(compact ? 24 : 30),
      ),
      child: Icon(
        Icons.laptop_mac_rounded,
        color: Colors.white,
        size: compact ? 40 : 48,
      ),
    );
    final text = Column(
      crossAxisAlignment: compact
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          data.identity.englishName,
          textAlign: compact ? TextAlign.center : TextAlign.start,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 5),
        Text(
          data.identity.headline,
          textAlign: compact ? TextAlign.center : TextAlign.start,
          style: AppleTheme.body(
            context,
          ).copyWith(color: AppleTheme.secondaryLabel(context)),
        ),
        const SizedBox(height: 11),
        const ApplePill(
          label: 'Flutter · Dart',
          icon: Icons.flutter_dash_rounded,
          color: AppleTheme.indigo,
        ),
      ],
    );

    return AppleSurfaceCard(
      padding: EdgeInsets.all(compact ? 21 : 28),
      child: compact
          ? Column(children: <Widget>[badge, const SizedBox(height: 17), text])
          : Row(
              children: <Widget>[
                badge,
                const SizedBox(width: 24),
                Expanded(child: text),
              ],
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.compact,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: compact ? 152 : 210,
      child: AppleSurfaceCard(
        radius: 16,
        padding: const EdgeInsets.all(17),
        child: Row(
          children: <Widget>[
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(value, style: Theme.of(context).textTheme.titleLarge),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppleTheme.caption(context),
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: 104,
          child: Text(label, style: AppleTheme.caption(context)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            style: AppleTheme.body(
              context,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
