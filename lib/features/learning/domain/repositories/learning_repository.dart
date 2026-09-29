import '../../../exams/domain/models/exam_models.dart';
import '../../../progress/domain/models/progress_summary_models.dart';
import '../../../progress/domain/models/xp_models.dart';
import '../models/learner_progress.dart';
import '../models/learning_profile.dart';
import '../models/lesson_models.dart';
import '../models/vocabulary_item.dart';

/// Repository contract for fetching and persisting student learning profiles, progress, and curriculum.
abstract class LearningRepository {
  Future<LearningProfile> getLearningProfile(String userId);
  Future<void> updateLearningProfile(LearningProfile profile);
  Future<LearnerProgress> getLearnerProgress(String userId);
  Future<void> updateLearnerProgress(String userId, LearnerProgress progress);
  Future<List<CurriculumModule>> getCurriculumModules({
    required String language,
  });
  Future<List<VocabularyItem>> getVocabularyList(String userId);
  Future<void> updateVocabularyItem(String userId, VocabularyItem item);
  Future<List<ExamResult>> getExamResults(String userId);
  Future<void> saveExamResult(String userId, ExamResult result);
  Future<DailyProgressSummary> getDailyProgress(String userId, DateTime date);
  Future<WeeklyProgressSummary> getWeeklyProgress(
    String userId,
    DateTime weekStart,
  );
  Future<void> recordLearningActivity(
    String userId,
    XpActivityType type, {
    int? accuracy,
    int? count,
    String? referenceId,
  });
}
