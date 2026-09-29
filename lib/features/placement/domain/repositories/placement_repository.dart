import '../../../onboarding/domain/models/age_group.dart';
import '../../../onboarding/domain/models/learning_goal.dart';
import '../../../onboarding/domain/models/native_language.dart';
import '../../../onboarding/domain/models/supported_language.dart';
import '../models/cefr_level.dart';
import '../models/placement_answer.dart';
import '../models/placement_evaluation.dart';
import '../models/placement_question.dart';

/// Abstract domain repository contract for placement evaluations.
abstract class PlacementRepository {
  /// Evaluates a learner's placement answer via the secure backend AI gateway.
  Future<PlacementEvaluation> evaluateAnswer({
    required SupportedLanguage targetLanguage,
    required NativeLanguage nativeLanguage,
    required AgeGroup ageGroup,
    required LearningGoal learningGoal,
    required CefrLevel difficulty,
    required PlacementQuestion question,
    required PlacementAnswer answer,
  });
}
