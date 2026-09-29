import 'package:flutter/foundation.dart';
import '../../../onboarding/domain/models/age_group.dart';
import '../../../onboarding/domain/models/experience_level.dart';
import '../../../onboarding/domain/models/learning_goal.dart';
import '../../../onboarding/domain/models/native_language.dart';
import '../../../onboarding/domain/models/supported_language.dart';
import 'cefr_level.dart';
import 'placement_answer.dart';
import 'placement_evaluation.dart';
import 'placement_question.dart';

enum PlacementSessionStatus { idle, inProgress, completed, error }

/// Immutable model representing an ongoing or completed adaptive placement test session.
@immutable
class PlacementSession {
  final String id;
  final String userId;
  final SupportedLanguage targetLanguage;
  final NativeLanguage nativeLanguage;
  final AgeGroup ageGroup;
  final LearningGoal learningGoal;
  final ExperienceLevel initialSelfAssessment;
  final CefrLevel currentDifficulty;
  final int currentQuestionIndex;
  final PlacementSessionStatus status;
  final DateTime startedAt;
  final DateTime? completedAt;
  final List<PlacementQuestion> questions;
  final List<PlacementAnswer> answers;
  final List<PlacementEvaluation> evaluations;

  const PlacementSession({
    required this.id,
    required this.userId,
    required this.targetLanguage,
    required this.nativeLanguage,
    required this.ageGroup,
    required this.learningGoal,
    required this.initialSelfAssessment,
    required this.currentDifficulty,
    this.currentQuestionIndex = 0,
    this.status = PlacementSessionStatus.inProgress,
    required this.startedAt,
    this.completedAt,
    this.questions = const [],
    this.answers = const [],
    this.evaluations = const [],
  });

  PlacementSession copyWith({
    String? id,
    String? userId,
    SupportedLanguage? targetLanguage,
    NativeLanguage? nativeLanguage,
    AgeGroup? ageGroup,
    LearningGoal? learningGoal,
    ExperienceLevel? initialSelfAssessment,
    CefrLevel? currentDifficulty,
    int? currentQuestionIndex,
    PlacementSessionStatus? status,
    DateTime? startedAt,
    DateTime? completedAt,
    List<PlacementQuestion>? questions,
    List<PlacementAnswer>? answers,
    List<PlacementEvaluation>? evaluations,
  }) {
    return PlacementSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      nativeLanguage: nativeLanguage ?? this.nativeLanguage,
      ageGroup: ageGroup ?? this.ageGroup,
      learningGoal: learningGoal ?? this.learningGoal,
      initialSelfAssessment:
          initialSelfAssessment ?? this.initialSelfAssessment,
      currentDifficulty: currentDifficulty ?? this.currentDifficulty,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      questions: questions ?? this.questions,
      answers: answers ?? this.answers,
      evaluations: evaluations ?? this.evaluations,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlacementSession &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'PlacementSession(id: $id, qIndex: $currentQuestionIndex, diff: ${currentDifficulty.code})';
}
