import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:portfolio_hesu/views/widgets/animation/section_moving_animation.dart';
import 'package:portfolio_hesu/views/widgets/animation/section_opacity_animation.dart';
import 'package:portfolio_hesu/views/widgets/custom_card.dart';
import 'package:url_launcher/url_launcher.dart';

/* ----- Talks ----- */

class History {
  final String maintitle;
  final String subtitle;
  final String year;
  final String git;
  const History(this.maintitle, this.subtitle, this.year, this.git);
}

class HistoryList extends StatelessWidget {
  final List<History> items;
  const HistoryList({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OpacityFade(
          direction: OpacityFadeInDirection.fadein,
          child: Text(
            'History',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 30),
        Column(
          children: items
              .map(
                (t) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: CustomCard(
                    child: SectionAnimation(
                      direction: MovingFadeInDirection.bottomToTop,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${t.subtitle} · ${t.year}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  t.maintitle,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              IconButton(
                                onPressed: () {
                                  launchUrl(
                                    Uri.parse(t.git),
                                    mode: LaunchMode.externalApplication,
                                  );
                                },
                                icon: Icon(FontAwesomeIcons.github),
                              ),
                              const SizedBox(width: 16),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
