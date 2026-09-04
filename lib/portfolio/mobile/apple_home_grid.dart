import 'package:flutter/material.dart';

import '../data/portfolio_data.dart';
import '../models/portfolio_app_id.dart';
import '../widgets/apple_app_icon.dart';

class AppleHomeGrid extends StatelessWidget {
  const AppleHomeGrid({
    required this.data,
    required this.tablet,
    required this.onOpen,
    super.key,
  });

  static const List<PortfolioAppId> apps = portfolioMobileLauncherAppIds;

  final PortfolioData data;
  final bool tablet;
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
              0,
            ),
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
          SliverToBoxAdapter(child: SizedBox(height: tablet ? 28 : 20)),
        ],
      ),
    );
  }
}
