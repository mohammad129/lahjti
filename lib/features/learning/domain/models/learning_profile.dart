import 'package:flutter/foundation.dart';
import '../../../placement/domain/models/cefr_level.dart';

/// Immutable model representing the student's holistic learning profile.
@immutable
class LearningProfile {
  final String userId;
  final String targetLanguage;
  final CefrLevel estimatedCefrLevel;
  final int overallScore;
  final int comprehensionScore;
  final int vocabularyScore;
  final int grammarScore;
  final int? speakingScore;
  final int? listeningScore;
  final int? pronunciationScore;
  final int? fluencyScore;
  final List<String> strengths;
  final List<String> weaknesses;
  final List<String> recommendedFocusAreas;
  final String currentLessonId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const LearningProfile({
    required this.userId,
    required this.targetLanguage,
    required this.estimatedCefrLevel,
    required this.overallScore,
    required this.comprehensionScore,
    required this.vocabularyScore,
    required this.grammarScore,
    this.speakingScore,
    this.listeningScore,
    this.pronunciationScore,
    this.fluencyScore,
    this.strengths = const [],
    this.weaknesses = const [],
    this.recommendedFocusAreas = const [],
    this.currentLessonId = 'lesson_1_1',
    required this.createdAt,
    required this.updatedAt,
  });

  factory LearningProfile.defaultProfile({
    String userId = 'user_default',
    String targetLanguage = 'english',
    CefrLevel level = CefrLevel.a1,
  }) {
    final now = DateTime.now();
    return LearningProfile(
      userId: userId,
      targetLanguage: targetLanguage,
      estimatedCefrLevel: level,
      overallScore: 65,
      comprehensionScore: 70,
      vocabularyScore: 65,
      grammarScore: 60,
      pronunciationScore: null, // Preserved null until voice assessed
      strengths: const ['المفردات الأساسية', 'التحيات'],
      weaknesses: const ['أزمنة الأفعال', 'تكوين الأسئلة'],
      recommendedFocusAreas: const ['التحدث والمحادثة', 'الماضي البسيط'],
      currentLessonId: 'lesson_1_1',
      createdAt: now,
      updatedAt: now,
    );
  }

  LearningProfile copyWith({
    String? userId,
    String? targetLanguage,
    CefrLevel? estimatedCefrLevel,
    int? overallScore,
    int? comprehensionScore,
    int? vocabularyScore,
    int? grammarScore,
    int? speakingScore,
    int? listeningScore,
    int? pronunciationScore,
    int? fluencyScore,
    List<String>? strengths,
    List<String>? weaknesses,
    List<String>? recommendedFocusAreas,
    String? currentLessonId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LearningProfile(
      userId: userId ?? this.userId,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      estimatedCefrLevel: estimatedCefrLevel ?? this.estimatedCefrLevel,
      overallScore: overallScore ?? this.overallScore,
      comprehensionScore: comprehensionScore ?? this.comprehensionScore,
      vocabularyScore: vocabularyScore ?? this.vocabularyScore,
      grammarScore: grammarScore ?? this.grammarScore,
      speakingScore: speakingScore ?? this.speakingScore,
      listeningScore: listeningScore ?? this.listeningScore,
      pronunciationScore: pronunciationScore ?? this.pronunciationScore,
      fluencyScore: fluencyScore ?? this.fluencyScore,
      strengths: strengths ?? this.strengths,
      weaknesses: weaknesses ?? this.weaknesses,
      recommendedFocusAreas:
          recommendedFocusAreas ?? this.recommendedFocusAreas,
      currentLessonId: currentLessonId ?? this.currentLessonId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LearningProfile &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          targetLanguage == other.targetLanguage &&
          estimatedCefrLevel == other.estimatedCefrLevel &&
          overallScore == other.overallScore;

  @override
  int get hashCode =>
      userId.hashCode ^
      targetLanguage.hashCode ^
      estimatedCefrLevel.hashCode ^
      overallScore.hashCode;

  @override
  String toString() =>
      'LearningProfile(user: $userId, lang: $targetLanguage, cefr: ${estimatedCefrLevel.code})';
}
