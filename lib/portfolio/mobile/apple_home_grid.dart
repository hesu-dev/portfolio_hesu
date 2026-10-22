import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/portfolio_data.dart';
import '../models/portfolio_app_id.dart';
import '../widgets/apple_app_artwork.dart';
import '../widgets/apple_app_icon.dart';

class AppleHomeGrid extends StatelessWidget {
  const AppleHomeGrid({
    required this.data,
    required this.tablet,
    required this.onOpen,
    this.trashEmpty = false,
    super.key,
  });

  static const List<PortfolioAppId> apps = portfolioMobileLauncherAppIds;

  final PortfolioData data;
  final bool tablet;
  final ValueChanged<PortfolioAppId> onOpen;
  final bool trashEmpty;

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = tablet ? 32.0 : 16.0;
    return KeyedSubtree(
      key: const Key('mobile-home-grid'),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          tablet ? 22 : 10,
          horizontalPadding,
          0,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final columns = tablet ? 6 : 4;
            final rows = (apps.length / columns).ceil();
            final gap = tablet ? 12.0 : 4.0;
            final rowHeight = math.min(
              tablet ? 126.0 : 112.0,
              (constraints.maxHeight - gap * (rows - 1)) / rows,
            );
            final labelHeight =
                MediaQuery.textScalerOf(context).scale(tablet ? 11.5 : 10.5) *
                1.6;
            final iconSize = math.min(
              tablet ? 62.0 : 52.0,
              math.max(24.0, rowHeight - labelHeight - (tablet ? 25 : 21)),
            );
            return Column(
              children: [
                for (var row = 0; row < rows; row++) ...[
                  if (row > 0) SizedBox(height: gap),
                  SizedBox(
                    height: rowHeight,
                    child: Row(
                      children: [
                        for (var column = 0; column < columns; column++)
                          Expanded(
                            child: row * columns + column >= apps.length
                                ? const SizedBox.shrink()
                                : Center(
                                    child: AppleAppIcon(
                                      key: Key(
                                        'home-app-${apps[row * columns + column].name}',
                                      ),
                                      appId: apps[row * columns + column],
                                      size: iconSize,
                                      compact: !tablet,
                                      autofocus: row == 0 && column == 0,
                                      artworkSurface:
                                          AppleAppArtworkSurface.mobile,
                                      trashEmpty: trashEmpty,
                                      onTap: () =>
                                          onOpen(apps[row * columns + column]),
                                    ),
                                  ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
