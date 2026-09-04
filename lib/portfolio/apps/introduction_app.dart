import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/apple_theme.dart';

/// A dedicated document surface for the self-introduction letter.
///
/// The body intentionally stays neutral until the user supplies the final
/// copy, so it does not duplicate Profile or About content.
class IntroductionApp extends StatelessWidget {
  const IntroductionApp({this.compact = false, this.tablet = false, super.key});

  final bool compact;
  final bool tablet;

  @override
  Widget build(BuildContext context) {
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
                          color: const Color(0xFF185ABD),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      SizedBox(height: compact ? 28 : 40),
                      Text(
                        '자기소개서 내용을 추가할 예정입니다.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppleTheme.secondaryLabel(context),
                        ),
                      ),
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
