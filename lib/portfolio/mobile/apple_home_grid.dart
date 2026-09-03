import 'package:flutter/material.dart';

import '../data/portfolio_data.dart';
import '../models/portfolio_app_id.dart';
import '../theme/apple_theme.dart';
import '../widgets/apple_app_icon.dart';
import '../widgets/apple_notes_surface.dart';

class AppleHomeGrid extends StatelessWidget {
  const AppleHomeGrid({
    required this.data,
    required this.tablet,
    required this.now,
    required this.onOpen,
    super.key,
  });

  static const List<PortfolioAppId> apps = portfolioLauncherAppIds;

  final PortfolioData data;
  final bool tablet;
  final DateTime now;
  final ValueChanged<PortfolioAppId> onOpen;

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = tablet ? 32.0 : 16.0;

    return KeyedSubtree(
      key: const Key('mobile-home-grid'),
      child: CustomScrollView(
        key: const Key('mobile-home-scroll'),
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: <Widget>[
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              tablet ? 22 : 10,
              horizontalPadding,
              tablet ? 24 : 16,
            ),
            sliver: SliverToBoxAdapter(
              child: _MobileNotesProfileButton(
                data: data,
                tablet: tablet,
                now: now,
                onPressed: () => onOpen(PortfolioAppId.about),
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final appId = apps[index];
                  return Center(
                    child: AppleAppIcon(
                      key: Key('home-app-${appId.name}'),
                      appId: appId,
                      size: tablet ? 62 : 52,
                      compact: !tablet,
                      autofocus: index == 0,
                      onTap: () => onOpen(appId),
                    ),
                  );
                },
                childCount: apps.length,
                addAutomaticKeepAlives: false,
              ),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: tablet ? 6 : 4,
                mainAxisExtent: tablet ? 126 : 112,
                crossAxisSpacing: tablet ? 10 : 4,
                mainAxisSpacing: tablet ? 12 : 4,
              ),
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: tablet ? 126 : 112)),
        ],
      ),
    );
  }
}

class _MobileNotesProfileButton extends StatelessWidget {
  const _MobileNotesProfileButton({
    required this.data,
    required this.tablet,
    required this.now,
    required this.onPressed,
  });

  final PortfolioData data;
  final bool tablet;
  final DateTime now;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final dark = AppleTheme.isDark(context);
    final widgetKey = tablet
        ? const Key('ipad-profile-widget')
        : const Key('iphone-notes-profile');
    final cardKey = tablet
        ? const Key('ipad-profile-card')
        : const Key('iphone-profile-card');
    final bodyForeground = dark
        ? const Color(0xFFF8F8FA)
        : const Color(0xFF242426);
    final secondaryForeground = dark
        ? const Color(0xFFC8C8CE)
        : const Color(0xFF515158);
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.4;
    final shortTablet = tablet && MediaQuery.sizeOf(context).height < 500;

    return AppleNotesSurface(
      key: widgetKey,
      cardKey: cardKey,
      headerKey: const Key('mobile-notes-profile-header'),
      bodyKey: const Key('mobile-notes-profile-body'),
      size: tablet
          ? AppleNotesSurfaceSize.regular
          : AppleNotesSurfaceSize.compact,
      darkPaper: dark,
      showSeparator: !shortTablet,
      showBody: !shortTablet,
      headerTitle: null,
      semanticLabel: '${data.name} 소개 열기',
      excludeSemantics: true,
      onTap: onPressed,
      headerTrailing: shortTablet
          ? Text(
              data.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: const Color(0xFF3A2700),
                fontWeight: FontWeight.w700,
              ),
            )
          : null,
      bodyPadding: EdgeInsets.all(largeText ? 10 : (tablet ? 18 : 14)),
      body: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  data.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: bodyForeground,
                    fontSize: tablet ? 23 : 20,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  data.identity.headline,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppleTheme.caption(
                    context,
                  ).copyWith(color: secondaryForeground, height: 1.3),
                ),
              ],
            ),
          ),
          if (!largeText) ...<Widget>[
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded, color: secondaryForeground),
          ],
        ],
      ),
    );
  }
}
