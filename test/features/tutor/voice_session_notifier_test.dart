import 'package:flutter_test/flutter_test.dart';
import 'package:lahjti/features/learning/domain/models/learner_context.dart';
import 'package:lahjti/features/learning/domain/repositories/learning_repository.dart';
import 'package:lahjti/features/onboarding/domain/models/tutor_persona.dart';
import 'package:lahjti/features/progress/domain/models/xp_models.dart';
import 'package:lahjti/features/tutor/data/services/mock_speech_to_text_service.dart';
import 'package:lahjti/features/tutor/data/services/mock_text_to_speech_service.dart';
import 'package:lahjti/features/tutor/domain/models/voice_session_state.dart';
import 'package:lahjti/features/tutor/domain/repositories/tutor_conversation_repository.dart';
import 'package:lahjti/features/tutor/presentation/providers/voice_session_provider.dart';

class FakeConversationRepository implements TutorConversationRepository {
  int callCount = 0;
  String lastUserText = '';
  bool lastIsSessionStart = false;
  LearnerContext? lastLearnerContext;

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
    callCount++;
    lastUserText = userText;
    lastIsSessionStart = isSessionStart;
    lastLearnerContext = learnerContext;

    if (isSessionStart) {
      return VoiceMessage(
        id: 'opening_$callCount',
        isUser: false,
        text: 'Hey there! Ready to practice today?',
        explanationArabic: 'أهلاً وسهلاً يا بطل! جاهز نتدرب سوا؟',
        shouldCorrect: false,
        encouragement: 'يلا نبدأ!',
        nextDifficulty: 'same',
        timestamp: DateTime.now(),
      );
    }

    if (userText.contains('go yesterday')) {
      return VoiceMessage(
        id: 'reply_$callCount',
        isUser: false,
        text: 'Oh nice! You mean: I went yesterday.',
        explanationArabic: 'الفعل لازم يكون بالماضي (went) 👍',
        correctedAnswer: 'I went yesterday.',
        detectedErrors: const ['Past tense: use "went"'],
        shouldCorrect: true,
        encouragement: 'قربنا نتقنها!',
        nextDifficulty: 'same',
        timestamp: DateTime.now(),
      );
    }

    return VoiceMessage(
      id: 'reply_$callCount',
      isUser: false,
      text: 'Great answer! Tell me more.',
      explanationArabic: 'كلامك مفهوم وممتاز 👍',
      shouldCorrect: false,
      encouragement: 'أحسنت!',
      nextDifficulty: 'same',
      timestamp: DateTime.now(),
    );
  }
}

class FakeLearningRepo implements LearningRepository {
  int recordedActivityCount = 0;
  XpActivityType? lastActivityType;
  int? lastAccuracy;

  @override
  Future<void> recordLearningActivity(
    String userId,
    XpActivityType type, {
    int? count,
    int? accuracy,
    String? referenceId,
  }) async {
    recordedActivityCount++;
    lastActivityType = type;
    lastAccuracy = accuracy;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('VoiceSessionNotifier Unit Tests', () {
    late MockSpeechToTextService mockStt;
    late MockTextToSpeechService mockTts;
    late FakeConversationRepository fakeRepo;
    late VoiceSessionNotifier notifier;

    final abbasTutor = TutorPersona.tutors.firstWhere((t) => t.id == 'abbas');

    setUp(() {
      mockStt = MockSpeechToTextService(autoFinalize: true);
      mockTts = MockTextToSpeechService();
      fakeRepo = FakeConversationRepository();

      notifier = VoiceSessionNotifier(
        sttService: mockStt,
        ttsService: mockTts,
        conversationRepository: fakeRepo,
        initialTutor: abbasTutor,
        targetLanguageCode: 'en',
      );
    });

    test(
      '1. Session initializes with ready status and dynamic AI tutor greeting',
      () async {
        await notifier.initializeSession(defaultGreeting: 'Hey there!');

        expect(notifier.state.status, VoiceSessionStatus.ready);
        expect(notifier.state.messages.length, 1);
        expect(fakeRepo.lastIsSessionStart, isTrue);
        expect(notifier.state.messages.first.text, contains('Hey there!'));
        expect(
          notifier.state.messages.first.explanationArabic,
          contains('أهلاً'),
        );
        expect(notifier.state.tutor.id, 'abbas');
        expect(mockTts.speakCount, 1);
      },
    );

    test(
      '2. Start listening updates status to listening and captures transcripts',
      () async {
        await notifier.initializeSession(defaultGreeting: 'Welcome!');

        mockStt.simulatedSpeechResult = 'I love learning languages';
        await notifier.startListening();

        expect(fakeRepo.callCount, 2); // 1 for session start, 1 for user turn
        expect(fakeRepo.lastUserText, 'I love learning languages');
        expect(notifier.state.messages.length, 3); // greeting, user, tutor
        expect(
          notifier.state.messages.last.explanationArabic,
          contains('مفهوم'),
        );
      },
    );

    test(
      '3. Structured correction and Arabic feedback returned for language errors',
      () async {
        await notifier.initializeSession(defaultGreeting: 'Welcome!');

        mockStt.simulatedSpeechResult = 'I go yesterday to the store';
        await notifier.startListening();

        final tutorReply = notifier.state.messages.last;
        expect(tutorReply.shouldCorrect, isTrue);
        expect(tutorReply.correctedAnswer, 'I went yesterday.');
        expect(tutorReply.explanationArabic, contains('الماضي'));
        expect(tutorReply.encouragement, isNotNull);
      },
    );

    test(
      '4. Duplicate startListening calls while listening are safely ignored',
      () async {
        await notifier.initializeSession(defaultGreeting: 'Hi');

        final slowStt = MockSpeechToTextService(autoFinalize: false);
        final customNotifier = VoiceSessionNotifier(
          sttService: slowStt,
          ttsService: mockTts,
          conversationRepository: fakeRepo,
          initialTutor: abbasTutor,
          targetLanguageCode: 'en',
        );

        customNotifier.startListening();
        expect(customNotifier.state.isListening, isTrue);

        // Second rapid call
        customNotifier.startListening();
        expect(customNotifier.state.isListening, isTrue);
      },
    );

    test(
      '5. Stop speaking halts TTS playback and resets status to ready',
      () async {
        await notifier.initializeSession(defaultGreeting: 'Hi');

        notifier.state = notifier.state.copyWith(
          status: VoiceSessionStatus.speaking,
        );
        await notifier.stopSpeaking();

        expect(mockTts.stopCount, 1);
        expect(notifier.state.status, VoiceSessionStatus.ready);
      },
    );

    test(
      '6. STT permission denied sets friendly error without crashing',
      () async {
        mockStt.setPermission(false);
        await notifier.initializeSession(defaultGreeting: 'Hi');

        await notifier.startListening();

        expect(notifier.state.status, VoiceSessionStatus.ready);
        expect(notifier.state.errorMessage, contains('permission'));
      },
    );

    test(
      '7. Sending text directly simulates turn and speaks response',
      () async {
        await notifier.initializeSession(defaultGreeting: 'Hi');

        await notifier.sendTextMessage('Hello tutor');

        expect(fakeRepo.callCount, 2);
        expect(notifier.state.messages.length, 3);
        expect(notifier.state.messages[1].text, 'Hello tutor');
        expect(notifier.state.messages[1].isUser, isTrue);
      },
    );

    test('8. Clean disposal releases audio resources', () {
      notifier.dispose();
      expect(mockStt.isListening, isFalse);
      expect(mockTts.isSpeaking, isFalse);
    });

    test(
      '9. LearnerContext is passed through to conversation repository',
      () async {
        const customContext = LearnerContext(
          currentLessonTitle: 'Travel Basics',
          currentTopic: 'Airport & Travel',
          targetVocabulary: ['passport', 'ticket', 'flight'],
          weaknesses: ['articles'],
        );

        final contextNotifier = VoiceSessionNotifier(
          sttService: mockStt,
          ttsService: mockTts,
          conversationRepository: fakeRepo,
          initialTutor: abbasTutor,
          targetLanguageCode: 'en',
          learnerContext: customContext,
        );

        await contextNotifier.initializeSession(defaultGreeting: 'Hi');
        expect(fakeRepo.lastLearnerContext, isNotNull);
        expect(
          fakeRepo.lastLearnerContext?.currentLessonTitle,
          'Travel Basics',
        );
        expect(fakeRepo.lastLearnerContext?.currentTopic, 'Airport & Travel');
        expect(
          fakeRepo.lastLearnerContext?.targetVocabulary,
          contains('passport'),
        );

        await contextNotifier.sendTextMessage('Where is my flight?');
        expect(
          fakeRepo.lastLearnerContext?.currentLessonTitle,
          'Travel Basics',
        );
      },
    );

    test(
      '10. Tutor conversation turn records learning activity in repository',
      () async {
        final fakeLearningRepo = FakeLearningRepo();

        final learningNotifier = VoiceSessionNotifier(
          sttService: mockStt,
          ttsService: mockTts,
          conversationRepository: fakeRepo,
          learningRepository: fakeLearningRepo,
          initialTutor: abbasTutor,
          targetLanguageCode: 'en',
        );

        await learningNotifier.initializeSession(defaultGreeting: 'Hi');
        expect(
          fakeLearningRepo.recordedActivityCount,
          0,
        ); // No XP for initial opening greeting

        // User sends turn with error
        await learningNotifier.sendTextMessage('I go yesterday');
        expect(fakeLearningRepo.recordedActivityCount, 1);
        expect(
          fakeLearningRepo.lastActivityType,
          XpActivityType.tutorConversation,
        );
        expect(fakeLearningRepo.lastAccuracy, 50);

        // User sends correct turn
        await learningNotifier.sendTextMessage('I love learning English');
        expect(fakeLearningRepo.recordedActivityCount, 2);
        expect(fakeLearningRepo.lastAccuracy, 95);
      },
    );
  });
}
