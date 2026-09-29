import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../learning/domain/models/learner_context.dart';
import '../../../learning/domain/repositories/learning_repository.dart';
import '../../../learning/presentation/providers/learning_providers.dart';
import '../../../onboarding/domain/models/tutor_persona.dart';
import '../../../onboarding/presentation/providers/onboarding_provider.dart';
import '../../../progress/domain/models/xp_models.dart';
import '../../data/repositories/remote_tutor_conversation_repository.dart';
import '../../data/services/hybrid_elevenlabs_tts_service.dart';
import '../../data/services/platform_speech_to_text_service.dart';
import '../../domain/models/voice_session_state.dart';
import '../../domain/repositories/tutor_conversation_repository.dart';
import '../../domain/services/speech_to_text_service.dart';
import '../../domain/services/text_to_speech_service.dart';

/// Provider for the [SpeechToTextService].
final speechToTextServiceProvider = Provider<SpeechToTextService>((ref) {
  final service = PlatformSpeechToTextService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider for the [TextToSpeechService] (defaults to Hybrid ElevenLabs with on-device fallback).
final textToSpeechServiceProvider = Provider<TextToSpeechService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final service = HybridElevenLabsTtsService(apiClient: apiClient);
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider for the Remote [TutorConversationRepository] calling the secure gateway.
final remoteTutorConversationRepositoryProvider =
    Provider<TutorConversationRepository>((ref) {
      final apiClient = ref.watch(apiClientProvider);
      return RemoteTutorConversationRepository(apiClient);
    });

/// Provider for the active [TutorConversationRepository] (defaults to remote with offline fallback).
final tutorConversationRepositoryProvider = Provider<
  TutorConversationRepository
>((ref) {
  // In tests/offline, can be overridden with TutorConversationRepositoryImpl or Mock
  final apiClient = ref.watch(apiClientProvider);
  return RemoteTutorConversationRepository(apiClient);
});

class VoiceSessionNotifier extends StateNotifier<VoiceSessionState> {
  final SpeechToTextService _sttService;
  final TextToSpeechService _ttsService;
  final TutorConversationRepository _conversationRepository;
  final LearningRepository? _learningRepository;
  final LearnerContext? _learnerContext;
  final String _nativeLanguage;
  final String _ageGroup;
  final String _learningGoal;
  final String _difficulty;

  VoiceSessionNotifier({
    required SpeechToTextService sttService,
    required TextToSpeechService ttsService,
    required TutorConversationRepository conversationRepository,
    required TutorPersona initialTutor,
    required String targetLanguageCode,
    LearningRepository? learningRepository,
    LearnerContext? learnerContext,
    String nativeLanguage = 'arabic',
    String ageGroup = 'adult',
    String learningGoal = 'conversation',
    String difficulty = 'a1',
  }) : _sttService = sttService,
       _ttsService = ttsService,
       _conversationRepository = conversationRepository,
       _learningRepository = learningRepository,
       _learnerContext = learnerContext,
       _nativeLanguage = nativeLanguage,
       _ageGroup = ageGroup,
       _learningGoal = learningGoal,
       _difficulty = difficulty,
       super(
         VoiceSessionState(
           status: VoiceSessionStatus.ready,
           tutor: initialTutor,
           targetLanguageCode: targetLanguageCode,
         ),
       );

  /// Initializes audio engines and dynamically generates the initial welcome greeting.
  Future<void> initializeSession({String? defaultGreeting}) async {
    state = state.copyWith(status: VoiceSessionStatus.requestingPermission);

    final sttOk = await _sttService.initialize();
    final ttsOk = await _ttsService.initialize();

    state = state.copyWith(
      status: VoiceSessionStatus.processing,
      isSpeechAvailable: sttOk,
      isTtsAvailable: ttsOk,
    );

    try {
      final openingMessage = await _conversationRepository
          .generateTutorResponse(
            userText: 'Start session',
            targetLanguageCode: state.targetLanguageCode,
            tutorId: state.tutor.id,
            history: const [],
            nativeLanguage: _nativeLanguage,
            ageGroup: _ageGroup,
            learningGoal: _learningGoal,
            difficulty: _difficulty,
            isSessionStart: true,
            learnerContext: _learnerContext,
          );

      state = state.copyWith(
        status: VoiceSessionStatus.ready,
        messages: [openingMessage],
      );

      if (ttsOk) {
        await speakTutorMessage(openingMessage);
      }
    } catch (e) {
      final isAbbas = state.tutor.id == 'abbas';
      final fallbackMsg = VoiceMessage(
        id: 'greeting_fallback_${DateTime.now().millisecondsSinceEpoch}',
        isUser: false,
        text:
            defaultGreeting ??
            (isAbbas
                ? "Hey! Ready to practice? Let's start!"
                : "Hello! Excited to practice with you today!"),
        explanationArabic:
            isAbbas
                ? "أهلاً وسهلاً يا بطل! يلا نبدأ المحادثة."
                : "أهلاً وسهلاً فيك! متحمسة نبدأ سوا.",
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        status: VoiceSessionStatus.ready,
        messages: [fallbackMsg],
      );

      if (ttsOk) {
        await speakTutorMessage(fallbackMsg);
      }
    }
  }

  /// Starts listening to the user's speech via the microphone.
  Future<void> startListening() async {
    if (state.isListening || state.isProcessing) return;

    // If currently speaking, interrupt playback immediately
    if (state.isSpeaking) {
      await _ttsService.stop();
    }

    state = state.copyWith(
      status: VoiceSessionStatus.listening,
      currentTranscript: '',
      errorMessage: null,
      soundLevel: 0.2,
    );

    try {
      await _sttService.startListening(
        languageCode: state.targetLanguageCode,
        onResult: (words, isFinal) {
          state = state.copyWith(currentTranscript: words);

          if (isFinal && words.trim().isNotEmpty) {
            _processFinalTranscript(words.trim());
          }
        },
        onSoundLevelChange: (level) {
          state = state.copyWith(soundLevel: level);
        },
        onError: (error) {
          state = state.copyWith(
            status: VoiceSessionStatus.ready,
            errorMessage: error,
            soundLevel: 0.0,
          );
        },
      );
    } catch (e) {
      state = state.copyWith(
        status: VoiceSessionStatus.ready,
        errorMessage: e.toString(),
        soundLevel: 0.0,
      );
    }
  }

  /// Manually stops microphone listening and processes accumulated transcript.
  Future<void> stopListening() async {
    if (!state.isListening) return;

    await _sttService.stopListening();
    final transcript = state.currentTranscript.trim();

    if (transcript.isNotEmpty) {
      await _processFinalTranscript(transcript);
    } else {
      state = state.copyWith(status: VoiceSessionStatus.ready, soundLevel: 0.0);
    }
  }

  /// Processes user transcribed text and triggers AI reply generation.
  Future<void> _processFinalTranscript(String transcript) async {
    if (state.isProcessing) return;

    final userMessage = VoiceMessage(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      isUser: true,
      text: transcript,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      status: VoiceSessionStatus.processing,
      messages: [...state.messages, userMessage],
      currentTranscript: '',
      soundLevel: 0.0,
    );

    try {
      final tutorReply = await _conversationRepository.generateTutorResponse(
        userText: transcript,
        targetLanguageCode: state.targetLanguageCode,
        tutorId: state.tutor.id,
        history: state.messages,
        nativeLanguage: _nativeLanguage,
        ageGroup: _ageGroup,
        learningGoal: _learningGoal,
        difficulty: _difficulty,
        isSessionStart: false,
        learnerContext: _learnerContext,
      );

      state = state.copyWith(
        messages: [...state.messages, tutorReply],
        status: VoiceSessionStatus.ready,
      );

      // Record bounded learning activity in repository (anti-farming + streak updates)
      if (_learningRepository != null) {
        final accuracy =
            tutorReply.shouldCorrect
                ? (tutorReply.detectedErrors.isEmpty ? 70 : 50)
                : 95;
        try {
          await _learningRepository.recordLearningActivity(
            'usr_active',
            XpActivityType.tutorConversation,
            accuracy: accuracy,
            referenceId: 'tutor_${state.tutor.id}',
          );
        } catch (_) {
          // Graceful fallback for offline or non-blocking network issues
        }
      }

      // Play tutor voice response
      await speakTutorMessage(tutorReply);
    } catch (e) {
      final userFriendlyMsg =
          e is AppException
              ? e.message
              : 'تعذر الاتصال بالمعلم الذكي. يرجى المحاولة مرة أخرى.';
      state = state.copyWith(
        status: VoiceSessionStatus.ready,
        errorMessage: userFriendlyMsg,
      );
    }
  }

  /// Speaks a tutor message using the TTS engine.
  Future<void> speakTutorMessage(VoiceMessage message) async {
    state = state.copyWith(status: VoiceSessionStatus.speaking);

    await _ttsService.speak(
      text: message.text,
      languageCode: state.targetLanguageCode,
      audioBase64: message.audioBase64,
      tutorPersona: state.tutor.id,
      onComplete: () {
        state = state.copyWith(status: VoiceSessionStatus.ready);
      },
      onError: (err) {
        state = state.copyWith(
          status: VoiceSessionStatus.ready,
          errorMessage: err,
        );
      },
    );
  }

  /// Stops ongoing TTS speech playback.
  Future<void> stopSpeaking() async {
    await _ttsService.stop();
    state = state.copyWith(status: VoiceSessionStatus.ready);
  }

  /// Sends text directly (fallback for typing instead of voice).
  Future<void> sendTextMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.isProcessing) return;
    await _processFinalTranscript(trimmed);
  }

  @override
  void dispose() {
    _sttService.dispose();
    _ttsService.dispose();
    super.dispose();
  }
}

/// Provider for the active [VoiceSessionNotifier].
final voiceSessionNotifierProvider = StateNotifierProvider.autoDispose<
  VoiceSessionNotifier,
  VoiceSessionState
>((ref) {
  final sttService = ref.watch(speechToTextServiceProvider);
  final ttsService = ref.watch(textToSpeechServiceProvider);
  final conversationRepo = ref.watch(tutorConversationRepositoryProvider);
  final learningRepo = ref.watch(learningRepositoryProvider);
  final learnerContext = ref.watch(learnerContextProvider);
  final onboardingData = ref.watch(onboardingProvider.select((s) => s.data));

  final selectedTutorId = onboardingData.selectedTutorId ?? 'abbas';
  final tutor = TutorPersona.tutors.firstWhere(
    (t) => t.id == selectedTutorId,
    orElse: () => TutorPersona.tutors.first,
  );

  final targetLangCode = learnerContext.targetLanguage;
  final nativeLang = learnerContext.nativeLanguage;
  final ageGroup = learnerContext.ageGroup;
  final learningGoal = learnerContext.learningGoal;
  final difficulty = learnerContext.cefrLevel.code.toLowerCase();

  return VoiceSessionNotifier(
    sttService: sttService,
    ttsService: ttsService,
    conversationRepository: conversationRepo,
    learningRepository: learningRepo,
    learnerContext: learnerContext,
    initialTutor: tutor,
    targetLanguageCode: targetLangCode,
    nativeLanguage: nativeLang,
    ageGroup: ageGroup,
    learningGoal: learningGoal,
    difficulty: difficulty,
  );
});
