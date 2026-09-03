import 'package:flutter/material.dart';

import '../theme/apple_theme.dart';
import 'apple_selection_control.dart';

typedef AppleFinderBodyBuilder =
    Widget Function(BuildContext context, bool compactLayout);

/// Optional desktop-window chrome embedded into a Finder toolbar.
///
/// Mobile surfaces omit this value and retain their own navigation chrome.
@immutable
class AppleFinderWindowChrome {
  const AppleFinderWindowChrome({
    required this.leadingControls,
    required this.onDragUpdate,
    this.onDragStart,
    this.cursor = SystemMouseCursors.move,
  });

  final Widget leadingControls;
  final GestureDragStartCallback? onDragStart;
  final GestureDragUpdateCallback onDragUpdate;
  final MouseCursor cursor;
}

/// Shared Finder chrome for portfolio apps that browse folder-like content.
///
/// App-specific selection, history, and detail state stay with each app. This
/// widget owns the toolbar, sidebar/location strip, and responsive split so
/// their spacing, colors, and view affordance remain consistent.
class AppleFinderScaffold extends StatelessWidget {
  const AppleFinderScaffold({
    required this.surfaceKey,
    required this.keyPrefix,
    required this.currentLocation,
    required this.ownerName,
    required this.compact,
    required this.tablet,
    required this.canGoBack,
    required this.canGoForward,
    required this.onBack,
    required this.onForward,
    required this.bodyBuilder,
    this.backTooltip = '뒤로',
    this.forwardTooltip = '앞으로',
    this.windowChrome,
    this.onViewPressed,
    super.key,
  });

  final Key surfaceKey;
  final String keyPrefix;
  final String currentLocation;
  final String ownerName;
  final bool compact;
  final bool tablet;
  final bool canGoBack;
  final bool canGoForward;
  final VoidCallback onBack;
  final VoidCallback onForward;
  final AppleFinderBodyBuilder bodyBuilder;
  final String backTooltip;
  final String forwardTooltip;
  final AppleFinderWindowChrome? windowChrome;
  final VoidCallback? onViewPressed;

  @override
  Widget build(BuildContext context) {
    return AppleAppSurface(
      key: surfaceKey,
      child: Column(
        children: <Widget>[
          AppleFinderToolbar(
            key: Key('$keyPrefix-finder-toolbar'),
            currentLocation: currentLocation,
            compact: compact,
            canGoBack: canGoBack,
            canGoForward: canGoForward,
            onBack: onBack,
            onForward: onForward,
            backTooltip: backTooltip,
            forwardTooltip: forwardTooltip,
            controlKeyPrefix: '$keyPrefix-finder',
            leadingControls: windowChrome?.leadingControls,
            onDragStart: windowChrome?.onDragStart,
            onDragUpdate: windowChrome?.onDragUpdate,
            dragCursor: windowChrome?.cursor,
            onViewPressed: onViewPressed,
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = !compact && constraints.maxWidth >= 700;
                if (wide) {
                  return Row(
                    children: <Widget>[
                      SizedBox(
                        width: tablet ? 224 : 252,
                        child: AppleFinderSidebar(
                          key: Key('$keyPrefix-finder-sidebar'),
                          ownerName: ownerName,
                          selectedLocation: currentLocation,
                        ),
                      ),
                      Expanded(child: bodyBuilder(context, false)),
                    ],
                  );
                }

                return Column(
                  children: <Widget>[
                    AppleFinderLocationStrip(
                      key: Key('$keyPrefix-finder-locations'),
                      ownerName: ownerName,
                      selectedLocation: currentLocation,
                    ),
                    Expanded(child: bodyBuilder(context, true)),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AppleFinderToolbar extends StatelessWidget {
  const AppleFinderToolbar({
    required this.currentLocation,
    required this.compact,
    required this.canGoBack,
    required this.canGoForward,
    required this.onBack,
    required this.onForward,
    this.backTooltip = '뒤로',
    this.forwardTooltip = '앞으로',
    this.controlKeyPrefix = 'finder',
    this.leadingControls,
    this.onDragStart,
    this.onDragUpdate,
    this.dragCursor,
    this.onViewPressed,
    super.key,
  });

  final String currentLocation;
  final bool compact;
  final bool canGoBack;
  final bool canGoForward;
  final VoidCallback onBack;
  final VoidCallback onForward;
  final String backTooltip;
  final String forwardTooltip;
  final String controlKeyPrefix;
  final Widget? leadingControls;
  final GestureDragStartCallback? onDragStart;
  final GestureDragUpdateCallback? onDragUpdate;
  final MouseCursor? dragCursor;
  final VoidCallback? onViewPressed;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: dragCursor ?? MouseCursor.defer,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanStart: onDragStart,
        onPanUpdate: onDragUpdate,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppleTheme.surface(context),
            border: Border(
              bottom: BorderSide(
                color: AppleTheme.separator(context),
                width: 0.7,
              ),
            ),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: compact ? 56 : 62),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 8 : 14,
                vertical: 5,
              ),
              child: Row(
                children: <Widget>[
                  if (leadingControls != null) ...<Widget>[
                    leadingControls!,
                    SizedBox(width: compact ? 4 : 10),
                  ],
                  IconButton(
                    key: Key('$controlKeyPrefix-back'),
                    tooltip: backTooltip,
                    onPressed: canGoBack ? onBack : null,
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  IconButton(
                    key: Key('$controlKeyPrefix-forward'),
                    tooltip: forwardTooltip,
                    onPressed: canGoForward ? onForward : null,
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                  SizedBox(width: compact ? 3 : 10),
                  Expanded(
                    child: Container(
                      key: Key('$controlKeyPrefix-current-location'),
                      alignment: Alignment.center,
                      constraints: const BoxConstraints(minHeight: 38),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        currentLocation,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ),
                  SizedBox(width: compact ? 4 : 8),
                  IconButton(
                    key: Key('$controlKeyPrefix-view-options'),
                    tooltip: '보기 방식',
                    onPressed: onViewPressed,
                    icon: Icon(
                      Icons.grid_view_rounded,
                      color: AppleTheme.secondaryLabel(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AppleFinderSidebar extends StatelessWidget {
  const AppleFinderSidebar({
    required this.ownerName,
    required this.selectedLocation,
    super.key,
  });

  final String ownerName;
  final String selectedLocation;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppleTheme.panel(context),
        border: Border(
          right: BorderSide(color: AppleTheme.separator(context), width: 0.7),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(10, 12, 10, 18),
        children: <Widget>[
          const _AppleFinderSidebarItem(
            label: '최근 항목',
            icon: Icons.access_time_filled_rounded,
          ),
          const _AppleFinderSidebarItem(
            label: '공유',
            icon: Icons.people_alt_rounded,
          ),
          const SizedBox(height: 12),
          const _AppleFinderSidebarHeading(label: '위치'),
          _AppleFinderSidebarItem(
            label: selectedLocation,
            icon: selectedLocation == 'iCloud Drive'
                ? Icons.cloud_rounded
                : Icons.folder_copy_rounded,
            selected: true,
          ),
          _AppleFinderSidebarItem(label: ownerName, icon: Icons.home_rounded),
        ],
      ),
    );
  }
}

class AppleFinderLocationStrip extends StatelessWidget {
  const AppleFinderLocationStrip({
    required this.ownerName,
    required this.selectedLocation,
    super.key,
  });

  final String ownerName;
  final String selectedLocation;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppleTheme.panel(context),
        border: Border(
          bottom: BorderSide(color: AppleTheme.separator(context), width: 0.7),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Row(
          children: <Widget>[
            const _AppleFinderLocationChip(label: '최근 항목'),
            const _AppleFinderLocationChip(label: '공유'),
            _AppleFinderLocationChip(label: selectedLocation, selected: true),
            _AppleFinderLocationChip(label: ownerName),
          ],
        ),
      ),
    );
  }
}

class AppleFinderFolderTile extends StatelessWidget {
  const AppleFinderFolderTile({
    required this.label,
    required this.semanticsLabel,
    required this.compact,
    required this.onPressed,
    this.selected = false,
    super.key,
  });

  final String label;
  final String semanticsLabel;
  final bool compact;
  final VoidCallback onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AppleSelectionControl(
      semanticsLabel: semanticsLabel,
      selected: selected,
      onPressed: onPressed,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        constraints: const BoxConstraints(minHeight: 126),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10,
          vertical: compact ? 10 : 12,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppleTheme.selectionBackground(context, AppleTheme.blue)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              selected ? Icons.folder_open_rounded : Icons.folder_rounded,
              size: compact ? 50 : 58,
              color: selected ? AppleTheme.blue : const Color(0xFF55B8F5),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: selected
                    ? AppleTheme.selectionForeground(context)
                    : AppleTheme.primaryLabel(context),
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppleFinderSidebarHeading extends StatelessWidget {
  const _AppleFinderSidebarHeading({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(11, 4, 11, 5),
      child: Text(
        label,
        style: AppleTheme.caption(
          context,
        ).copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _AppleFinderSidebarItem extends StatelessWidget {
  const _AppleFinderSidebarItem({
    required this.label,
    required this.icon,
    this.selected = false,
  });

  final String label;
  final IconData icon;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: selected
            ? AppleTheme.selectionBackground(context, AppleTheme.blue)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 18, color: AppleTheme.blue),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: selected
                    ? AppleTheme.selectionForeground(context)
                    : AppleTheme.primaryLabel(context),
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppleFinderLocationChip extends StatelessWidget {
  const _AppleFinderLocationChip({required this.label, this.selected = false});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: selected
            ? AppleTheme.selectionBackground(context, AppleTheme.blue)
            : AppleTheme.surface(context),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppleTheme.separator(context)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: selected
              ? AppleTheme.selectionForeground(context)
              : AppleTheme.primaryLabel(context),
        ),
      ),
    );
  }
}
