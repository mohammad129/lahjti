import 'package:flutter/foundation.dart';
import '../../../placement/domain/models/cefr_level.dart';
import 'learning_skill.dart';

/// Immutable domain model capturing the student's unified pedagogical context.
///
/// Serves as the single authoritative source of context passed to the Adaptive Learning Engine
/// and AI Tutor (Abbas / Dunya) to ensure personalized, coherent language instruction.
@immutable
class LearnerContext {
  final String targetLanguage;
  final String nativeLanguage;
  final String ageGroup;
  final CefrLevel cefrLevel;
  final String learningGoal;
  final String experienceLevel;
  final String tutorPersona;
  final String currentLessonId;
  final String currentLessonTitle;
  final String currentTopic;
  final LearningSkill targetSkill;
  final List<String> targetVocabulary;
  final List<String> weaknesses;
  final List<String> strengths;
  final int streakDays;
  final int totalXp;
  final int dueVocabularyCount;

  const LearnerContext({
    this.targetLanguage = 'english',
    this.nativeLanguage = 'arabic',
    this.ageGroup = 'adult',
    this.cefrLevel = CefrLevel.a1,
    this.learningGoal = 'conversation',
    this.experienceLevel = 'beginnerWithBasics',
    this.tutorPersona = 'abbas',
    this.currentLessonId = 'lesson_1_1',
    this.currentLessonTitle = 'Hello & Nice to Meet You',
    this.currentTopic = 'Greetings & Introductions',
    this.targetSkill = LearningSkill.speaking,
    this.targetVocabulary = const ['hello', 'name', 'nice', 'meet'],
    this.weaknesses = const [],
    this.strengths = const [],
    this.streakDays = 1,
    this.totalXp = 0,
    this.dueVocabularyCount = 0,
  });

  /// Serializes the context into a compact, safe map to pass to the backend tutor gateway.
  Map<String, dynamic> toGatewayPayload() {
    return {
      'targetLanguage': targetLanguage,
      'nativeLanguage': nativeLanguage,
      'ageGroup': ageGroup,
      'difficulty': cefrLevel.code.toLowerCase(),
      'learningGoal': learningGoal,
      'tutorPersona': tutorPersona,
      'currentLessonTitle': currentLessonTitle,
      'currentTopic': currentTopic,
      'targetSkill': targetSkill.name,
      'targetVocabulary': targetVocabulary.take(10).toList(),
      'recentWeaknesses': weaknesses.take(5).toList(),
      'recentStrengths': strengths.take(5).toList(),
    };
  }

  LearnerContext copyWith({
    String? targetLanguage,
    String? nativeLanguage,
    String? ageGroup,
    CefrLevel? cefrLevel,
    String? learningGoal,
    String? experienceLevel,
    String? tutorPersona,
    String? currentLessonId,
    String? currentLessonTitle,
    String? currentTopic,
    LearningSkill? targetSkill,
    List<String>? targetVocabulary,
    List<String>? weaknesses,
    List<String>? strengths,
    int? streakDays,
    int? totalXp,
    int? dueVocabularyCount,
  }) {
    return LearnerContext(
      targetLanguage: targetLanguage ?? this.targetLanguage,
      nativeLanguage: nativeLanguage ?? this.nativeLanguage,
      ageGroup: ageGroup ?? this.ageGroup,
      cefrLevel: cefrLevel ?? this.cefrLevel,
      learningGoal: learningGoal ?? this.learningGoal,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      tutorPersona: tutorPersona ?? this.tutorPersona,
      currentLessonId: currentLessonId ?? this.currentLessonId,
      currentLessonTitle: currentLessonTitle ?? this.currentLessonTitle,
      currentTopic: currentTopic ?? this.currentTopic,
      targetSkill: targetSkill ?? this.targetSkill,
      targetVocabulary: targetVocabulary ?? this.targetVocabulary,
      weaknesses: weaknesses ?? this.weaknesses,
      strengths: strengths ?? this.strengths,
      streakDays: streakDays ?? this.streakDays,
      totalXp: totalXp ?? this.totalXp,
      dueVocabularyCount: dueVocabularyCount ?? this.dueVocabularyCount,
    );
  }
}
