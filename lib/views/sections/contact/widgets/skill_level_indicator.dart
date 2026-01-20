import 'package:flutter/material.dart';

class SkillLevelIndicator extends StatelessWidget {
  final int level; // 0 ~ 5
  final double size;
  final double gap;
  final bool isCompact;

  const SkillLevelIndicator({
    super.key,
    required this.level,
    this.size = 14,
    this.gap = 4,
    required this.isCompact,
  });

  static const int maxLevel = 5;
  static const Color activeColor = Color(0xFF25A77C);
  static const Color inactiveColor = Color(0xFFE0E0E0);

  @override
  Widget build(BuildContext context) {
    final safeLevel = level.clamp(0, maxLevel);

    return LayoutBuilder(
      builder: (context, constraints) {
        // 📱 화면이 좁으면 숫자 표시
        if (isCompact) {
          return Text(
            '$safeLevel / $maxLevel',
            style: Theme.of(context).textTheme.bodyMedium,
          );
        }

        // 🖥️ 화면이 넓으면 아이콘 표시
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(maxLevel, (index) {
            final isActive = index < safeLevel;

            return Padding(
              padding: EdgeInsets.only(right: index == maxLevel - 1 ? 0 : gap),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: isActive ? activeColor : inactiveColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
