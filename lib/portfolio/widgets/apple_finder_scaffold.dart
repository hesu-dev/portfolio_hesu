import 'package:flutter/material.dart';

import '../theme/apple_theme.dart';
import 'apple_selection_control.dart';

typedef AppleFinderBodyBuilder =
    Widget Function(BuildContext context, bool compactLayout);
typedef AppleFinderMobileLeadingControlsBuilder =
    Widget Function(bool canGoBack, VoidCallback onBack);

@immutable
class AppleFinderLocation {
  const AppleFinderLocation({
    required this.id,
    required this.label,
    required this.icon,
  });

  final String id;
  final String label;
  final IconData icon;
}

@immutable
class AppleFinderMobileDestination {
  const AppleFinderMobileDestination({
    required this.id,
    required this.label,
    required this.icon,
  });

  final String id;
  final String label;
  final IconData icon;
}

/// Optional desktop-window chrome embedded into a Finder toolbar.
///
/// Projects supplies this value on every form factor so one Finder toolbar owns
/// the traffic controls, navigation, title, and view affordance.
@immutable
class AppleFinderWindowChrome {
  const AppleFinderWindowChrome({
    required this.leadingControls,
    required this.onDragUpdate,
    this.onDragStart,
    this.cursor = SystemMouseCursors.move,
    this.mobileLeadingControlsBuilder,
  });

  final Widget leadingControls;
  final GestureDragStartCallback? onDragStart;
  final GestureDragUpdateCallback onDragUpdate;
  final MouseCursor cursor;
  final AppleFinderMobileLeadingControlsBuilder? mobileLeadingControlsBuilder;
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
    this.locations,
    this.recentLocation,
    this.selectedLocationId,
    this.onLocationSelected,
    this.toolbarTitle,
    this.backTooltip = '뒤로',
    this.forwardTooltip = '앞으로',
    this.windowChrome,
    this.mobileBottomNavigation,
    this.onViewPressed,
    super.key,
  }) : assert(locations == null || selectedLocationId != null);

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
  final List<AppleFinderLocation>? locations;
  final AppleFinderLocation? recentLocation;
  final String? selectedLocationId;
  final ValueChanged<String>? onLocationSelected;
  final String? toolbarTitle;
  final String backTooltip;
  final String forwardTooltip;
  final AppleFinderWindowChrome? windowChrome;
  final Widget? mobileBottomNavigation;
  final VoidCallback? onViewPressed;

  @override
  Widget build(BuildContext context) {
    final mobileLayout = mobileBottomNavigation != null;
    final leadingControls = mobileLayout
        ? windowChrome?.mobileLeadingControlsBuilder?.call(canGoBack, onBack) ??
              windowChrome?.leadingControls
        : windowChrome?.leadingControls;
    return AppleAppSurface(
      key: surfaceKey,
      child: Column(
        children: <Widget>[
          AppleFinderToolbar(
            key: Key('$keyPrefix-finder-toolbar'),
            currentLocation: toolbarTitle ?? currentLocation,
            compact: compact,
            canGoBack: canGoBack,
            canGoForward: canGoForward,
            onBack: onBack,
            onForward: onForward,
            backTooltip: backTooltip,
            forwardTooltip: forwardTooltip,
            controlKeyPrefix: '$keyPrefix-finder',
            leadingControls: leadingControls,
            onDragStart: windowChrome?.onDragStart,
            onDragUpdate: windowChrome?.onDragUpdate,
            dragCursor: windowChrome?.cursor,
            onViewPressed: onViewPressed,
            mobile: mobileLayout,
          ),
          Expanded(
            child: mobileLayout
                ? bodyBuilder(context, compact)
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final wide =
                          !compact && (tablet || constraints.maxWidth >= 700);
                      if (wide) {
                        return Row(
                          children: <Widget>[
                            SizedBox(
                              width: tablet ? 176 : 252,
                              child: AppleFinderSidebar(
                                key: Key('$keyPrefix-finder-sidebar'),
                                ownerName: ownerName,
                                selectedLocation: currentLocation,
                                locations: locations,
                                recentLocation: recentLocation,
                                selectedLocationId: selectedLocationId,
                                onLocationSelected: onLocationSelected,
                                controlKeyPrefix: '$keyPrefix-finder',
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
                            locations: locations,
                            recentLocation: recentLocation,
                            selectedLocationId: selectedLocationId,
                            onLocationSelected: onLocationSelected,
                            controlKeyPrefix: '$keyPrefix-finder',
                          ),
                          Expanded(child: bodyBuilder(context, true)),
                        ],
                      );
                    },
                  ),
          ),
          if (mobileBottomNavigation case final navigation?) navigation,
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
    this.mobile = false,
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
  final bool mobile;

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
          child: mobile
              ? _MobileFinderToolbarContent(
                  currentLocation: currentLocation,
                  controlKeyPrefix: controlKeyPrefix,
                  leadingControls: leadingControls,
                )
              : ConstrainedBox(
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

class _MobileFinderToolbarContent extends StatelessWidget {
  const _MobileFinderToolbarContent({
    required this.currentLocation,
    required this.controlKeyPrefix,
    required this.leadingControls,
  });

  final String currentLocation;
  final String controlKeyPrefix;
  final Widget? leadingControls;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          PositionedDirectional(
            start: 8,
            child: leadingControls ?? const SizedBox.square(dimension: 44),
          ),
          Positioned.fill(
            left: 62,
            right: 62,
            child: Container(
              key: Key('$controlKeyPrefix-current-location'),
              alignment: Alignment.center,
              child: Text(
                currentLocation,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          PositionedDirectional(
            end: 8,
            child: IgnorePointer(
              child: ExcludeSemantics(
                child: SizedBox.square(
                  key: Key('$controlKeyPrefix-more'),
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
        ],
      ),
    );
  }
}

class AppleFinderMobileNavigationBar extends StatelessWidget {
  const AppleFinderMobileNavigationBar({
    required this.keyPrefix,
    required this.destinations,
    required this.selectedId,
    required this.onSelected,
    super.key,
  });

  final String keyPrefix;
  final List<AppleFinderMobileDestination> destinations;
  final String selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Container(
            key: Key('$keyPrefix-mobile-dock'),
            constraints: const BoxConstraints(minHeight: 66),
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: AppleTheme.surface(context).withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: AppleTheme.separator(context),
                width: 0.8,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppleTheme.subtleShadow(context),
                  blurRadius: 18,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Row(
              children: <Widget>[
                for (final destination in destinations)
                  Expanded(
                    child: _MobileFinderDestinationButton(
                      controlKey: Key('$keyPrefix-location-${destination.id}'),
                      destination: destination,
                      selected: destination.id == selectedId,
                      onPressed: () => onSelected(destination.id),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileFinderDestinationButton extends StatelessWidget {
  const _MobileFinderDestinationButton({
    required this.controlKey,
    required this.destination,
    required this.selected,
    required this.onPressed,
  });

  final Key controlKey;
  final AppleFinderMobileDestination destination;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final foreground = selected
        ? AppleTheme.blue
        : AppleTheme.secondaryLabel(context);
    return AppleSelectionControl(
      key: controlKey,
      semanticsLabel: 'Open ${destination.label}',
      selected: selected,
      onPressed: onPressed,
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        width: double.infinity,
        child: Container(
          constraints: const BoxConstraints(minHeight: 54),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? AppleTheme.selectionBackground(context, AppleTheme.blue)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(destination.icon, color: foreground, size: 22),
              const SizedBox(height: 3),
              Text(
                destination.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: foreground,
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ],
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
    this.locations,
    this.recentLocation,
    this.selectedLocationId,
    this.onLocationSelected,
    this.controlKeyPrefix = 'finder',
    super.key,
  }) : assert(locations == null || selectedLocationId != null);

  final String ownerName;
  final String selectedLocation;
  final List<AppleFinderLocation>? locations;
  final AppleFinderLocation? recentLocation;
  final String? selectedLocationId;
  final ValueChanged<String>? onLocationSelected;
  final String controlKeyPrefix;

  @override
  Widget build(BuildContext context) {
    final configuredLocations = locations;
    final recentItem = _AppleFinderSidebarItem(
      controlKey: recentLocation == null
          ? null
          : Key('$controlKeyPrefix-location-${recentLocation!.id}'),
      label: recentLocation?.label ?? '최근 항목',
      icon: recentLocation?.icon ?? Icons.access_time_filled_rounded,
      selected: recentLocation?.id == selectedLocationId,
      onPressed: recentLocation == null || onLocationSelected == null
          ? null
          : () => onLocationSelected!(recentLocation!.id),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppleTheme.panel(context),
        border: Border(
          right: BorderSide(color: AppleTheme.separator(context), width: 0.7),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(10, 12, 10, 18),
        children: configuredLocations == null
            ? <Widget>[
                recentItem,
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
                _AppleFinderSidebarItem(
                  label: ownerName,
                  icon: Icons.home_rounded,
                ),
              ]
            : <Widget>[
                recentItem,
                const _AppleFinderSidebarItem(
                  label: '공유',
                  icon: Icons.people_alt_rounded,
                ),
                const SizedBox(height: 12),
                const _AppleFinderSidebarHeading(label: '위치'),
                for (final location in configuredLocations)
                  _AppleFinderSidebarItem(
                    controlKey: Key(
                      '$controlKeyPrefix-location-${location.id}',
                    ),
                    label: location.label,
                    icon: location.icon,
                    selected: location.id == selectedLocationId,
                    onPressed: onLocationSelected == null
                        ? null
                        : () => onLocationSelected!(location.id),
                  ),
              ],
      ),
    );
  }
}

class AppleFinderLocationStrip extends StatefulWidget {
  const AppleFinderLocationStrip({
    required this.ownerName,
    required this.selectedLocation,
    this.locations,
    this.recentLocation,
    this.selectedLocationId,
    this.onLocationSelected,
    this.controlKeyPrefix = 'finder',
    super.key,
  }) : assert(locations == null || selectedLocationId != null);

  final String ownerName;
  final String selectedLocation;
  final List<AppleFinderLocation>? locations;
  final AppleFinderLocation? recentLocation;
  final String? selectedLocationId;
  final ValueChanged<String>? onLocationSelected;
  final String controlKeyPrefix;

  @override
  State<AppleFinderLocationStrip> createState() =>
      _AppleFinderLocationStripState();
}

class _AppleFinderLocationStripState extends State<AppleFinderLocationStrip> {
  final Map<String, GlobalKey> _locationAnchors = <String, GlobalKey>{};

  @override
  void initState() {
    super.initState();
    _scheduleSelectedLocationReveal();
  }

  @override
  void didUpdateWidget(covariant AppleFinderLocationStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedLocation != widget.selectedLocation ||
        oldWidget.selectedLocationId != widget.selectedLocationId ||
        !identical(oldWidget.locations, widget.locations)) {
      _scheduleSelectedLocationReveal();
    }
  }

  GlobalKey _anchorFor(String locationId) {
    return _locationAnchors.putIfAbsent(locationId, GlobalKey.new);
  }

  void _scheduleSelectedLocationReveal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final locations = widget.locations;
      if (locations == null) {
        return;
      }
      final selectedId = widget.selectedLocationId;
      final anchorContext = selectedId == null
          ? null
          : _locationAnchors[selectedId]?.currentContext;
      if (anchorContext == null) {
        return;
      }
      Scrollable.ensureVisible(
        anchorContext,
        alignment: 0.5,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final configuredLocations = widget.locations;
    final recentItem = _AppleFinderLocationChip(
      controlKey: widget.recentLocation == null
          ? null
          : Key(
              '${widget.controlKeyPrefix}-location-${widget.recentLocation!.id}',
            ),
      label: widget.recentLocation?.label ?? '최근 항목',
      selected: widget.recentLocation?.id == widget.selectedLocationId,
      onPressed:
          widget.recentLocation == null || widget.onLocationSelected == null
          ? null
          : () => widget.onLocationSelected!(widget.recentLocation!.id),
    );
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
          children: configuredLocations == null
              ? <Widget>[
                  recentItem,
                  const _AppleFinderLocationChip(label: '공유'),
                  _AppleFinderLocationChip(
                    label: widget.selectedLocation,
                    selected: true,
                  ),
                  _AppleFinderLocationChip(label: widget.ownerName),
                ]
              : <Widget>[
                  recentItem,
                  const _AppleFinderLocationChip(label: '공유'),
                  for (final location in configuredLocations)
                    _AppleFinderLocationChip(
                      visibilityKey: _anchorFor(location.id),
                      controlKey: Key(
                        '${widget.controlKeyPrefix}-location-${location.id}',
                      ),
                      label: location.label,
                      selected: location.id == widget.selectedLocationId,
                      onPressed: widget.onLocationSelected == null
                          ? null
                          : () => widget.onLocationSelected!(location.id),
                    ),
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
    final tileHeight = compact ? 154.0 : 166.0;
    final folderSize = compact ? 50.0 : 58.0;
    final selectedArtworkColor = AppleTheme.isDark(context)
        ? const Color(0xFF3A3A3A)
        : const Color(0xFFE2E2E2);

    return AppleSelectionControl(
      semanticsLabel: semanticsLabel,
      selected: selected,
      onPressed: onPressed,
      borderRadius: BorderRadius.circular(14),
      overlayColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
      child: AnimatedContainer(
        key: const Key('apple-finder-folder-container'),
        duration: const Duration(milliseconds: 160),
        height: tileHeight,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10,
          vertical: compact ? 10 : 12,
        ),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            AnimatedContainer(
              key: const Key('apple-finder-folder-artwork-background'),
              duration: const Duration(milliseconds: 160),
              width: folderSize + 14,
              height: folderSize + 8,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? selectedArtworkColor : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.folder_rounded,
                key: const Key('apple-finder-folder-artwork'),
                size: folderSize,
                color: const Color(0xFF55B8F5),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 64,
              child: Align(
                alignment: Alignment.topCenter,
                child: DecoratedBox(
                  key: const Key('apple-finder-folder-label-background'),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    child: Text(
                      label,
                      key: const Key('apple-finder-folder-label'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppleTheme.primaryLabel(context),
                        fontWeight: FontWeight.w500,
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
    this.controlKey,
    this.selected = false,
    this.onPressed,
  });

  final String label;
  final IconData icon;
  final Key? controlKey;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final content = Container(
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

    final action = onPressed;
    if (action == null) {
      return content;
    }
    return AppleSelectionControl(
      key: controlKey,
      semanticsLabel: '$label 위치 열기',
      selected: selected,
      onPressed: action,
      borderRadius: BorderRadius.circular(9),
      child: content,
    );
  }
}

class _AppleFinderLocationChip extends StatelessWidget {
  const _AppleFinderLocationChip({
    required this.label,
    this.controlKey,
    this.visibilityKey,
    this.selected = false,
    this.onPressed,
  });

  final String label;
  final Key? controlKey;
  final Key? visibilityKey;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      key: visibilityKey,
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

    final action = onPressed;
    if (action == null) {
      return content;
    }
    return AppleSelectionControl(
      key: controlKey,
      semanticsLabel: '$label 위치 열기',
      selected: selected,
      onPressed: action,
      borderRadius: BorderRadius.circular(999),
      child: content,
    );
  }
}
