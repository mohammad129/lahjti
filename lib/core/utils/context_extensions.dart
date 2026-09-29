import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

/// Extension on [BuildContext] providing streamlined access to theme, localization, and media queries.
extension BuildContextExtensions on BuildContext {
  /// Typed localization instance
  AppLocalizations get l10n {
    final localizations = AppLocalizations.of(this);
    assert(
      localizations != null,
      'No AppLocalizations found in context. Ensure MaterialApp includes localizationsDelegates.',
    );
    return localizations!;
  }

  /// Theme data
  ThemeData get theme => Theme.of(this);

  /// ColorScheme
  ColorScheme get colors => Theme.of(this).colorScheme;

  /// TextTheme
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// MediaQuery data
  MediaQueryData get mediaQuery => MediaQuery.of(this);

  /// Screen Dimensions
  double get screenWidth => mediaQuery.size.width;
  double get screenHeight => mediaQuery.size.height;

  /// Directionality helpers
  bool get isRtl => Directionality.of(this) == TextDirection.rtl;
  bool get isLtr => Directionality.of(this) == TextDirection.ltr;
}
