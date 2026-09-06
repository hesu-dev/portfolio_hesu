import 'dart:ui';

/// Returns the integer-snapped foreground origin that centers the combined
/// foreground and shadow bounds inside [contentRect].
Offset centeredPixelTextOrigin({
  required Rect contentRect,
  required Size foregroundSize,
  required Size shadowSize,
  Offset shadowOffset = const Offset(1, 1),
}) {
  if (!contentRect.left.isFinite ||
      !contentRect.top.isFinite ||
      !contentRect.right.isFinite ||
      !contentRect.bottom.isFinite ||
      contentRect.width < 0 ||
      contentRect.height < 0) {
    throw ArgumentError.value(contentRect, 'contentRect', 'must be finite');
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

void _validateSize(Size size, String name) {
  if (!size.width.isFinite ||
      !size.height.isFinite ||
      size.width < 0 ||
      size.height < 0) {
    throw ArgumentError.value(size, name, 'must be finite and non-negative');
  }
}
