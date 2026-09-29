import '../../../learning/domain/models/learner_context.dart';
import '../models/voice_session_state.dart';

/// Abstract repository contract for AI tutor conversation turns.
abstract class TutorConversationRepository {
  /// Sends the user's spoken transcript to the secure backend AI gateway and receives a structured tutor reply.
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
  });
}
