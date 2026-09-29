import 'package:flutter/material.dart';

/// Spacing, dimension, and border radius tokens.
class AppSpacing {
  AppSpacing._();

  // Spacing / Margins / Paddings
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;
  static const double huge = 48.0;

  // EdgeInsets helpers
  static const EdgeInsets paddingXs = EdgeInsets.all(xs);
  static const EdgeInsets paddingSm = EdgeInsets.all(sm);
  static const EdgeInsets paddingMd = EdgeInsets.all(md);
  static const EdgeInsets paddingLg = EdgeInsets.all(lg);
  static const EdgeInsets paddingXl = EdgeInsets.all(xl);
  static const EdgeInsets paddingXxl = EdgeInsets.all(xxl);

  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: xl,
    vertical: lg,
  );

  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    horizontal: xxl,
    vertical: lg,
  );

  // Border Radii
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusFull = 999.0;

  static final BorderRadius borderRadiusSm = BorderRadius.circular(radiusSm);
  static final BorderRadius borderRadiusMd = BorderRadius.circular(radiusMd);
  static final BorderRadius borderRadiusLg = BorderRadius.circular(radiusLg);
  static final BorderRadius borderRadiusXl = BorderRadius.circular(radiusXl);
  static final BorderRadius borderRadiusFull = BorderRadius.circular(
    radiusFull,
  );

  // Heights / Sizes
  static const double buttonHeight = 54.0;
  static const double buttonHeightSm = 42.0;
  static const double inputHeight = 54.0;
  static const double iconSm = 16.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;
}
