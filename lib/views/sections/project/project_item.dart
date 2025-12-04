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
              child: Text(
                'Projects',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 30),

        SectionAnimation(
          direction: MovingFadeInDirection.bottomToTop,
          child: LayoutBuilder(
            builder: (context, c) {
              return GridView.builder(
                itemCount: items.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: (c.maxWidth ~/ 300).clamp(1, 4),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          p.desc,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
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
                                onPressed: () {
                                  launchUrl(
                                    Uri.parse(p.google),
                                    mode: LaunchMode.externalApplication,
                                  );
                                },
                                icon: Icon(FontAwesomeIcons.googlePlay),
                              ),

                            if (p.app.isNotEmpty)
                              IconButton(
                                onPressed: () {
                                  launchUrl(
                                    Uri.parse(p.app),
                                    mode: LaunchMode.externalApplication,
                                  );
                                },
                                icon: Icon(FontAwesomeIcons.appStore),
                              ),

                            if (p.link.isNotEmpty)
                              IconButton(
                                onPressed: () {
                                  launchUrl(
                                    Uri.parse(p.link),
                                    mode: LaunchMode.externalApplication,
                                  );
                                },
                                icon: Icon(FontAwesomeIcons.link),
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
}
