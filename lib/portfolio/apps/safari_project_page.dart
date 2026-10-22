import 'package:flutter/material.dart';

import '../data/portfolio_data.dart';
import '../theme/apple_theme.dart';
import '../widgets/project_architecture_diagram.dart';
import '../widgets/project_app_icon.dart';

class SafariProjectPage extends StatelessWidget {
  const SafariProjectPage({
    required this.project,
    required this.onOpenLink,
    required this.pendingLinks,
    this.compact = false,
    this.feedback,
    super.key,
  });

  final PortfolioProject project;
  final bool compact;
  final ValueChanged<PortfolioProjectLink> onOpenLink;
  final Set<Uri> pendingLinks;
  final String? feedback;

  static const _troubleshootingKinds = <PortfolioProjectSectionKind>[
    PortfolioProjectSectionKind.problem,
    PortfolioProjectSectionKind.cause,
    PortfolioProjectSectionKind.measurement,
    PortfolioProjectSectionKind.solution,
    PortfolioProjectSectionKind.evaluation,
  ];

  static const _technicalKinds = <PortfolioProjectSectionKind>[
    PortfolioProjectSectionKind.coreTechnology,
    PortfolioProjectSectionKind.technicalDecision,
  ];

  TextStyle _body(BuildContext context) => AppleTheme.body(
    context,
  ).copyWith(fontSize: compact ? 15 : 16, height: 1.8);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide =
            constraints.maxWidth >= 900 &&
            MediaQuery.textScalerOf(context).scale(14) <= 21;
        final main = _report(context);
        final support = _support(context);
        return SizedBox(
          key: const Key('safari-project-page'),
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(context),
              if (project.description.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  project.description,
                  style: _body(
                    context,
                  ).copyWith(color: AppleTheme.secondaryLabel(context)),
                ),
              ],
              _links(context),
              const SizedBox(height: 24),
              if (wide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: main),
                    const SizedBox(width: 24),
                    SizedBox(
                      width: (constraints.maxWidth * .27).clamp(270.0, 340.0),
                      child: support,
                    ),
                  ],
                )
              else ...[
                support,
                main,
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _header(BuildContext context) {
    return Row(
      key: const Key('safari-project-header'),
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          key: const Key('project-detail-icon'),
          width: 74,
          height: 74,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppleTheme.surface(context),
            borderRadius: BorderRadius.circular(20),
            border: project.appIconAsset == null
                ? Border.all(color: AppleTheme.separator(context))
                : null,
          ),
          child: project.appIconAsset == null
              ? null
              : ProjectAppIcon(assetPath: project.appIconAsset!),
        ),
        SizedBox(width: compact ? 14 : 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  project.title,
                  key: const Key('safari-project-title'),
                  style:
                      (compact
                              ? Theme.of(context).textTheme.titleLarge
                              : Theme.of(context).textTheme.headlineSmall)
                          ?.copyWith(color: AppleTheme.primaryLabel(context)),
                ),
              ),
              if (project.period.trim().isNotEmpty) ...[
                const SizedBox(height: 9),
                ApplePill(
                  label: project.period,
                  icon: Icons.calendar_month_rounded,
                  color: AppleTheme.secondaryLabel(context),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _report(BuildContext context) {
    final body = _body(context);
    final troubleshooting = [
      for (final kind in _troubleshootingKinds)
        for (final section in project.sections)
          if (section.kind == kind && section.body.trim().isNotEmpty) section,
    ];
    final architecture = project.architecture;
    final nodes =
        architecture?.nodes.where((node) => node.trim().isNotEmpty).toList() ??
        <String>[];
    return Column(
      key: const Key('safari-report-main'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _section(context, '프로젝트 구조', [
          if (architecture == null)
            Text('등록된 구조 설명이 없습니다.', style: AppleTheme.caption(context))
          else ...[
            if (architecture.title.trim().isNotEmpty) ...[
              Text(
                architecture.title,
                style: body.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
            ],
            if (architecture.description.trim().isNotEmpty)
              Text(architecture.description, style: body),
            if (architecture.diagram case final diagram?) ...[
              const SizedBox(height: 22),
              ProjectArchitectureDiagram(diagram: diagram),
            ] else if (nodes.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                nodes.join(
                  architecture.presentation ==
                          PortfolioArchitecturePresentation.flow
                      ? ' → '
                      : '\n',
                ),
                style: body,
              ),
            ],
          ],
        ]),
        _summaries(context),
        for (final kind in _technicalKinds)
          for (final section in project.sections)
            if (section.kind == kind && section.body.trim().isNotEmpty)
              _section(context, kind.label, [Text(section.body, style: body)]),
        if (project.highlights.any((item) => item.trim().isNotEmpty))
          _section(context, '담당 업무 · 기여', [
            for (final highlight in project.highlights)
              if (highlight.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '—',
                        style: body.copyWith(
                          color: AppleTheme.secondaryLabel(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(highlight, style: body)),
                    ],
                  ),
                ),
          ]),
        KeyedSubtree(
          key: const Key('safari-troubleshooting'),
          child: _section(context, 'Troubleshooting', [
            if (troubleshooting.isEmpty)
              Text('등록된 트러블슈팅 기록이 없습니다.', style: AppleTheme.caption(context))
            else
              for (final section in troubleshooting)
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        section.kind.label,
                        style: AppleTheme.caption(context).copyWith(
                          color: AppleTheme.primaryLabel(context),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(section.body, style: body),
                    ],
                  ),
                ),
          ]),
        ),
        for (final section in project.sections)
          if (section.body.trim().isNotEmpty &&
              !_troubleshootingKinds.contains(section.kind) &&
              !_technicalKinds.contains(section.kind) &&
              !(section.kind == PortfolioProjectSectionKind.work &&
                  section.body.trim() == project.description.trim()))
            _section(context, section.kind.label, [
              Text(section.body, style: body),
            ]),
        if (project.screenshots.isNotEmpty)
          _section(context, '프로젝트 화면', [
            Text('이미지를 누르면 확대해서 볼 수 있습니다.', style: AppleTheme.caption(context)),
            for (final (index, screenshot) in project.screenshots.indexed) ...[
              const SizedBox(height: 22),
              Semantics(
                label: '${screenshot.caption} 확대 보기',
                button: true,
                child: Material(
                  color: AppleTheme.panel(context),
                  borderRadius: BorderRadius.circular(8),
                  clipBehavior: Clip.antiAlias,
                  child: AspectRatio(
                    aspectRatio: screenshot.aspectRatio,
                    child: Ink.image(
                      image: AssetImage(screenshot.asset),
                      fit: BoxFit.contain,
                      child: InkWell(
                        key: Key('safari-project-screenshot-$index'),
                        onTap: () => _openScreenshot(context, screenshot),
                        focusColor: AppleTheme.blue.withValues(alpha: .18),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                screenshot.caption,
                style: AppleTheme.caption(context).copyWith(height: 1.6),
              ),
            ],
          ]),
      ],
    );
  }

  Widget _summaries(BuildContext context) {
    final body = _body(context).copyWith(fontSize: 13, height: 1.6);
    // Store links establish distribution channels, not OS or runtime versions.
    final channels = {
      for (final link in project.links)
        switch (link.uri.host) {
          'apps.apple.com' => 'App Store',
          'play.google.com' => 'Google Play',
          'chromewebstore.google.com' => 'Chrome Web Store',
          _ => null,
        },
    }..remove(null);
    final architecture = project.architecture;
    final components = architecture?.diagram != null
        ? architecture!.diagram!.nodes
              .map((node) => (node.label, node.detail))
              .toList()
        : [
            for (final label in architecture?.nodes ?? <String>[])
              if (label.trim().isNotEmpty) (label, ''),
          ];
    final environment = _section(context, '운영 환경', [
      Text('공개 배포 채널', style: AppleTheme.caption(context)),
      const SizedBox(height: 4),
      Text(
        channels.isEmpty ? '등록된 배포 정보가 없습니다.' : channels.join(' · '),
        style: body,
      ),
    ], key: const Key('safari-environment-summary'));
    final structure = _section(context, '구조 요약', [
      if (architecture == null)
        Text('등록된 구조 정보가 없습니다.', style: body)
      else ...[
        Text(
          architecture.presentation == PortfolioArchitecturePresentation.flow
              ? '처리 흐름'
              : '구성 요소',
          style: AppleTheme.caption(context),
        ),
        const SizedBox(height: 4),
        if (architecture.title.trim().isNotEmpty)
          Text(architecture.title, style: body),
        if (components.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            '${components.length}개 ${architecture.diagram == null && architecture.presentation == PortfolioArchitecturePresentation.flow ? '단계' : '구성 요소'}',
            style: body.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
        for (final (index, component) in components.indexed) ...[
          const SizedBox(height: 8),
          Text(
            '${index + 1}. ${component.$1}'
            '${component.$2.trim().isEmpty ? '' : ' — ${component.$2}'}',
            style: body,
          ),
        ],
      ],
    ], key: const Key('safari-structure-summary'));
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 560 &&
            MediaQuery.textScalerOf(context).scale(14) <= 21) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: environment),
              const SizedBox(width: 16),
              Expanded(child: structure),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [environment, structure],
        );
      },
    );
  }

  Widget _support(BuildContext context) {
    final body = _body(context);
    final technologies = project.technologies.where(
      (item) => item.trim().isNotEmpty,
    );
    return Column(
      key: const Key('safari-report-support'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _section(context, '기술 스택', [
          if (technologies.isEmpty)
            Text('등록된 기술 스택이 없습니다.', style: AppleTheme.caption(context))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final technology in technologies)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: AppleTheme.panel(context),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(technology, style: body.copyWith(fontSize: 13)),
                  ),
              ],
            ),
        ]),
      ],
    );
  }

  Widget _links(BuildContext context) {
    final foreground = AppleTheme.primaryLabel(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (project.links.isNotEmpty) ...[
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              key: const Key('safari-project-links'),
              alignment: WrapAlignment.start,
              spacing: 9,
              runSpacing: 9,
              children: [
                for (final (index, link) in project.links.indexed)
                  Tooltip(
                    message: link.label,
                    excludeFromSemantics: true,
                    child: OutlinedButton(
                      key: Key('safari-project-link-$index'),
                      onPressed: pendingLinks.contains(link.uri)
                          ? null
                          : () => onOpenLink(link),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(48, 48),
                        padding: const EdgeInsets.all(12),
                        foregroundColor: foreground,
                        backgroundColor: AppleTheme.panel(context),
                        side: BorderSide(color: AppleTheme.separator(context)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: Semantics(
                        label: link.label,
                        child: SizedBox.square(
                          dimension: 24,
                          child: Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.center,
                            children: [
                              Icon(_projectLinkIcon(link.uri), size: 21),
                              Positioned(
                                bottom: -5,
                                right: -5,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: AppleTheme.panel(context),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Padding(
                                    padding: EdgeInsets.all(1),
                                    child: Icon(Icons.link_rounded, size: 12),
                                  ),
                                ),
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
        ],
        if (feedback case final message? when message.trim().isNotEmpty) ...[
          const SizedBox(height: 14),
          AppleFeedbackBanner(
            key: const Key('safari-project-feedback'),
            message: message,
          ),
        ],
      ],
    );
  }

  Widget _section(
    BuildContext context,
    String title,
    List<Widget> children, {
    Key? key,
  }) {
    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 18),
      padding: EdgeInsets.all(compact ? 16 : 20),
      decoration: BoxDecoration(
        color: AppleTheme.surface(context),
        border: Border.all(color: AppleTheme.separator(context)),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              title,
              style: AppleTheme.title(
                context,
              ).copyWith(color: AppleTheme.primaryLabel(context), fontSize: 16),
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  void _openScreenshot(
    BuildContext context,
    PortfolioProjectScreenshot screenshot,
  ) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog.fullscreen(
        key: const Key('safari-project-screenshot-preview'),
        child: Scaffold(
          backgroundColor: AppleTheme.canvas(context),
          appBar: AppBar(
            leading: IconButton(
              tooltip: '닫기',
              icon: const Icon(Icons.close_rounded),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              screenshot.caption,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppleTheme.body(context),
            ),
          ),
          body: Center(
            child: InteractiveViewer(
              maxScale: 5,
              child: Image.asset(
                screenshot.asset,
                semanticLabel: screenshot.caption,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

IconData _projectLinkIcon(Uri uri) => switch (uri.host) {
  'apps.apple.com' => Icons.apple_rounded,
  'play.google.com' => Icons.play_arrow_rounded,
  'chromewebstore.google.com' => Icons.extension_rounded,
  'www.dbpia.co.kr' => Icons.article_outlined,
  _ => Icons.language_rounded,
};
