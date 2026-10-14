import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../learning/domain/models/learner_context.dart';
import '../../domain/models/student_tutor_session.dart';
import '../../domain/models/voice_session_state.dart';
import '../../domain/repositories/tutor_conversation_repository.dart';

/// Concrete implementation of [TutorConversationRepository] that communicates
/// with the secure backend AI gateway via [ApiClient] (Dio).
class RemoteTutorConversationRepository implements TutorConversationRepository {
  final ApiClient _apiClient;

  const RemoteTutorConversationRepository(this._apiClient);

  String _gatewayAgeGroup(String value) {
    final v = value.toLowerCase();
    if (v.contains('child') || v.contains('0_') || v.contains('5_') || v.contains('6_') || v.contains('12')) return 'child';
    if (v.contains('teen') || v.contains('13_') || v.contains('18')) return 'teen';
    if (v.contains('senior') || v.contains('60') || v.contains('65')) return 'senior';
    return 'adult';
  }

  String _gatewayLearningGoal(String value) {
    const accepted = {'travel', 'work', 'study', 'conversation', 'general'};
    final v = value.toLowerCase();
    return accepted.contains(v) ? v : 'conversation';
  }

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
    String? sessionId,
    int voiceDurationSeconds = 0,
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
      'ageGroup': _gatewayAgeGroup(learnerContext?.ageGroup ?? ageGroup),
      'learningGoal': _gatewayLearningGoal(learnerContext?.learningGoal ?? learningGoal),
      'difficulty': learnerContext?.cefrLevel.code.toLowerCase() ?? difficulty,
      'tutorPersona': learnerContext?.tutorPersona ?? tutorId,
      'userMessage':
          userText.length > 1000 ? userText.substring(0, 1000) : userText,
      'recentHistory': recentHistory,
      'isSessionStart': isSessionStart,
      if (sessionId != null) 'sessionId': sessionId,
      if (voiceDurationSeconds > 0) 'voiceDurationSeconds': voiceDurationSeconds,
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

  @override
  Future<StudentTutorSession?> getStudentSessionStatus() async {
    try {
      final response = await _apiClient.get('/tutor/student-session/status');
      if (response.data == null) return null;
      final map = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : Map<String, dynamic>.from(response.data as Map);
      return StudentTutorSession.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<StudentTutorSession?> startStudentSession() async {
    try {
      final response = await _apiClient.post('/tutor/student-session/start');
      if (response.data == null) return null;
      final map = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : Map<String, dynamic>.from(response.data as Map);
      if (map['status'] != null) {
        return StudentTutorSession.fromJson(Map<String, dynamic>.from(map['status'] as Map));
      }
      return StudentTutorSession.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<StudentTutorSession?> endStudentSession({String? sessionId}) async {
    try {
      final response = await _apiClient.post(
        '/tutor/student-session/end',
        data: sessionId != null ? {'sessionId': sessionId} : {},
      );
      if (response.data == null) return null;
      final map = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : Map<String, dynamic>.from(response.data as Map);
      if (map['status'] != null) {
        return StudentTutorSession.fromJson(Map<String, dynamic>.from(map['status'] as Map));
      }
      return StudentTutorSession.fromJson(map);
    } catch (_) {
      return null;
    }
  }
}
