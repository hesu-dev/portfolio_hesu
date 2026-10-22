import 'package:flutter/material.dart';

import '../data/portfolio_data.dart';
import '../theme/apple_theme.dart';
import '../widgets/project_app_icon.dart';

class SafariStartPage extends StatelessWidget {
  const SafariStartPage({
    required this.projects,
    required this.query,
    required this.onOpenProject,
    this.bottomClearance = 0,
    super.key,
  });

  final List<PortfolioProject> projects;
  final String query;
  final ValueChanged<PortfolioProject> onOpenProject;
  final double bottomClearance;

  @override
  Widget build(BuildContext context) {
    final search = query.trim().toLowerCase();
    final entries = projects.indexed.toList();
    final results = entries.where((entry) {
      final project = entry.$2;
      return '${project.title} ${project.description} '
              '${project.technologies.join(' ')}'
          .toLowerCase()
          .contains(search);
    }).toList();
    final dark = AppleTheme.isDark(context);

    return DecoratedBox(
      key: const Key('safari-start-page'),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? const [Color(0xFF242C38), Color(0xFF24262D), Color(0xFF302D37)]
              : const [Color(0xFFE2EAF2), Color(0xFFECEDF1), Color(0xFFEAE4EC)],
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 600;
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              narrow ? 20 : 36,
              narrow ? 28 : 40,
              narrow ? 20 : 36,
              36 + bottomClearance,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1040),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (projects.isEmpty)
                      const AppleEmptyState(
                        icon: Icons.web_asset_rounded,
                        title: '프로젝트가 없습니다.',
                        message: '프로젝트가 추가되면 이곳에서 확인할 수 있습니다.',
                      )
                    else if (search.isNotEmpty) ...[
                      _heading(context, '검색 결과'),
                      const SizedBox(height: 18),
                      if (results.isEmpty)
                        const AppleEmptyState(
                          icon: Icons.search_rounded,
                          title: '검색 결과가 없습니다.',
                          message: '프로젝트 검색창',
                        )
                      else
                        _cards(context, results),
                    ] else ...[
                      _heading(context, '즐겨찾기'),
                      const SizedBox(height: 20),
                      _favorites(context, entries),
                      for (final category in [
                        PortfolioProjectCategory.personal,
                        PortfolioProjectCategory.career,
                      ])
                        if (entries.any(
                          (entry) => entry.$2.category == category,
                        )) ...[
                          const SizedBox(height: 36),
                          _heading(
                            context,
                            category == PortfolioProjectCategory.personal
                                ? '개인 프로젝트'
                                : '회사 프로젝트',
                          ),
                          const SizedBox(height: 18),
                          _cards(
                            context,
                            entries
                                .where((entry) => entry.$2.category == category)
                                .toList(),
                          ),
                        ],
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _heading(BuildContext context, String title) => Semantics(
    header: true,
    child: Text(
      title,
      style: AppleTheme.title(
        context,
      ).copyWith(fontSize: 23, fontWeight: FontWeight.w700, letterSpacing: -.5),
    ),
  );

  Widget _favorites(
    BuildContext context,
    List<(int, PortfolioProject)> entries,
  ) => LayoutBuilder(
    builder: (context, constraints) {
      final largeText = MediaQuery.textScalerOf(context).scale(13) > 19;
      final idealWidth = largeText
          ? 124.0
          : constraints.maxWidth < 600
          ? 82.0
          : 104.0;
      final columns = (constraints.maxWidth / idealWidth).floor().clamp(1, 8);
      final width = constraints.maxWidth / columns;
      return Wrap(
        runSpacing: 16,
        children: [
          for (final (index, project) in entries)
            SizedBox(
              width: width,
              child: TextButton(
                key: Key('safari-favorite-$index'),
                onPressed: () => onOpenProject(project),
                style: TextButton.styleFrom(
                  foregroundColor: AppleTheme.primaryLabel(context),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: .07),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: _ProjectArtwork(project: project, size: 62),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      project.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: AppleTheme.body(context).copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    },
  );

  Widget _cards(BuildContext context, List<(int, PortfolioProject)> entries) =>
      LayoutBuilder(
        builder: (context, constraints) {
          final largeText = MediaQuery.textScalerOf(context).scale(14) > 20;
          final columns = constraints.maxWidth >= 740 && !largeText ? 2 : 1;
          final width = (constraints.maxWidth - 14 * (columns - 1)) / columns;
          return Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              for (final (index, project) in entries)
                SizedBox(
                  width: width,
                  child: Semantics(
                    button: true,
                    child: Material(
                      color: AppleTheme.surface(context).withValues(alpha: .8),
                      borderRadius: BorderRadius.circular(22),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        key: Key('safari-project-card-$index'),
                        onTap: () => onOpenProject(project),
                        child: Container(
                          constraints: BoxConstraints(
                            minHeight: columns == 2 ? 180 : 0,
                          ),
                          padding: EdgeInsets.all(width < 400 ? 16 : 20),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _ProjectArtwork(
                                key: Key('safari-project-image-$index'),
                                project: project,
                                size: width < 400 ? 72 : 88,
                              ),
                              SizedBox(width: width < 400 ? 14 : 18),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      project.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppleTheme.body(context).copyWith(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        height: 1.3,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      project.description,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppleTheme.body(context).copyWith(
                                        color: AppleTheme.secondaryLabel(
                                          context,
                                        ),
                                        fontSize: 13,
                                        height: 1.45,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      project.period,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppleTheme.caption(context),
                                    ),
                                    if (project.technologies.isNotEmpty) ...[
                                      const SizedBox(height: 3),
                                      Text(
                                        project.technologies.join(' · '),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppleTheme.caption(context),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      );
}

class _ProjectArtwork extends StatelessWidget {
  const _ProjectArtwork({required this.project, required this.size, super.key});

  final PortfolioProject project;
  final double size;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(14),
    child: SizedBox.square(
      dimension: size,
      child: project.appIconAsset != null
          ? ProjectAppIcon(assetPath: project.appIconAsset!, size: size)
          : project.screenshots.isNotEmpty
          ? Image.asset(
              project.screenshots.first.asset,
              fit: BoxFit.cover,
              excludeFromSemantics: true,
            )
          : ColoredBox(
              color: AppleTheme.isDark(context)
                  ? const Color(0xFF46536A)
                  : const Color(0xFFCAD8E8),
              child: Center(
                child: ExcludeSemantics(
                  child: Text(
                    project.title.characters.take(2).toString().toUpperCase(),
                    textScaler: TextScaler.noScaling,
                    style: TextStyle(
                      fontSize: size * .34,
                      fontWeight: FontWeight.w500,
                      color: AppleTheme.isDark(context)
                          ? const Color(0xFFF0F4FA)
                          : const Color(0xFF52647D),
                    ),
                  ),
                ),
              ),
            ),
    ),
  );
}
