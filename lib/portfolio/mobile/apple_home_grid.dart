import 'package:flutter/material.dart';

import '../data/portfolio_data.dart';
import '../models/portfolio_app_id.dart';
import '../theme/apple_theme.dart';
import '../widgets/apple_app_icon.dart';

class AppleHomeGrid extends StatelessWidget {
  const AppleHomeGrid({
    required this.data,
    required this.tablet,
    required this.onOpen,
    super.key,
  });

  static const List<PortfolioAppId> apps = PortfolioAppId.values;

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
              tablet ? 24 : 16,
            ),
            sliver: SliverToBoxAdapter(
              child: tablet
                  ? _IPadProfileWidget(data: data)
                  : _IPhoneIdentityHeader(data: data),
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

class _IPhoneIdentityHeader extends StatelessWidget {
  const _IPhoneIdentityHeader({required this.data});

  final PortfolioData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            data.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontSize: 28,
              letterSpacing: -0.7,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            data.identity.headline,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppleTheme.caption(context).copyWith(
              color: AppleTheme.primaryLabel(context).withValues(alpha: 0.72),
            ),
          ),
        ],
      ),
    );
  }
}

class _IPadProfileWidget extends StatelessWidget {
  const _IPadProfileWidget({required this.data});

  final PortfolioData data;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dark = AppleTheme.isDark(context);
    final date =
        '${_weekdays[now.weekday - 1]}, ${_months[now.month - 1]} '
        '${now.day}';

    return Semantics(
      key: const Key('ipad-profile-widget'),
      container: true,
      label: '${data.name} portfolio profile',
      child: Container(
        key: const Key('ipad-profile-card'),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: dark
                ? const <Color>[Color(0xF2292C36), Color(0xF21B2433)]
                : <Color>[
                    Colors.white.withValues(alpha: 0.72),
                    const Color(0xFFE9F2FF).withValues(alpha: 0.64),
                  ],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: Colors.white.withValues(alpha: dark ? 0.18 : 0.72),
            width: 0.9,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: dark
                  ? Colors.black.withValues(alpha: 0.34)
                  : const Color(0xFF385A90).withValues(alpha: 0.12),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[Color(0xFF75D6FF), Color(0xFF416AF4)],
                ),
                borderRadius: BorderRadius.circular(23),
              ),
              alignment: Alignment.center,
              child: Text(
                data.monogram,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    date,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppleTheme.caption(context).copyWith(
                      color: dark ? const Color(0xFF73B5FF) : AppleTheme.blue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    data.identity.headline,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppleTheme.caption(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const List<String> _weekdays = <String>[
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

const List<String> _months = <String>[
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];
