import '../../../../l10n/app_localizations.dart';

/// Enum representing the user's initial self-assessment of their experience.
enum ExperienceLevel {
  zero('zero'),
  basic('basic'),
  intermediate('intermediate'),
  conversational('conversational'),
  advanced('advanced');

  final String id;
  const ExperienceLevel(this.id);

  static const ExperienceLevel beginner = ExperienceLevel.zero;

  String localizedTitle(AppLocalizations l10n) {
    switch (this) {
      case ExperienceLevel.zero:
        return l10n.expZeroTitle;
      case ExperienceLevel.basic:
        return l10n.expBasicTitle;
      case ExperienceLevel.intermediate:
        return l10n.expIntermediateTitle;
      case ExperienceLevel.conversational:
        return l10n.expConversationalTitle;
      case ExperienceLevel.advanced:
        return l10n.expAdvancedTitle;
    }
  }

  String localizedDescription(AppLocalizations l10n) {
    switch (this) {
      case ExperienceLevel.zero:
        return l10n.expZeroDesc;
      case ExperienceLevel.basic:
        return l10n.expBasicDesc;
      case ExperienceLevel.intermediate:
        return l10n.expIntermediateDesc;
      case ExperienceLevel.conversational:
        return l10n.expConversationalDesc;
      case ExperienceLevel.advanced:
        return l10n.expAdvancedDesc;
    }
  }
}
