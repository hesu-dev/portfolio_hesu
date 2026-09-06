import 'dart:ui';

/// Snaps a logical rectangle to the pixel geometry used by the scene painters.
///
/// The origin and dimensions are rounded independently, and each drawn
/// dimension remains at least one logical pixel.
Rect snapPixelRect(Rect rect) {
  _validateFiniteRect(rect, 'rect');
  final width = rect.width.roundToDouble();
  final height = rect.height.roundToDouble();
  return Rect.fromLTWH(
    rect.left.roundToDouble(),
    rect.top.roundToDouble(),
    width < 1 ? 1 : width,
    height < 1 ? 1 : height,
  );
}

/// Returns the integer-snapped foreground origin that centers the combined
/// foreground and shadow bounds inside [contentRect].
Offset centeredPixelTextOrigin({
  required Rect contentRect,
  required Size foregroundSize,
  required Size shadowSize,
  Offset shadowOffset = const Offset(1, 1),
}) {
  _validateFiniteRect(contentRect, 'contentRect');
  if (contentRect.width < 0 || contentRect.height < 0) {
    throw ArgumentError.value(
      contentRect,
      'contentRect',
      'must have non-negative dimensions',
    );
  }
  _validateSize(foregroundSize, 'foregroundSize');
  _validateSize(shadowSize, 'shadowSize');
  if (!shadowOffset.dx.isFinite || !shadowOffset.dy.isFinite) {
    throw ArgumentError.value(shadowOffset, 'shadowOffset', 'must be finite');
  }

  final visualLeft = shadowOffset.dx < 0 ? shadowOffset.dx : 0.0;
  final visualTop = shadowOffset.dy < 0 ? shadowOffset.dy : 0.0;
  final shadowRight = shadowOffset.dx + shadowSize.width;
  final shadowBottom = shadowOffset.dy + shadowSize.height;
  final visualRight = foregroundSize.width > shadowRight
      ? foregroundSize.width
      : shadowRight;
  final visualBottom = foregroundSize.height > shadowBottom
      ? foregroundSize.height
      : shadowBottom;

  return Offset(
    (contentRect.center.dx - ((visualLeft + visualRight) / 2)).roundToDouble(),
    (contentRect.center.dy - ((visualTop + visualBottom) / 2)).roundToDouble(),
  );
}

void _validateFiniteRect(Rect rect, String name) {
  if (!rect.left.isFinite ||
      !rect.top.isFinite ||
      !rect.right.isFinite ||
      !rect.bottom.isFinite) {
    throw ArgumentError.value(rect, name, 'must be finite');
  }
}

void _validateSize(Size size, String name) {
  if (!size.width.isFinite ||
      !size.height.isFinite ||
      size.width < 0 ||
      size.height < 0) {
    throw ArgumentError.value(size, name, 'must be finite and non-negative');
  }
}
