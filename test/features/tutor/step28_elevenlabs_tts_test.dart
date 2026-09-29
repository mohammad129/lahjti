import 'package:flutter_test/flutter_test.dart';
import 'package:lahjti/features/onboarding/domain/models/tutor_persona.dart';
import 'package:lahjti/features/tutor/data/services/hybrid_elevenlabs_tts_service.dart';
import 'package:lahjti/features/tutor/data/services/mock_speech_to_text_service.dart';
import 'package:lahjti/features/tutor/data/services/mock_text_to_speech_service.dart';
import 'package:lahjti/features/tutor/domain/models/voice_session_state.dart';
import 'package:lahjti/features/tutor/domain/repositories/tutor_conversation_repository.dart';
import 'package:lahjti/features/tutor/presentation/providers/voice_session_provider.dart';

class _MockTutorConversationRepo implements TutorConversationRepository {
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
  }) async {
    return VoiceMessage(
      id: 'm_eleven_01',
      isUser: false,
      text: '¡Hola! ¿Cómo estás hoy?',
      explanationArabic: 'مرحباً! كيف حالك اليوم؟',
      audioBase64:
          'UklGRiQAAABXQVZFZm10IBAAAAABAAEARKwAAIhYAQACABAAZGF0YQAAAAA=',
      voiceProvider: 'elevenlabs',
      timestamp: DateTime.now(),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('STEP 28: Production ElevenLabs Voice & TTS Tests', () {
    test(
      '1. VoiceMessage model serializes and deserializes audioBase64 and voiceProvider',
      () {
        final msg = VoiceMessage(
          id: 'msg_101',
          isUser: false,
          text: 'Bonjour le monde!',
          explanationArabic: 'أهلاً بالعالم!',
          audioBase64: 'base64_mp3_audio_payload_here',
          voiceProvider: 'elevenlabs',
          timestamp: DateTime(2026, 9, 26, 12, 0),
        );

        final json = msg.toJson();
        expect(json['audioBase64'], equals('base64_mp3_audio_payload_here'));
        expect(json['voiceProvider'], equals('elevenlabs'));

        final reconstructed = VoiceMessage.fromJson(
          {
            'tutorResponse': 'Bonjour le monde!',
            'explanationArabic': 'أهلاً بالعالم!',
            'audioBase64': 'base64_mp3_audio_payload_here',
            'voiceProvider': 'elevenlabs',
          },
          id: 'msg_101',
          timestamp: DateTime(2026, 9, 26, 12, 0),
        );

        expect(
          reconstructed.audioBase64,
          equals('base64_mp3_audio_payload_here'),
        );
        expect(reconstructed.voiceProvider, equals('elevenlabs'));
        expect(reconstructed.text, equals('Bonjour le monde!'));
      },
    );

    test(
      '2. HybridElevenLabsTtsService initializes and reports availability',
      () async {
        final hybridService = HybridElevenLabsTtsService();
        final isInit = await hybridService.initialize();
        expect(isInit, isTrue);
        expect(hybridService.isAvailable, isTrue);
      },
    );

    test(
      '3. VoiceSessionNotifier routes tutor voice responses with ElevenLabs payload',
      () async {
        final mockStt = MockSpeechToTextService();
        final mockTts = MockTextToSpeechService();
        final repo = _MockTutorConversationRepo();

        final notifier = VoiceSessionNotifier(
          sttService: mockStt,
          ttsService: mockTts,
          conversationRepository: repo,
          initialTutor: TutorPersona.tutors.first,
          targetLanguageCode: 'es',
        );

        await notifier.initializeSession();

        expect(notifier.state.messages, isNotEmpty);
        final firstMsg = notifier.state.messages.first;
        expect(firstMsg.text, equals('¡Hola! ¿Cómo estás hoy?'));
        expect(firstMsg.audioBase64, isNotNull);
        expect(firstMsg.voiceProvider, equals('elevenlabs'));
      },
    );
  });
}
