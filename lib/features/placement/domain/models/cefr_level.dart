import '../../../../l10n/app_localizations.dart';

/// Standard CEFR (Common European Framework of Reference for Languages) proficiency levels.
enum CefrLevel {
  preA1('Pre-A1', 0),
  a1('A1', 1),
  a2('A2', 2),
  b1('B1', 3),
  b2('B2', 4),
  c1('C1', 5),
  c2('C2', 6);

  final String code;
  final int rank;

  const CefrLevel(this.code, this.rank);

  String localizedTitle(AppLocalizations l10n) {
    switch (this) {
      case CefrLevel.preA1:
        return l10n.cefrPreA1;
      case CefrLevel.a1:
        return l10n.cefrA1;
      case CefrLevel.a2:
        return l10n.cefrA2;
      case CefrLevel.b1:
        return l10n.cefrB1;
      case CefrLevel.b2:
        return l10n.cefrB2;
      case CefrLevel.c1:
        return l10n.cefrC1;
      case CefrLevel.c2:
        return l10n.cefrC2;
    }
  }

  CefrLevel get nextLevel {
    final nextRank = (rank + 1).clamp(0, CefrLevel.values.length - 1);
    return CefrLevel.values[nextRank];
  }

  CefrLevel get previousLevel {
    final prevRank = (rank - 1).clamp(0, CefrLevel.values.length - 1);
    return CefrLevel.values[prevRank];
  }

  static CefrLevel fromRank(int rank) {
    final clamped = rank.clamp(0, CefrLevel.values.length - 1);
    return CefrLevel.values[clamped];
  }

  static CefrLevel fromCode(String? code) {
    if (code == null) return CefrLevel.a1;
    final normalized = code.toLowerCase().replaceAll('-', '').trim();
    for (final level in CefrLevel.values) {
      if (level.name.toLowerCase() == normalized ||
          level.code.toLowerCase().replaceAll('-', '') == normalized) {
        return level;
      }
    }
    return CefrLevel.a1;
  }
}
