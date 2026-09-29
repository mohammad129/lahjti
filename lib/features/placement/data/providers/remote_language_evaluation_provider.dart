import '../../../onboarding/domain/models/age_group.dart';
import '../../../onboarding/domain/models/learning_goal.dart';
import '../../../onboarding/domain/models/native_language.dart';
import '../../../onboarding/domain/models/supported_language.dart';
import '../../domain/models/placement_answer.dart';
import '../../domain/models/placement_evaluation.dart';
import '../../domain/models/placement_question.dart';
import '../../domain/providers/language_evaluation_provider.dart';
import '../../domain/repositories/placement_repository.dart';

/// Concrete implementation of [LanguageEvaluationProvider] that delegates
/// to [PlacementRepository] for remote secure backend evaluation.
class RemoteLanguageEvaluationProvider implements LanguageEvaluationProvider {
  final PlacementRepository _repository;

  const RemoteLanguageEvaluationProvider(this._repository);

  @override
  Future<PlacementEvaluation> evaluate({
    required SupportedLanguage targetLanguage,
    required NativeLanguage nativeLanguage,
    required AgeGroup ageGroup,
    required LearningGoal learningGoal,
    required PlacementQuestion question,
    required PlacementAnswer answer,
  }) {
    return _repository.evaluateAnswer(
      targetLanguage: targetLanguage,
      nativeLanguage: nativeLanguage,
      ageGroup: ageGroup,
      learningGoal: learningGoal,
      difficulty: question.difficulty,
      question: question,
      answer: answer,
    );
  }
}
