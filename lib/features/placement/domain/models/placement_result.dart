import 'package:flutter/foundation.dart';
import '../../../learning/domain/models/learning_profile.dart';
import 'cefr_level.dart';

/// Immutable model representing the computed result of an adaptive placement assessment session.
@immutable
class PlacementResult {
  final CefrLevel estimatedCefrLevel;
  final int overallScore;
  final int comprehensionScore;
  final int vocabularyScore;
  final int grammarScore;
  final int? speakingScore;
  final int? listeningScore;

  /// Nullable: strictly null when evaluated via typed text.
  final int? pronunciationScore;
  final int? fluencyScore;
  final List<String> strengths;
  final List<String> weaknesses;
  final CefrLevel recommendedStartingDifficulty;
  final List<String> recommendedFocusAreas;

  const PlacementResult({
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
    required this.recommendedStartingDifficulty,
    this.recommendedFocusAreas = const [],
  });

  /// Converts this initial placement result into a full persistent [LearningProfile].
  LearningProfile toLearningProfile({
    required String userId,
    required String targetLanguage,
  }) {
    final now = DateTime.now();
    return LearningProfile(
      userId: userId,
      targetLanguage: targetLanguage,
      estimatedCefrLevel: estimatedCefrLevel,
      overallScore: overallScore,
      comprehensionScore: comprehensionScore,
      vocabularyScore: vocabularyScore,
      grammarScore: grammarScore,
      speakingScore: speakingScore,
      listeningScore: listeningScore,
      pronunciationScore: pronunciationScore,
      fluencyScore: fluencyScore,
      strengths: strengths,
      weaknesses: weaknesses,
      recommendedFocusAreas: recommendedFocusAreas,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlacementResult &&
          runtimeType == other.runtimeType &&
          estimatedCefrLevel == other.estimatedCefrLevel &&
          overallScore == other.overallScore;

  @override
  int get hashCode => estimatedCefrLevel.hashCode ^ overallScore.hashCode;

  @override
  String toString() =>
      'PlacementResult(cefr: ${estimatedCefrLevel.code}, score: $overallScore)';
}
