import 'package:flutter/material.dart';

import '../data/portfolio_data.dart';
import '../theme/apple_theme.dart';
import 'resume_bullet.dart';

class CareerTimelineEntry extends StatelessWidget {
  const CareerTimelineEntry({
    required this.experience,
    required this.isLast,
    required this.keyPrefix,
    super.key,
  });

  final PortfolioExperience experience;
  final bool isLast;
  final String keyPrefix;

  @override
  Widget build(BuildContext context) {
    final accent = AppleTheme.isDark(context)
        ? const Color(0xFFAFBAFF)
        : const Color(0xFF4656A1);
    return Stack(
      children: [
        if (!isLast)
          Positioned(
            left: 15,
            top: 40,
            bottom: 6,
            child: Container(width: 1.5, color: accent.withValues(alpha: 0.5)),
          ),
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
          child: Icon(
            Icons.work_outline_rounded,
            size: 17,
            color: AppleTheme.isDark(context)
                ? const Color(0xFF202540)
                : Colors.white,
          ),
        ),
        Padding(
          padding: EdgeInsets.only(left: 48, bottom: isLast ? 0 : 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                experience.role,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppleTheme.primaryLabel(context),
                  fontWeight: FontWeight.w800,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                key: Key('$keyPrefix-author'),
                child: Text(
                  experience.organization,
                  style: AppleTheme.body(context).copyWith(
                    color: accent,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Column(
                key: Key('$keyPrefix-content'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    experience.period,
                    style: AppleTheme.caption(context).copyWith(
                      color: AppleTheme.secondaryLabel(context),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ResumeBullet(text: experience.description, accent: accent),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
