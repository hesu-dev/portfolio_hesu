import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:portfolio_hesu/views/sections/about/about_item.dart';
import 'package:portfolio_hesu/views/sections/contact/history.dart';
import 'package:portfolio_hesu/views/sections/hello/social_profiles.dart';
import 'package:portfolio_hesu/views/widgets/animation/section_moving_animation.dart';
import 'package:portfolio_hesu/views/widgets/animation/section_opacity_animation.dart';
import 'package:url_launcher/url_launcher.dart';

/* ---------------- Widgets ---------------- */

class Aboutme extends StatelessWidget {
  const Aboutme({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionAnimation(
          direction: MovingFadeInDirection.bottomToTop,
          child: OpacityFade(
            direction: OpacityFadeInDirection.fadein,
            child:
                // Text(
                //   'About Me',
                //   style: Theme.of(
                //     context,
                //   ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                // ),
                AnimatedTextKit(
                  animatedTexts: [
                    TypewriterAnimatedText(
                      "Hi! I'm Min He-su.",
                      textStyle: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontSize: 40,
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                      speed: const Duration(milliseconds: 120),
                      cursor: "┃",
                    ),
                  ],
                  totalRepeatCount: 1,
                  pause: Duration.zero,
                  displayFullTextOnTap: true,
                  stopPauseOnTap: true,
                ),
          ),
        ),
        const SizedBox(height: 30),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              fit: FlexFit.loose,
              child: SectionAnimation(
                direction: MovingFadeInDirection.leftToRight,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Text(
                      //   "Who am I?",
                      //   style: TextStyle(
                      //     color: Colors.white,
                      //     fontSize: 22,
                      //     fontWeight: FontWeight.bold,
                      //   ),
                      // ),
                      // const SizedBox(height: 16),
                      const Text(
                        "About Me",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        // "Flutter Developer and Google Developer for Dart\n"
                        "2~3년차 개발자 입니다.\n"
                        "IT 기업에서 몇 가지 디지털 프로젝트를 경험했습니다\n"
                        "현재에도 모바일 앱 개발자를 지향하고 있습니다.\n",
                        style: TextStyle(color: Colors.white70, fontSize: 15),
                      ),
                      const SizedBox(height: 20),
                      SectionAnimation(
                        direction: MovingFadeInDirection.bottomToTop,
                        child: OpacityFade(
                          direction: OpacityFadeInDirection.fadein,
                          child: SocialProfiles(num: 1),
                        ),
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: () {
                          launchUrl(
                            Uri.parse(
                              'https://docs.google.com/document/d/1UiJ1jcZ_tpOmKapLEo-1kmjFjZRQ-trZa793GETV3JI/edit?usp=sharing',
                            ),
                            mode: LaunchMode.externalApplication,
                          );
                          // showDialog(
                          //   context: context,
                          //   barrierDismissible: false,
                          //   builder: (BuildContext context) {
                          //     return AlertDialog(
                          //       title: const Text('알림'),
                          //       content: const Text('현재 준비중입니다.'),
                          //       actions: [
                          //         TextButton(
                          //           onPressed: () {
                          //             Navigator.of(context).pop();
                          //           },
                          //           child: const Text('닫기'),
                          //         ),
                          //       ],
                          //     );
                          //   },
                          // );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text("Skill Inventory"),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(width: 20),

            Flexible(
              fit: FlexFit.loose,
              child: SectionAnimation(
                direction: MovingFadeInDirection.rightToLeft,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Experience Overview",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),

                      buildTimelineItem(
                        title: "Junior Flutter Developer",
                        subtitle: "Freelance | 2026 - Present",
                        description: "flutter를 이용한 어플리케이션 기획 및 개발",
                      ),

                      buildTimelineItem(
                        title: "Junior Flutter Developer",
                        subtitle: "Company : (주)LSMK | 2021 - 2024",
                        description: "flutter를 이용한 어플리케이션 기획 및 개발, Rnd 연구 참여.",
                      ),

                      buildTimelineItem(
                        title: "Junior Java Developer",
                        subtitle: "Company : CKnB | 2020 - 2021",
                        description: "안드로이드 스튜디오를 통한 java(jsp) 어플리케이션 개발",
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        HistoryList(
          items: const [
            History(
              'Java 개발자 양성과정(6개월) 수료 - 파이널 프로젝트 : BoardCa APP 개발',
              '한국소프트웨어인재개발원 (KOSMO)',
              '20.04~20.10',
              'https://github.com/parkyj0720/Final-Team-Project',
            ),
            History('게임엔터테인먼트(게임기획비즈니스)과 졸업', '여주 대학교', '09.03~11.02', ''),
          ],
        ),
      ],
    );
  }
}
