import 'package:flutter/material.dart';

import '../theme/apple_theme.dart';

/// Shared iPhone/iPad application header.
///
/// The leading and trailing controls occupy fixed edge slots while the title
/// stays centered against the full surface width. Apps may supply a trailing
/// ellipsis action; otherwise it remains a visual placeholder.
class AppleMobileNavigationHeader extends StatelessWidget {
  const AppleMobileNavigationHeader({
    required this.title,
    required this.keyPrefix,
    this.leading,
    this.titleKey,
    this.titleContainerKey,
    this.moreKey,
    this.onMorePressed,
    this.titleStyle,
    this.height = 64,
    this.titleInset = 62,
    super.key,
  });

  final String title;
  final String keyPrefix;
  final Widget? leading;
  final Key? titleKey;
  final Key? titleContainerKey;
  final Key? moreKey;
  final VoidCallback? onMorePressed;
  final TextStyle? titleStyle;
  final double height;
  final double titleInset;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppleTheme.surface(context).withValues(alpha: 0.96),
        border: Border(
          bottom: BorderSide(color: AppleTheme.separator(context), width: 0.7),
        ),
      ),
      child: SizedBox(
        height: height,
        child: Stack(
          children: <Widget>[
            PositionedDirectional(
              start: 8,
              top: (height - 44) / 2,
              child: leading ?? const SizedBox.square(dimension: 44),
            ),
            Positioned.fill(
              left: titleInset,
              right: titleInset,
              child: Center(
                child: Container(
                  key: titleContainerKey,
                  alignment: Alignment.center,
                  child: Text(
                    title,
                    key: titleKey,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style:
                        titleStyle ?? Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
            ),
            PositionedDirectional(
              end: 8,
              top: (height - 44) / 2,
              child: ExcludeSemantics(
                excluding: onMorePressed == null,
                child: Semantics(
                  label: '더보기',
                  button: true,
                  onTap: onMorePressed,
                  child: GestureDetector(
                    key: moreKey ?? Key('$keyPrefix-more'),
                    behavior: HitTestBehavior.opaque,
                    excludeFromSemantics: true,
                    onTap: onMorePressed ?? () {},
                    child: ExcludeSemantics(
                      child: SizedBox.square(
                        dimension: 44,
                        child: Center(
                          child: Container(
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppleTheme.panel(context),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppleTheme.separator(context),
                                width: 0.8,
                              ),
                            ),
                            child: Icon(
                              Icons.more_horiz_rounded,
                              color: AppleTheme.primaryLabel(context),
                              size: 23,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
