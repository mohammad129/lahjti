import 'package:flutter/foundation.dart';
import '../../../placement/domain/models/cefr_level.dart';
import '../../../learning/domain/models/learning_skill.dart';

/// The category/scope of the exam.
enum ExamType {
  /// Baseline evaluation check.
  placementCheck,

  /// Monthly milestone exam (Month 1: Foundation, Month 2: Real Life, Month 3: Fluency).
  monthlyMilestone,

  /// Focused checkpoint for specific skill groups.
  skillCheckpoint,

  /// Full comprehensive assessment.
  comprehensive,
}

/// The specific cognitive and communicative skill measured by an exam question.
enum ExamQuestionType {
  /// Reading comprehension passage + question.
  readingComprehension,

  /// Vocabulary in context.
  vocabularySelection,

  /// Grammar, syntax, and sentence structure.
  grammarUsage,

  /// Listening comprehension with native audio/TTS.
  listeningComprehension,

  /// Spoken production using STT microphone capture.
  speakingProduction,

  /// Real-world situational response / practical dialogue.
  practicalCommunication,
}

/// Extension providing localized names and icons for exam question types.
extension ExamQuestionTypeExtension on ExamQuestionType {
  String get nameArabic {
    switch (this) {
      case ExamQuestionType.readingComprehension:
        return 'فهم المقروء';
      case ExamQuestionType.vocabularySelection:
        return 'المفردات والسياق';
      case ExamQuestionType.grammarUsage:
        return 'القواعد والتركيب';
      case ExamQuestionType.listeningComprehension:
        return 'الاستماع والفهم';
      case ExamQuestionType.speakingProduction:
        return 'النطق والتحدث';
      case ExamQuestionType.practicalCommunication:
        return 'التواصل الواقعي';
    }
  }

  String get nameEnglish {
    switch (this) {
      case ExamQuestionType.readingComprehension:
        return 'Reading Comprehension';
      case ExamQuestionType.vocabularySelection:
        return 'Vocabulary in Context';
      case ExamQuestionType.grammarUsage:
        return 'Grammar & Structure';
      case ExamQuestionType.listeningComprehension:
        return 'Listening Comprehension';
      case ExamQuestionType.speakingProduction:
        return 'Speaking & Pronunciation';
      case ExamQuestionType.practicalCommunication:
        return 'Practical Communication';
    }
  }

  LearningSkill get associatedSkill {
    switch (this) {
      case ExamQuestionType.readingComprehension:
        return LearningSkill.reading;
      case ExamQuestionType.vocabularySelection:
        return LearningSkill.vocabulary;
      case ExamQuestionType.grammarUsage:
        return LearningSkill.grammar;
      case ExamQuestionType.listeningComprehension:
        return LearningSkill.listening;
      case ExamQuestionType.speakingProduction:
        return LearningSkill.speaking;
      case ExamQuestionType.practicalCommunication:
        return LearningSkill.fluency;
    }
  }
}

/// An individual question within an exam.
@immutable
class ExamQuestion {
  final String id;
  final String sectionId;
  final ExamQuestionType type;
  final String promptText;
  final String? promptSubtext;
  final String? passageText;
  final String? textToSpeak;
  final List<String> options;
  final int correctOptionIndex;
  final String? targetSpokenPhrase;
  final int points;

  const ExamQuestion({
    required this.id,
    required this.sectionId,
    required this.type,
    required this.promptText,
    this.promptSubtext,
    this.passageText,
    this.textToSpeak,
    this.options = const [],
    required this.correctOptionIndex,
    this.targetSpokenPhrase,
    this.points = 10,
  });

  bool isCorrectAnswer(int? selectedIndex, String? spokenText) {
    if (type == ExamQuestionType.speakingProduction) {
      if (spokenText == null || spokenText.trim().isEmpty) return false;
      final target =
          (targetSpokenPhrase ?? promptText)
              .toLowerCase()
              .replaceAll(RegExp(r'[^\w\s]'), '')
              .trim();
      final spoken =
          spokenText.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '').trim();
      return spoken.contains(target) || target.contains(spoken);
    }
    return selectedIndex == correctOptionIndex;
  }
}

/// A structured section within an exam focusing on a specific skill domain.
@immutable
class ExamSection {
  final String id;
  final String titleArabic;
  final String titleEnglish;
  final LearningSkill skill;
  final List<ExamQuestion> questions;
  final int? timeLimitMinutes;

  const ExamSection({
    required this.id,
    required this.titleArabic,
    required this.titleEnglish,
    required this.skill,
    required this.questions,
    this.timeLimitMinutes,
  });

  int get totalPoints => questions.fold(0, (sum, q) => sum + q.points);
}

/// A complete exam entity.
@immutable
class Exam {
  final String id;
  final String titleArabic;
  final String titleEnglish;
  final String descriptionArabic;
  final String descriptionEnglish;
  final String targetLanguage;
  final CefrLevel cefrLevel;
  final ExamType type;
  final int month;
  final List<ExamSection> sections;
  final int estimatedMinutes;

  const Exam({
    required this.id,
    required this.titleArabic,
    required this.titleEnglish,
    required this.descriptionArabic,
    required this.descriptionEnglish,
    required this.targetLanguage,
    required this.cefrLevel,
    required this.type,
    this.month = 1,
    required this.sections,
    this.estimatedMinutes = 15,
  });

  int get totalQuestions =>
      sections.fold(0, (sum, s) => sum + s.questions.length);

  int get totalPoints => sections.fold(0, (sum, s) => sum + s.totalPoints);
}

/// A learner's answer to a single question during an exam attempt.
@immutable
class ExamAnswer {
  final String questionId;
  final int? selectedOptionIndex;
  final String? spokenText;
  final bool isSkipped;
  final int timeSpentSeconds;

  const ExamAnswer({
    required this.questionId,
    this.selectedOptionIndex,
    this.spokenText,
    this.isSkipped = false,
    this.timeSpentSeconds = 0,
  });
}

/// Performance score for a specific skill in an exam.
@immutable
class ExamSkillScore {
  final LearningSkill skill;
  final int scorePercentage;
  final int pointsEarned;
  final int pointsPossible;

  const ExamSkillScore({
    required this.skill,
    required this.scorePercentage,
    required this.pointsEarned,
    required this.pointsPossible,
  });

  bool get isStrength => scorePercentage >= 75;
  bool get needsPractice => scorePercentage < 60;
}

/// An actionable pedagogical recommendation produced from an exam result.
@immutable
class ExamRecommendation {
  final LearningSkill skill;
  final String titleArabic;
  final String titleEnglish;
  final String rationaleArabic;
  final String rationaleEnglish;
  final String targetRoute;

  const ExamRecommendation({
    required this.skill,
    required this.titleArabic,
    required this.titleEnglish,
    required this.rationaleArabic,
    required this.rationaleEnglish,
    required this.targetRoute,
  });
}

/// The final comprehensive evaluation result of an exam attempt.
@immutable
class ExamResult {
  final String id;
  final String examId;
  final String examTitleArabic;
  final String examTitleEnglish;
  final int overallScore;
  final CefrLevel estimatedCefrLevel;
  final List<ExamSkillScore> skillScores;
  final int answeredCount;
  final int skippedCount;
  final int correctCount;
  final int totalQuestions;
  final List<String> strengthsArabic;
  final List<String> areasForImprovementArabic;
  final List<ExamRecommendation> recommendations;
  final DateTime completedAt;

  const ExamResult({
    required this.id,
    required this.examId,
    required this.examTitleArabic,
    required this.examTitleEnglish,
    required this.overallScore,
    required this.estimatedCefrLevel,
    required this.skillScores,
    required this.answeredCount,
    required this.skippedCount,
    required this.correctCount,
    required this.totalQuestions,
    required this.strengthsArabic,
    required this.areasForImprovementArabic,
    required this.recommendations,
    required this.completedAt,
  });

  bool get isPassing => overallScore >= 60;
  bool get isDistinction => overallScore >= 85;
}

/// The active state of an ongoing exam session attempt.
@immutable
class ExamAttemptState {
  final Exam exam;
  final int currentSectionIndex;
  final int currentQuestionIndex;
  final Map<String, ExamAnswer> answers;
  final bool isSubmitting;
  final ExamResult? result;

  const ExamAttemptState({
    required this.exam,
    this.currentSectionIndex = 0,
    this.currentQuestionIndex = 0,
    this.answers = const {},
    this.isSubmitting = false,
    this.result,
  });

  ExamSection? get currentSection =>
      currentSectionIndex < exam.sections.length
          ? exam.sections[currentSectionIndex]
          : null;

  ExamQuestion? get currentQuestion {
    final sec = currentSection;
    if (sec == null) return null;
    return currentQuestionIndex < sec.questions.length
        ? sec.questions[currentQuestionIndex]
        : null;
  }

  int get totalQuestions => exam.totalQuestions;

  int get currentGlobalQuestionNumber {
    int count = 0;
    for (int s = 0; s < currentSectionIndex; s++) {
      count += exam.sections[s].questions.length;
    }
    return count + currentQuestionIndex + 1;
  }

  bool get isLastQuestion {
    if (currentSection == null) return true;
    final isLastInSec =
        currentQuestionIndex == currentSection!.questions.length - 1;
    final isLastSec = currentSectionIndex == exam.sections.length - 1;
    return isLastInSec && isLastSec;
  }

  ExamAttemptState copyWith({
    Exam? exam,
    int? currentSectionIndex,
    int? currentQuestionIndex,
    Map<String, ExamAnswer>? answers,
    bool? isSubmitting,
    ExamResult? result,
  }) {
    return ExamAttemptState(
      exam: exam ?? this.exam,
      currentSectionIndex: currentSectionIndex ?? this.currentSectionIndex,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      answers: answers ?? this.answers,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      result: result ?? this.result,
    );
  }
}
