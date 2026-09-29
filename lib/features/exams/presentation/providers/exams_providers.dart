import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../learning/presentation/providers/learning_providers.dart';
import '../../../onboarding/presentation/providers/onboarding_provider.dart';
import '../../domain/models/exam_models.dart';
import '../../domain/services/exam_generator.dart';
import '../../domain/services/exam_scoring_service.dart';

/// Provider for the singleton [ExamGenerator].
final examGeneratorProvider = Provider<ExamGenerator>((ref) {
  return const ExamGenerator();
});

/// Provider for the singleton [ExamScoringService].
final examScoringServiceProvider = Provider<ExamScoringService>((ref) {
  return const ExamScoringService();
});

/// Provider supplying the list of available exams tailored to the active learner.
final availableExamsProvider = Provider<List<Exam>>((ref) {
  final generator = ref.watch(examGeneratorProvider);
  final onboardingData = ref.watch(onboardingProvider.select((s) => s.data));
  final profile = ref.watch(learningProfileProvider);

  final targetLang = onboardingData.targetLanguage?.id ?? 'english';
  final ageGroup = onboardingData.ageGroup;

  return generator.generateAvailableExams(
    targetLanguage: targetLang,
    cefrLevel: profile.estimatedCefrLevel,
    ageGroup: ageGroup,
  );
});

/// Provider for the learner's completed exam history.
final examHistoryProvider = FutureProvider<List<ExamResult>>((ref) async {
  final repo = ref.watch(learningRepositoryProvider);
  return repo.getExamResults('usr_active');
});

/// Holds the most recently evaluated [ExamResult] for review on the Result screen.
final selectedExamResultProvider = StateProvider<ExamResult?>((ref) => null);

/// StateNotifier driving the active exam attempt session.
class ExamAttemptNotifier extends StateNotifier<ExamAttemptState?> {
  final Ref _ref;

  ExamAttemptNotifier(this._ref) : super(null);

  /// Initializes and starts an exam attempt.
  void startExam(Exam exam) {
    state = ExamAttemptState(
      exam: exam,
      currentSectionIndex: 0,
      currentQuestionIndex: 0,
      answers: {},
      isSubmitting: false,
    );
  }

  /// Selects an option for a multiple choice / reading / grammar question.
  void selectOption(int optionIndex) {
    final current = state;
    final q = current?.currentQuestion;
    if (current == null || q == null) return;

    final updatedAnswers = Map<String, ExamAnswer>.from(current.answers);
    updatedAnswers[q.id] = ExamAnswer(
      questionId: q.id,
      selectedOptionIndex: optionIndex,
      isSkipped: false,
    );

    state = current.copyWith(answers: updatedAnswers);
  }

  /// Records spoken audio text for a speaking question.
  void recordSpokenAnswer(String spokenText) {
    final current = state;
    final q = current?.currentQuestion;
    if (current == null || q == null) return;

    final updatedAnswers = Map<String, ExamAnswer>.from(current.answers);
    updatedAnswers[q.id] = ExamAnswer(
      questionId: q.id,
      spokenText: spokenText,
      isSkipped: false,
    );

    state = current.copyWith(answers: updatedAnswers);
  }

  /// Skips the current question explicitly.
  void skipQuestion() {
    final current = state;
    final q = current?.currentQuestion;
    if (current == null || q == null) return;

    final updatedAnswers = Map<String, ExamAnswer>.from(current.answers);
    updatedAnswers[q.id] = ExamAnswer(questionId: q.id, isSkipped: true);

    state = current.copyWith(answers: updatedAnswers);
    nextQuestion();
  }

  /// Advances to the next question or next section.
  void nextQuestion() {
    final current = state;
    if (current == null) return;

    final currentSec = current.currentSection;
    if (currentSec == null) return;

    if (current.currentQuestionIndex + 1 < currentSec.questions.length) {
      state = current.copyWith(
        currentQuestionIndex: current.currentQuestionIndex + 1,
      );
    } else if (current.currentSectionIndex + 1 < current.exam.sections.length) {
      state = current.copyWith(
        currentSectionIndex: current.currentSectionIndex + 1,
        currentQuestionIndex: 0,
      );
    }
  }

  /// Navigates back to the previous question.
  void previousQuestion() {
    final current = state;
    if (current == null) return;

    if (current.currentQuestionIndex > 0) {
      state = current.copyWith(
        currentQuestionIndex: current.currentQuestionIndex - 1,
      );
    } else if (current.currentSectionIndex > 0) {
      final prevSecIndex = current.currentSectionIndex - 1;
      final prevSec = current.exam.sections[prevSecIndex];
      state = current.copyWith(
        currentSectionIndex: prevSecIndex,
        currentQuestionIndex: prevSec.questions.length - 1,
      );
    }
  }

  /// Submits the completed exam attempt, calculates scores, updates profile evidence, and persists result.
  Future<ExamResult?> submitExam() async {
    final current = state;
    if (current == null || current.isSubmitting) return null;

    state = current.copyWith(isSubmitting: true);

    final scoringService = _ref.read(examScoringServiceProvider);
    final attemptId = 'attempt_${DateTime.now().millisecondsSinceEpoch}';

    final result = scoringService.evaluateAttempt(
      exam: current.exam,
      answers: current.answers,
      attemptId: attemptId,
    );

    // Persist result to repository
    final repo = _ref.read(learningRepositoryProvider);
    await repo.saveExamResult('usr_active', result);

    // Update learning profile strengths & focus areas based on exam evidence
    final profile = _ref.read(learningProfileProvider);
    final updatedWeaknesses = result.areasForImprovementArabic;
    final updatedStrengths =
        {...profile.strengths, ...result.strengthsArabic}.toList();

    final updatedProfile = profile.copyWith(
      weaknesses: updatedWeaknesses,
      strengths: updatedStrengths,
    );
    await _ref
        .read(learningProfileProvider.notifier)
        .updateProfile(updatedProfile);

    // Store in selected result provider for UI navigation
    _ref.read(selectedExamResultProvider.notifier).state = result;

    state = current.copyWith(isSubmitting: false, result: result);

    // Refresh history
    _ref.invalidate(examHistoryProvider);

    return result;
  }
}

/// Provider for active exam attempt state.
final activeExamAttemptNotifierProvider =
    StateNotifierProvider<ExamAttemptNotifier, ExamAttemptState?>((ref) {
      return ExamAttemptNotifier(ref);
    });
