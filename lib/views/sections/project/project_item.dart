import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:portfolio_hesu/views/widgets/animation/section_moving_animation.dart';
import 'package:portfolio_hesu/views/widgets/animation/section_opacity_animation.dart';
import 'package:portfolio_hesu/views/widgets/custom_card.dart';
import 'package:portfolio_hesu/views/sections/project/project.dart';
import 'package:url_launcher/url_launcher.dart';

class ProjectsGrid extends StatelessWidget {
  final List<Project> items;
  const ProjectsGrid({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            OpacityFade(
              direction: OpacityFadeInDirection.fadein,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Projects',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "담당 프로젝트 리스트",
                    style: TextStyle(color: Colors.white70, fontSize: 15),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 30),

        SectionAnimation(
          direction: MovingFadeInDirection.bottomToTop,
          child: LayoutBuilder(
            builder: (context, c) {
              // final cardWidth = c.maxWidth;
              return GridView.builder(
                itemCount: items.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: (c.maxWidth ~/ 240).clamp(1, 4),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  mainAxisExtent: 330,
                ),
                itemBuilder: (context, i) {
                  final p = items[i];
                  return CustomCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          p.desc,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          p.date,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        // if (cardWidth >= 1100 ||
                        //     (cardWidth >= 10 && cardWidth < 480))
                        Wrap(
                          spacing: 3,
                          runSpacing: 3,
                          children: p.tags
                              .map((t) => Chip(label: Text(t)))
                              .toList(),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 3,
                          children: [
                            if (p.google.isNotEmpty)
                              IconButton(
                                icon: const Icon(FontAwesomeIcons.googlePlay),
                                onPressed: () => _open(p.google),
                              ),

                            if (p.app.isNotEmpty)
                              IconButton(
                                icon: const Icon(FontAwesomeIcons.appStore),
                                onPressed: () => _open(p.app),
                              ),

                            if (p.link.isNotEmpty)
                              IconButton(
                                icon: const Icon(FontAwesomeIcons.link),
                                onPressed: () => _open(p.link),
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _open(String url) {
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }
}
