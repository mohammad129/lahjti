import '../../../../l10n/app_localizations.dart';

/// Enum representing age group brackets for personalization and adaptive UX.
enum AgeGroup {
  /// Children (Ages 6–10): Child mode, larger touch targets (>= 56dp), games, visual guidance.
  age6_10('6–10'),

  /// Early teens (Ages 11–15): Gamified challenges, visual progress, conversation.
  age11_15('11–15'),

  /// Late teens (Ages 16–17): Modern sleek UI, challenges, real-world context.
  age16_17('16–17'),

  /// Young adults (Ages 18–25): Career, university, travel, immersive conversations.
  age18_25('18–25'),

  /// Adults (Ages 26–40): Professional, workplace, business, social dialects.
  age26_40('26–40'),

  /// Mature adults (Ages 41–55): Practical communication, travel, culture, clean UI.
  age41_55('41–55'),

  /// Senior adults (Ages 55+): Accessible, clear typography, cultural enrichment.
  age55Plus('55+'),

  // Backwards compatibility entries:
  age11_14('11–14'),
  age15_18('15–18'),
  age19_25('19–25'),
  age26_35('26–35'),
  age36_50('36–50'),
  age50Plus('50+');

  final String label;
  const AgeGroup(this.label);

  /// Primary age groups displayed during onboarding.
  static const List<AgeGroup> primaryGroups = [
    AgeGroup.age6_10,
    AgeGroup.age11_15,
    AgeGroup.age16_17,
    AgeGroup.age18_25,
    AgeGroup.age26_40,
    AgeGroup.age41_55,
  ];

  /// Whether this age group activates Child Mode (large touch targets, simplified text).
  bool get isChild => this == AgeGroup.age6_10;

  /// Whether this age group is in the Teen category.
  bool get isTeen =>
      this == AgeGroup.age11_15 ||
      this == AgeGroup.age16_17 ||
      this == AgeGroup.age11_14 ||
      this == AgeGroup.age15_18;

  /// Whether this age group is in the Adult category.
  bool get isAdult => !isChild && !isTeen;

  /// Minimum touch target dimension in logical pixels.
  double get minTouchTargetSize => isChild ? 56.0 : 48.0;

  /// Semantic category name for adaptive UI and AI prompts.
  String get categoryKey {
    if (isChild) return 'child';
    if (isTeen) return 'teen';
    return 'adult';
  }

  String localizedLabel(AppLocalizations l10n) {
    switch (this) {
      case AgeGroup.age6_10:
        return l10n.age6_10;
      case AgeGroup.age11_15:
        return '11–15';
      case AgeGroup.age16_17:
        return '16–17';
      case AgeGroup.age18_25:
        return '18–25';
      case AgeGroup.age26_40:
        return '26–40';
      case AgeGroup.age41_55:
        return '41–55';
      case AgeGroup.age55Plus:
        return '55+';
      case AgeGroup.age11_14:
        return l10n.age11_14;
      case AgeGroup.age15_18:
        return l10n.age15_18;
      case AgeGroup.age19_25:
        return l10n.age19_25;
      case AgeGroup.age26_35:
        return l10n.age26_35;
      case AgeGroup.age36_50:
        return l10n.age36_50;
      case AgeGroup.age50Plus:
        return l10n.age50Plus;
    }
  }
}
