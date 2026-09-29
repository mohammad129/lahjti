import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../learning/data/curriculum/starter_curriculum.dart';
import '../../../learning/presentation/providers/learning_providers.dart';
import '../../../onboarding/domain/models/age_group.dart';
import '../../../onboarding/presentation/providers/onboarding_provider.dart';
import '../../data/repositories/remote_school_learning_repository.dart';
import '../../domain/models/daily_task.dart';
import '../../domain/models/game_models.dart';
import '../../domain/models/school_student_profile.dart';
import '../../domain/models/student_progress_summary.dart';
import '../../domain/repositories/student_dashboard_repository.dart';
import '../../domain/services/daily_task_engine.dart';

/// Provider for the singleton StudentDashboardRepository instance.
/// Uses RemoteSchoolLearningRepository for backend integration with graceful local fallback.
final studentDashboardRepositoryProvider = Provider<StudentDashboardRepository>(
  (ref) {
    final apiClient = ref.watch(apiClientProvider);
    return RemoteSchoolLearningRepository(apiClient);
  },
);

/// Provider for the deterministic DailyTaskEngine.
final dailyTaskEngineProvider = Provider<DailyTaskEngine>((ref) {
  return const DailyTaskEngine();
});

/// StateProvider holding the authenticated School Student profile.
final currentSchoolStudentProfileProvider =
    StateProvider<SchoolStudentProfile?>((ref) => null);

/// Provider to determine if the active student is in Child-Friendly Mode (Ages 6–10).
final isChildModeProvider = Provider<bool>((ref) {
  final student = ref.watch(currentSchoolStudentProfileProvider);
  final onboardingData = ref.watch(onboardingProvider.select((s) => s.data));

  if (student?.ageGroup == AgeGroup.age6_10) return true;
  if (onboardingData.ageGroup == AgeGroup.age6_10) return true;

  final grade = student?.grade ?? onboardingData.schoolGrade ?? '';
  if (grade.contains('الأول') ||
      grade.contains('الثاني') ||
      grade.contains('الثالث') ||
      grade.contains('الرابع') ||
      grade.contains('الخامس') ||
      grade.contains('Grade 1') ||
      grade.contains('Grade 2') ||
      grade.contains('Grade 3') ||
      grade.contains('Grade 4') ||
      grade.contains('Grade 5')) {
    return true;
  }

  return false;
});

/// Provider for student daily learning tasks.
final studentDailyTasksProvider = FutureProvider<List<DailyTask>>((ref) async {
  final repo = ref.watch(studentDashboardRepositoryProvider);
  final student = ref.watch(currentSchoolStudentProfileProvider);
  final onboardingData = ref.watch(onboardingProvider.select((s) => s.data));
  final isChild = ref.watch(isChildModeProvider);

  final studentId = student?.studentId ?? 'stu_sami_01';
  final schoolCode =
      student?.schoolCode ?? onboardingData.schoolCode ?? 'SCH-1001';

  return repo.getDailyTasks(
    studentId: studentId,
    schoolCode: schoolCode,
    isChild: isChild,
  );
});

/// Provider calculating the full deterministic DailyTaskPlan from current progress.
final studentDailyPlanProvider = Provider<DailyTaskPlan>((ref) {
  final engine = ref.watch(dailyTaskEngineProvider);
  final profile = ref.watch(learningProfileProvider);
  final progress = ref.watch(learnerProgressProvider);
  final vocabAsync = ref.watch(vocabularyListProvider);
  final isChild = ref.watch(isChildModeProvider);

  final vocabList = vocabAsync.value ?? const [];
  final lessonsList =
      StarterCurriculum.modules.expand((m) => m.lessons).toList();

  return engine.generatePlan(
    profile: profile,
    progress: progress,
    vocabularyList: vocabList,
    availableLessons: lessonsList,
    isChild: isChild,
  );
});

/// Provider for student gamification progress summary.
final studentProgressSummaryProvider = FutureProvider<StudentProgressSummary>((
  ref,
) async {
  final repo = ref.watch(studentDashboardRepositoryProvider);
  final student = ref.watch(currentSchoolStudentProfileProvider);
  final onboardingData = ref.watch(onboardingProvider.select((s) => s.data));

  final studentId = student?.studentId ?? 'stu_sami_01';
  final schoolCode =
      student?.schoolCode ?? onboardingData.schoolCode ?? 'SCH-1001';

  return repo.getStudentProgressSummary(
    studentId: studentId,
    schoolCode: schoolCode,
  );
});

/// Provider for mini-games catalog.
final availableGamesProvider = FutureProvider<List<GameActivity>>((ref) async {
  final repo = ref.watch(studentDashboardRepositoryProvider);
  final student = ref.watch(currentSchoolStudentProfileProvider);
  final onboardingData = ref.watch(onboardingProvider.select((s) => s.data));
  final isChild = ref.watch(isChildModeProvider);

  final studentId = student?.studentId ?? 'stu_sami_01';
  final schoolCode =
      student?.schoolCode ?? onboardingData.schoolCode ?? 'SCH-1001';

  return repo.getAvailableGames(
    studentId: studentId,
    schoolCode: schoolCode,
    isChild: isChild,
  );
});

/// Provider for specific game activity.
final gameDetailsProvider = FutureProvider.family<GameActivity?, String>((
  ref,
  gameId,
) async {
  final repo = ref.watch(studentDashboardRepositoryProvider);
  final student = ref.watch(currentSchoolStudentProfileProvider);
  final onboardingData = ref.watch(onboardingProvider.select((s) => s.data));

  final studentId = student?.studentId ?? 'stu_sami_01';
  final schoolCode =
      student?.schoolCode ?? onboardingData.schoolCode ?? 'SCH-1001';

  return repo.getGameById(
    gameId: gameId,
    studentId: studentId,
    schoolCode: schoolCode,
  );
});

/// Provider for unlocked achievements.
final studentAchievementsProvider = FutureProvider<List<String>>((ref) async {
  final repo = ref.watch(studentDashboardRepositoryProvider);
  final student = ref.watch(currentSchoolStudentProfileProvider);
  final onboardingData = ref.watch(onboardingProvider.select((s) => s.data));

  final studentId = student?.studentId ?? 'stu_sami_01';
  final schoolCode =
      student?.schoolCode ?? onboardingData.schoolCode ?? 'SCH-1001';

  return repo.getStudentAchievements(
    studentId: studentId,
    schoolCode: schoolCode,
  );
});

/// Controller for mutating student daily tasks and game sessions with anti-farming protection.
class StudentActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  final Set<String> _recentlySubmittedGames = {};

  StudentActionsNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<void> completeTask(String taskId) async {
    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(studentDashboardRepositoryProvider);
      final student = _ref.read(currentSchoolStudentProfileProvider);
      final onboardingData = _ref.read(
        onboardingProvider.select((s) => s.data),
      );

      final studentId = student?.studentId ?? 'stu_sami_01';
      final schoolCode =
          student?.schoolCode ?? onboardingData.schoolCode ?? 'SCH-1001';

      await repo.completeDailyTask(
        studentId: studentId,
        taskId: taskId,
        schoolCode: schoolCode,
      );

      _ref.invalidate(studentDailyTasksProvider);
      _ref.invalidate(studentProgressSummaryProvider);
      _ref.invalidate(studentAchievementsProvider);

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> submitGame(GameResult result) async {
    // Anti-farming check: prevent rapid duplicate submissions of same game
    final submissionKey = '${result.gameId}_${result.completedAt.minute}';
    if (_recentlySubmittedGames.contains(submissionKey)) {
      // Duplicate submission ignored safely
      state = const AsyncValue.data(null);
      return;
    }
    _recentlySubmittedGames.add(submissionKey);

    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(studentDashboardRepositoryProvider);
      final student = _ref.read(currentSchoolStudentProfileProvider);
      final onboardingData = _ref.read(
        onboardingProvider.select((s) => s.data),
      );

      final studentId = student?.studentId ?? 'stu_sami_01';
      final schoolCode =
          student?.schoolCode ?? onboardingData.schoolCode ?? 'SCH-1001';

      await repo.submitGameResult(
        studentId: studentId,
        schoolCode: schoolCode,
        result: result,
      );

      _ref.invalidate(studentDailyTasksProvider);
      _ref.invalidate(studentProgressSummaryProvider);
      _ref.invalidate(studentAchievementsProvider);

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final studentActionsProvider =
    StateNotifierProvider<StudentActionsNotifier, AsyncValue<void>>((ref) {
      return StudentActionsNotifier(ref);
    });
