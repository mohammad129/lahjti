import '../../../../l10n/app_localizations.dart';

/// Supported Native Languages for the user interface and explanations.
enum NativeLanguage {
  arabic('ar', 'العربية', '🇸🇦'),
  english('en', 'English', '🇬🇧'),
  spanish('es', 'Español', '🇪🇸'),
  french('fr', 'Français', '🇫🇷'),
  german('de', 'Deutsch', '🇩🇪'),
  turkish('tr', 'Türkçe', '🇹🇷'),
  other('other', 'Other / أخرى', '🌐');

  final String code;
  final String nativeName;
  final String flagEmoji;

  const NativeLanguage(this.code, this.nativeName, this.flagEmoji);

  String localizedName(AppLocalizations l10n) {
    switch (this) {
      case NativeLanguage.arabic:
        return l10n.langArabic;
      case NativeLanguage.english:
        return l10n.langEnglish;
      case NativeLanguage.spanish:
        return l10n.langSpanish;
      case NativeLanguage.french:
        return l10n.langFrench;
      case NativeLanguage.german:
        return l10n.langGerman;
      case NativeLanguage.turkish:
        return l10n.langTurkish;
      case NativeLanguage.other:
        return l10n.langOther;
    }
  }
}
