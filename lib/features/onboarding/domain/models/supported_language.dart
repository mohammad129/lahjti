import 'package:flutter/foundation.dart';
import '../../../../l10n/app_localizations.dart';

/// Immutable model representing a single source of truth for target languages to learn.
@immutable
class SupportedLanguage {
  final String id;
  final String nameEn;
  final String nameAr;
  final String flagEmoji;
  final bool isEnabled;

  const SupportedLanguage({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.flagEmoji,
    this.isEnabled = true,
  });

  /// Standard ISO 639-1 code (e.g. 'en', 'es', 'fr', 'de', 'ar')
  String get code => id;

  /// General name alias
  String get name => nameEn;

  /// Native language script name
  String get nativeName => nameAr;

  /// Whether the language is actively supported
  bool get supported => isEnabled;

  /// Standard platform speech & TTS locale string
  String get locale {
    switch (id.toLowerCase()) {
      case 'es':
        return 'es_ES';
      case 'fr':
        return 'fr_FR';
      case 'de':
        return 'de_DE';
      case 'it':
        return 'it_IT';
      case 'tr':
        return 'tr_TR';
      case 'ja':
        return 'ja_JP';
      case 'zh':
        return 'zh_CN';
      case 'ko':
        return 'ko_KR';
      case 'jo':
        return 'ar_JO';
      case 'ar':
        return 'ar_SA';
      case 'en':
      default:
        return 'en_US';
    }
  }

  String localizedName(AppLocalizations l10n) {
    switch (id) {
      case 'jo':
        return 'اللهجة الأردنية';
      case 'ar':
        return 'العربية الفصحى';
      case 'en':
        return l10n.langEnglish;
      case 'es':
        return l10n.langSpanish;
      case 'fr':
        return l10n.langFrench;
      case 'de':
        return l10n.langGerman;
      case 'it':
        return l10n.langItalian;
      case 'tr':
        return l10n.langTurkish;
      case 'ja':
        return l10n.langJapanese;
      case 'zh':
        return l10n.langChinese;
      case 'ko':
        return l10n.langKorean;
      default:
        return nameAr.isNotEmpty ? nameAr : nameEn;
    }
  }

  static const SupportedLanguage jordanianDialect = SupportedLanguage(
    id: 'jo',
    nameEn: 'Jordanian Dialect',
    nameAr: 'اللهجة الأردنية',
    flagEmoji: '🇯🇴',
  );

  static const SupportedLanguage english = SupportedLanguage(
    id: 'en',
    nameEn: 'English',
    nameAr: 'الإنجليزية',
    flagEmoji: '🇬🇧',
  );

  static const SupportedLanguage spanish = SupportedLanguage(
    id: 'es',
    nameEn: 'Spanish',
    nameAr: 'الإسبانية',
    flagEmoji: '🇪🇸',
  );

  static SupportedLanguage? fromCode(String? code) {
    if (code == null) return null;
    final normalized = code.toLowerCase().trim();
    if (normalized == 'jo' || normalized == 'jordanian') {
      return jordanianDialect;
    }
    if (normalized == 'en' || normalized == 'english') {
      return english;
    }
    if (normalized == 'es' || normalized == 'spanish') {
      return spanish;
    }

    return initialLanguages.firstWhere(
      (l) => l.id == normalized || l.nameEn.toLowerCase() == normalized,
      orElse:
          () => SupportedLanguage(
            id: normalized,
            nameEn: code.toUpperCase(),
            nameAr: code,
            flagEmoji: '🌐',
          ),
    );
  }

  static const List<SupportedLanguage> initialLanguages = [
    SupportedLanguage(
      id: 'en',
      nameEn: 'English',
      nameAr: 'الإنجليزية',
      flagEmoji: '🇬🇧',
    ),
    SupportedLanguage(
      id: 'es',
      nameEn: 'Spanish',
      nameAr: 'الإسبانية',
      flagEmoji: '🇪🇸',
    ),
    SupportedLanguage(
      id: 'fr',
      nameEn: 'French',
      nameAr: 'الفرنسية',
      flagEmoji: '🇫🇷',
    ),
    SupportedLanguage(
      id: 'de',
      nameEn: 'German',
      nameAr: 'الألمانية',
      flagEmoji: '🇩🇪',
    ),
    SupportedLanguage(
      id: 'ar',
      nameEn: 'Arabic',
      nameAr: 'العربية الفصحى',
      flagEmoji: '🇸🇦',
    ),
    SupportedLanguage(
      id: 'it',
      nameEn: 'Italian',
      nameAr: 'الإيطالية',
      flagEmoji: '🇮🇹',
    ),
    SupportedLanguage(
      id: 'tr',
      nameEn: 'Turkish',
      nameAr: 'التركية',
      flagEmoji: '🇹🇷',
    ),
    SupportedLanguage(
      id: 'ja',
      nameEn: 'Japanese',
      nameAr: 'اليابانية',
      flagEmoji: '🇯🇵',
    ),
    SupportedLanguage(
      id: 'zh',
      nameEn: 'Chinese',
      nameAr: 'الصينية',
      flagEmoji: '🇨🇳',
    ),
    SupportedLanguage(
      id: 'ko',
      nameEn: 'Korean',
      nameAr: 'الكورية',
      flagEmoji: '🇰🇷',
    ),
    SupportedLanguage(
      id: 'jo',
      nameEn: 'Jordanian Arabic (Dialect)',
      nameAr: 'اللهجة الأردنية',
      flagEmoji: '🇯🇴',
    ),
  ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SupportedLanguage &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'SupportedLanguage(id: $id, nameEn: $nameEn, locale: $locale)';
}

/// Type alias providing clean `TargetLanguage` domain model compatibility
typedef TargetLanguage = SupportedLanguage;
