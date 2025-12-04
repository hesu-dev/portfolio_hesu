import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:portfolio_hesu/views/widgets/animation/section_moving_animation.dart';
import 'package:portfolio_hesu/views/widgets/animation/section_opacity_animation.dart';
import 'package:portfolio_hesu/views/widgets/custom_card.dart';
import 'package:url_launcher/url_launcher.dart';

class PackageItem {
  final String title;
  final String desc;
  final String git;
  final String link;
  const PackageItem(this.title, this.desc, this.git, this.link);
}

class Packages extends StatelessWidget {
  const Packages({super.key});

  @override
  Widget build(BuildContext context) {
    return PackagesList(
      items: const [
        // title, desc, git, link
        PackageItem(
          '코코포리아 로그 변환 사이트',
          '*(25. 02 배포) \n React를 이용한 파이어베이스 파싱데이터 정렬 및 CSS 스타일링',
          'https://github.com/sukenell/cclog_custom',
          'https://www.postype.com/@reha-dev/post/18656933',
        ),

        // PackageItem(
        //   '김장 게임 - Kimchi Run by nell',
        //   '유니티를 이용한 2D 모바일 러닝 게임',
        //   'https://github.com/sukenell/cclog_custom',
        //   'https://www.postype.com/@reha-dev/post/18656933',
        // ),

        // PackageItem('연애문답 : 커플 아카이브', 'flutter를 이용한 하이브리드 웹앱.', '', ''),
        // PackageItem('', 'flutter를 이용한 하이브리드 웹앱.', '', ''),
      ],
    );
  }
}

class PackagesList extends StatelessWidget {
  final List<PackageItem> items;
  const PackagesList({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OpacityFade(
          direction: OpacityFadeInDirection.fadein,
          child: Text(
            'Little project List',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 28),
        SectionAnimation(
          direction: MovingFadeInDirection.bottomToTop,
          child: LayoutBuilder(
            builder: (context, c) {
              return GridView.builder(
                itemCount: items.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 340,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemBuilder: (context, i) {
                  final p = items[i];
                  return CustomCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF25A77C),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.code, size: 28),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          p.title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          p.desc,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                launchUrl(
                                  Uri.parse(p.git),
                                  mode: LaunchMode.externalApplication,
                                );
                              },
                              icon: Icon(FontAwesomeIcons.github),
                            ),
                            const SizedBox(width: 16),
                            IconButton(
                              onPressed: () {
                                launchUrl(
                                  Uri.parse(p.link),
                                  mode: LaunchMode.externalApplication,
                                );
                              },
                              icon: Icon(Icons.open_in_new, size: 20),
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
