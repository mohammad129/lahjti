import '../../../onboarding/domain/models/age_group.dart';
import '../../../onboarding/domain/models/learning_goal.dart';
import '../../../onboarding/domain/models/native_language.dart';
import '../../../onboarding/domain/models/supported_language.dart';
import '../models/cefr_level.dart';
import '../models/placement_question.dart';

/// Abstract contract for generating language-agnostic, age-aware, and goal-aware placement questions.
/// Production implementation will query AI backend prompts/services.
abstract class PlacementContentProvider {
  /// Fetches or generates the next adaptive question.
  Future<PlacementQuestion> getNextQuestion({
    required SupportedLanguage targetLanguage,
    required NativeLanguage nativeLanguage,
    required AgeGroup ageGroup,
    required LearningGoal learningGoal,
    required CefrLevel difficulty,
    required List<String> previousQuestionIds,
  });
}
