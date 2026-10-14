import 'package:flutter_test/flutter_test.dart';
import 'package:lahjti/features/onboarding/domain/models/tutor_persona.dart';
import 'package:lahjti/features/tutor/data/services/mock_speech_to_text_service.dart';
import 'package:lahjti/features/tutor/data/services/mock_text_to_speech_service.dart';
import 'package:lahjti/features/tutor/domain/models/student_tutor_session.dart';
import 'package:lahjti/features/tutor/domain/models/voice_session_state.dart';
import 'package:lahjti/features/tutor/domain/repositories/tutor_conversation_repository.dart';
import 'package:lahjti/features/tutor/presentation/providers/voice_session_provider.dart';

class _FakeStudentConversationRepo implements TutorConversationRepository {
  StudentTutorSession currentSession;

  _FakeStudentConversationRepo(this.currentSession);

  @override
  Future<StudentTutorSession?> getStudentSessionStatus() async => currentSession;

  @override
  Future<StudentTutorSession?> startStudentSession() async {
    currentSession = currentSession.copyWith(
      activeSessionId: 'sess_new_active',
      currentSessionNumber: currentSession.currentSessionNumber,
      activeSessionDurationSeconds: 0,
    );
    return currentSession;
  }

  @override
  Future<StudentTutorSession?> endStudentSession({String? sessionId}) async {
    currentSession = currentSession.copyWith(
      activeSessionId: null,
      completedSessionsCount: currentSession.completedSessionsCount + 1,
      currentSessionNumber: (currentSession.completedSessionsCount + 2).clamp(1, 4),
      activeSessionDurationSeconds: 0,
    );
    return currentSession;
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
    dynamic learnerContext,
    String? sessionId,
    int voiceDurationSeconds = 0,
  }) async {
    return VoiceMessage(
      id: 'resp_1',
      isUser: false,
      text: 'Good job speaking English today!',
      explanationArabic: 'ممتاز يا بطل! لغتك واضحة وجميلة.',
      studentSession: currentSession,
      timestamp: DateTime.now(),
    );
  }
}

void main() {
  group('StudentTutorSession Domain and Quota Rules', () {
    test('1. Model calculations for 4 sessions and 1 hour limit', () {
      const session = StudentTutorSession(
        isSchoolStudent: true,
        maxDailySessions: 4,
        completedSessionsCount: 1,
        currentSessionNumber: 2,
        remainingSessions: 3,
        maxDailySeconds: 3600,
        totalSecondsUsedToday: 900,
        remainingSecondsToday: 2700,
        canStartOrContinueSession: true,
      );

      expect(session.isDailyLimitReached, isFalse);
      expect(session.remainingMinutesText(true), equals('45 دقيقة'));
      expect(session.remainingMinutesText(false), equals('45 min'));
      expect(session.sessionProgressLabel(true), equals('الجلسة 2 من 4'));
      expect(session.sessionProgressLabel(false), equals('Session 2 of 4'));
      expect(session.remainingTimeFormatted, equals('45:00'));
      expect(session.dailyUsedFraction, closeTo(0.25, 0.01));
    });

    test('2. Limit reached when 4 sessions completed or 3600 seconds exhausted', () {
      const sessionCompleted4 = StudentTutorSession(
        isSchoolStudent: true,
        completedSessionsCount: 4,
        maxDailySessions: 4,
        remainingSecondsToday: 600,
      );
      expect(sessionCompleted4.isDailyLimitReached, isTrue);

      const sessionTimeExhausted = StudentTutorSession(
        isSchoolStudent: true,
        completedSessionsCount: 2,
        maxDailySessions: 4,
        remainingSecondsToday: 0,
      );
      expect(sessionTimeExhausted.isDailyLimitReached, isTrue);
    });

    test('3. JSON serialization preserves all school quota attributes', () {
      final original = StudentTutorSession(
        isSchoolStudent: true,
        maxDailySessions: 4,
        completedSessionsCount: 3,
        currentSessionNumber: 4,
        remainingSessions: 1,
        maxDailySeconds: 3600,
        totalSecondsUsedToday: 3000,
        remainingSecondsToday: 600,
        activeSessionId: 'sess_12345',
        activeSessionDurationSeconds: 120,
        canStartOrContinueSession: true,
      );

      final json = original.toJson();
      final parsed = StudentTutorSession.fromJson(json);

      expect(parsed.isSchoolStudent, isTrue);
      expect(parsed.maxDailySessions, equals(4));
      expect(parsed.completedSessionsCount, equals(3));
      expect(parsed.currentSessionNumber, equals(4));
      expect(parsed.remainingSecondsToday, equals(600));
      expect(parsed.activeSessionId, equals('sess_12345'));
    });
  });

  group('VoiceSessionNotifier Student Session Integration', () {
    test('1. Loads student session and ends current session cleanly', () async {
      final initialSession = StudentTutorSession(
        isSchoolStudent: true,
        maxDailySessions: 4,
        completedSessionsCount: 0,
        currentSessionNumber: 1,
        remainingSessions: 4,
        maxDailySeconds: 3600,
        totalSecondsUsedToday: 0,
        remainingSecondsToday: 3600,
        activeSessionId: 'sess_active_1',
      );

      final fakeRepo = _FakeStudentConversationRepo(initialSession);
      final notifier = VoiceSessionNotifier(
        conversationRepository: fakeRepo,
        sttService: MockSpeechToTextService(),
        ttsService: MockTextToSpeechService(),
        initialTutor: TutorPersona.tutors.first,
        targetLanguageCode: 'en',
      );

      await notifier.initializeSession();
      expect(notifier.state.studentSession, isNotNull);
      expect(notifier.state.studentSession!.currentSessionNumber, equals(1));

      // End session
      await notifier.endCurrentSession();
      expect(notifier.state.isSessionEnded, isTrue);
      expect(notifier.state.studentSession!.completedSessionsCount, equals(1));

      // Start next session
      await notifier.startNextSession();
      expect(notifier.state.isSessionEnded, isFalse);
      expect(notifier.state.studentSession!.activeSessionId, equals('sess_new_active'));
    });
  });
}
