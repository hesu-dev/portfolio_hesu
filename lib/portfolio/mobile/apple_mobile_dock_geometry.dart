/// Shared vertical geometry for the iPhone and iPad Dock surfaces.
///
/// The home Dock is laid out above the 17 px home-indicator row. App-level
/// bottom navigation uses the same measurements so switching screens does not
/// move or resize the Dock surface.
abstract final class AppleMobileDockGeometry {
  static const double homeIndicatorExtent = 17;
  static const double phoneBottomOffset = 9;
  static const double tabletBottomOffset = 14;

  // Includes the Dock's 0.8 px border on both edges.
  static const double phoneHeight = 77.6;
  static const double tabletHeight = 84.6;
  static const double tabletAppSurfaceBorderWidth = 0.9;

  static double height({required bool tablet}) =>
      tablet ? tabletHeight : phoneHeight;

  static double homeBottomOffset({required bool tablet}) =>
      tablet ? tabletBottomOffset : phoneBottomOffset;

  static double appBottomClearance({
    required bool tablet,
    required double safeAreaBottom,
  }) =>
      safeAreaBottom +
      homeIndicatorExtent +
      homeBottomOffset(tablet: tablet) -
      (tablet ? tabletAppSurfaceBorderWidth : 0);
}
