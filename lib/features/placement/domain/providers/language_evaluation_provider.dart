import '../../../onboarding/domain/models/age_group.dart';
import '../../../onboarding/domain/models/learning_goal.dart';
import '../../../onboarding/domain/models/native_language.dart';
import '../../../onboarding/domain/models/supported_language.dart';
import '../models/placement_answer.dart';
import '../models/placement_evaluation.dart';
import '../models/placement_question.dart';

/// Abstract contract for evaluating student responses.
/// Designed for future structured AI backend API integration.
abstract class LanguageEvaluationProvider {
  /// Evaluates an answer submitted by a user for a given question.
  Future<PlacementEvaluation> evaluate({
    required SupportedLanguage targetLanguage,
    required NativeLanguage nativeLanguage,
    required AgeGroup ageGroup,
    required LearningGoal learningGoal,
    required PlacementQuestion question,
    required PlacementAnswer answer,
  });
}
