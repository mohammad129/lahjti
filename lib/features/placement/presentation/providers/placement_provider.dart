import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../learning/domain/models/learning_profile.dart';
import '../../../onboarding/domain/models/experience_level.dart';
import '../../../onboarding/domain/models/onboarding_data.dart';
import '../../../../core/network/api_client.dart';
import '../../data/providers/mock_language_evaluation_provider.dart';
import '../../data/providers/mock_placement_content_provider.dart';
import '../../data/providers/remote_language_evaluation_provider.dart';
import '../../data/repositories/remote_placement_repository.dart';
import '../../domain/models/placement_answer.dart';
import '../../domain/models/placement_evaluation.dart';
import '../../domain/models/placement_question.dart';
import '../../domain/models/placement_result.dart';
import '../../domain/models/placement_session.dart';
import '../../domain/providers/language_evaluation_provider.dart';
import '../../domain/providers/placement_content_provider.dart';
import '../../domain/providers/placement_engine.dart';
import '../../domain/repositories/placement_repository.dart';

/// Provider for the [PlacementContentProvider].
final placementContentProvider = Provider<PlacementContentProvider>((ref) {
  return const MockPlacementContentProvider();
});

/// Provider for the [PlacementRepository] connecting to the secure AI backend gateway.
final placementRepositoryProvider = Provider<PlacementRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return RemotePlacementRepository(apiClient);
});

/// Provider for the [RemoteLanguageEvaluationProvider] using the backend gateway.
final remoteLanguageEvaluationProvider = Provider<LanguageEvaluationProvider>((
  ref,
) {
  final repository = ref.watch(placementRepositoryProvider);
  return RemoteLanguageEvaluationProvider(repository);
});

/// Provider for the active [LanguageEvaluationProvider].
/// In test/mock mode, defaults to [MockLanguageEvaluationProvider].
/// In production, can be overridden with [remoteLanguageEvaluationProvider].
final languageEvaluationProvider = Provider<LanguageEvaluationProvider>((ref) {
  return const MockLanguageEvaluationProvider();
});

/// Provider for the [PlacementEngine].
final placementEngineProvider = Provider<PlacementEngine>((ref) {
  return const PlacementEngine();
});

enum PlacementStatus {
  idle,
  initializing,
  questionReady,
  evaluating,
  feedback,
  completed,
  error,
}

class PlacementState {
  final PlacementSession? session;
  final PlacementQuestion? currentQuestion;
  final PlacementStatus status;
  final PlacementEvaluation? lastEvaluation;
  final String? feedbackMessage;
  final PlacementResult? result;
  final LearningProfile? learningProfile;
  final String? errorMessage;
  final bool isSubmitting;
  final DateTime? questionStartTime;

  const PlacementState({
    this.session,
    this.currentQuestion,
    this.status = PlacementStatus.idle,
    this.lastEvaluation,
    this.feedbackMessage,
    this.result,
    this.learningProfile,
    this.errorMessage,
    this.isSubmitting = false,
    this.questionStartTime,
  });

  PlacementState copyWith({
    PlacementSession? session,
    PlacementQuestion? currentQuestion,
    PlacementStatus? status,
    PlacementEvaluation? lastEvaluation,
    String? feedbackMessage,
    PlacementResult? result,
    LearningProfile? learningProfile,
    String? errorMessage,
    bool? isSubmitting,
    DateTime? questionStartTime,
  }) {
    return PlacementState(
      session: session ?? this.session,
      currentQuestion: currentQuestion ?? this.currentQuestion,
      status: status ?? this.status,
      lastEvaluation: lastEvaluation ?? this.lastEvaluation,
      feedbackMessage: feedbackMessage ?? this.feedbackMessage,
      result: result ?? this.result,
      learningProfile: learningProfile ?? this.learningProfile,
      errorMessage: errorMessage ?? this.errorMessage,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      questionStartTime: questionStartTime ?? this.questionStartTime,
    );
  }
}

class PlacementNotifier extends StateNotifier<PlacementState> {
  final PlacementContentProvider _contentProvider;
  final LanguageEvaluationProvider _evaluationProvider;
  final PlacementEngine _engine;

  PlacementNotifier({
    required PlacementContentProvider contentProvider,
    required LanguageEvaluationProvider evaluationProvider,
    required PlacementEngine engine,
  }) : _contentProvider = contentProvider,
       _evaluationProvider = evaluationProvider,
       _engine = engine,
       super(const PlacementState());

  /// Initializes a new adaptive placement session from onboarding data.
  Future<void> startSession(OnboardingData data) async {
    if (data.targetLanguage == null ||
        data.nativeLanguage == null ||
        data.ageGroup == null ||
        data.learningGoal == null) {
      return;
    }

    state = state.copyWith(
      status: PlacementStatus.initializing,
      errorMessage: null,
    );

    try {
      final initialDifficulty = _engine.determineInitialDifficulty(
        data.experienceLevel ?? ExperienceLevel.zero,
      );

      final session = PlacementSession(
        id: 'session_${DateTime.now().millisecondsSinceEpoch}',
        userId: data.registeredUserId ?? 'guest_user',
        targetLanguage: data.targetLanguage!,
        nativeLanguage: data.nativeLanguage!,
        ageGroup: data.ageGroup!,
        learningGoal: data.learningGoal!,
        initialSelfAssessment: data.experienceLevel ?? ExperienceLevel.zero,
        currentDifficulty: initialDifficulty,
        startedAt: DateTime.now(),
      );

      final firstQuestion = await _contentProvider.getNextQuestion(
        targetLanguage: session.targetLanguage,
        nativeLanguage: session.nativeLanguage,
        ageGroup: session.ageGroup,
        learningGoal: session.learningGoal,
        difficulty: initialDifficulty,
        previousQuestionIds: const [],
      );

      state = state.copyWith(
        session: session.copyWith(questions: [firstQuestion]),
        currentQuestion: firstQuestion,
        status: PlacementStatus.questionReady,
        questionStartTime: DateTime.now(),
        isSubmitting: false,
      );
    } catch (e) {
      state = state.copyWith(
        status: PlacementStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Submits the user's answer or skip action and adapts difficulty.
  Future<void> submitAnswer({
    required String response,
    bool isSkipped = false,
  }) async {
    final session = state.session;
    final currentQ = state.currentQuestion;

    if (session == null ||
        currentQ == null ||
        state.isSubmitting ||
        state.status == PlacementStatus.evaluating) {
      return;
    }

    state = state.copyWith(
      status: PlacementStatus.evaluating,
      isSubmitting: true,
      errorMessage: null,
    );

    final duration =
        state.questionStartTime != null
            ? DateTime.now().difference(state.questionStartTime!)
            : const Duration(seconds: 5);

    final answer = PlacementAnswer(
      questionId: currentQ.id,
      userResponse: isSkipped ? '' : response.trim(),
      responseDuration: duration,
      skipped: isSkipped,
      submittedAt: DateTime.now(),
    );

    try {
      final evaluation = await _evaluationProvider.evaluate(
        targetLanguage: session.targetLanguage,
        nativeLanguage: session.nativeLanguage,
        ageGroup: session.ageGroup,
        learningGoal: session.learningGoal,
        question: currentQ,
        answer: answer,
      );

      // Append to session
      final updatedAnswers = [...session.answers, answer];
      final updatedEvaluations = [...session.evaluations, evaluation];

      final nextDiff = _engine.calculateNextDifficulty(
        session.copyWith(evaluations: updatedEvaluations),
        evaluation,
      );

      final updatedSession = session.copyWith(
        answers: updatedAnswers,
        evaluations: updatedEvaluations,
        currentDifficulty: nextDiff,
        currentQuestionIndex: session.currentQuestionIndex + 1,
      );

      final shouldStop = _engine.shouldStop(updatedSession);

      if (shouldStop) {
        final result = _engine.calculateFinalResult(updatedSession);
        final profile = result.toLearningProfile(
          userId: updatedSession.userId,
          targetLanguage: updatedSession.targetLanguage.id,
        );

        state = state.copyWith(
          session: updatedSession.copyWith(
            status: PlacementSessionStatus.completed,
            completedAt: DateTime.now(),
          ),
          lastEvaluation: evaluation,
          feedbackMessage: evaluation.explanationArabic,
          result: result,
          learningProfile: profile,
          status: PlacementStatus.completed,
          isSubmitting: false,
        );
      } else {
        // Fetch next adaptive question
        final previousIds = updatedSession.questions.map((q) => q.id).toList();
        final nextQuestion = await _contentProvider.getNextQuestion(
          targetLanguage: updatedSession.targetLanguage,
          nativeLanguage: updatedSession.nativeLanguage,
          ageGroup: updatedSession.ageGroup,
          learningGoal: updatedSession.learningGoal,
          difficulty: nextDiff,
          previousQuestionIds: previousIds,
        );

        state = state.copyWith(
          session: updatedSession.copyWith(
            questions: [...updatedSession.questions, nextQuestion],
          ),
          currentQuestion: nextQuestion,
          lastEvaluation: evaluation,
          feedbackMessage: evaluation.explanationArabic,
          status: PlacementStatus.questionReady,
          questionStartTime: DateTime.now(),
          isSubmitting: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: PlacementStatus.error,
        errorMessage: e.toString(),
        isSubmitting: false,
      );
    }
  }

  void reset() {
    state = const PlacementState();
  }
}

final placementNotifierProvider =
    StateNotifierProvider<PlacementNotifier, PlacementState>((ref) {
      final contentProvider = ref.watch(placementContentProvider);
      final evalProvider = ref.watch(languageEvaluationProvider);
      final engine = ref.watch(placementEngineProvider);

      return PlacementNotifier(
        contentProvider: contentProvider,
        evaluationProvider: evalProvider,
        engine: engine,
      );
    });
