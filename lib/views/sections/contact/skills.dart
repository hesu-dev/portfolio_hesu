import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:portfolio_hesu/views/sections/contact/widgets/skill_level_indicator.dart';

class _SkillItem extends StatelessWidget {
  final String title;
  final int level;
  final Widget icon;
  final bool isCompact;

  const _SkillItem({
    required this.title,
    required this.level,
    required this.icon,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color.fromARGB(255, 137, 137, 137)),
      ),
      child: SizedBox(
        width: double.infinity,
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  if (!isCompact) icon,
                  const SizedBox(width: 6),
                  Expanded(child: Text(title, overflow: TextOverflow.ellipsis)),
                ],
              ),
            ),
            SkillLevelIndicator(level: level, isCompact: isCompact),
          ],
        ),
      ),
    );
  }
}

class SkillData {
  final String title;
  final int level;
  final FaIcon icon;

  const SkillData(this.title, this.level, this.icon);
}

class SkillsTitle extends StatelessWidget {
  final String categoryTitle;
  final List<SkillData> skills;

  const SkillsTitle({
    super.key,
    required this.categoryTitle,
    required this.skills,
  });

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.width < 1000;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          categoryTitle,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        ...skills.map(
          (skill) => _SkillItem(
            title: skill.title,
            level: skill.level,
            icon: skill.icon,
            isCompact: isCompact,
          ),
        ),
      ],
    );
  }
}
