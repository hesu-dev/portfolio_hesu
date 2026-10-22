import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/apple_theme.dart';
import '../models/introduction_section.dart';
import '../widgets/resume_bullet.dart';

/// A dedicated document surface for the self-introduction letter.
class IntroductionApp extends StatelessWidget {
  const IntroductionApp({
    required this.introduction,
    this.compact = false,
    this.tablet = false,
    super.key,
  });

  final String introduction;
  final bool compact;
  final bool tablet;

  @override
  Widget build(BuildContext context) {
    final accent = AppleTheme.isDark(context)
        ? const Color(0xFF91CDB9)
        : const Color(0xFF24594A);
    final sections = introductionSections(introduction);
    final horizontalPadding = compact ? 16.0 : (tablet ? 28.0 : 36.0);
    final verticalPadding = compact ? 18.0 : 28.0;

    return AppleAppSurface(
      key: const Key('introduction-app'),
      color: AppleTheme.panel(context),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final minimumDocumentHeight = compact ? 440.0 : 560.0;
          final availableHeight = math.max(
            0.0,
            constraints.maxHeight - verticalPadding * 2,
          );

          return SingleChildScrollView(
            key: const Key('introduction-scroll'),
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Container(
                  key: const Key('introduction-document'),
                  width: double.infinity,
                  constraints: BoxConstraints(
                    minHeight: math.max(minimumDocumentHeight, availableHeight),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 24 : 54,
                    vertical: compact ? 32 : 52,
                  ),
                  decoration: BoxDecoration(
                    color: AppleTheme.surface(context),
                    borderRadius: BorderRadius.circular(compact ? 12 : 16),
                    border: Border.all(
                      color: AppleTheme.separator(context),
                      width: 0.7,
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: AppleTheme.subtleShadow(context),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '자기소개',
                        style: compact
                            ? Theme.of(context).textTheme.headlineSmall
                            : AppleTheme.largeTitle(context),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: 42,
                        height: 3,
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      SizedBox(height: compact ? 28 : 40),
                      for (final section in sections.indexed) ...[
                        if (section.$1 > 0) const SizedBox(height: 30),
                        if (section.$2.title case final title?) ...[
                          Semantics(
                            header: true,
                            child: Stack(
                              alignment: Alignment.centerLeft,
                              children: [
                                Divider(color: accent.withValues(alpha: 0.45)),
                                ColoredBox(
                                  color: AppleTheme.surface(context),
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 12),
                                    child: Text(
                                      title,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                            color: accent,
                                            height: 1.4,
                                          ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                        for (final paragraph
                            in section.$2.paragraphs.indexed) ...[
                          if (paragraph.$1 > 0) const SizedBox(height: 9),
                          if (section.$2.title != null)
                            ResumeBullet(text: paragraph.$2, accent: accent)
                          else
                            Text(
                              paragraph.$2,
                              style: AppleTheme.body(context).copyWith(
                                color: AppleTheme.primaryLabel(context),
                                height: 1.65,
                              ),
                            ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
