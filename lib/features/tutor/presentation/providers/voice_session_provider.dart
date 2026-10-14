import 'dart:async';
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
import '../../domain/models/student_tutor_session.dart';
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
  Timer? _sessionTicker;

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

  void _startSessionTicker() {
    _sessionTicker?.cancel();
    _sessionTicker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final currentSession = state.studentSession;
      if (currentSession == null || !currentSession.isSchoolStudent) return;

      final updatedElapsed = state.sessionElapsedSeconds + 1;
      final remaining = (currentSession.remainingSecondsToday - 1).clamp(0, 3600);
      final updatedSession = currentSession.copyWith(
        remainingSecondsToday: remaining,
        activeSessionDurationSeconds:
            currentSession.activeSessionDurationSeconds + 1,
        totalSecondsUsedToday: currentSession.totalSecondsUsedToday + 1,
      );

      if (remaining <= 0) {
        timer.cancel();
        state = state.copyWith(
          sessionElapsedSeconds: updatedElapsed,
          studentSession: updatedSession,
          isSessionEnded: true,
          errorMessage:
              'أحسنت يا بطل! أنهيت ساعة المحادثة اليومية بالكامل. استرح الآن ونراك غداً لمتابعة التعلّم!',
        );
      } else {
        state = state.copyWith(
          sessionElapsedSeconds: updatedElapsed,
          studentSession: updatedSession,
        );
      }
    });
  }

  /// Concludes current active student session and marks it completed
  Future<void> endCurrentSession() async {
    _sessionTicker?.cancel();
    try {
      final updated = await _conversationRepository.endStudentSession(
        sessionId: state.studentSession?.activeSessionId,
      );
      if (!mounted) return;
      state = state.copyWith(
        studentSession: updated ?? state.studentSession,
        isSessionEnded: true,
        status: VoiceSessionStatus.ready,
      );
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(isSessionEnded: true);
    }
  }

  /// Starts the next session for the school student (up to 4 sessions/day)
  Future<void> startNextSession() async {
    try {
      final newSession = await _conversationRepository.startStudentSession();
      if (!mounted) return;
      state = state.copyWith(
        studentSession: newSession ?? state.studentSession,
        sessionElapsedSeconds: 0,
        isSessionEnded: false,
        status: VoiceSessionStatus.ready,
        errorMessage: null,
      );
      _startSessionTicker();
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  /// Initializes audio engines and dynamically generates the initial welcome greeting.
  Future<void> initializeSession({String? defaultGreeting}) async {
    state = state.copyWith(status: VoiceSessionStatus.requestingPermission);

    final sttOk = await _sttService.initialize();
    final ttsOk = await _ttsService.initialize();

    if (!mounted) return;

    // Load school student daily session status if in school context
    try {
      final studentStatus =
          await _conversationRepository.getStudentSessionStatus();
      if (mounted && studentStatus != null) {
        state = state.copyWith(studentSession: studentStatus);
        if (studentStatus.isSchoolStudent && !studentStatus.isDailyLimitReached) {
          _startSessionTicker();
        }
      }
    } catch (_) {
      // Non-blocking fallback
    }

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
            sessionId: state.studentSession?.activeSessionId,
          );

      if (!mounted) return;

      state = state.copyWith(
        status: VoiceSessionStatus.ready,
        messages: [openingMessage],
        studentSession: openingMessage.studentSession ?? state.studentSession,
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

      if (!mounted) return;

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

    if (!mounted) return;

    state = state.copyWith(
      status: VoiceSessionStatus.listening,
      currentTranscript: '',
      errorMessage: null,
      soundLevel: 0.2,
    );

    try {
      await _sttService.startListening(
        // Recognition follows the learner's spoken language, not the language
        // being learned. This makes Arabic speech work for an Arabic learner
        // practising English, while the backend still detects language per turn.
        languageCode: _recognitionLanguageCode(),
        onResult: (words, isFinal) {
          if (!mounted) return;
          state = state.copyWith(currentTranscript: words);

          if (isFinal && words.trim().isNotEmpty) {
            _processFinalTranscript(words.trim());
          }
        },
        onSoundLevelChange: (level) {
          if (!mounted) return;
          state = state.copyWith(soundLevel: level);
        },
        onError: (error) {
          if (!mounted) return;
          state = state.copyWith(
            status: VoiceSessionStatus.ready,
            errorMessage: error,
            soundLevel: 0.0,
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
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
      if (!mounted) return;
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
        sessionId: state.studentSession?.activeSessionId,
        voiceDurationSeconds: 15,
      );

      if (!mounted) return;

      state = state.copyWith(
        messages: [...state.messages, tutorReply],
        status: VoiceSessionStatus.ready,
        studentSession: tutorReply.studentSession ?? state.studentSession,
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
      if (!mounted) return;
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
      languageCode: message.conversationLanguage ?? state.targetLanguageCode,
      audioBase64: message.audioBase64,
      tutorPersona: state.tutor.id,
      onComplete: () {
        if (!mounted) return;
        state = state.copyWith(status: VoiceSessionStatus.ready);
      },
      onError: (err) {
        if (!mounted) return;
        state = state.copyWith(
          status: VoiceSessionStatus.ready,
          errorMessage: err,
        );
      },
    );
  }

  /// Stops ongoing TTS speech playback (interrupts tutor immediately).
  Future<void> stopSpeaking() async {
    await _ttsService.stop();
    if (!mounted) return;
    state = state.copyWith(status: VoiceSessionStatus.ready);
  }

  /// Toggles spoken input language between Arabic ('ar') and English ('en')
  void toggleInputLanguage() {
    final next = state.inputLanguageCode == 'ar' ? 'en' : 'ar';
    state = state.copyWith(inputLanguageCode: next);
  }

  /// Explicitly sets the input spoken language mode ('ar' or 'en')
  void setInputLanguage(String code) {
    state = state.copyWith(inputLanguageCode: code);
  }

  String _recognitionLanguageCode() {
    return state.inputLanguageCode;
  }

  /// Sends text directly (fallback for typing instead of voice).
  Future<void> sendTextMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.isProcessing) return;
    await _processFinalTranscript(trimmed);
  }

  @override
  void dispose() {
    _sessionTicker?.cancel();
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

/// Lightweight provider for daily student tutor session status (used on Home/Dashboard screens).
final studentTutorSessionStatusProvider =
    FutureProvider<StudentTutorSession?>((ref) async {
  try {
    final repo = ref.watch(tutorConversationRepositoryProvider);
    return await repo.getStudentSessionStatus();
  } catch (_) {
    return null;
  }
});

