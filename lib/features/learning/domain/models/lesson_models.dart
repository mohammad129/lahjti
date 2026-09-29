import 'package:flutter/foundation.dart';
import '../../../placement/domain/models/cefr_level.dart';
import 'learning_skill.dart';

/// Distinct pedagogical steps within a lesson.
enum LessonStepType {
  introduction,
  explanation,
  examples,
  listeningActivity,
  speakingActivity,
  vocabularyPractice,
  grammarPractice,
  conversationPractice,
  review,
  completion,
}

/// A single granular activity / step within a lesson.
@immutable
class LessonStep {
  final String id;
  final LessonStepType type;
  final String title;
  final String titleArabic;
  final String content;
  final String contentArabic;
  final List<String> targetPhrases;
  final String? interactivePrompt;

  const LessonStep({
    required this.id,
    required this.type,
    required this.title,
    required this.titleArabic,
    required this.content,
    required this.contentArabic,
    this.targetPhrases = const [],
    this.interactivePrompt,
  });
}

/// Complete pedagogical lesson unit.
@immutable
class Lesson {
  final String id;
  final String moduleId;
  final int month; // 1, 2, or 3 of the journey
  final String title;
  final String titleArabic;
  final String description;
  final String descriptionArabic;
  final CefrLevel cefrLevel;
  final LearningSkill primarySkill;
  final List<LearningSkill> targetSkills;
  final List<LessonStep> steps;
  final List<String> targetVocabulary;
  final String? grammarFocus;
  final int estimatedMinutes;
  final int order;

  const Lesson({
    required this.id,
    required this.moduleId,
    required this.month,
    required this.title,
    required this.titleArabic,
    required this.description,
    required this.descriptionArabic,
    required this.cefrLevel,
    required this.primarySkill,
    this.targetSkills = const [],
    required this.steps,
    this.targetVocabulary = const [],
    this.grammarFocus,
    this.estimatedMinutes = 8,
    required this.order,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Lesson && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Thematic module grouping related lessons together in the curriculum.
@immutable
class CurriculumModule {
  final String id;
  final int month; // 1, 2, or 3
  final String theme;
  final String themeArabic;
  final String description;
  final String descriptionArabic;
  final String iconEmoji;
  final List<Lesson> lessons;
  final int order;

  const CurriculumModule({
    required this.id,
    required this.month,
    required this.theme,
    required this.themeArabic,
    required this.description,
    required this.descriptionArabic,
    required this.iconEmoji,
    required this.lessons,
    required this.order,
  });

  int get totalLessons => lessons.length;
}
