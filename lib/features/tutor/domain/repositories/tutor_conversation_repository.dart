import '../../../learning/domain/models/learner_context.dart';
import '../models/student_tutor_session.dart';
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
    String? sessionId,
    int voiceDurationSeconds = 0,
  });

  /// Fetches daily 4-session and 1-hour quota status for a school student
  Future<StudentTutorSession?> getStudentSessionStatus();

  /// Starts a new session slot (1..4) for a school student
  Future<StudentTutorSession?> startStudentSession();

  /// Concludes the active session slot
  Future<StudentTutorSession?> endStudentSession({String? sessionId});
}
