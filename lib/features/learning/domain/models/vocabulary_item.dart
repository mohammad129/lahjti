import 'package:flutter/foundation.dart';
import '../../../placement/domain/models/cefr_level.dart';

/// The mastery status of a vocabulary term in the learner's memory.
enum MasteryStatus { newWord, learning, reviewing, mastered }

/// A vocabulary term with its pedagogical and spaced review tracking data.
@immutable
class VocabularyItem {
  final String id;
  final String term;
  final String translationArabic;
  final String? phonetic;
  final String exampleSentence;
  final String exampleTranslationArabic;
  final CefrLevel difficulty;
  final String category;
  final MasteryStatus status;
  final int correctStreak;
  final int totalAttempts;
  final int incorrectAttempts;
  final DateTime? lastReviewed;
  final DateTime? nextReview;

  const VocabularyItem({
    required this.id,
    required this.term,
    required this.translationArabic,
    this.phonetic,
    required this.exampleSentence,
    required this.exampleTranslationArabic,
    required this.difficulty,
    required this.category,
    this.status = MasteryStatus.newWord,
    this.correctStreak = 0,
    this.totalAttempts = 0,
    this.incorrectAttempts = 0,
    this.lastReviewed,
    this.nextReview,
  });

  bool isDueForReview(DateTime now) {
    if (nextReview == null) return true;
    return now.isAfter(nextReview!) || now.isAtSameMomentAs(nextReview!);
  }

  VocabularyItem copyWith({
    String? id,
    String? term,
    String? translationArabic,
    String? phonetic,
    String? exampleSentence,
    String? exampleTranslationArabic,
    CefrLevel? difficulty,
    String? category,
    MasteryStatus? status,
    int? correctStreak,
    int? totalAttempts,
    int? incorrectAttempts,
    DateTime? lastReviewed,
    DateTime? nextReview,
  }) {
    return VocabularyItem(
      id: id ?? this.id,
      term: term ?? this.term,
      translationArabic: translationArabic ?? this.translationArabic,
      phonetic: phonetic ?? this.phonetic,
      exampleSentence: exampleSentence ?? this.exampleSentence,
      exampleTranslationArabic:
          exampleTranslationArabic ?? this.exampleTranslationArabic,
      difficulty: difficulty ?? this.difficulty,
      category: category ?? this.category,
      status: status ?? this.status,
      correctStreak: correctStreak ?? this.correctStreak,
      totalAttempts: totalAttempts ?? this.totalAttempts,
      incorrectAttempts: incorrectAttempts ?? this.incorrectAttempts,
      lastReviewed: lastReviewed ?? this.lastReviewed,
      nextReview: nextReview ?? this.nextReview,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VocabularyItem &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
