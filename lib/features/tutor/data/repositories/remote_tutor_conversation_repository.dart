import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../learning/domain/models/learner_context.dart';
import '../../domain/models/voice_session_state.dart';
import '../../domain/repositories/tutor_conversation_repository.dart';

/// Concrete implementation of [TutorConversationRepository] that communicates
/// with the secure backend AI gateway via [ApiClient] (Dio).
class RemoteTutorConversationRepository implements TutorConversationRepository {
  final ApiClient _apiClient;

  const RemoteTutorConversationRepository(this._apiClient);

  @override
  Future<VoiceMessage> generateTutorResponse({
    required String userText,
    required String targetLanguageCode,
    required String tutorId,
    required List<VoiceMessage> history,
    String nativeLanguage = 'arabic',
    String ageGroup = 'adult',
    String learningGoal = 'conversation',
    String difficulty = 'a1',
    bool isSessionStart = false,
    LearnerContext? learnerContext,
  }) async {
    // 1. Convert history to bounded recent context (max 6 turns)
    final recentHistory =
        history
            .where((m) => m.text.trim().isNotEmpty)
            .take(6)
            .map(
              (m) => {
                'role': m.isUser ? 'user' : 'tutor',
                'text': m.text.length > 500 ? m.text.substring(0, 500) : m.text,
                'explanationArabic': m.explanationArabic,
                'correctedVersion': m.correctedAnswer,
              },
            )
            .toList();

    final payload = {
      'targetLanguage': learnerContext?.targetLanguage ?? targetLanguageCode,
      'nativeLanguage': learnerContext?.nativeLanguage ?? nativeLanguage,
      'ageGroup': learnerContext?.ageGroup ?? ageGroup,
      'learningGoal': learnerContext?.learningGoal ?? learningGoal,
      'difficulty': learnerContext?.cefrLevel.code.toLowerCase() ?? difficulty,
      'tutorPersona': learnerContext?.tutorPersona ?? tutorId,
      'userMessage':
          userText.length > 1000 ? userText.substring(0, 1000) : userText,
      'recentHistory': recentHistory,
      'isSessionStart': isSessionStart,
      if (learnerContext != null) ...{
        'currentLessonTitle': learnerContext.currentLessonTitle,
        'currentTopic': learnerContext.currentTopic,
        'targetSkill': learnerContext.targetSkill.name,
        'targetVocabulary': learnerContext.targetVocabulary.take(10).toList(),
        'recentWeaknesses': learnerContext.weaknesses.take(5).toList(),
        'recentStrengths': learnerContext.strengths.take(5).toList(),
      },
      'synthesizeVoice': true,
    };

    try {
      final response = await _apiClient.post(
        '/tutor/conversation',
        data: payload,
      );

      final rawData = response.data;
      if (rawData == null) {
        throw const ServerException(
          message: 'Received empty response from AI tutor conversation gateway',
          statusCode: 500,
        );
      }

      final Map<String, dynamic> data =
          rawData is Map<String, dynamic>
              ? rawData
              : Map<String, dynamic>.from(rawData as Map);

      return VoiceMessage.fromJson(
        data,
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      );
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(
        message: 'Failed to communicate with AI tutor: $e',
        statusCode: 500,
      );
    }
  }
}
