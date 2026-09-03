import 'package:flutter/material.dart';

import '../models/portfolio_app_id.dart';

/// Geometry shared by the desktop and every managed window.
abstract final class MacDesktopMetrics {
  static const double menuBarHeight = 32;
  static const double windowMargin = 8;
  static const double dockReservedHeight = 106;

  static Rect workArea(Size viewport) {
    final right = (viewport.width - windowMargin).clamp(
      windowMargin,
      double.infinity,
    );
    final bottom = (viewport.height - dockReservedHeight).clamp(
      menuBarHeight + windowMargin,
      double.infinity,
    );
    return Rect.fromLTRB(
      windowMargin,
      menuBarHeight + windowMargin,
      right,
      bottom,
    );
  }
}

@immutable
class MacWindowState {
  const MacWindowState({
    required this.appId,
    required this.position,
    required this.size,
    this.minimized = false,
    this.maximized = false,
    this.restorePosition,
    this.restoreSize,
  });

  factory MacWindowState.initial({
    required PortfolioAppId appId,
    required int cascadeIndex,
    required Size viewport,
  }) {
    final workArea = MacDesktopMetrics.workArea(viewport);
    final width = (workArea.width * 0.76).clamp(620.0, 860.0);
    final height = (workArea.height * 0.86).clamp(420.0, 620.0);
    final cascade = Offset(
      (cascadeIndex % 5) * 24.0,
      (cascadeIndex % 5) * 22.0,
    );
    final origin = Offset(
      workArea.left + (workArea.width - width) / 2 - 40 + cascade.dx,
      workArea.top + 30 + cascade.dy,
    );
    final frame = _clampFrame(
      Rect.fromLTWH(origin.dx, origin.dy, width, height),
      workArea,
    );

    return MacWindowState(
      appId: appId,
      position: frame.topLeft,
      size: frame.size,
    );
  }

  final PortfolioAppId appId;
  final Offset position;
  final Size size;
  final bool minimized;
  final bool maximized;
  final Offset? restorePosition;
  final Size? restoreSize;

  Rect frameFor(Size viewport) {
    final workArea = MacDesktopMetrics.workArea(viewport);
    if (maximized) {
      return workArea;
    }
    return _clampFrame(
      Rect.fromLTWH(position.dx, position.dy, size.width, size.height),
      workArea,
    );
  }

  MacWindowState focused() => copyWith(minimized: false);

  MacWindowState minimizedCopy() => copyWith(minimized: true);

  MacWindowState draggedBy(Offset delta, Size viewport) {
    if (maximized) {
      return this;
    }
    final current = frameFor(viewport);
    final moved = _clampFrame(
      current.shift(delta),
      MacDesktopMetrics.workArea(viewport),
    );
    return copyWith(position: moved.topLeft, size: moved.size);
  }

  MacWindowState toggleMaximized(Size viewport) {
    if (maximized) {
      final restoredFrame = _clampFrame(
        Rect.fromLTWH(
          (restorePosition ?? position).dx,
          (restorePosition ?? position).dy,
          (restoreSize ?? size).width,
          (restoreSize ?? size).height,
        ),
        MacDesktopMetrics.workArea(viewport),
      );
      return copyWith(
        position: restoredFrame.topLeft,
        size: restoredFrame.size,
        maximized: false,
        clearRestoreFrame: true,
      );
    }

    final current = frameFor(viewport);
    return copyWith(
      position: current.topLeft,
      size: current.size,
      maximized: true,
      restorePosition: current.topLeft,
      restoreSize: current.size,
    );
  }

  MacWindowState copyWith({
    Offset? position,
    Size? size,
    bool? minimized,
    bool? maximized,
    Offset? restorePosition,
    Size? restoreSize,
    bool clearRestoreFrame = false,
  }) {
    return MacWindowState(
      appId: appId,
      position: position ?? this.position,
      size: size ?? this.size,
      minimized: minimized ?? this.minimized,
      maximized: maximized ?? this.maximized,
      restorePosition: clearRestoreFrame
          ? null
          : restorePosition ?? this.restorePosition,
      restoreSize: clearRestoreFrame ? null : restoreSize ?? this.restoreSize,
    );
  }
}

Rect _clampFrame(Rect frame, Rect workArea) {
  final width = frame.width.clamp(0.0, workArea.width);
  final height = frame.height.clamp(0.0, workArea.height);
  final left = frame.left.clamp(workArea.left, workArea.right - width);
  final top = frame.top.clamp(workArea.top, workArea.bottom - height);
  return Rect.fromLTWH(left, top, width, height);
}
