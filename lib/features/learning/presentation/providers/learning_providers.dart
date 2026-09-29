import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../account/domain/models/account_context.dart';
import '../../../onboarding/presentation/providers/onboarding_provider.dart';
import '../../../progress/domain/models/xp_models.dart';
import '../../data/curriculum/starter_curriculum.dart';
import '../../data/repositories/remote_learning_repository.dart';
import '../../domain/models/learner_context.dart';
import '../../domain/models/learner_progress.dart';
import '../../domain/models/learning_profile.dart';
import '../../domain/models/learning_recommendation.dart';
import '../../domain/models/lesson_models.dart';
import '../../domain/models/vocabulary_item.dart';
import '../../domain/repositories/learning_repository.dart';
import '../../domain/services/adaptive_learning_engine.dart';
import '../../domain/services/daily_learning_plan_engine.dart';

/// Provider for the singleton [AdaptiveLearningEngine].
final adaptiveLearningEngineProvider = Provider<AdaptiveLearningEngine>((ref) {
  return const AdaptiveLearningEngine();
});

/// Provider for the active [LearningRepository] (defaults to production RemoteLearningRepository).
final learningRepositoryProvider = Provider<LearningRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return RemoteLearningRepository(apiClient);
});

/// StateNotifier for managing the student's [LearningProfile].
class LearningProfileNotifier extends StateNotifier<LearningProfile> {
  final LearningRepository _repo;

  LearningProfileNotifier(this._repo, LearningProfile initialProfile)
    : super(initialProfile);

  Future<void> updateProfile(LearningProfile updated) async {
    state = updated;
    await _repo.updateLearningProfile(updated);
  }

  void updateCurrentLesson(String lessonId) {
    state = state.copyWith(currentLessonId: lessonId);
  }
}

final learningProfileProvider =
    StateNotifierProvider<LearningProfileNotifier, LearningProfile>((ref) {
      final repo = ref.watch(learningRepositoryProvider);
      return LearningProfileNotifier(
        repo,
        LearningProfile.defaultProfile(userId: 'usr_active'),
      );
    });

/// StateNotifier for managing [LearnerProgress].
class LearnerProgressNotifier extends StateNotifier<LearnerProgress> {
  final LearningRepository _repo;

  LearnerProgressNotifier(this._repo, LearnerProgress initialProgress)
    : super(initialProgress);

  void markLessonCompleted(String lessonId) {
    if (!state.completedLessonIds.contains(lessonId)) {
      final newXp = state.totalXp + 30;
      final tx = XpTransaction(
        id: 'xp_lesson_${lessonId}_${DateTime.now().millisecondsSinceEpoch}',
        activityType: XpActivityType.lessonCompletion,
        referenceId: lessonId,
        xpEarned: 30,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        completedLessonIds: [...state.completedLessonIds, lessonId],
        totalMinutesLearned: state.totalMinutesLearned + 8,
        totalXp: newXp,
        xpTransactions: [...state.xpTransactions, tx],
      );
      _repo.updateLearnerProgress('usr_active', state);
    }
  }

  void addXp(
    int xp, {
    XpActivityType activityType = XpActivityType.tutorConversation,
    String? referenceId,
  }) {
    if (xp <= 0) return;
    final tx = XpTransaction(
      id: 'xp_${DateTime.now().millisecondsSinceEpoch}',
      activityType: activityType,
      referenceId: referenceId,
      xpEarned: xp,
      timestamp: DateTime.now(),
    );
    state = state.copyWith(
      totalXp: state.totalXp + xp,
      xpTransactions: [...state.xpTransactions, tx],
    );
    _repo.updateLearnerProgress('usr_active', state);
  }
}

final learnerProgressProvider =
    StateNotifierProvider<LearnerProgressNotifier, LearnerProgress>((ref) {
      final repo = ref.watch(learningRepositoryProvider);
      return LearnerProgressNotifier(
        repo,
        LearnerProgress(
          completedLessonIds: const [],
          inProgressLessonId: 'lesson_1_1',
          masteredVocabCount: 0,
          reviewQueueCount: 1,
          lastSessionDate: DateTime.now(),
        ),
      );
    });

/// Provider for available curriculum modules.
final curriculumModulesProvider = FutureProvider<List<CurriculumModule>>((
  ref,
) async {
  final repo = ref.watch(learningRepositoryProvider);
  return repo.getCurriculumModules(language: 'english');
});

/// Provider for vocabulary list.
final vocabularyListProvider = FutureProvider<List<VocabularyItem>>((
  ref,
) async {
  final repo = ref.watch(learningRepositoryProvider);
  return repo.getVocabularyList('usr_active');
});

/// Provider computing the authoritative [LearnerContext] for the AI Tutor and Adaptive Engine.
final learnerContextProvider = Provider<LearnerContext>((ref) {
  final profile = ref.watch(learningProfileProvider);
  final progress = ref.watch(learnerProgressProvider);
  final modulesAsync = ref.watch(curriculumModulesProvider);
  final vocabAsync = ref.watch(vocabularyListProvider);
  final onboardingData = ref.watch(onboardingProvider.select((s) => s.data));

  final allModules = modulesAsync.value ?? StarterCurriculum.modules;
  final allLessons = allModules.expand((m) => m.lessons).toList();

  final currentLesson = allLessons.firstWhere(
    (l) => l.id == profile.currentLessonId,
    orElse:
        () =>
            allLessons.isNotEmpty
                ? allLessons.first
                : StarterCurriculum.modules.first.lessons.first,
  );

  final currentModule = allModules.firstWhere(
    (m) => m.lessons.any((l) => l.id == currentLesson.id),
    orElse: () => allModules.first,
  );

  final vocabList = vocabAsync.value ?? [];
  final dueVocab =
      vocabList.where((v) => v.isDueForReview(DateTime.now())).length;

  return LearnerContext(
    targetLanguage: onboardingData.targetLanguage?.id ?? profile.targetLanguage,
    nativeLanguage: onboardingData.nativeLanguage?.code ?? 'arabic',
    ageGroup: onboardingData.ageGroup?.name ?? 'adult',
    cefrLevel: profile.estimatedCefrLevel,
    learningGoal: onboardingData.learningGoal?.id ?? 'conversation',
    experienceLevel: onboardingData.experienceLevel?.id ?? 'beginnerWithBasics',
    tutorPersona: onboardingData.selectedTutorId ?? 'abbas',
    currentLessonId: currentLesson.id,
    currentLessonTitle: currentLesson.title,
    currentTopic: currentModule.theme,
    targetSkill: currentLesson.primarySkill,
    targetVocabulary: currentLesson.targetVocabulary,
    weaknesses: profile.weaknesses,
    strengths: profile.strengths,
    streakDays: progress.streakData.currentStreak,
    totalXp: progress.totalXp,
    dueVocabularyCount: dueVocab,
  );
});

/// Computes the top [LearningRecommendation] for the student's home dashboard.
final dailyRecommendationProvider = Provider<LearningRecommendation>((ref) {
  final engine = ref.watch(adaptiveLearningEngineProvider);
  final profile = ref.watch(learningProfileProvider);
  final progress = ref.watch(learnerProgressProvider);
  final modulesAsync = ref.watch(curriculumModulesProvider);
  final vocabAsync = ref.watch(vocabularyListProvider);

  final allLessons =
      modulesAsync.value?.expand((m) => m.lessons).toList() ?? [];
  final vocabItems = vocabAsync.value ?? [];

  return engine.generateDailyRecommendation(
    profile: profile,
    progress: progress,
    vocabularyItems: vocabItems,
    availableLessons: allLessons,
  );
});

/// Provider for the singleton [DailyLearningPlanEngine].
final dailyLearningPlanEngineProvider = Provider<DailyLearningPlanEngine>((
  ref,
) {
  return const DailyLearningPlanEngine();
});

/// Provider computing the full deterministic [DailyPlanResult] for the student home dashboard.
final dailyLearningPlanProvider = Provider<DailyPlanResult>((ref) {
  final engine = ref.watch(dailyLearningPlanEngineProvider);
  final profile = ref.watch(learningProfileProvider);
  final progress = ref.watch(learnerProgressProvider);
  final modulesAsync = ref.watch(curriculumModulesProvider);
  final vocabAsync = ref.watch(vocabularyListProvider);
  final onboardingData = ref.watch(onboardingProvider.select((s) => s.data));

  final allModules = modulesAsync.value ?? StarterCurriculum.modules;
  final allLessons = allModules.expand((m) => m.lessons).toList();
  final vocabItems = vocabAsync.value ?? [];

  return engine.generatePlan(
    profile: profile,
    progress: progress,
    vocabularyItems: vocabItems,
    availableLessons: allLessons,
    isChild: onboardingData.isChild,
    accountContext:
        onboardingData.isSchool
            ? AccountContext.school
            : AccountContext.individual,
  );
});
