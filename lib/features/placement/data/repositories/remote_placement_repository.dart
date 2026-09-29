import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../onboarding/domain/models/age_group.dart';
import '../../../onboarding/domain/models/learning_goal.dart';
import '../../../onboarding/domain/models/native_language.dart';
import '../../../onboarding/domain/models/supported_language.dart';
import '../../domain/models/cefr_level.dart';
import '../../domain/models/placement_answer.dart';
import '../../domain/models/placement_evaluation.dart';
import '../../domain/models/placement_question.dart';
import '../../domain/repositories/placement_repository.dart';

/// Concrete implementation of [PlacementRepository] using [ApiClient] to talk
/// to the secure backend AI gateway.
class RemotePlacementRepository implements PlacementRepository {
  final ApiClient _apiClient;

  const RemotePlacementRepository(this._apiClient);

  @override
  Future<PlacementEvaluation> evaluateAnswer({
    required SupportedLanguage targetLanguage,
    required NativeLanguage nativeLanguage,
    required AgeGroup ageGroup,
    required LearningGoal learningGoal,
    required CefrLevel difficulty,
    required PlacementQuestion question,
    required PlacementAnswer answer,
  }) async {
    final payload = {
      'targetLanguage': targetLanguage.id,
      'nativeLanguage': nativeLanguage.code,
      'ageGroup': ageGroup.name,
      'learningGoal': learningGoal.id,
      'difficulty': difficulty.name,
      'question': {
        'id': question.id,
        'type': question.type.name,
        'prompt': question.prompt,
        'promptArabic': question.promptArabic,
      },
      'response': answer.userResponse,
      'responseDurationMs': answer.responseDuration.inMilliseconds,
      'skipped': answer.skipped,
    };

    try {
      final response = await _apiClient.post(
        '/placement/evaluate',
        data: payload,
      );

      final rawData = response.data;
      if (rawData == null) {
        throw const ServerException(
          message: 'Received empty response from placement evaluation gateway',
          statusCode: 500,
        );
      }

      final Map<String, dynamic> data =
          rawData is Map<String, dynamic>
              ? rawData
              : Map<String, dynamic>.from(rawData as Map);

      return PlacementEvaluation.fromJson(data);
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(
        message: 'Failed to evaluate placement answer: $e',
        statusCode: 500,
      );
    }
  }
}
