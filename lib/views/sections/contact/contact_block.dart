import 'package:flutter/material.dart';
import 'package:portfolio_hesu/views/sections/contact/skills.dart';
import 'package:portfolio_hesu/views/sections/project/footer.dart';
import 'package:portfolio_hesu/views/widgets/animation/section_opacity_animation.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ContactSection extends StatelessWidget {
  const ContactSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OpacityFade(
          direction: OpacityFadeInDirection.fadein,
          child: Text(
            "Skills",
            textAlign: TextAlign.left,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: SkillsTitle(
                categoryTitle: 'Language',
                skills: [
                  SkillData(
                    'Dart',
                    4,
                    const FaIcon(
                      FontAwesomeIcons.dartLang,
                      color: Color(0xFF0175C2),
                    ),
                  ),
                  SkillData(
                    'React',
                    3,
                    const FaIcon(
                      FontAwesomeIcons.react,
                      color: Color(0xFF61DAFB),
                    ),
                  ),
                  SkillData(
                    'JAVA',
                    2,
                    const FaIcon(
                      FontAwesomeIcons.java,
                      color: Color(0xFFED8B00),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 5),
            Expanded(
              child: SkillsTitle(
                categoryTitle: 'Collabor',
                skills: [
                  SkillData(
                    'Notion',
                    3,
                    const FaIcon(
                      FontAwesomeIcons.circleNotch,
                      color: Color.fromARGB(255, 80, 80, 80),
                    ),
                  ),
                  SkillData(
                    'Slack',
                    4,
                    const FaIcon(
                      FontAwesomeIcons.slack,
                      color: Color(0xFF4A154B),
                    ),
                  ),
                  SkillData(
                    'Trello',
                    3,
                    const FaIcon(
                      FontAwesomeIcons.trello,
                      color: Color(0xFF0079BF),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 5),
            Expanded(
              child: SkillsTitle(
                categoryTitle: 'Design-UIUX',
                skills: [
                  SkillData(
                    'Figma',
                    3,
                    const FaIcon(
                      FontAwesomeIcons.figma,
                      color: Color(0xFFF24E1E),
                    ),
                  ),
                  SkillData(
                    'Adobe Photoshop',
                    4,
                    const FaIcon(
                      FontAwesomeIcons.photoFilm,
                      color: Color(0xFF31A8FF),
                    ),
                  ),
                  SkillData(
                    'Adobe Illustrator',
                    3,
                    const FaIcon(
                      FontAwesomeIcons.penClip,
                      color: Color(0xFFFF9A00),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 20),
        CustomFooter(),
      ],
    );
  }
}
