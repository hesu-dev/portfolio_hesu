import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/portfolio_app_id.dart';
import '../theme/apple_theme.dart';
import '../widgets/apple_app_icon.dart';
import 'mac_window_state.dart';

enum MacSystemPanel { none, systemMenu, controlCenter, notifications }

Color _menuForeground(BuildContext context) => AppleTheme.isDark(context)
    ? AppleTheme.primaryLabel(context)
    : const Color(0xFF17171B);

Color _menuSelection(BuildContext context) => AppleTheme.isDark(context)
    ? Colors.white.withValues(alpha: 0.14)
    : Colors.black.withValues(alpha: 0.09);

class MacMenuBar extends StatefulWidget {
  const MacMenuBar({
    required this.activeApp,
    required this.openPanel,
    required this.onSystemMenuPressed,
    required this.onControlCenterPressed,
    required this.onClockPressed,
    super.key,
  });

  final PortfolioAppId? activeApp;
  final MacSystemPanel openPanel;
  final VoidCallback onSystemMenuPressed;
  final VoidCallback onControlCenterPressed;
  final VoidCallback onClockPressed;

  @override
  State<MacMenuBar> createState() => _MacMenuBarState();
}

class _MacMenuBarState extends State<MacMenuBar> {
  late DateTime _now;
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      final next = DateTime.now();
      if (next.minute != _now.minute || next.day != _now.day) {
        setState(() => _now = next);
      }
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = AppleTheme.isDark(context);
    final activeName = widget.activeApp == null
        ? 'Finder'
        : AppleAppIcon.labelFor(widget.activeApp!);
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    const notchWidth = 176.0;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: DecoratedBox(
          key: const Key('mac-menu-bar-surface'),
          decoration: BoxDecoration(
            color: dark
                ? const Color(0xFF17171B).withValues(alpha: 0.74)
                : Colors.white.withValues(alpha: 0.66),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withValues(alpha: dark ? 0.14 : 0.48),
                width: 0.6,
              ),
            ),
          ),
          child: SizedBox(
            height: MacDesktopMetrics.menuBarHeight,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final sideWidth = (constraints.maxWidth - notchWidth) / 2;
                final visibleMenuLabels = textScale > 1.25
                    ? 0
                    : constraints.maxWidth < 1100
                    ? 3
                    : 5;
                final compactClock =
                    textScale > 1.25 || constraints.maxWidth < 1100;

                return Stack(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        SizedBox(
                          key: const Key('mac-menu-left-region'),
                          width: sideWidth,
                          child: _buildLeftRegion(
                            context,
                            activeName,
                            visibleMenuLabels: visibleMenuLabels,
                            largeText: textScale > 1.25,
                          ),
                        ),
                        const SizedBox(width: notchWidth),
                        SizedBox(
                          key: const Key('mac-menu-right-region'),
                          width: sideWidth,
                          child: _buildRightRegion(
                            context,
                            compactClock: compactClock,
                          ),
                        ),
                      ],
                    ),
                    const Align(
                      alignment: Alignment.topCenter,
                      child: ExcludeSemantics(child: _MacDisplayNotch()),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeftRegion(
    BuildContext context,
    String activeName, {
    required int visibleMenuLabels,
    required bool largeText,
  }) {
    const labels = <String>['File', 'Edit', 'View', 'Window', 'Help'];
    return Row(
      children: <Widget>[
        const SizedBox(width: 9),
        _SystemMenuButton(
          selected: widget.openPanel == MacSystemPanel.systemMenu,
          onPressed: widget.onSystemMenuPressed,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: largeText ? 190 : 110),
            child: Text(
              activeName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _menuForeground(context),
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.15,
              ),
            ),
          ),
        ),
        const SizedBox(width: 5),
        for (final label in labels.take(visibleMenuLabels))
          _MenuLabel(label: label),
      ],
    );
  }

  Widget _buildRightRegion(BuildContext context, {required bool compactClock}) {
    final foreground = _menuForeground(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        Tooltip(
          message: 'Wi-Fi status',
          child: Semantics(
            label: 'Wi-Fi status',
            child: Padding(
              key: const Key('mac-wifi-status'),
              padding: const EdgeInsets.symmetric(horizontal: 7),
              child: Icon(Icons.wifi_rounded, size: 16, color: foreground),
            ),
          ),
        ),
        Tooltip(
          message: 'Battery status',
          child: Semantics(
            label: 'Battery status',
            child: Padding(
              key: const Key('mac-battery-status'),
              padding: const EdgeInsets.symmetric(horizontal: 7),
              child: Icon(
                Icons.battery_5_bar_rounded,
                size: 18,
                color: foreground,
              ),
            ),
          ),
        ),
        _MenuIconButton(
          buttonKey: const Key('mac-control-center-button'),
          tooltip: 'Control Center',
          selected: widget.openPanel == MacSystemPanel.controlCenter,
          icon: Icons.tune_rounded,
          onPressed: widget.onControlCenterPressed,
        ),
        _ClockButton(
          now: _now,
          selected: widget.openPanel == MacSystemPanel.notifications,
          compact: compactClock,
          onPressed: widget.onClockPressed,
        ),
        const SizedBox(width: 7),
      ],
    );
  }
}

class _MacDisplayNotch extends StatelessWidget {
  const _MacDisplayNotch();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('mac-display-notch'),
      width: 176,
      height: 30,
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(11),
          bottomRight: Radius.circular(11),
        ),
      ),
    );
  }
}

class _SystemMenuButton extends StatefulWidget {
  const _SystemMenuButton({required this.selected, required this.onPressed});

  final bool selected;
  final VoidCallback onPressed;

  @override
  State<_SystemMenuButton> createState() => _SystemMenuButtonState();
}

class _SystemMenuButtonState extends State<_SystemMenuButton> {
  final FocusNode _focusNode = FocusNode(debugLabel: 'mac-system-menu');
  bool _showFocus = false;

  @override
  void didUpdateWidget(covariant _SystemMenuButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected && !oldWidget.selected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _focusNode.requestFocus();
        }
      });
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: const Key('mac-system-menu-button'),
      label: 'Open system menu',
      button: true,
      expanded: widget.selected,
      onTap: widget.onPressed,
      child: Focus(
        focusNode: _focusNode,
        onFocusChange: (value) {
          if (_showFocus != value) {
            setState(() => _showFocus = value);
          }
        },
        onKeyEvent: (_, event) {
          if (event is KeyDownEvent &&
              (event.logicalKey == LogicalKeyboardKey.enter ||
                  event.logicalKey == LogicalKeyboardKey.space)) {
            widget.onPressed();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: ExcludeSemantics(
            child: Tooltip(
              message: 'System menu',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  _focusNode.requestFocus();
                  widget.onPressed();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  width: 28,
                  height: 26,
                  decoration: BoxDecoration(
                    color: widget.selected
                        ? _menuSelection(context)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(7),
                    border: _showFocus
                        ? Border.all(color: const Color(0xFF0A84FF), width: 1.5)
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: CustomPaint(
                    key: const Key('mac-system-icon'),
                    size: const Size(16, 16),
                    painter: _SystemMarkPainter(
                      color: _menuForeground(context),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SystemMarkPainter extends CustomPainter {
  const _SystemMarkPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final center = size.center(Offset.zero);
    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(center.dx - 3.1, center.dy + 1.8),
            width: 6.2,
            height: 9.4,
          ),
          const Radius.circular(3.2),
        ),
        paint,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(center.dx + 3.1, center.dy + 1.8),
            width: 6.2,
            height: 9.4,
          ),
          const Radius.circular(3.2),
        ),
        paint,
      )
      ..save()
      ..translate(center.dx + 2.4, center.dy - 5.2)
      ..rotate(-0.45)
      ..drawOval(const Rect.fromLTWH(-1.6, -2.7, 3.2, 5.4), paint)
      ..restore();
  }

  @override
  bool shouldRepaint(covariant _SystemMarkPainter oldDelegate) =>
      color != oldDelegate.color;
}

class _MenuLabel extends StatelessWidget {
  const _MenuLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        label,
        style: TextStyle(
          color: AppleTheme.isDark(context)
              ? AppleTheme.primaryLabel(context)
              : const Color(0xFF202024),
          fontSize: 12.5,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _MenuIconButton extends StatelessWidget {
  const _MenuIconButton({
    required this.buttonKey,
    required this.tooltip,
    required this.selected,
    required this.icon,
    required this.onPressed,
  });

  final Key buttonKey;
  final String tooltip;
  final bool selected;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: buttonKey,
      tooltip: tooltip,
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(width: 30, height: 28),
      padding: EdgeInsets.zero,
      style: IconButton.styleFrom(
        backgroundColor: selected
            ? _menuSelection(context)
            : Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
      ),
      icon: Icon(icon, size: 17, color: _menuForeground(context)),
    );
  }
}

class _ClockButton extends StatelessWidget {
  const _ClockButton({
    required this.now,
    required this.selected,
    required this.compact,
    required this.onPressed,
  });

  final DateTime now;
  final bool selected;
  final bool compact;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      key: const Key('mac-clock-button'),
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: _menuForeground(context),
        backgroundColor: selected
            ? _menuSelection(context)
            : Colors.transparent,
        minimumSize: Size(compact ? 74 : 118, 28),
        maximumSize: Size(compact ? 88 : 132, 28),
        padding: const EdgeInsets.symmetric(horizontal: 7),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
        textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
      ),
      child: Text(
        compact ? _largeTime(now) : _menuTime(now),
        maxLines: 1,
        overflow: TextOverflow.clip,
      ),
    );
  }
}

class MacControlCenterPanel extends StatelessWidget {
  const MacControlCenterPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return _MacSystemPanelSurface(
      panelKey: const Key('mac-control-center-panel'),
      surfaceKey: const Key('mac-control-center-panel-surface'),
      width: 316,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Control Center',
            key: const Key('mac-control-center-title'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppleTheme.primaryLabel(context),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          const Row(
            children: <Widget>[
              Expanded(
                child: _ControlTile(
                  tileKey: Key('mac-control-center-wifi'),
                  icon: Icons.wifi_rounded,
                  title: 'Wi-Fi',
                  subtitle: 'Network controls',
                  color: Color(0xFF0A84FF),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _ControlTile(
                  tileKey: Key('mac-control-center-bluetooth'),
                  icon: Icons.bluetooth_rounded,
                  title: 'Bluetooth',
                  subtitle: 'Device controls',
                  color: Color(0xFF0A84FF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const _ControlTile(
            tileKey: Key('mac-control-center-display'),
            icon: Icons.dark_mode_rounded,
            title: 'Display',
            subtitle: 'Appearance follows your system',
            color: Color(0xFF5E5CE6),
          ),
        ],
      ),
    );
  }
}

class MacSystemMenuPanel extends StatelessWidget {
  const MacSystemMenuPanel({
    required this.identityName,
    required this.onOpenAbout,
    required this.onOpenThisMac,
    super.key,
  });

  final String identityName;
  final VoidCallback onOpenAbout;
  final VoidCallback onOpenThisMac;

  @override
  Widget build(BuildContext context) {
    return _MacSystemPanelSurface(
      panelKey: const Key('mac-system-menu-panel'),
      surfaceKey: const Key('mac-system-menu-panel-surface'),
      width: 252,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _SystemMenuItem(
            actionKey: const Key('system-menu-about'),
            label: 'About This Portfolio',
            icon: Icons.person_outline_rounded,
            onPressed: onOpenAbout,
          ),
          const Divider(height: 11),
          _SystemMenuItem(
            actionKey: const Key('system-menu-this-mac'),
            label: '프로젝트 열기',
            icon: Icons.folder_copy_rounded,
            onPressed: onOpenThisMac,
          ),
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              '$identityName · Flutter portfolio',
              style: TextStyle(
                fontSize: 10.5,
                color: AppleTheme.isDark(context)
                    ? AppleTheme.secondaryLabel(context)
                    : const Color(0xFF77777D),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SystemMenuItem extends StatelessWidget {
  const _SystemMenuItem({
    required this.actionKey,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final Key actionKey;
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      key: actionKey,
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: AppleTheme.isDark(context)
            ? AppleTheme.primaryLabel(context)
            : const Color(0xFF252529),
        minimumSize: const Size.fromHeight(36),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        alignment: Alignment.centerLeft,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
      icon: Icon(icon, size: 17),
      label: Text(label),
    );
  }
}

class MacNotificationsPanel extends StatefulWidget {
  const MacNotificationsPanel({super.key});

  @override
  State<MacNotificationsPanel> createState() => _MacNotificationsPanelState();
}

class _MacNotificationsPanelState extends State<MacNotificationsPanel> {
  late final DateTime _openedAt;

  @override
  void initState() {
    super.initState();
    _openedAt = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return _MacSystemPanelSurface(
      panelKey: const Key('mac-notifications-panel'),
      surfaceKey: const Key('mac-notifications-panel-surface'),
      width: 332,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            _longDate(_openedAt),
            key: const Key('mac-notifications-date'),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppleTheme.isDark(context)
                  ? AppleTheme.secondaryLabel(context)
                  : const Color(0xFF65656B),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            _largeTime(_openedAt),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppleTheme.primaryLabel(context),
              fontSize: 34,
              fontWeight: FontWeight.w700,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            key: const Key('mac-notifications-empty-card'),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppleTheme.isDark(context)
                  ? const Color(0xFF292A2F).withValues(alpha: 0.82)
                  : Colors.white.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withValues(
                  alpha: AppleTheme.isDark(context) ? 0.12 : 0.58,
                ),
              ),
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  Icons.notifications_none_rounded,
                  color: AppleTheme.isDark(context)
                      ? AppleTheme.secondaryLabel(context)
                      : const Color(0xFF68686D),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    'No new notifications',
                    style: TextStyle(
                      color: AppleTheme.primaryLabel(context),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MacSystemPanelSurface extends StatelessWidget {
  const _MacSystemPanelSurface({
    required this.panelKey,
    required this.surfaceKey,
    required this.width,
    required this.child,
  });

  final Key panelKey;
  final Key surfaceKey;
  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      key: panelKey,
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 34, sigmaY: 34),
        child: Container(
          key: surfaceKey,
          width: width,
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: AppleTheme.isDark(context)
                ? const Color(0xFF1C1D21).withValues(alpha: 0.88)
                : const Color(0xFFF4F4F7).withValues(alpha: 0.83),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white.withValues(
                alpha: AppleTheme.isDark(context) ? 0.18 : 0.72,
              ),
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: AppleTheme.isDark(context) ? 0.42 : 0.2,
                ),
                blurRadius: 38,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _ControlTile extends StatelessWidget {
  const _ControlTile({
    required this.tileKey,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final Key tileKey;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: tileKey,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppleTheme.isDark(context)
            ? const Color(0xFF2A2B30).withValues(alpha: 0.82)
            : Colors.white.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: Colors.white.withValues(
            alpha: AppleTheme.isDark(context) ? 0.12 : 0.62,
          ),
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppleTheme.primaryLabel(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: AppleTheme.isDark(context)
                        ? AppleTheme.secondaryLabel(context)
                        : const Color(0xFF6E6E73),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _menuTime(DateTime time) {
  const weekdays = <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return '${weekdays[time.weekday - 1]} ${time.month}/${time.day} ${_largeTime(time)}';
}

String _largeTime(DateTime time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String _longDate(DateTime time) {
  const weekdays = <String>[
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  const months = <String>[
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
  return '${weekdays[time.weekday - 1]}, ${months[time.month - 1]} ${time.day}';
}
