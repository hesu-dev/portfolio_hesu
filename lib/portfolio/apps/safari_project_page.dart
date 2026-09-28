import 'package:flutter/material.dart';

import '../data/portfolio_data.dart';
import '../theme/apple_theme.dart';

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
          child: wide
              ? Row(
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
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [main, support],
                ),
        );
      },
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
        Semantics(
          header: true,
          child: Text(
            project.title,
            key: const Key('safari-project-title'),
            style: AppleTheme.largeTitle(context).copyWith(
              color: AppleTheme.buttonBlue,
              fontSize: compact ? 28 : 34,
              height: 1.2,
              letterSpacing: -.7,
            ),
          ),
        ),
        if (project.description.trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            project.description,
            style: body.copyWith(color: AppleTheme.secondaryLabel(context)),
          ),
        ],
        const SizedBox(height: 24),
        _summaries(context),
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
            if (nodes.isNotEmpty) ...[
              const SizedBox(height: 22),
              Wrap(
                spacing: 10,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (final (index, node) in nodes.indexed) ...[
                    if (index > 0 &&
                        architecture.presentation ==
                            PortfolioArchitecturePresentation.flow)
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 18,
                        color: AppleTheme.secondaryLabel(context),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppleTheme.panel(context),
                        border: Border.all(
                          color: AppleTheme.separator(context),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(node, style: body.copyWith(fontSize: 14)),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ]),
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
                          color: AppleTheme.buttonBlue,
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
    final nodeCount =
        architecture?.nodes.where((node) => node.trim().isNotEmpty).length ?? 0;
    final environment = _section(
      context,
      '운영 환경',
      [
        Text('작업 기간', style: AppleTheme.caption(context)),
        const SizedBox(height: 4),
        Text(
          project.period.trim().isEmpty ? '등록된 기간이 없습니다.' : project.period,
          style: body,
        ),
        const SizedBox(height: 12),
        Text('공개 배포 채널', style: AppleTheme.caption(context)),
        const SizedBox(height: 4),
        Text(
          channels.isEmpty ? '등록된 배포 정보가 없습니다.' : channels.join(' · '),
          style: body,
        ),
      ],
      key: const Key('safari-environment-summary'),
      icon: Icons.dns_outlined,
    );
    final structure = _section(
      context,
      '구조 요약',
      [
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
          if (nodeCount > 0) ...[
            const SizedBox(height: 12),
            Text(
              '$nodeCount개 ${architecture.presentation == PortfolioArchitecturePresentation.flow ? '단계' : '구성 요소'}',
              style: body.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ],
      key: const Key('safari-structure-summary'),
      icon: Icons.schema_outlined,
    );
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
        _section(context, '작업 링크', [
          if (project.links.isEmpty)
            Text('공개된 작업 링크가 없습니다.', style: AppleTheme.caption(context))
          else
            for (final (index, link) in project.links.indexed)
              Padding(
                padding: EdgeInsets.only(
                  bottom: index == project.links.length - 1 ? 0 : 10,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    key: Key('safari-project-link-$index'),
                    onPressed: pendingLinks.contains(link.uri)
                        ? null
                        : () => onOpenLink(link),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 58),
                      padding: const EdgeInsets.all(12),
                      alignment: Alignment.centerLeft,
                      side: BorderSide(color: AppleTheme.separator(context)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                link.label,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                link.uri.host,
                                style: AppleTheme.caption(
                                  context,
                                ).copyWith(fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (pendingLinks.contains(link.uri))
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 1.5),
                          )
                        else
                          const Icon(Icons.arrow_outward_rounded, size: 16),
                      ],
                    ),
                  ),
                ),
              ),
          if (feedback case final message? when message.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            AppleFeedbackBanner(
              key: const Key('safari-project-feedback'),
              message: message,
            ),
          ],
        ]),
      ],
    );
  }

  Widget _section(
    BuildContext context,
    String title,
    List<Widget> children, {
    Key? key,
    IconData? icon,
  }) {
    final sectionIcon =
        icon ??
        switch (title) {
          '프로젝트 구조' => Icons.account_tree_outlined,
          'Troubleshooting' => Icons.build_outlined,
          '담당 업무 · 기여' => Icons.task_alt_rounded,
          '기술 스택' => Icons.layers_outlined,
          '작업 링크' => Icons.link_rounded,
          '프로젝트 화면' => Icons.image_outlined,
          _ => Icons.article_outlined,
        };
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
            child: Row(
              children: [
                Icon(sectionIcon, size: 19, color: AppleTheme.buttonBlue),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    title,
                    style: AppleTheme.title(
                      context,
                    ).copyWith(color: AppleTheme.buttonBlue, fontSize: 16),
                  ),
                ),
              ],
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
