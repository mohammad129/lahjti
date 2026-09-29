import 'package:flutter/foundation.dart';
import 'package:lahjti/features/learning/domain/models/vocabulary_item.dart';

/// The distinct practice modes supported during vocabulary training.
enum PracticeMode {
  /// Target word shown in English -> Select Arabic meaning.
  recognizeMeaning,

  /// Arabic definition shown -> Select correct English word.
  wordSelection,

  /// Incomplete English sentence -> Select word to fill in the blank.
  sentenceCompletion,

  /// Spoken production -> Speak the word aloud using STT.
  speakingProduction,
}

/// Extension for localized titles of practice modes.
extension PracticeModeExtension on PracticeMode {
  String get nameArabic {
    switch (this) {
      case PracticeMode.recognizeMeaning:
        return 'معرفة المعنى';
      case PracticeMode.wordSelection:
        return 'اختيار الكلمة';
      case PracticeMode.sentenceCompletion:
        return 'إكمال الجملة';
      case PracticeMode.speakingProduction:
        return 'النطق والتحدث';
    }
  }

  String get nameEnglish {
    switch (this) {
      case PracticeMode.recognizeMeaning:
        return 'Meaning Recognition';
      case PracticeMode.wordSelection:
        return 'Word Selection';
      case PracticeMode.sentenceCompletion:
        return 'Sentence Completion';
      case PracticeMode.speakingProduction:
        return 'Speaking & Pronunciation';
    }
  }
}

/// A generated practice question with multiple choice options and target context.
@immutable
class PracticeQuestion {
  final String id;
  final PracticeMode mode;
  final VocabularyItem targetItem;
  final String promptText;
  final String? promptSubtext;
  final List<String> options;
  final int correctOptionIndex;
  final String explanationArabic;
  final String explanationEnglish;

  const PracticeQuestion({
    required this.id,
    required this.mode,
    required this.targetItem,
    required this.promptText,
    this.promptSubtext,
    required this.options,
    required this.correctOptionIndex,
    required this.explanationArabic,
    required this.explanationEnglish,
  });

  bool isCorrect(int selectedIndex) => selectedIndex == correctOptionIndex;
}

/// The result of answering a single practice question.
@immutable
class PracticeAnswerResult {
  final PracticeQuestion question;
  final int? selectedOptionIndex;
  final String? spokenText;
  final bool isCorrect;
  final DateTime timestamp;

  const PracticeAnswerResult({
    required this.question,
    this.selectedOptionIndex,
    this.spokenText,
    required this.isCorrect,
    required this.timestamp,
  });
}

/// The state of an active vocabulary practice session.
@immutable
class PracticeSessionState {
  final List<PracticeQuestion> questions;
  final int currentIndex;
  final int? selectedOptionIndex;
  final bool? isAnswerSubmitted;
  final bool isEvaluatingSpeech;
  final List<PracticeAnswerResult> results;
  final bool isCompleted;

  const PracticeSessionState({
    required this.questions,
    this.currentIndex = 0,
    this.selectedOptionIndex,
    this.isAnswerSubmitted = false,
    this.isEvaluatingSpeech = false,
    this.results = const [],
    this.isCompleted = false,
  });

  PracticeQuestion? get currentQuestion =>
      currentIndex < questions.length ? questions[currentIndex] : null;

  int get totalQuestions => questions.length;
  int get correctCount => results.where((r) => r.isCorrect).length;
  int get incorrectCount => results.where((r) => !r.isCorrect).length;
  double get scorePercentage =>
      totalQuestions > 0 ? (correctCount / totalQuestions) * 100 : 0.0;

  PracticeSessionState copyWith({
    List<PracticeQuestion>? questions,
    int? currentIndex,
    int? selectedOptionIndex,
    bool? isAnswerSubmitted,
    bool? isEvaluatingSpeech,
    List<PracticeAnswerResult>? results,
    bool? isCompleted,
  }) {
    return PracticeSessionState(
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      selectedOptionIndex: selectedOptionIndex ?? this.selectedOptionIndex,
      isAnswerSubmitted: isAnswerSubmitted ?? this.isAnswerSubmitted,
      isEvaluatingSpeech: isEvaluatingSpeech ?? this.isEvaluatingSpeech,
      results: results ?? this.results,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

/// Daily vocabulary learning and review target.
@immutable
class DailyVocabularyGoal {
  final int targetCount;
  final int learnedTodayCount;
  final int reviewedTodayCount;
  final int masteredTotalCount;
  final int dueForReviewCount;

  const DailyVocabularyGoal({
    required this.targetCount,
    required this.learnedTodayCount,
    required this.reviewedTodayCount,
    required this.masteredTotalCount,
    required this.dueForReviewCount,
  });

  int get totalCompletedToday => learnedTodayCount + reviewedTodayCount;
  double get progressRatio =>
      targetCount > 0
          ? (totalCompletedToday / targetCount).clamp(0.0, 1.0)
          : 0.0;
  bool get isGoalReached => totalCompletedToday >= targetCount;
}
