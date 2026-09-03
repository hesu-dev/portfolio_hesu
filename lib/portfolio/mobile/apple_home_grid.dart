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
    required this.onOpen,
    super.key,
  });

  static const List<PortfolioAppId> apps = portfolioLauncherAppIds;

  final PortfolioData data;
  final bool tablet;
  final ValueChanged<PortfolioAppId> onOpen;

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = tablet ? 32.0 : 16.0;
    final dockSafeInset = tablet ? 100.0 : 78.0;

    return KeyedSubtree(
      key: const Key('mobile-home-grid'),
      child: Padding(
        padding: EdgeInsets.only(bottom: dockSafeInset),
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
      ),
    );
  }
}

class _MobileNotesProfileButton extends StatelessWidget {
  const _MobileNotesProfileButton({
    required this.data,
    required this.tablet,
    required this.onPressed,
  });

  final PortfolioData data;
  final bool tablet;
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
    final profileLineStyle =
        (Theme.of(context).textTheme.titleMedium ?? const TextStyle()).copyWith(
          fontSize: tablet ? 18 : 17,
          fontWeight: FontWeight.w600,
          height: 1.2,
        );

    return AppleNotesSurface(
      key: widgetKey,
      cardKey: cardKey,
      headerKey: const Key('mobile-notes-profile-header'),
      bodyKey: const Key('mobile-notes-profile-body'),
      size: tablet && !shortTablet
          ? AppleNotesSurfaceSize.regular
          : AppleNotesSurfaceSize.compact,
      darkPaper: dark,
      showSeparator: !shortTablet,
      headerTitle: null,
      semanticLabel: '${data.name} 소개 열기',
      excludeSemantics: true,
      onTap: onPressed,
      bodyPadding: EdgeInsets.all(
        largeText ? (shortTablet ? 6 : 10) : (tablet ? 18 : 14),
      ),
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
                  style: profileLineStyle.copyWith(color: bodyForeground),
                ),
                const SizedBox(height: 3),
                Text(
                  data.identity.headline,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: profileLineStyle.copyWith(color: secondaryForeground),
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
